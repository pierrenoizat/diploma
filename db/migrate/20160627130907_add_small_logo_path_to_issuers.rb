class AddSmallLogoPathToIssuers < ActiveRecord::Migration
  def change
    add_column :issuers, :small_logo_path, :string
  end
end
