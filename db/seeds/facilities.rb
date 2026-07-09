# frozen_string_literal: true

require_relative '../seed_data/facilities'

Facility.upsert_all(FACILITIES, unique_by: %i[code])
