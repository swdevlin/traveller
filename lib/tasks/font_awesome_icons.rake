# frozen_string_literal: true

namespace :font_awesome do
  desc 'Fetch and cache a Font Awesome icon. Example: bin/rails font_awesome:cache[fa-star,solid]'
  task :cache, %i[icon style] => :environment do |_task, args|
    icon_name = args[:icon].to_s.strip
    style = args[:style].to_s.strip.presence || 'solid'

    if icon_name.blank?
      puts 'No icon supplied.'
      puts 'Example: bin/rails font_awesome:cache[fa-star,solid]'
      next
    end

    print "Fetching #{icon_name} (#{style})... "

    attrs = FontAwesomeIconFetcher.call(icon_name, style:)

    icon = FontAwesomeIcon.find_or_initialize_by(name: attrs[:name], style: attrs[:style])
    icon.assign_attributes(view_box: attrs[:view_box], svg_content: attrs[:svg_content])
    icon.save!

    puts 'cached'
  rescue FontAwesomeIconFetcher::NotFound => e
    puts "not found: #{e.message}"
  rescue StandardError => e
    puts "failed: #{e.class}: #{e.message}"
  end
end
