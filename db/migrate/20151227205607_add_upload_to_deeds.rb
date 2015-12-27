class AddUploadToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :upload, :string
  end
end
