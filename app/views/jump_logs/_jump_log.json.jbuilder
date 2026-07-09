json.extract! jump_log, :id, :ship_id, :from_parsec_id, :to_parsec_id, :depart_year, :depart_day, :arrive_year, :arrive_day, :sequence, :notes, :created_at, :updated_at
json.url jump_log_url(jump_log, format: :json)
