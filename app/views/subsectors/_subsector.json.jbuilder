json.extract! subsector, :id, :name, :x, :y, :created_at, :updated_at
json.url subsector_url(subsector, format: :json)
json.tags owns_campaign? ? subsector.tag_names : []
