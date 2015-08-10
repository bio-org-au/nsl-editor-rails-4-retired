json.array!(@queries) do |query|
  json.extract! query, :id
  json.url query_url(query, format: :json)
end
