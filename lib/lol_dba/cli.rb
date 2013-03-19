require 'optparse'

module LolDba
  class CLI

    class << self
      def start
        options = {:format => 'migration'}
        OptionParser.new do |opts|
          opts.on("-f", '--format=[FORMAT]', 'Specify the format to be used (migration or sql), defaults to migration.') { |v| options[:format] = v }
          opts.on('-d', '--debug', 'Show stack traces when an error occurs.') { |v| options[:debug] = v }
        end.parse!
        new(Dir.pwd, options).start
      end
    end

    def initialize(path, options)
      @path, @options = path, options
    end

    def start
      load_application
      validate_format!
      send("generate_#{@options[:format]}")
    rescue Exception => e
      $stderr.puts "Failed: #{e.class}: #{e.message}"
      $stderr.puts e.backtrace.map { |t| "    from #{t}" } if @options[:debug]
    end

    protected

    def validate_format!
      unless self.respond_to?("generate_#{@options[:format]}")
        $stderr.puts "Unknown format: #{@options[:format]}"
        exit 1
      end
    end

    # Tks to https://github.com/voormedia/rails-erd/blob/master/lib/rails_erd/cli.rb
    def load_application
      $stderr.puts "Loading application in '#{File.basename(@path)}'..."
      require "#{@path}/config/environment"
    end

    def generate_sql
      LolDba::SqlGenerator.generate
    end

    def generate_migration
      LolDba.simple_migration
    end
  end
end
