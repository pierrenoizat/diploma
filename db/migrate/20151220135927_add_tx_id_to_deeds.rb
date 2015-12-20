class AddTxIdToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :tx_id, :integer
  end
end
