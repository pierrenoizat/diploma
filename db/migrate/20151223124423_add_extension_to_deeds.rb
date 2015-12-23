class AddExtensionToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :extension, :string
  end
end
