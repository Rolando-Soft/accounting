class AddDescriptionToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :description, :string
  end
end
