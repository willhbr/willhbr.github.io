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

  def related_posts(post, all_posts, limit)
    posts = [post.previous, post.next].reject &:nil?
    return posts unless post['tags'] && all_posts
    related = all_posts.select do |p|
      post.url != p.url && (p['tags'] & post['tags']).any? && !posts.any? { |e| e.url == p.url }
    end

    posts.concat related.first(limit - posts.size)
    posts.sort_by(&:date).reverse!
  end
end

Liquid::Template.register_filter(CustomFilters)
