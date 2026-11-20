class CreateWorkspaces < ActiveRecord::Migration[8.0]
  def up
    create_table :workspaces do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :workspaces, :name, unique: true

    default_workspace_id = select_value("INSERT INTO workspaces (name, created_at, updated_at) VALUES ('Personal', datetime('now'), datetime('now')) RETURNING id")

    add_reference :accounts, :workspace, foreign_key: true
    add_reference :journal_transactions, :workspace, foreign_key: true

    execute "UPDATE accounts SET workspace_id = #{default_workspace_id}"
    execute "UPDATE journal_transactions SET workspace_id = #{default_workspace_id}"

    change_column_null :accounts, :workspace_id, false
    change_column_null :journal_transactions, :workspace_id, false
  end

  def down
    remove_reference :journal_transactions, :workspace, foreign_key: true
    remove_reference :accounts, :workspace, foreign_key: true
    drop_table :workspaces
  end
end
