class UpdateDeedColumns < ActiveRecord::Migration
  def change
    change_table :deeds do |t|
      t.change :tx_id, :string
    end
  end
end