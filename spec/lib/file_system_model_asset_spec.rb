require File.dirname(__FILE__) + '/../spec_helper'

class MockAsset
  def self.class_of_active_record_descendant(klass)
    MockAsset
  end
end

def mock_filepath
  "#{RAILS_ROOT}/design/mock_assets"
end

describe Asset do

  before :each do
    MockAsset.send :include, FileSystem::Model
    MockAsset.send :include, FileSystem::Model::AssetExtensions
    @model = MockAsset.new
  end

  [
    FileSystem::Model,
    FileSystem::Model::AssetExtensions,
    FileSystem::Model::AssetExtensions::InstanceMethods
  ].each do |module_name|
    it "should include #{module_name} module" do
      Asset.included_modules.should include(module_name)
    end
  end

  it "should include FileSystem::Model::AssetExtensions::ClassMethods module" do
    (class << Asset; self; end).included_modules.
        should include(FileSystem::Model::AssetExtensions::ClassMethods)
  end

  it "should have class methods" do
    [:path, :load_files, :save_files].each do |m|
      MockAsset.should respond_to(m)
    end
  end

  it "should have instance methods" do
    @model.should respond_to(:load_file)
    @model.should respond_to(:save_file)
    @model.should respond_to(:filename)
  end

  %w{find_or_initialize_by_filename}.each do |method|
    it "should redefine #{method} class method" do
      Asset.should respond_to("#{method}")
      Asset.should respond_to("#{method}_with_id")
      Asset.should respond_to("#{method}_without_id")
    end
  end

  %w{filename save_file load_file}.each do |method|
    it "should redefine #{method} instance method" do
      @model.should respond_to("#{method}")
      @model.should respond_to("#{method}_with_id")
      @model.should respond_to("#{method}_without_id")
    end
  end

  describe "filename" do
    before(:each) do
      class << @model
        attr_accessor :id
      end
      @model.id = 1
    end
    it "should create a filename with id" do
      @model.filename.should == "#{RAILS_ROOT}/design/mock_assets/00001.yaml"
    end
    it "should handle a large id" do
      @model.id = 999999
      @model.filename.should == "#{RAILS_ROOT}/design/mock_assets/999999.yaml"
    end
  end

  describe "save_file" do
    before(:each) do
      class << @model
        attr_accessor :id, :title, :caption, :asset_file_name, :asset_content_type, :asset_file_size
      end
      @attrs = {
        :id => 1,
        :title => "asset-name",
        :caption => "Some caption",
        :asset_file_name => "asset-name.png",
        :asset_content_type => "image/png",
        :asset_file_size => 1234
      }
      @model.id = @attrs[:id]
      @model.title = @attrs[:title]
      @model.caption = @attrs[:caption]
      @model.asset_file_name = @attrs[:asset_file_name]
      @model.asset_content_type = @attrs[:asset_content_type]
      @model.asset_file_size = @attrs[:asset_file_size]
      @file_mock = mock("file_mock")
    end

    it "should save file with attributes as yaml" do
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_assets/00001.yaml", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write)
      @model.should_receive(:attributes).and_return(YAML.dump(@attrs))
      @model.save_file
    end
   end
end