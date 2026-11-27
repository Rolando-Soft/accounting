class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :projects, [ :workspace_id, :name ], unique: true
    add_index :projects, [ :workspace_id, :code ], unique: true
  end
end
