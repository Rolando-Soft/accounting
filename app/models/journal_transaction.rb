class JournalTransaction < ApplicationRecord
  has_many :entries, dependent: :destroy
  accepts_nested_attributes_for :entries

  validates :date, presence: true
  validate :balanced_entries

  private

  def balanced_entries
      debit_sum  = entries.select { |e| e.entry_type == "debit" }.sum(&:amount)
      credit_sum = entries.select { |e| e.entry_type == "credit" }.sum(&:amount)

      if debit_sum != credit_sum
        errors.add(:base, "Transaction is not balanced: debits (#{debit_sum}) must equal credits (#{credit_sum})")
      end
  end
end
