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
date = frontmatter["date"] || Date.today

slug = title.gsub(/\d+,\d+/) { |num| num.gsub(',', '') }
slug = slug.downcase.gsub("'", '').gsub(/[\W]+/, '-').chomp('-')

if slug.size > 35
  puts slug
  print "That's a long slug, want a smaller one? "
  re = STDIN.gets&.chomp
  slug = re unless re.empty?
end

filename = "#{date.strftime('%F')}-#{slug}.md"

dest = "./_posts/#{date.year}/#{filename}"

puts({
  slug: slug,
  date: date,
  title: title,
  destination: dest
}.to_yaml)


FileUtils.mv(path, dest)
