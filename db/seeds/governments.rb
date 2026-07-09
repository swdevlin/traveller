# frozen_string_literal: true

require_relative '../seed_data/governments'

Government.upsert_all(GOVERNMENTS, unique_by: %i[code])
