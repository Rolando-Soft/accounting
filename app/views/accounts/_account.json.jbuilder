json.extract! account, :id, :name, :account_type, :description, :category_id, :created_at, :updated_at
json.url account_url(account, format: :json)
