# frozen_string_literal: true

require 'ridgepole/executor/adapter/mysqlcli/cli'

module Ridgepole
  class Executor
    class Adapter
      # Adapter to run nonblocking SQL commands through the `mysql` CLI.
      class Mysqlcli
        def initialize
          @cli = Cli.new
        end

        def parse(config, metaconfig)
          @cli.parse(config, metaconfig)
        end

        def config
          @cli.config
        end

        def dry_run?
          # Use known migrator dry run flags to determine if the adapter should
          # be dry-run too. This should probably use an API in the migrator
          # class....
          ENV['PTOSC_OTHER_FLAGS'] =~ /--dry-run/
        end

        def user_cmdline
          return unless config['user'] || config['username']

          ['--user', config['user'] || config['username']]
        end

        def password_cmdline
          ['--password', config['password']] if config['password']
        end

        def connectivity_cmdline
          cmd = []
          %w[socket host port].each do |x|
            cmd << "--#{x} #{config[x]}" if config[x]
          end
          cmd
        end

        def mysql_cmdline
          [
            config[:command],
            *user_cmdline,
            *password_cmdline,
            *connectivity_cmdline,
            config['database']
          ]
        end

        def do
          if dry_run?
            puts "#{mysql_cmdline.join(' ')}\n  \\. #{config[:sql]}"
          else
            IO.popen(mysql_cmdline, 'w+') do |io|
              io.puts config[:sql]
              io.close_write
              io.read
            end
          end
        end
      end
    end
  end
end
