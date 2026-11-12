class Account < ApplicationRecord
  before_destroy :ensure_no_journal_transactions
  before_destroy :ensure_no_children

  belongs_to :parent, class_name: "Account", optional: true, inverse_of: :children
  has_many :children, class_name: "Account", foreign_key: :parent_id, inverse_of: :parent

  has_many :entries, dependent: :destroy
  has_many :journal_transactions, through: :entries

  enum :account_type, {asset: 0, liability: 1, income: 2, expense: 3, equity: 4}
  enum :cash_flow_category, {operating: 0, investing: 1, financing: 2}, allow_nil: true

  validates :name, presence: true, uniqueness: true
  validates :account_type, presence: true
  validates :description, length: { maximum: 500 }
  validate :parent_cannot_be_self
  validate :parent_must_have_same_account_type
  validate :parent_cannot_create_cycle

  private
  def ensure_no_journal_transactions
    if entries.exists?
      errors.add(:base, "Cannot delete account with associated journal transactions")
      throw(:abort)
    end
  end

  def ensure_no_children
    if children.exists?
      errors.add(:base, "Cannot delete account with sub-accounts")
      throw(:abort)
    end
  end

  def parent_cannot_be_self
    errors.add(:parent, "can't be the account itself") if parent_id.present? && parent_id == id
  end

  def parent_must_have_same_account_type
    if parent && account_type.present? && parent.account_type != account_type
      errors.add(:account_type, "must match the parent account's type (#{parent.account_type})")
    end
  end

  def parent_cannot_create_cycle
    return unless parent_id.present? && id.present?

    ancestor = parent
    while ancestor
      if ancestor.id == id
        errors.add(:parent, "cannot create a cycle")
        break
      end
      ancestor = ancestor.parent
    end
  end
end
