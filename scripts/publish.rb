#!/usr/bin/ruby
require 'yaml'
require 'date'
require 'fileutils'

path = ARGV[0]
contents = File.read(path)
frontmatter = YAML.load(contents, permitted_classes: [Date])

m = contents.match /http:\/\/\w+(:\d+)/
if m
  raise "looks like you've got a dev server address in there: #{m}"
end

if contents.match(/^!\[/) && frontmatter['image'].nil?
  raise "you've included an image but it's not in the frontmatter"
end

title = frontmatter["title"]
date = frontmatter["date"] || Date.today
slug = title.gsub(/\d+,\d+/) { |num| num.gsub(',', '') }

if slug.size > 35
  puts slug
  print "That's a long slug, want a smaller one? "
  re = STDIN.gets&.chomp
  slug = re unless re.empty?
end
slug = slug.downcase.gsub("'", '').gsub(/[\W]+/, '-').chomp('-')

filename = "#{date.strftime('%F')}-#{slug}.md"

dest = "./_posts/#{date.year}/#{filename}"

FileUtils.mkdir_p "./_posts/#{date.year}"

puts({
  slug: slug,
  date: date,
  title: title,
  destination: dest
}.to_yaml)


FileUtils.mv(path, dest)
