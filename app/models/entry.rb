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

  # Day-to-day toggling only moves an entry between unreconciled and
  # cleared ("ticked"). Becoming reconciled happens only in bulk, via the
  # register's Reconcile button, once the statement difference is zero.
  RECONCILIATION_CYCLE = { "unreconciled" => "cleared", "cleared" => "unreconciled" }.freeze

  def next_reconciliation_status
    RECONCILIATION_CYCLE.fetch(reconciliation_status, reconciliation_status)
  end
end
