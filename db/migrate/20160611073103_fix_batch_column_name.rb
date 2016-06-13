class FixBatchColumnName < ActiveRecord::Migration
  def self.up
    rename_column :issuers, :batch, :batch_id
  end

  def self.down
    # rename back if you need or do something else or do nothing
  end
end