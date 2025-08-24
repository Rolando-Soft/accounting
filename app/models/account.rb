class Account < ApplicationRecord

  enum :account_type, {asset: 0, liability: 1, income: 2, expense: 3, equity: 4}

  validates :name, presence: true, uniqueness: true
  validates :account_type, presence: true
  validates :description, length: { maximum: 500 }

end
