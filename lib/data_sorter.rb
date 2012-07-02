require 'json'
require 'csv'
require 'date'

class DataSorter

  class Task
    attr_reader :row

    def initialize(row)
      @row = row
    end

    def id
      field(:feature_id)
    end

    def start_date
      field(:development_started)
    end

    def end_date
      field(:in_production)
    end

    def field(name)
      @row[name]
    end

    def time_spent_in_days
      if !end_date.nil? && !start_date.nil?
        (Date.parse(end_date) - Date.parse(start_date)).to_i
      end
    end

    def valid?
      !time_spent_in_days.nil?
    end

    def in_range?(date_range)
      return true if date_range.nil?
      date_range.cover?(Date.parse(start_date)) || date_range.cover?(Date.parse(end_date)) || 
        (Date.parse(start_date)..Date.parse(end_date)).cover?(date_range.first)
    end

    def time_delay(from_date, to_date)
      return 0 if from_date.nil? || to_date.nil?
      (Date.parse(to_date) - Date.parse(from_date)).to_i
    end
        
    def time_to_start_development
      time_delay(field(:analysis_completed), field(:development_started))
    end

    def time_to_uat
      time_delay(field(:systest_ok), field(:in_uat))
    end

    def time_to_production
      time_delay(field(:ready_for_release), field(:in_production))
    end
  end

  class Project < Struct.new(:id, :name, :description, :color, :task_color, :tasks)
    def initialize(*args)
      super
      self.tasks ||= []
    end
  end

  def initialize(csv_data, options = {})
    @csv_data = csv_data
    @options = options
    @date_range = options[:date_range]
  end

  def self.load_file(csv_path, options = {})
    data = File.read(csv_path)
    DataSorter.new(data, options)
  end

  def empty_projects
    [
      #           id   name         description                  color      task color
      Project.new("A", "Project A", "A comment about Project A", "#6A8CE0", "#7CB2E0"),
      Project.new("C", "Project C", "A comment about Project C", "#E34A33", "#FC8D59"),
      Project.new("F", "Project F", "A comment about Project F", "#78C679", "#C2E699"),
      Project.new("S", "Project S", "A comment about Project S", "#E4A12D", "#F2D433")
    ]
  end

  def projects_with_tasks_from_csv
    projects = empty_projects

    #Read in the CSV row by row 
    CSV.parse(@csv_data, headers: true, converters: :numeric, header_converters: :symbol).each do |row|
      
      #ignore blank rows
      next if row.to_hash.values.none?
      
      #find the project to which the task applies - ignore this row if it's not one of the ones we're looking at
      project = projects.find { |p| p.name == row[:application_name] } or next

      #add the date we are interested in to our task object
      task = Task.new(row)

      #add it to that project's tasks if it is valid and in our range
      project.tasks << task if task.valid? && task.in_range?(@date_range)
    end
    projects
  end

  def task_data_structure(project, task)
    {
      "id" => task.id,
      "name" => task.id,
      "data" => {
        "$angularWidth" => task.time_spent_in_days,
        "startDate" => task.start_date,
        "endDate" => task.end_date,
        "timeTaken" => task.time_spent_in_days,
        "$color" => project.task_color
      },
      "children" => []
    }
  end

  def project_data_structure(project)
    {
      "id" => project.id,
      "name" => project.name,
      "data" => {
        "description" => project.description,
        "$color" => project.color,
      },
      "children" => project.tasks.map { |task| task_data_structure(project, task) }
    }
  end

  def data_structure
    projects = projects_with_tasks_from_csv
    {
      "id" => "Parent",
      "name" => "All Projects",
      "data" => { "$type" => "none" },
      "children" => projects.map { |project| project_data_structure(project) }
    }
  end

  def all_months(first_month, last_month)
    months = []
    current_month = first_month
    while current_month <= last_month
      months << current_month
      current_month = Date.parse(current_month + "-01").next_month.strftime("%Y-%m")
    end
    months
  end

  def delays_by_month
    all_tasks = projects_with_tasks_from_csv.map do |project|
      project.tasks
    end.flatten

    by_month = all_tasks.group_by do |task| 
      next unless task.start_date
      Date.parse(task.start_date).strftime("%Y-%m")
    end

    first_month, last_month = by_month.keys.minmax

    results = {:first_month => first_month, :last_month => last_month}

    results[:time_to_start_development] = all_months(first_month, last_month).map do |month|
      by_month[month] && by_month[month].inject(0) do |sum, task|
        sum + task.time_to_start_development
      end
    end

    results[:time_to_uat] = all_months(first_month, last_month).map do |month|
      by_month[month] && by_month[month].inject(0) do |sum, task|
        sum + task.time_to_uat
      end
    end

    results[:time_to_production] = all_months(first_month, last_month).map do |month|
      by_month[month] && by_month[month].inject(0) do |sum, task|
        sum + task.time_to_production
      end
    end

    results
  end
end
