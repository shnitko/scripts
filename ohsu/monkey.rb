# column index is a number of column - 1.
# For example: the column called TotalTrials is 5. 5-1 = 4, so COLUMN_INDEX equals to 4.
COLUMN_INDEX = 4

# script assumes that the input and output files are in the current folder
SOURCE_FILE_NAME = 'data.csv'
OUTPUT_FILE_NAME = 'result.csv'


# you don't need to change anything after this line
require 'date'
class Monkey

  def initialize
    @data = {}
    File.truncate(OUTPUT_FILE_NAME, 0) if File.exist? OUTPUT_FILE_NAME
  end

  def start
    File.readlines(SOURCE_FILE_NAME).each_with_index do |line, index|
      next if index == 0
      add_monkey line
    end
    sort_data
    write_in_file
  end

  private

  def write_in_file
    File.open(OUTPUT_FILE_NAME, 'w') do |file|
      file.write first_line
      @data.each do |date, data|
        line = "#{date}"
        data.each do |h, i|
          line << ",#{h[:data]}"
        end
        file.write "#{line}\n"
      end
    end
  end

  def first_line
    monkey_names = @data.values.first.map { |h| h[:name] }
    "dates,#{monkey_names.join(',')}\n"
  end

  def add_monkey(line)
    data = parse_line line
    if @data[data[:date]]
      combine_existing_record data
    else
      @data[data[:date]] = [add_record(data)]
    end
  end

  def parse_line(line)
    data = line.split ','
    {
      name: data[0],
      date: fix_date(data[2]),
      data: data[COLUMN_INDEX],
      test_phase: data[12]
    }
  end

  def combine_existing_record(data)
    date = data[:date]
    @data[date].each do |monkey_record|
      if monkey_record[:name] == data[:name]
        monkey_record[:data] += data[:data].to_i
      end
    end
    if @data[date].select { |h| h[:name] == data[:name] }.empty?
      @data[date] << add_record(data)
    end
  end

  def add_record(data)
    {name: data[:name], data: data[:data].to_i}
  end

  def fix_date(date)
    date = date.split('/')
    day = date[1].to_i
    month = date[0].to_i
    year = date[2]
    year = "20#{year}" if year.size == 2
    Date.new(year.to_i, month, day).to_s
  end

  def sort_data
    @data.sort.to_h
  end

end

Monkey.new.start
