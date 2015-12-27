class AddCategoryToUsers < ActiveRecord::Migration
  def change
    add_column :users, :category, :integer
    add_column :users, :credit, :integer
  end
end
