class MediaTransformation
  attr_reader :dest, :src, :specs, :optimize, :interlace

  def initialize(dest:, src:, specs:, optimize:, interlace:)
    @dest = dest
    @src = src
    @specs = specs
    @optimize = optimize
    @interlace = interlace
  end

  def file_basename(path, site)
    File.basename(File.join(site.source, path), ".*")
  end

  def process(site:)
    return if src.empty?

    pipeline = ImageProcessing::Vips.source(File.join(site.source, src))

    specs.each do |format, specs|
      pipeline.convert(format) 

      pipeline.saver(interlace: true) if format == "jpg" && interlace

      specs.each do |spec|
        destination = File.join(site.config["destination"], "#{Bridgetown.environment == 'development' ? '_bridgetown/' : ''}", "#{File.join(File.dirname(dest), file_basename(src, site))}-#{spec.first}.#{format}")

        FileUtils.mkdir_p(File.dirname(destination)) if Bridgetown.environment == "development"

        unless File.exist? destination
          Bridgetown.logger.info "[media-transformation] Generating #{destination}"

          pipeline
            .resize_to_fit(spec.first, nil)
            .call(destination: destination)

          if optimize && Bridgetown.environment == "production"
            Bridgetown.logger.info "[media-transformation] Optimizing #{destination}"
            image_optim = ImageOptim.new
            image_optim.optimize_image!(destination)
          end
        end
      end
    end
  end
end
