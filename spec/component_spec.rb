# frozen_string_literal: true

require "spec_helper"

describe(BridgetownMediaTransformation) do
  let(:overrides) { {} }
  let(:config) do
    Bridgetown.configuration(Bridgetown::Utils.deep_merge_hashes({
      "full_rebuild" => true,
      "root_dir"     => root_dir,
      "source"       => source_dir,
      "destination"  => dest_dir,
    }, overrides))
  end
  let(:metadata_overrides) { {} }
  let(:metadata_defaults) do
    {
      "name" => "My Awesome Site",
      "author" => {
        "name" => "Ada Lovejoy",
      }
    }
  end
  let(:site) { Bridgetown::Site.new(config) }
  let(:contents) { File.read(dest_dir("with_component.html")) }
  before(:each) do
    metadata = metadata_defaults.merge(metadata_overrides).to_yaml.sub("---\n", "")
    File.write(source_dir("_data/site_metadata.yml"), metadata)
    site.process
    FileUtils.rm(source_dir("_data/site_metadata.yml"))
  end

  it "outputs a srcset with default transformations" do
    expect(contents).to match '<source srcset="/assets/img/sample_image-640.webp 640w, /assets/img/sample_image-1024.webp 1024w, /assets/img/sample_image-1280.webp 1280w, /assets/img/sample_image-1920.webp 1920w, /assets/img/sample_image-3840.webp 2x" type="image/webp" />'
    expect(contents).to match '<source srcset="/assets/img/sample_image-640.jpg 640w, /assets/img/sample_image-1024.jpg 1024w, /assets/img/sample_image-1280.jpg 1280w, /assets/img/sample_image-1920.jpg 1920w, /assets/img/sample_image-3840.jpg 2x" type="image/jpg" />'
  end
end
