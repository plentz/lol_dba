require 'optparse'
require 'lol_dba/sql_generator'

module LolDba
  class CLI

    class << self
      def start
        options = {}
        OptionParser.new do |opts|
          opts.on('-d', '--debug', 'Show stack traces when an error occurs.') { |v| options[:debug] = v }
          opts.on_tail("-v", "--version", "Show version") do
            puts LolDba::VERSION
            exit
          end
        end.parse!
        new(Dir.pwd, options).start
      end
    end

    def initialize(path, options)
      @path, @options = path, options
    end

    def start
      load_application
      arg = ARGV.first
      if arg =~ /db:find_indexes/
        LolDba.simple_migration
      elsif arg !~ /\[/
        LolDba::SqlGenerator.generate("all")
      else
        which = arg.match(/.*\[(.*)\].*/).captures[0]
        LolDba::SqlGenerator.generate(which)
      end
    rescue Exception => e
      $stderr.puts "Failed: #{e.class}: #{e.message}" if @options[:debug]
      $stderr.puts e.backtrace.map { |t| "    from #{t}" } if @options[:debug]
    end

    protected

    # Tks to https://github.com/voormedia/rails-erd/blob/master/lib/rails_erd/cli.rb
    def load_application
      require "#{@path}/config/environment"
    end
  end
end
