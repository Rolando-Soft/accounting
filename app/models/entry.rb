class Entry < ApplicationRecord
  belongs_to :journal_transaction
  belongs_to :account

  enum :entry_type, { debit: 0, credit: 1 }
  enum :reconciliation_status, { unreconciled: 0, cleared: 1, reconciled: 2 }

  validates :amount, numericality: { greater_than: 0 }

  # Amount signed so that summing it moves the account's balance in the
  # right direction regardless of the account's normal balance side.
  def signed_amount
    entry_type == account.normal_balance ? amount : -amount
  end
end
