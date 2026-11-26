class AddProjectToEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :entries, :project, null: true, foreign_key: { on_delete: :restrict }
  end
end
