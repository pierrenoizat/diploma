json.array!(@viewers) do |viewer|
  json.extract! viewer, :id, :email, :deed_id
  json.url viewer_url(viewer, format: :json)
end
