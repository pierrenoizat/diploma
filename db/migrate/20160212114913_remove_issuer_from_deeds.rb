class RemoveIssuerFromDeeds < ActiveRecord::Migration
  def change
    remove_column :deeds, :issuer, :string
  end
end
