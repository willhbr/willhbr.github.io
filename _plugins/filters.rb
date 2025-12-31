module CustomFilters
  def smart_date(input)
    build_time = @context.registers[:site].time
    if input.strftime('%F') == build_time.strftime('%F')
      build_time
    else
      input
    end
  end
end

Liquid::Template.register_filter(CustomFilters)
