class AddBatchIdToIssuers < ActiveRecord::Migration
  def change
    add_column :issuers, :batch_id, :integer
  end
end
