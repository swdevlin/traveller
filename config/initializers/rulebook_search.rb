Rails.application.config.x.show_rulebook_search_rank =
  ActiveModel::Type::Boolean.new.cast(ENV.fetch('SHOW_RULEBOOK_SEARCH_RANK', !Rails.env.production?))
