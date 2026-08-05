# frozen_string_literal: true

namespace :rulebooks do
  desc 'Import (or reimport) a rulebook PDF from a local server path. ' \
       'Usage: bin/rails "rulebooks:import[42,/path/to/core-rulebook.pdf]" ' \
       'or bin/rails "rulebooks:import[core,/path/to/core-rulebook.pdf]" ' \
       '(second arg is a Rulebook id or short_title). Add FORCE=true to reprocess an unchanged file.'
  task :import, %i[identifier path] => :environment do |_t, args|
    identifier = args[:identifier].presence or abort 'Usage: bin/rails "rulebooks:import[id_or_short_title,path]"'
    path = args[:path].presence or abort 'Usage: bin/rails "rulebooks:import[id_or_short_title,path]"'

    rulebook = Rulebook.find_by(id: identifier) || Rulebook.find_by(short_title: identifier)
    abort "No rulebook found matching '#{identifier}'" unless rulebook

    ImportRulebookJob.perform_now(rulebook.id, path, force: ENV['FORCE'] == 'true')
    rulebook.reload
    puts "#{rulebook.title}: #{rulebook.status} (#{rulebook.rulebook_pages.count} pages)"
    puts rulebook.import_error if rulebook.failed?
  end

  desc 'Re-run text normalization and rebuild search vectors for a rulebook (or all rulebooks if none given). ' \
       'Usage: bin/rails "rulebooks:rebuild_search_vectors[42]" or bin/rails rulebooks:rebuild_search_vectors'
  task :rebuild_search_vectors, [:identifier] => :environment do |_t, args|
    rulebooks =
      if args[:identifier].present?
        [Rulebook.find_by(id: args[:identifier]) || Rulebook.find_by(short_title: args[:identifier])].compact
      else
        Rulebook.all.to_a
      end
    abort "No rulebook found matching '#{args[:identifier]}'" if rulebooks.empty?

    rulebooks.each do |rulebook|
      RulebookReindexer.new(rulebook).call
      puts "Rebuilt search vectors for #{rulebook.title}"
    end
  end
end
