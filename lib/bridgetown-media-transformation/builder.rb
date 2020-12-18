# frozen_string_literal: true

require "image_processing/mini_magick"
require "image_processing/vips"
require "image_optim"

module BridgetownMediaTransformation
  class Builder < Bridgetown::Builder
    attr_reader :attributes
    attr_reader :media_transformations

    def build
      @media_transformations ||= {}

      Bridgetown.logger.info "[media-transformation] Interlacing JPEG: #{interlace?}"
      Bridgetown.logger.info "[media-transformation] Optimizing: #{optimize?}"

      liquid_tag "resp_picture", as_block: true do |attributes, tag|
        @attributes = attributes.split(",").map(&:strip)
        path = tag.context["src"]
        path ||= @attributes.first
        lazy = kargs.fetch("lazy") { false }
        transformation_specs = kargs.fetch("transformation_specs") {
          {
            # scaled width, srcset_descriptor
            "webp" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]],
            "jpg" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]]
          }
        }
        @media_transformations.merge!({path => transformation_specs})
        picture_tag(path: path, lazy: lazy, attributes: tag.content, transformation_specs: transformation_specs)
      end

      unless Bridgetown.environment == "test"
        hook :site, :post_write do |site|
          # kick off transformations
          media_transformations.each do |path, spec|
            next if path.empty?

            pipeline = ImageProcessing::Vips.source(File.join(site.source, path))

            spec.each do |format, specs|
              pipeline.convert(format) 

              pipeline.saver(interlace: true) if format == "jpg" && interlace?

              specs.each do |spec|
                destination = File.join(site.config["destination"], "#{File.join(File.dirname(path), file_basename(path))}-#{spec.first}.#{format}")

                unless File.exist? destination
                  Bridgetown.logger.info "[media-transformation] Generating #{destination}"

                  pipeline
                    .resize_to_limit(spec.first, spec.first)
                    .call(destination: destination)

                  if optimize? && Bridgetown.environment == "production"
                    Bridgetown.logger.info "[media-transformation] Optimizing #{destination}"
                    image_optim = ImageOptim.new
                    image_optim.optimize_image!(destination)
                  end
                end
              end
            end
          end
        end
      end
    end

    def picture_tag(path: "", lazy: false, attributes:, transformation_specs:)
      source_elements = transformation_specs.map do |format, spec|
        srcset = spec.map do |s|
          scaled_width, srcset_descriptor = s
          "#{File.join(File.dirname(path), file_basename(path))}-#{scaled_width}.#{format} #{srcset_descriptor}"
        end.join(", ")
        "<source #{lazy ? 'data-' : ''}srcset=\"#{srcset}\" type=\"image/#{format}\"></source>"
      end

      tag = <<~PICTURE
        <picture>
          #{source_elements.join("\n")}
          <img #{lazy ? 'data-' : ''}src="#{path}" #{attributes}>
        </picture>
      PICTURE
      tag
    end
    
    private

    def kargs
      return {} unless attributes.size > 1
      
      json_payload = attributes[1..].join(", ")
      @kargs = JSON.parse(JSON.parse(json_payload).gsub("'", "\""))
    end

    def file_basename(path)
      File.basename(File.join(site.source, path), ".*")
    end

    def interlace?
      options.dig(:interlace) || false
    end

    def optimize?
      options.dig(:optimize) || false
    end

    def options
      config["media_transformation"] || {}
    end
  end
end

BridgetownMediaTransformation::Builder.register
