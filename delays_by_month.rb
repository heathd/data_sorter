#!/usr/bin/env ruby
require_relative "lib/cli"

DataSorter::DelaysByMonth.new(ARGV).run
