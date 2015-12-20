class AddTxHashToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :tx_hash, :string
  end
end
