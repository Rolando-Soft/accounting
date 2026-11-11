class Account < ApplicationRecord
  before_destroy :ensure_no_journal_transactions

  has_many :entries, dependent: :destroy
  has_many :journal_transactions, through: :entries

  enum :account_type, {asset: 0, liability: 1, income: 2, expense: 3, equity: 4}

  validates :name, presence: true, uniqueness: true
  validates :account_type, presence: true
  validates :description, length: { maximum: 500 }

  private
  def ensure_no_journal_transactions
    if entries.exists?
      errors.add(:base, "Cannot delete account with associated journal transactions")
      throw(:abort)
    end
  end
end
