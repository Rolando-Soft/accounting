class Entry < ApplicationRecord
  belongs_to :journal_transaction
  belongs_to :account

  enum :entry_type, { debit: 0, credit: 1 }
  enum :reconciliation_status, { unreconciled: 0, cleared: 1, reconciled: 2 }

  validates :amount, numericality: { greater_than: 0 }

  # The transaction form shows one DB column and one CR column per entry
  # instead of an entry-type dropdown; whichever side the user fills in
  # determines entry_type/amount. Setting entry_type/amount happens inside
  # the writer itself (not a before_validation) because nested-attributes
  # autosave decides whether a changed child record needs saving using
  # ActiveRecord dirty-tracking *before* validation callbacks run — a plain
  # attr_accessor change is invisible to that check, so the real attributes
  # must change at assignment time or the update gets silently dropped.
  attr_reader :debit_amount, :credit_amount

  def debit_amount=(value)
    @debit_amount = value
    if value.present?
      self.entry_type = "debit"
      self.amount = value
    end
  end

  def credit_amount=(value)
    @credit_amount = value
    if value.present?
      self.entry_type = "credit"
      self.amount = value
    end
  end

  # The form's R checkbox mirrors an entry's reconciled state: checking it
  # reconciles the entry, unchecking a previously-reconciled entry reverts
  # it to unreconciled (the register locks reconciled entries, so the
  # transaction edit form is the only place to undo a reconciliation).
  # Leaving it unchecked on an already-unreconciled/cleared entry is a
  # no-op. Same eager-assignment reasoning as above.
  attr_reader :mark_reconciled

  def mark_reconciled=(value)
    @mark_reconciled = value
    if ActiveModel::Type::Boolean.new.cast(value)
      self.reconciliation_status = "reconciled"
    elsif reconciliation_status == "reconciled"
      self.reconciliation_status = "unreconciled"
    end
  end

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
