#!/usr/bin/ruby
require 'yaml'
require 'date'
require 'fileutils'

def get_images
  `jj diff --name-only`.split("\n").select do |path|
    %w(webp jpeg jpg png gif).any? { |e| path.end_with? ".#{e}" }
  end
end

path = ARGV[0]
contents = File.read(path)
frontmatter = YAML.load(contents, permitted_classes: [Date])

m = contents.match /http:\/\/\w+(:\d+)/
if m
  raise "looks like you've got a dev server address in there: #{m}"
end

if contents.include? "\t"
  raise "you've got a tab character, I don't think you want that"
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

images = get_images
unless images.empty?
  puts "images:"
  puts images.join("\n")
  print "strip and scale images? [y/N] "

  if STDIN.gets.chomp == 'y'
    images.each do |img|
      size = (1400 * 1400)
      system 'convert', img, '-strip', '-resize', "#{size}@", img
    end
  end
end

FileUtils.mv(path, dest)
