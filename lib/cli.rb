require_relative "data_sorter"

class DataSorter::Cli
  def usage
    $stderr.puts "USAGE: #{$PROGRAM_NAME} <path/to/input_data.csv>"
    exit(1)
  end

  def initialize(argv)
    validate!(argv)
    @argv = argv
  end

  def validate!(argv)
    unless argv.size == 1
      usage
    end
  end

  def input_file
    @argv[0]
  end

  def output_file
    File.basename(input_file, ".csv") + ".js"
  end

  def data_sorter
    @data_sorter ||= DataSorter.load_file(input_file)
  end

  def process
    raise "Not implemented"
  end

  def run
    data_structure = process
    File.open(output_file, "w") do |io|
      io << "var json =" << JSON.dump(data_structure)
    end

    puts "Wrote sorted data to #{output_file}"
  end
end

class DataSorter::SortCommand < DataSorter::Cli
  def process
    data_sorter.data_structure
  end
end

class DataSorter::DelaysByMonth < DataSorter::Cli
  def process
    data_sorter.delays_by_month
  end
end