class AddIssuerIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :issuer_id, :integer
  end
end
