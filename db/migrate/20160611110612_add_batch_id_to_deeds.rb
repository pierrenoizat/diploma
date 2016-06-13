class AddBatchIdToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :batch_id, :integer
  end
end
