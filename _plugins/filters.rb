module CustomFilters
  def smart_date(input)
    build_time = @context.registers[:site].time
    if input.strftime('%F') == build_time.strftime('%F')
      build_time
    else
      input
    end
  end

  def strip_highlighting(input)
    input.gsub(/<code>(.*?)<\/code>/m) do |code|
      code.gsub(/<span class=".*?">/, '').gsub('</span>', '')
    end
  end
end

Liquid::Template.register_filter(CustomFilters)
