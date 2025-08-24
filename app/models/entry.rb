class Entry < ApplicationRecord
  belongs_to :journal_transaction
  belongs_to :account

  enum :entry_type, { debit: 0, credit: 1 }

  validates :amount, numericality: { greater_than: 0 }
end
