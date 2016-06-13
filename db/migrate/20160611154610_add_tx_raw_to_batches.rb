class AddTxRawToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :tx_raw, :text
  end
end
