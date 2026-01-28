# frozen_string_literal: true

require_relative '../seed_data/tech_levels'

TechLevel.upsert_all(TECH_LEVELS, unique_by: %i[code])
