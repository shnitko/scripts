class Modeled

  require 'statsample'

  def self.run
    new.perform
  end

  def initialize
    @rat_params = ['[DA]p', 'Vmax', 'Km', 'Thickness', 'R Pearson']
  end

  def perform
    File.open('models_result.csv', 'w') do |result|
      @rat_params.each do |param|
        add_rat_param param, result
        add_header result
        add_results_bl param, result
        add_results_sal param, result
        add_results_numeric param, result
        result.write "\n"
      end
    end
  end

  def add_rat_param(param, result)
    result.write "#{param}\n"
  end

  def add_header(result)
    header = 'File_Name'
    pretty_rat_names = rat_names.map { |name| name.split(' ').first }
    pretty_rat_names.each do |rat|
      header += ",#{rat}"
    end
    result.write header + "\n"
  end

  def rat_names
    @rat_names ||= (
      Dir.glob('*').select { |f| File.directory?(f) && f =~ /NAD[0-9]+\s.+/ }.sort
    )
  end

  def method_missing(m, param, result)
    file_type = m.to_s.split('_').last.upcase
    data_files(file_type).each do |file_name|
      result.write file_name
      result.write ',' + rat_params_for(param, file_name)
      result.write "\n"
    end
  end

  def rat_params_for(param, file_name)
    line = ''
    rat_names.each do |dir_name|
      if Dir.glob("#{dir_name}/**/*").select { |f| f =~ /#{file_name}$/ }.first.nil?
        line += ','
      else
        file = File.open Dir.glob("#{dir_name}/**/*").select { |f| f =~ /#{file_name}$/ }.first
        line += (read_param_from_file(param, file) + ',')
      end
    end
    line
  end

  def read_param_from_file(param, file)
    data = file.readline.split(/[\t]/)
    case param
    when '[DA]p'
      d = data[0]
    when 'Vmax'
      d = data[1]
    when 'Km'
      d = data[2]
    when 'Thickness'
      d = data[3]
    when 'R Pearson'
      d = correlation(file)
    end
    d.to_s
  end

  def data_files(type)
    if type == 'numeric'.upcase
      files = Dir.glob("**/*").select { |f| f =~ /[1-9]_10[0-9]_fit$/ }
    else
      files = Dir.glob("**/*").select { |f| f =~ /#{type}_10[0-9]_fit$/ }
    end
    files.map { |path| path.split('/').last }.uniq.sort
  end

  def correlation(file)
    x = []
    y = []
    file.each_with_index do |line, i|
      line = line.split(/[\t]/)
      if i > 50 && i < 102
        x << line[1].to_f
        y << line[2].to_f
      end
    end
    pearson_cor(x, y)
  end

  def pearson_cor(x, y)
    x = x.to_scale
    y = y.to_scale
    pearson = Statsample::Bivariate::Pearson.new(x,y)
    pearson.r.round(3)
  end

end

Modeled.run
