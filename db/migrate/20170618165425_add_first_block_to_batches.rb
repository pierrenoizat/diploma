class AddFirstBlockToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :first_block, :integer
    add_column :batches, :school_url, :string
    add_column :batches, :adress_url, :string
  end
end
