module LolDba
  class ErrorLogging
    def self.log(class_name, reflection_options, exception)
      puts 'Some errors here:'
      puts 'Please, create an issue with the following information here https://github.com/plentz/lol_dba/issues:'
      puts '***************************'
      puts "Class: #{class_name}"
      puts "Association type: #{reflection_options.macro}"
      puts "Association options: #{reflection_options.options}"
      puts "Exception: #{exception.message}"
      exception.backtrace.each { |trace| puts trace }
    end
  end
end
