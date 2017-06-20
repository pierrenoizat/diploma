class RenameAddressUrl < ActiveRecord::Migration
  def change
    rename_column :batches, :adress_url, :address_url
  end
end
