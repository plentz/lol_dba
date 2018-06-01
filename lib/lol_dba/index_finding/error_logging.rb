module LolDba
  class ErrorLogging
    def self.log(model_class, reflection_options, exception)
      puts 'some errors here...'
      puts 'please, create an issue with the following information here:'
      puts 'https://github.com/plentz/lol_dba/issues'
      puts '***************************'
      puts "class: #{model_class}"
      puts "association type: #{reflection_options.macro}"
      puts "association options: #{reflection_options.options}"
      puts "exception: #{exception.message}"
      exception.backtrace.each { |trace| puts trace }
    end
  end
end
