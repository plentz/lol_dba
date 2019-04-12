module LolDba
  class Writer
    def initialize(file_name)
      @file_name = file_name
    end

    def self.reset_output_dir
      FileUtils.rm_rf output_dir
      Dir.mkdir output_dir
    end

    def write(string)
      return unless @file_name.present?
      File.open(path, 'a') do |file|
        file << string << ";\n"
        file.close
      end
    end

    private_class_method

    def self.output_dir
      File.join(Rails.root, 'db', 'migrate_sql')
    end

    private

    def path
      File.join(self.class.output_dir, @file_name)
    end
  end
end
