# frozen_string_literal: true

require 'ridgepole/executor/adapter/mysqlcli/cli'

module Ridgepole
  class Executor
    class Adapter
      # Adapter to run nonblocking SQL commands through the `mysql` CLI.
      class MysqlCli
        def initialize
          @cli = Cli.new
        end

        def parse(config, metaconfig)
          @cli.parse(config, metaconfig)
        end

        def config
          @cli.config
        end

        def user_cmdline
          ['--user', config[:user]] if config[:user]
        end

        def password_cmdline
          ['--password', config[:password]] if config[:password]
        end

        def connectivity_cmdline
          cmd = []
          cmd << "--socket #{config[:socket]}" if config[:socket]
          cmd << "--host #{config[:host]}" if config[:host]
          cmd << "--port #{config[:port]}" if config[:port]
          cmd
        end

        def mysql_cmdline
          [
            config[:command],
            *user_cmdline,
            *password_cmdline,
            *connectivity_cmdline,
            config[:database]
          ]
        end

        def do(sql)
          IO.popen(mysql_cmdline, 'w+') do |io|
            io.puts sql
            io.close_write
            io.read
          end
        end
      end
    end
  end
end
