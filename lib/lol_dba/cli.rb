require 'optparse'
require 'lol_dba/version'

module LolDba
  class CLI
    class << self
      def start
        new(Dir.pwd, parse_options).start(ARGV.first)
      end

      def parse_options
        options = {}
        OptionParser.new do |opts|
          opts.on('-d', '--debug',
                  'Show stack traces when an error occurs.') do |opt|
            options[:debug] = opt
          end
          opts.on_tail('-v', '--version', 'Show version') do
            puts LolDba::VERSION
            exit
          end
        end.parse!
      end
    end

    def initialize(path, options)
      @path = path
      @options = options
    end

    def start(arg)
      load_application
      select_action(arg)
    rescue Exception => exception
      if @options[:debug]
        warn "Failed: #{exception.class}: #{exception.message}"
        warn exception.backtrace.map { |trace| "    from #{trace}" }
      end
    end

    protected

    def select_action(arg)
      if arg =~ /db:find_indexes/
        LolDba::IndexFinder.run
      elsif arg !~ /\[/
        LolDba::SqlGenerator.run('all')
      else
        which = arg.match(/.*\[(.*)\].*/).captures[0]
        LolDba::SqlGenerator.run(which)
      end
    end

    # Tks to https://github.com/voormedia/rails-erd/blob/master/lib/rails_erd/cli.rb
    def load_application
      require "#{@path}/config/environment"
    end
  end
end
