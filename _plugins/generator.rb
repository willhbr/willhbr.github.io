module Willhbr
  class TagsGenerator < Jekyll::Generator
    def generate(site)
      tags = site.data['tags']

      tags.each do |name, desc|
        file = Jekyll::PageWithoutAFile.new(site, site.source, 'tags', "#{name}.html")
        file.data.merge!(
          "layout" => 'tag',
          "tag" => name,
          "title" => name,
        )
        site.pages << file
      end
    end
  end
end
