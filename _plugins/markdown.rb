require 'jekyll'
require 'rouge'

class Jekyll::Converters::Markdown::CustomKramdownConverter
  def initialize(config)
    @config = config
  end

  def convert(content)
    document = Kramdown::Document.new(content, input: 'GFM')
    document.to_willhbr_html
  end
end

class Kramdown::Converter::WillhbrHtml < Kramdown::Converter::Html
  def convert_img(el, _indent)
    "<img#{html_attributes({"loading" => "lazy"}.merge(el.attr))} />"
  end
end
