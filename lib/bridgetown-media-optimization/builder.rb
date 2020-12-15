# frozen_string_literal: true

require "pry"
require "image_processing/mini_magick"
require "image_processing/vips"

module BridgetownMediaOptimization
  class Builder < Bridgetown::Builder
    def build
      liquid_tag "resp_picture", as_block: true do |attributes, tag|
        path = tag.context["src"]
        path ||= attributes.split(",").first
        path ||= ""
        # transformation_specs = JSON.parse(attributes.split(",").last)
        transformation_specs ||= {'webp' => [640, 1024, 1280, 1920], 'jpg' => [640, 1024, 1280, 1920]}
        site.data[:media_optimizations] ||= {}
        site.data[:media_optimizations][path] = transformation_specs
        picture_tag(path: path, attributes: tag.content)
      end

      hook :site, :post_write do |site|
        # kick off transformations
        site.data[:media_optimizations].each do |path, spec|
          next if path.empty?

          basename = File.basename(File.join(site.source, path), ".*")
 
          pipeline = ImageProcessing::Vips
            .source(File.join(site.source, path))

          spec.each do |format, widths|
            pipeline
              .convert(format) 

            widths.each do |width|
              pipeline
                .resize_to_limit(width, width)
                .call(destination: File.join(site.config["destination"], "assets/img/#{basename}-#{width}.#{format}"))
            end
          end
        end
      end
    end

    def picture_tag(path:, attributes:)
      tag = <<~PICTURE
        <picture>
          <img src="#{path}" #{attributes}>
        </picture>
      PICTURE
      tag
    end
  end
end

BridgetownMediaOptimization::Builder.register
