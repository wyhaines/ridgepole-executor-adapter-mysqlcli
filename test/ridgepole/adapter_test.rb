# frozen_string_literal: true

require 'test_helper'
require 'english'

# rubocop: disable Style/ClassAndModuleChildren
# Test the Executor
class Ridgepole::Executor::Adapter::MysqlcliTest < Minitest::Test
  TESTUSER = 'testuser'
  TESTPASSWORD = 'testpassword'
  TESTHOST = '127.0.0.1'
  TESTPORT = '1234'
  TESTSOCKET = "/tmp/__test__#{$PID}__mysql.sock"
  TESTDATABASE = 'testdatabase'

  def test_that_it_has_a_version_number
    refute_nil ::Ridgepole::Executor::Adapter::Mysqlcli::VERSION
  end

  def setup
    File.open(TESTSOCKET, 'w+') { |fh| fh.puts 'deleteme' }
  end

  def teardown
    File.unlink(TESTSOCKET)
  end

  def _setup_argv(set)
    ARGV[0..7] = [
      '--user', TESTUSER,
      '--password', TESTPASSWORD,
      '--bind', "#{TESTHOST}:#{TESTPORT}",
      '--database', TESTDATABASE
    ]

    ARGV[5] = TESTSOCKET if set == :socket
  end

  def _setup_sink_as_command
    _setup_argv(:tcp)
    ARGV[8..9] = ['--command',
                  File.join(File.expand_path(__dir__), 'sink.rb')]
  end

  def _setup_dummy_config
    config = Ridgepole::Executor::Config.new
    metaconfig = Ridgepole::Executor::Config.new
    metaconfig[:helptext] = +''
    [config, metaconfig]
  end

  def _setup_test_cli_parser(set = :tcp)
    _setup_argv(set)
    cli = Ridgepole::Executor::Adapter::Mysqlcli::Cli.new
    config, metaconfig = _setup_dummy_config
    cli.parse(config, metaconfig)
    cli
  end

  # rubocop: disable Metrics/AbcSize
  def test_cli_parser_with_host
    cli = _setup_test_cli_parser
    assert cli.config[:user] == TESTUSER
    assert cli.config[:password] == TESTPASSWORD
    assert cli.config[:database] == TESTDATABASE
    assert cli.config[:host] == TESTHOST
    assert cli.config[:port] == TESTPORT
    assert cli.config[:socket].nil?
  end

  def test_cli_parser_with_socket
    cli = _setup_test_cli_parser(:socket)
    assert cli.config[:user] == TESTUSER
    assert cli.config[:password] == TESTPASSWORD
    assert cli.config[:database] == TESTDATABASE
    assert cli.config[:socket] == TESTSOCKET
    assert cli.config[:host].nil?
    assert cli.config[:port].nil?
  end
  # rubocop: enable Metrics/AbcSize

  def _setup_adapter
    adapter = Ridgepole::Executor::Adapter::Mysqlcli.new
    config, metaconfig = _setup_dummy_config
    adapter.parse(config, metaconfig)
    adapter
  end

  def test_generate_mysql_command_line
    _setup_argv(:tcp)
    assert _setup_adapter.mysql_cmdline.join(' ') == [
      'mysql',
      '--user', TESTUSER,
      '--password', TESTPASSWORD,
      '--host', TESTHOST,
      '--port', TESTPORT,
      TESTDATABASE
    ].join(' ')
  end

  def test_run_sql
    _setup_sink_as_command
    sql = "select 1 from #{TESTDATABASE}\n"
    adapter = _setup_adapter
    adapter.config[:sql] = sql
    result = adapter.do
    assert result == sql
  end
end
# rubocop: enable Style/ClassAndModuleChildren
