#!/usr/bin/env ruby
# frozen_string_literal: true

require 'timeout'

Timeout.timeout(2) do
  puts STDIN.read unless STDIN.tty?
end
