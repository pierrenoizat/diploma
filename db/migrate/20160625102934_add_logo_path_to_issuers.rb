class AddLogoPathToIssuers < ActiveRecord::Migration
  def change
    add_column :issuers, :logo_path, :string
  end
end
