class Ct

  require 'date'
  require 'ostruct'

  def initialize
    @params = ['J', 'L']
    @file_names = Dir.glob('*').reject { |file| file.include?('.rb') || file.include?('.csv') }
    @rats = {}
  end

  def run
    create_rats
    sort_by_start_date
    write_result
  end

  def write_result
    File.open('results.csv', 'w') do |result|
      @params.each do |param|
        result.write header(param)
        @rats.each do |rat_name, data|
          result.write "#{rat_name}#{rows(param, data)}\n"
        end
        result.write "\n"
      end
    end
  end

  def rows(param, data)
    line = ''
    data.each do |obj|
      line += ",#{obj[param]}"
    end
    line
  end

  def header(param)
    line = "#{param}\n"
    all_days.each do |day|
      line += ",#{day}"
    end
    "#{line}\n"
  end

  def all_days
    days = []
    @rats.each do |name, data|
      data.each do |obj|
        next if days.include? obj.start_date
        days << obj.start_date
      end
    end
    days.uniq.sort
  end

  def create_rats
    @file_names.each do |file_name|
      add_rat file_name
    end
  end

  def add_rat(file_name)
    lines = File.readlines file_name
    rat_day = OpenStruct.new
    lines.each do |l|
      name = extract_subject(l) if l =~ /Subject:.+/
      rat_day.start_date = extract_date(l) if l =~ /^Start\sDate/
      @params.each do |param|
        rat_day[param] = extract_param(l, param) if l =~ /^#{param}:\s/
      end
      if name
        add_data_to_rat name, rat_day
      end
    end
  end

  def add_data_to_rat(rat_name, data)
    if @rats[rat_name]
      @rats[rat_name] << data
    else
      @rats[rat_name] = [data]
    end
  end

  def sort_by_start_date
    @rats.each do |rat_name, data|
      data.sort_by! do |ostruct|
        ostruct.start_date
      end
    end
  end

  def extract_date(string)
    # string: Start Date: 10/28/14
    date = string[/[0-9]+\/[0-9]+\/[0-9]+/]
    Date.strptime(date, '%m/%d/%y')
  end

  def extract_subject(string)
    # string: Subject: CSV1
    string.match(/Subject:\s+([A-Z0-9]+)/)[1]
  end

  def extract_param(string, param)
    # string: J: 10.000
    string.match(/^#{param}:\s+([0-9.]+)/)[1]
  end

end

Ct.new.run
