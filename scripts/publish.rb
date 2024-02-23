require 'yaml'
require 'date'
require 'fileutils'

path = ARGV[0]
front = ''
File.open(path) do |f|
  first = true
  f.each_line do |line|
    if first
      first = false
      next
    end
    if line.strip == '---'
      break
    end
    front += line
  end
end
frontmatter = YAML.load(front, permitted_classes: [Date])
title = frontmatter["title"]
date = frontmatter["date"]

if date.nil?
  date = Date.today
end
year = date.year

slug = title.downcase.gsub(/[\W]+/, '-')
filename = "#{date}-#{slug}.md"

dest = "./_posts/#{year}/#{filename}"

puts({
  slug: slug,
  date: date,
  title: title,
  destination: dest
}.to_yaml)


FileUtils.mv(path, dest)
