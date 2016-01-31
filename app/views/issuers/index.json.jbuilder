json.array!(@issuers) do |issuer|
  json.extract! issuer, :id, :name, :batch, :mpk
  json.url issuer_url(issuer, format: :json)
end
