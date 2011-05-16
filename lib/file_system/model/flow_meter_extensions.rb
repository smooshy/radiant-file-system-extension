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
      %w{find_or_initialize_by_filename load_files}.each do |m|
       alias_method_chain m.to_sym, :id
      end
    end
  end

  module ClassMethods
    def find_or_initialize_by_filename_with_id(filename)
      id = $1.to_i if File.basename(filename) =~ FILENAME_REGEX
      find_or_initialize_by_id(id)
    end

    def load_files_with_id
      files = Dir[path + "/**"]
      unless files.blank?
        records_on_filesystem = []
        process_after_delete = []
        files.each do |file|
          record = find_or_initialize_by_filename(file)
          puts "Loading #{self.name.downcase} from #{File.basename(file)}"
          record.load_file(file)
          begin
            record.save!
            records_on_filesystem << record
          rescue
            puts "Saving #{self.name.downcase} #{record.id} for later processing"
            process_after_delete << record
          end
        end
        fileless_db_records = records_on_database - records_on_filesystem
        fileless_db_records.each do |item|
          puts "Deleting #{self.name.downcase}: #{item.id}"
          delete_record(item)
        end
        process_after_delete.each do |r|
          puts "Loading #{self.name.downcase}: #{r.id}"
          r.save
        end
      end
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
    end
  end
end