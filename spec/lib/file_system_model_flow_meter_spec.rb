require File.dirname(__FILE__) + '/../spec_helper'

class MockFlowMeter
  def self.class_of_active_record_descendant(klass)
    MockFlowMeter
  end
end

def mock_filepath
  "#{RAILS_ROOT}/design/mock_flow_meters"
end

describe FlowMeter do

  before :each do
    MockFlowMeter.send :include, FileSystem::Model
    MockFlowMeter.send :include, FileSystem::Model::FlowMeterExtensions
    @model = MockFlowMeter.new
  end

  [
    FileSystem::Model,
    FileSystem::Model::FlowMeterExtensions,
    FileSystem::Model::FlowMeterExtensions::InstanceMethods
  ].each do |module_name|
    it "should include #{module_name} module" do
      FlowMeter.included_modules.should include(module_name)
    end
  end

  it "should include FileSystem::Model::FlowMeterExtensions::ClassMethods module" do
    (class << FlowMeter; self; end).included_modules.
        should include(FileSystem::Model::FlowMeterExtensions::ClassMethods)
  end

  it "should have class methods" do
    [:path, :load_files, :save_files].each do |m|
      MockFlowMeter.should respond_to(m)
    end
  end

  it "should have instance methods" do
    @model.should respond_to(:load_file)
    @model.should respond_to(:save_file)
    @model.should respond_to(:filename)
  end

  %w{find_or_initialize_by_filename load_files}.each do |method|
    it "should redefine #{method} class method" do
      FlowMeter.should respond_to("#{method}")
      FlowMeter.should respond_to("#{method}_with_id")
      FlowMeter.should respond_to("#{method}_without_id")
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
      @model.filename.should == "#{RAILS_ROOT}/design/mock_flow_meters/00001.yaml"
    end
    it "should handle a large id" do
      @model.id = 999999
      @model.filename.should == "#{RAILS_ROOT}/design/mock_flow_meters/999999.yaml"
    end
  end

  describe "save_file" do
    before(:each) do
      class << @model
        attr_accessor :id, :catch_url, :redirect_url, :status
      end
      @attrs = {
        :id => 1,
        :catch_url => "moms",
        :redirect_url => "dads",
        :status => "301 Moved Permanently"
      }
      @model.id = @attrs[:id]
      @model.catch_url = @attrs[:catch_url]
      @model.redirect_url = @attrs[:redirect_url]
      @model.status = @attrs[:status]
      @file_mock = mock("file_mock")
    end

    it "should save file with attributes as yaml" do
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_flow_meters/00001.yaml", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write)
      @model.should_receive(:attributes).and_return(YAML.dump(@attrs))
      @model.save_file
    end
  end
end