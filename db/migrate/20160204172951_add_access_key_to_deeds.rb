class AddAccessKeyToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :access_key, :string
  end
end
