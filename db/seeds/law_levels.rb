# frozen_string_literal: true

require_relative '../seed_data/law_levels'

LawLevel.upsert_all(LAW_LEVELS, unique_by: %i[code])
