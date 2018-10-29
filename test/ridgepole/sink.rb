#!/usr/bin/env ruby

require 'timeout'

Timeout::timeout(5) do
  unless STDIN.tty?
    puts STDIN.read
  end
end
