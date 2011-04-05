module FileSystem::Model::FlowMeterExtensions
  FILENAME_REGEX = /^(?:(\d+))([^.]+)?(?:\.([\.\-\w]+))?/
  IGNORED = %w{created_at updated_at}

  def self.included(base)
    # Instance methods
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
      %w{filename save_file load_file}.each do |m|
        alias_method_chain m.to_sym, :id
      end
    end
    # Singleton/class methods
    class << base
      %w{find_or_initialize_by_filename}.each do |m|
       alias_method_chain m.to_sym, :id
      end
    end
  end

  module ClassMethods
    def find_or_initialize_by_filename_with_id(filename)
      id = $1.to_i if File.basename(filename) =~ FILENAME_REGEX
      find_or_initialize_by_id(id)
    end
  end

  module InstanceMethods
    def filename_with_id
      File.join(self.class.path, ["%05d" % self.id, 'yaml'].join("."))
    end

    def save_file_with_id
      FileUtils.mkdir_p(File.dirname(self.filename)) unless File.directory?(File.dirname(self.filename))
      attrs = self.attributes.dup
      IGNORED.each {|a| attrs.delete a}
      File.open(self.filename, 'w') {|f| f.write YAML.dump(attrs) }
    end

    def load_file_with_id(path)
      attrs = YAML.load_file(path)
      IGNORED.each {|a| attrs.delete a }
      attrs = attrs.reject {|k,v| v.blank? }
      self.attributes = attrs
      self.id = attrs["id"]
      save!
    end
  end
end