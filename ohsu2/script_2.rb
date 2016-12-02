require 'date'
require 'time'

class SetShiftingVariables

  def run
    @data = {}
    files = Dir.glob("Panel*").sort { |f1, f2| extract_file_number(f1)  <=> extract_file_number(f2) }
    files = remove_duplicate_files files
    files = last_10_files files
    files.each { |f| parse f }
    build_result_file
    puts "\n Finished!\n"
  end

  def last_10_files(files)
    unique_panels = files.map { |name| name.split('_').first[/\d+/].to_i }.uniq
    heap = {}
    unique_panels.each do |panel_number|
      heap["panel_#{panel_number}"] = 0
    end
    new_files = []
    files.reverse.each do |name|
      panel_name = "panel_#{name.split('_').first[/\d+/].to_i}"
      if heap[panel_name] < 10
        new_files.unshift name
        heap[panel_name] += 1
      end
    end
    new_files
  end

  def build_result_file
    @data.each do |panel_name, data|
      File.open("#{panel_name}.csv", 'w') do |file|
        file.puts output_header
        data = data.sort.to_h
        dates = data.keys
        data.each do |date, phases_hash|
          add_missing_phases phases_hash
          merge_phases7_8 phases_hash
          phases_hash.each do |phase, events_data|
            file.puts calc_line(panel_name, dates.index(date), phase, events_data)
          end
        end
      end
    end
  end

  def merge_phases7_8(phases_hash)
    return if phases_hash['phase_7'].nil? || phases_hash['phase_8'].nil?
    phases_hash['phase_7']['event_numbers'].concat phases_hash['phase_8']['event_numbers']
    phases_hash.delete 'phase_8'
  end

  def add_missing_phases(phases_hash)
    keys = phases_hash.keys
    8.times do |index|
      next if keys.include? "phase_#{index}"
      phases_hash["phase_#{index}"] = {'event_numbers'=>[], 'time'=>[]}
    end
  end

  def calc_line(panel_name, date_index, phase, events_data)
    phase_index = phase.split('_').last.to_i
    line = "#{panel_name}"
    line << ',""' # empty column for history
    line << calc_session_number(date_index)
    line << calc_set_group(phase_index)
    line << calc_set(phase_index)
    line << calc_set_difficulty(phase_index)
    line << calc_criteria(events_data)
    line << calc_time(events_data)
    line << calc_trials(events_data)
    line << calc_errors(events_data)
    line << calc_max_consecutive_errors(events_data)
    line << calc_perseverative(events_data, phase)
    line << calc_non_perseverative(events_data, phase)
    #line << calc_trials_no_criteria(phases_hash)
    #line << calc_errors_no_criteria(phases_hash)
    #line << calc_correct(phases_hash)
    #line << calc_sum(phases_hash, 5)
    #line << calc_sum(phases_hash, 6)
    #line << calc_max_phase_reached(phases_hash)
    #line << calc_max_phase_engaged(phases_hash)
    #line << time_to_finish_session(date, phases_hash, panel_name)
    #puts "#{output_header.split(',').count} #{output_header}"
    #puts "#{line.split(',').count} #{line}"
    raise "Line doesn't match header columns" if line.split(',').count != output_header.split(',').count
    line
  end

  def calc_time(data)
    start_time = data['time'].first
    end_time = data['time'].last
    if start_time.nil? || end_time.nil? || !criteria_met?(data['event_numbers'])
      ',""'
    else
      duration_seconds = Time.parse(end_time).to_i - Time.parse(start_time).to_i
      ",#{duration_seconds}"
    end
  end

  def calc_criteria(events_data)
    result = criteria_met?(events_data['event_numbers']) ? 1 : 0
    ",#{result}"
  end

  def calc_set_group(phase_index)
    phase_index.even? ? ',Original' : ',Reversal'
  end

  def calc_set(phase_index)
    ",#{phase_index}"
  end

  def calc_set_difficulty(phase_index)
    case phase_index
    when 0 then ',1'
    when 1 then ',2'
    when 2 then ',3'
    when 3 then ',4'
    when 4 then ',3'
    when 5 then ',4'
    when 6 then ',5'
    when 7 then ',6'
    end
  end

  def calc_session_number(date_index)
    ",#{date_index+1}"
  end

  def calc_trials_no_criteria(phases_hash)
    line = ''
    phases_hash.each do |phase_name, data|
      event_numbers = data['event_numbers']
      line << ",#{event_numbers.count(2) + event_numbers.count(3)}"
    end
    line << add_empty_columns(phases_hash.keys)
    line
  end

  def calc_trials(events_data)
    event_numbers = events_data['event_numbers']
    if criteria_met?(event_numbers)
      ",#{event_numbers.count(2) + event_numbers.count(3)}"
    else
      ',""'
    end
  end

  def add_empty_columns(existing_panels)
    line = ''
    8.times do |index|
      next if existing_panels.include?("phase_#{index}")
      line << ','
    end
    line
  end

  def calc_errors(events_data)
    event_numbers = events_data['event_numbers']
    if criteria_met?(event_numbers)
      ",#{event_numbers.count(3)}"
    else
      ',""'
    end
  end

  def calc_errors_no_criteria(phases_hash)
    line = ''
    phases_hash.each do |phase_name, data|
      event_numbers = data['event_numbers']
      line << ",#{event_numbers.count(3)}"
    end
    line << add_empty_columns(phases_hash.keys)
    line
  end

  def calc_correct(phases_hash)
    line = ''
    phases_hash.each do |phase_name, data|
      event_numbers = data['event_numbers']
      if criteria_met?(event_numbers)
        line << ",#{event_numbers.count(2)}"
      else
        line << ','
      end
    end
    line << add_empty_columns(phases_hash.keys)
    line
  end

  def criteria_met?(event_numbers)
    criteries = []
    numbers_one = []
    numbers = event_numbers.reverse
    numbers.each_with_index do |num, index|
      break if numbers_one.count == 15
      numbers_one << num if num == 1
      criteries << num if num == 2
    end
    criteries.count >= 12
  end

  def calc_sum(phases_hash, count_value)
    line = ''
    phases_hash.each do |phase_name, data|
      event_numbers = data['event_numbers']
      line << ",#{event_numbers.count(count_value)}"
    end
    line << add_empty_columns(phases_hash.keys)
    line
  end

  def calc_perseverative(events_data, phase)
    return ',""' if !criteria_met?(events_data['event_numbers'])
    phase_number = phase.split('_').last.to_i
    if not [1, 3, 5, 7].include? phase_number
      ',""'
    else
      sum = 0
      events_data['event_numbers'].each do |num|
        break if num == 2
        sum += 1 if num == 3
      end
      ",#{sum}"
    end
  end

  def calc_non_perseverative(events_data, phase)
    return ',""' if !criteria_met?(events_data['event_numbers'])
    phase_number = phase.split('_').last.to_i
    if not [1, 3, 5, 7].include? phase_number
      ',""'
    else
      sum = 0
      num_flag = false
      events_data['event_numbers'].each do |num|
        num_flag = true if num == 2 && !num_flag
        sum += 1 if num == 3 && num_flag
      end
      ",#{sum}"
    end
  end

  def calc_max_consecutive_errors(events_data)
    return ',""' if !criteria_met?(events_data['event_numbers'])
    sum = 0
    entities = []
    events_data['event_numbers'].each do |num|
      sum += 1 if num == 3
      if num == 2
        entities << sum
        sum = 0
      end
    end
    max = entities.max || 0
    max > 1 ? ",#{max}" : ',""'
  end

  def calc_max_phase_reached(phase_hash)
    last_phase = ''
    phase_hash.each do |phase_name, data|
      phase_number = phase_name.split('_').last.to_i
      last_phase = phase_number if data['event_numbers'].include? 9
    end
    ",#{last_phase+1}"
  end

  def calc_max_phase_engaged(phase_hash)
    last_phase = ''
    phase_hash.each do |phase_name, data|
      phase_number = phase_name.split('_').last.to_i
      last_phase = phase_number if data['event_numbers'].include? 9
    end
    ",#{last_phase}"
  end

  def time_to_finish_session(date, phases_hash, panel_name)
    start_time = @data[panel_name][date]["phase_0"]['time'].first
    end_time = @data[panel_name][date][phases_hash.keys.last]['time'].last
    duration_seconds = Time.parse(end_time).to_i - Time.parse(start_time).to_i
    ",#{Time.at(duration_seconds).utc.strftime("%M:%S")}"
  end

  def output_header
    @output_header ||= (
      header = 'Subject,History,Session#,Set Group,Set,Set Difficulty,Criteria,Duration(sec)'
      header << ',# Trails(12/15),# Errors,# MC_Errors,# P_Errors,# NP_Errors'
      header
    )
  end

  def parse(file)
    panel_name = extract_panel_number file
    total_lines = File.readlines(file).count
    File.foreach(file).with_index do |line, index|
      next if index == 0
      numbers = line.split("\t")
      extract_date panel_name, numbers, file
      extract_event_number panel_name, numbers
      collect_time(panel_name, numbers) if index != (total_lines-1)
    end
  end

  def collect_time(panel_name, data_array)
    date = data_array[0].strip
    phase_index = data_array[12].strip.to_i
    phase_index = 7 if phase_index == 8
    @data[panel_name][date]["phase_#{phase_index}"]['time'] = [] if @data[panel_name][date]["phase_#{phase_index}"]['time'].nil?
    @data[panel_name][date]["phase_#{phase_index}"]['time'] << data_array[1]
  end

  def extract_file_number(file_name)
    array = file_name.split('_')
    panel_number = array.first.gsub(/[A-z]+/, '').to_i
    date_time = "#{array[1]}_#{array[2]}_#{array[3]}_#{array[4]}_#{array[5]}_#{array[6]}"
    date_time = DateTime.strptime(date_time, '%Y_%m_%d_%H_%M_%p').to_time.to_i
    "#{panel_number}_#{date_time}"
  end

  def extract_time(name)
    arr = name.split('_')
    arr[4] + arr[5] + arr[6]
  end

  def remove_duplicate_files(files)
    groups = files.group_by do |file|
      parsed_name = file.split('_')
      panel = parsed_name.first
      date = parsed_name[1] +'_'+ parsed_name[2] +'_'+ parsed_name[3]
      /#{panel}_#{date}.+/
    end
    groups.each do |date, files_names|
      if files_names.count > 1
        files_names.sort! do |name1, name2|
          extract_time(name1) <=> extract_time(name2)
        end.pop
        files = files - files_names
      end
    end
    files
  end

  def extract_panel_number(file_name)
    panel_number = file_name.split('_').first[/\d+/].to_i
    panel_name = "panel_#{panel_number}"
    @data[panel_name] = {} if @data[panel_name].nil?
    panel_name
  end

  def extract_event_number(panel_name, data_array)
    event_number = data_array[8].strip.to_i
    date = data_array[0].strip
    phase_index = data_array[12].strip.to_i
    phase_index = 7 if phase_index == 8
    @data[panel_name][date]["phase_#{phase_index}"] = {} if @data[panel_name][date]["phase_#{phase_index}"].nil?
    @data[panel_name][date]["phase_#{phase_index}"]['event_numbers'] = [] if @data[panel_name][date]["phase_#{phase_index}"]['event_numbers'].nil?
    @data[panel_name][date]["phase_#{phase_index}"]['event_numbers'] << event_number
  end

  def extract_date(panel_name, data_array, file)
    date = data_array[0]
    raise "Bad date. #{date} in #{file}" if date.split('/').count != 3
    return if @data[panel_name][date]
    @data[panel_name][date] = {}
  end

end

SetShiftingVariables.new.run
