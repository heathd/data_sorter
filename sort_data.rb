#!/usr/bin/env ruby
require_relative "lib/cli"

DataSorter::SortCommand.new(ARGV).run
