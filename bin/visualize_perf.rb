#!/usr/bin/env ruby
require 'json'
RMAGICK_BYPASS_VERSION_TEST = true
require 'gruff'

bags = []
output_file_pattern = /^outputmas\.(\d+)\.txt$/

def average(obj)
  transform = {}
  obj.each do |id, value|
    value.each do |action, value|
      transform[action] ||= []
      transform[action] << value
    end
  end

  transform.each do |key, value|
    transform[key] = (value.inject {|sum, n| sum + n })/(value.length*1.0)
  end
  puts "transform **************" + transform.map{|k,v| "#{k}=#{v}"}.join('&')
  transform
end

Dir.entries(Dir.getwd).each do |entry|
  if entry =~ output_file_pattern
    bags << {
      :label => $1,
      :results => average(JSON.parse(File.open(entry).read, :symbolize_names => true))
    }
  end
end

bags = bags.sort {|a, b| a[:label].to_i <=> b[:label].to_i }
puts "=============== " + bags.join(",")

def get_series(bags)
  series = {}
  bags.each do |item|
    item[:results].each do |key, value|
      series[key] ||= []
      series[key] << value
    end
  end
  puts "series **************" + series.map{|k,v| "#{k}=#{v}"}.join('&')
  series
end

def get_labels(bags)
  labels = {}
  i = 0
  bags.each do |item|
    labels[i] = item[:label]
    i += 1
  end
  puts "labels**************" + labels.map{|k,v| "#{k}=#{v}"}.join('&')
  labels
end

#g = Gruff::Line.new(1024)
g = Gruff::Line.new()
g.add_color('#c0c0c0')
g.add_color('#ff00ff')
g.add_color('#808000')
g.add_color('#814A19')
g.add_color('#00ffff')
g.add_color('#00ff00')
g.add_color('#CFE0FF')
g.add_color('#0000ff')
g.add_color('#FFCDF3')
g.title = ARGV[0] || "Concurrent Requests Test"
g.y_axis_label = "seconds"
g.x_axis_label = "users"

series = get_series(bags)
series.each do |key, value|
  g.data(key, value)
end
g.maximum_value = 5 # 1 minutes shuld be a'plenty when waiting for the server to come back
g.dot_radius = 3
g.line_width = 2

labels = get_labels(bags)
g.labels = labels
g.marker_count = 5
g.write('chart.png')

# Generate HTML report
report = File.new("report.html", "w")
hi = true
report.write("<html><head><title>#{g.title}</title>")
style = <<STYLE
<style type="text/css">
.hi { background-color: #f6f6f6 }
table { border-collapse:collapse; border: 1px solid #333 }
td, th { padding: 0.3em }
td { border-left: 1px solid #333; text-align: right }
thead th { border-left: 1px solid #333 }
</style>
STYLE
report.write(style)
report.write("</head><body><h1>#{g.title}</h1><table>")
#report.write("<caption><b>User runs</b></caption>")
report.write("<thead><tr><th></th><th>"+(labels.collect {|key, value| value+" users" }).join("</th><th>")+"</th></tr></thead>")
report.write("<tbody>")
series.each do |key, values|
  cssclass = hi ? "hi" : ""
  report.write("<tr class=\"#{cssclass}\"><th>#{key.to_s}</th><td>"+(values.collect {|value| value.round(4).to_s+"s" }).join("</td><td>")+"</td></tr>")
  hi = !hi
end
report.write("</tbody></table></body></html>")
report.close
