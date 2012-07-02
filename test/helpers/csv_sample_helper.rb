module CsvSampleHelper
  def csv_sample(*data_rows)
    expected_keys = ["Feature ID","Application Name","Type","T-Shirt Size","Option",
      "Prioritised, Awaiting Analysis","Analysis Completed","Development Started",
      "Systest Ready","Systest OK","In UAT","Ready For Release","In Production",
      "Lead Time","Cycle Time","Development Cycle Time"]
    data = [CSV.generate_line(expected_keys)]
    data_rows.each do |row|
      data << CSV.generate_line(expected_keys.map {|key| row[key]})
    end
    data.join ""
  end
end