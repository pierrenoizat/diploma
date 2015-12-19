json.array!(@deeds) do |deed|
  json.extract! deed, :id, :name, :user_id, :category, :description
  json.url deed_url(deed, format: :json)
end
