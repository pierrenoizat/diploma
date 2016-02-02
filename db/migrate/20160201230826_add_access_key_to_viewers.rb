class AddAccessKeyToViewers < ActiveRecord::Migration
  def change
    add_column :viewers, :access_key, :string
  end
end
