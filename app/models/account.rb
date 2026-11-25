class Account < ApplicationRecord
  include WorkspaceScoped

  before_destroy :ensure_no_journal_transactions
  before_destroy :ensure_no_children

  belongs_to :parent, class_name: "Account", optional: true, inverse_of: :children
  has_many :children, class_name: "Account", foreign_key: :parent_id, inverse_of: :parent

  has_many :entries, dependent: :destroy
  has_many :journal_transactions, through: :entries

  enum :account_type, {asset: 0, liability: 1, income: 2, expense: 3, equity: 4}
  enum :cash_flow_category, {operating: 0, investing: 1, financing: 2, cash: 3}, allow_nil: true

  TYPE_LABELS = {
    "asset" => "Assets",
    "liability" => "Liabilities",
    "income" => "Income",
    "expense" => "Expense",
    "equity" => "Equity"
  }.freeze

  # Grouped by type in TYPE_LABELS' order (Assets, Liabilities, Income,
  # Expense, Equity), then by name — the order account pickers should use.
  scope :ordered_by_type, -> { order(:account_type, :name) }

  # Leaf accounts only — a parent account can't itself hold entries (see
  # Entry#account_must_not_have_children), so transaction forms should only
  # offer accounts that are actually postable.
  scope :postable, -> { where.not(id: Account.where.not(parent_id: nil).select(:parent_id)) }

  # The accounts the Cash Flow Statement treats as cash itself (vs. an asset
  # whose cash_flow_category tracks its own cash effect, e.g. investments or
  # receivables) — an Asset account whose cash_flow_category is "cash".
  scope :cash, -> { where(account_type: "asset", cash_flow_category: cash_flow_categories[:cash]) }
  scope :non_cash, -> { where.not(account_type: "asset", cash_flow_category: cash_flow_categories[:cash]) }

  # The entry_type ("debit" or "credit") that increases this account's balance.
  NORMAL_BALANCE = {
    "asset" => "debit",
    "liability" => "credit",
    "income" => "credit",
    "expense" => "debit",
    "equity" => "credit"
  }.freeze

  def normal_balance
    NORMAL_BALANCE[account_type]
  end

  def label_with_type
    "#{name} (#{TYPE_LABELS[account_type]})"
  end

  # Fuzzy-matches `term` against `name`: a plain substring match always
  # counts, and a short Levenshtein distance catches typos.
  def self.search_by_name(term, max_distance: 2)
    return none if term.blank?

    normalized_term = term.strip.downcase
    where.not(name: [ nil, "" ]).select do |account|
      normalized_name = account.name.downcase
      normalized_name.include?(normalized_term) ||
        levenshtein_distance(normalized_name, normalized_term) <= max_distance
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
    costs[b.length]
  end

  validates :name, presence: true, uniqueness: { scope: :workspace_id }
  validates :account_type, presence: true
  validates :cash_flow_category, presence: true
  validates :description, length: { maximum: 500 }
  validate :parent_cannot_be_self
  validate :parent_must_have_same_account_type
  validate :parent_must_have_same_workspace
  validate :parent_cannot_create_cycle
  validate :cash_category_only_for_asset_accounts

  private
  def cash_category_only_for_asset_accounts
    if cash_flow_category == "cash" && account_type != "asset"
      errors.add(:cash_flow_category, "can only be \"Cash\" for an Asset account")
    end
  end

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

  def parent_must_have_same_workspace
    if parent && workspace_id.present? && parent.workspace_id != workspace_id
      errors.add(:parent, "must belong to the same workspace")
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
