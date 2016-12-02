File.open('result.csv', 'w') do |fl|

  files = Dir.glob("*_SCAN_????*.txt")
  files = files.sort_by {|e| e.split(/(\d+)/).map {|a| a =~ /\d+/ ? a.to_i : a }}
  files.each do |f|
    full_name = /.+_SCAN_([0-9]{4,}).+/.match(f)
    number = full_name[1]
    first_part = number[0..-2]
    last_part = number[-1]

    value1 = "#{first_part}.#{last_part}".to_f.round(1)
    value2 = (value1.to_f / 60).round(4)
    value3 = (101 + value2).round(2)
    value4 = (value1 - (value2.to_i * 60)).round(1)
    value5 = (value4 + 3).round(1)

    fl.write("#{value1},#{value2},#{value3},#{value4},#{value5}\n")
  end

end
