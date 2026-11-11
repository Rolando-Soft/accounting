json.extract! account, :id, :name, :account_type, :description, :cash_flow_category, :created_at, :updated_at
json.url account_url(account, format: :json)
