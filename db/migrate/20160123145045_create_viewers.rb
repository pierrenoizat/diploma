class CreateViewers < ActiveRecord::Migration
  def change
    create_table :viewers do |t|
      t.string :email
      t.integer :deed_id

      t.timestamps null: false
    end
  end
end
