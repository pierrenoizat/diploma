class AddTxRawToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :tx_raw, :string
  end
end
