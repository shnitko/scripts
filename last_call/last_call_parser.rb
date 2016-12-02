def generate_array(arr)
  array = []
  arr.each do |value|
    value = value.split(':')
    if value && !value.empty? && value != '0'
      value = value[1].strip
      if !value.empty? && value != '0'
        array << value
      end
    end
  end
  array
end

File.open('result.csv', 'w') do |fl|

  arr = []
  files = Dir.glob("CALL*").sort
  files.each do |f|
    text = File.open(f).read
    g = text.match(/G:(.*)H:.*?\n/m)[1]
    h = text.match(/H:(.*)K:.*?\n/m)[1]
    g = g.split(/\r?\n/)
    h = h.split(/\r?\n/)
    first_column = generate_array(g)
    second_column = generate_array(h)
    arr << first_column
    arr << second_column
  end

  max = 0
  arr.each do |column|
    max = column.count if column.count > max
  end

  max.times do |index|
    line = ''
    arr.each_with_index do |column, i|
      column[index] = column[index] || ''
      if line.empty?
        if i == 0
          line = "#{column[index]}"
        else
          (i-1).times { line = "#{line}," }
          line = "#{line},#{column[index]}"
        end
      else
        line = "#{line},#{column[index]}"
      end
    end
    fl.write("#{line}\n")
  end

end
