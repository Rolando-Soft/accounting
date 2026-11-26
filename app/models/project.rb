class Project < ApplicationRecord
  include WorkspaceScoped

  has_many :entries, dependent: :restrict_with_error

  enum :status, { active: 0, archived: 1 }

  validates :name, presence: true, uniqueness: { scope: :workspace_id }
  validates :code, uniqueness: { scope: :workspace_id }, allow_blank: true

  def label
    code.present? ? "#{name} (#{code})" : name
  end
end
