module LolDba
  class Writer
    class << self
      attr_accessor :file_name
    
      def reset
        FileUtils.rm_rf output_dir
        Dir.mkdir output_dir
      end
  
      def output_dir
        File.join(Rails.root, "db", "migrate_sql")
      end
  
      def path
        File.join(output_dir, file_name)
      end
  
      def write(string)
        File.open(path, 'a') { |file|
          # if has semi-colons switch the delimiter
          if string[";"] && ! string["DELIMITER"]
            file << "DELIMITER $$\n"
            file << string
            file << "$$\nDELIMITER ;\n"
          else
            file << string
            file << ";\n"
          end
        }
      end
      
    end
    
  end
end
