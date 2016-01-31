class AddIssuerIdToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :issuer_id, :integer
  end
end
