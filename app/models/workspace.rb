class Workspace < ApplicationRecord
  # Plain has_many, deliberately not used for reads/deletes elsewhere in this
  # model: Account/JournalTransaction carry a default_scope restricting them
  # to Current.workspace, which would silently filter out everything here
  # whenever this isn't the active workspace. Counting and deleting always
  # go through Account.unscoped / JournalTransaction.unscoped instead.
  has_many :accounts
  has_many :journal_transactions
  has_many :projects

  validates :name, presence: true, uniqueness: true

  before_destroy :ensure_not_last_workspace

  def accounts_count
    Account.unscoped.where(workspace_id: id).count
  end

  def journal_transactions_count
    JournalTransaction.unscoped.where(workspace_id: id).count
  end

  # Wipes every account, journal transaction, and entry belonging to this
  # workspace, then deletes the workspace itself. Uses delete_all (not
  # destroy_all) to bypass the per-record guards on Account/JournalTransaction
  # that exist to prevent *accidental* single-record deletion (e.g. an
  # account with entries) — here the whole workspace is intentionally being
  # wiped, so those guards would only get in the way. Entries are removed
  # before their journal transactions/accounts to satisfy the restrict-on-delete
  # foreign keys.
  def destroy_everything!
    transaction do
      journal_transaction_ids = JournalTransaction.unscoped.where(workspace_id: id).select(:id)
      Entry.where(journal_transaction_id: journal_transaction_ids).delete_all
      JournalTransaction.unscoped.where(workspace_id: id).delete_all
      Account.unscoped.where(workspace_id: id).delete_all
      Project.unscoped.where(workspace_id: id).delete_all
      destroy!
    end
  end

  private
  def ensure_not_last_workspace
    if Workspace.count <= 1
      errors.add(:base, "Cannot delete the last remaining workspace")
      throw(:abort)
    end
  end
end
