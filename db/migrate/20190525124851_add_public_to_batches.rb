class AddPublicToBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :batches, :public, :boolean
  end
end
