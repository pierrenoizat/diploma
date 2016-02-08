class AddCategoryToIssuers < ActiveRecord::Migration
  def change
    add_column :issuers, :category, :integer
  end
end
