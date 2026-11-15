class JournalTransaction < ApplicationRecord
  has_many :entries, dependent: :destroy
  accepts_nested_attributes_for :entries, allow_destroy: true, reject_if: :all_blank

  # Set when the user has confirmed a change to a reconciled entry.
  attr_accessor :allow_reconciled_changes

  validates :date, presence: true
  validate :balanced_entries
  validate :minimum_two_entries
  validate :protect_reconciled_entries

  # Fuzzy-matches `term` against `payee`: a plain substring match always
  # counts, and a short Levenshtein distance catches typos (e.g. "Amazn").
  def self.search_by_payee(term, max_distance: 2)
    return all if term.blank?

    normalized_term = term.strip.downcase
    where.not(payee: [ nil, "" ]).select do |jt|
      normalized_payee = jt.payee.downcase
      normalized_payee.include?(normalized_term) ||
        levenshtein_distance(normalized_payee, normalized_term) <= max_distance
    end
  end

  def self.levenshtein_distance(a, b)
    costs = (0..b.length).to_a
    a.each_char.with_index do |char_a, i|
      costs[0] = i + 1
      previous = i
      b.each_char.with_index do |char_b, j|
        current = costs[j + 1]
        costs[j + 1] = if char_a == char_b
          previous
        else
          [ costs[j] + 1, costs[j + 1] + 1, previous + 1 ].min
        end
        previous = current
      end
    end
    costs.last
  end

  private

  def balanced_entries
    debit_sum  = entries.reject(&:marked_for_destruction?).select { |e| e.entry_type == "debit" }.sum(&:amount)
    credit_sum = entries.reject(&:marked_for_destruction?).select { |e| e.entry_type == "credit" }.sum(&:amount)

    if debit_sum != credit_sum
      errors.add(:base, "Transaction is not balanced: debits (#{debit_sum}) must equal credits (#{credit_sum})")
    end
  end

  def minimum_two_entries
    if entries.reject(&:marked_for_destruction?).size < 2
      errors.add(:base, "Transaction must have at least two entries")
    end
  end

  PROTECTED_ENTRY_ATTRIBUTES = %w[account_id amount entry_type].freeze

  def protect_reconciled_entries
    return if allow_reconciled_changes

    entries.each do |entry|
      next unless entry.persisted? && entry.reconciliation_status_was == "reconciled"
      next unless entry.marked_for_destruction? || PROTECTED_ENTRY_ATTRIBUTES.any? { |attr| entry.attribute_changed?(attr) }

      errors.add(:base, "#{entry.account.name} is reconciled: changing or removing this entry will affect previously reconciled balances. Confirm to proceed.")
    end
  end
end
