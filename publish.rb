require 'json'
require 'date'
require 'fileutils'

path = ARGV[0]
file = File.read(path)
lines = file.split("\n")
title = JSON.parse(lines.find { |l| l.start_with? 'title:' }[6..])
date = lines.find { |l| l.start_with? 'date:' }

if date.nil?
  date = Date.today.strftime('%F')
else
  date = date[5..]
end
year = date[0...4]

slug = title.downcase.gsub(/\s+/, '-')
filename = "#{date}-#{slug}.md"

FileUtils.mv(path, "./_posts/#{year}/#{filename}")
