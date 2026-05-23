# frozen_string_literal: true

desc 'Generate words for a language (LANGUAGE=imperium COUNT=10)'
task generate_word: :environment do
  unless ENV['LANGUAGE']
    puts 'Available languages:'
    WordGenerator.languages.each { |l| puts "  #{l}" }
    next
  end

  language = ENV['LANGUAGE'].to_sym
  count = ENV.fetch('COUNT', '10').to_i
  generator = WordGenerator.new(language: language)
  count.times { puts generator.generate }
end
