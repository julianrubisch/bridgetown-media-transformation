# frozen_string_literal: true

require "fileutils"

class MediaTransformation
  attr_reader :dest, :src, :specs, :optimize, :interlace, :site

  def initialize(dest:, src:, specs:, optimize:, interlace:, site:, builder:)
    @dest = dest
    @src = src
    @specs = specs
    @optimize = optimize
    @interlace = interlace
    @site = site
    @builder = builder
  end

  def file_basename(path)
    File.basename(File.join(site.source, path), ".*")
  end

  def file_hash
    Digest::MD5.file(File.join(site.source, src)).hexdigest
  end

  def process
    return if src.empty?

    pipeline = ImageProcessing::Vips.source(File.join(site.source, src))

    specs.each do |format, specs|
      pipeline.convert(format)

      pipeline.saver(interlace: true) if format == "jpg" && interlace

      specs.each do |spec|
        destination_filename = "#{file_hash}-#{file_basename(src)}"
        cache_destination = File.join(site.source, "..", ".bmt-cache", "#{File.join(File.dirname(dest), destination_filename)}-#{spec.first}.#{format}")
        destination = File.join(site.config["destination"], "#{File.join(File.dirname(dest), destination_filename)}-#{spec.first}.#{format}")

        FileUtils.mkdir_p(File.dirname(cache_destination))

        unless File.exist? cache_destination
          if @builder.verbose?
            Bridgetown.logger.info "[media-transformation] Generating #{cache_destination}"
          end

          pipeline
            .resize_to_fit(spec.first, nil)
            .call(destination: cache_destination)

          if optimize && Bridgetown.environment == "production"
            if @builder.verbose?
              Bridgetown.logger.info "[media-transformation] Optimizing #{cache_destination}"
            end
            image_optim = ImageOptim.new
            image_optim.optimize_image!(cache_destination)
          end
        end

        if @builder.verbose?
          Bridgetown.logger.info "[media-transformation] Copying #{cache_destination} to #{destination}"
        end
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(cache_destination, destination)
      end
    end
  end
end
