class UpdateIssuerColumns < ActiveRecord::Migration
  def change
    remove_column :issuers, :batch_id
  end
end

