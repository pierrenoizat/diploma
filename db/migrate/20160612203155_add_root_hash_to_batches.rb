class AddRootHashToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :root_hash, :string
  end
end
