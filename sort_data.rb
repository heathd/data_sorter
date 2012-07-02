#!/usr/bin/env ruby
require_relative "lib/data_sorter"

def usage
  $stderr.puts "USAGE: sort_data.rb <path/to/input_data.csv>"
  exit(1)
end

unless ARGV.size == 2
  usage
end

input_file = ARGV[1]
output_file = File.basename(input_file, ".csv") + ".js"

data_sorter =  DataSorter.load_file(input_file)
data_structure = data_sorter.delays_by_month
File.open(output_file, "w") do |io|
  io << "var json =" << JSON.dump(data_structure)
end

puts "Wrote sorted data to #{output_file}"
