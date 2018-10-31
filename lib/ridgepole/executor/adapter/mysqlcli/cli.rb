# frozen_string_literal: true

require 'optparse'
require 'swiftcore/tasks'
require 'ridgepole/executor/config'

module Ridgepole
  class Executor
    class Adapter
      class Mysqlcli
        # Parse command line arguments for this CLI.
        class Cli
          Task = Swiftcore::Tasks::Task
          DEFAULT_CMD = 'mysql'
          attr_reader :config, :metaconfig

          def initialize
            @config = Config.new
            @config[:command] = DEFAULT_CMD
            @metaconfig = Config.new
          end

          def _opt_bind(opts, call_list)
            opts.on('-b', '--bind HOST[:PORT}|PATH') do |bind|
              call_list << Task.new(9000) do
                if File.exist?(bind)
                  @config[:socket] = bind
                else
                  @config[:host], @config[:port] = bind.split(/:/, 2)
                end
              end
            end
          end

          def _opt_cmdline(opts, call_list)
            opts.on('-c', '--command COMMAND') do |command|
              call_list << Task.new(9000) { @config[:command] = command }
            end
          end

          def _opt_database(opts, call_list)
            opts.on('-d', '--database DATABASE') do |database|
              call_list << Task.new(9000) { @config[:database] = database }
            end
          end

          def _opt_password(opts, call_list)
            opts.on('-p', '--password PASSWORD') do |password|
              call_list << Task.new(9000) { @config[:password] = password }
            end
          end

          def _opt_user(opts, call_list)
            opts.on('-u', '--user USERNAME') do |user|
              call_list << Task.new(9000) { @config[:user] = user }
            end
          end

          def _setup_helptext
            @metaconfig[:helptext] << <<~EHELP
              -b, --bind HOST[:PORT]|PATH :
                The host/port or the socket to connect to to access the database.

              -c, --command COMMAND:
                The command to invoke. This defaults to #{DEFAULT_CMD}.

              -d, --database DBNAME:
                The name of the database to access.

              -p, --password PASSWORD:
                The password to use to log into the database.

              -u, --user USER:
                The user name to use to log into the database.
            EHELP
          end

          def _handle_options(opts, call_list)
            _opt_bind(opts, call_list)
            _opt_cmdline(opts, call_list)
            _opt_database(opts, call_list)
            _opt_password(opts, call_list)
            _opt_user(opts, call_list)
          end

          def _handle_leftovers(options)
            leftovers = []

            begin
              options.parse!(ARGV)
            rescue OptionParser::InvalidOption => e
              e.recover ARGV
              leftovers << ARGV.shift
              leftovers << ARGV.shift if ARGV.any? && (ARGV.first[0..0] != '-')
              retry
            end

            ARGV.replace(leftovers) if leftovers.any?
          end

          def parse(config, metaconfig)
            @config.merge!(config)
            @metaconfig.merge!(metaconfig)
            call_list = Swiftcore::Tasks::TaskList.new
            _setup_helptext

            options = OptionParser.new do |opts|
              _handle_options(opts, call_list)
            end
            _handle_leftovers(options)

            call_list.run
          end
        end
      end
    end
  end
end
