class CreateDeeds < ActiveRecord::Migration
  def change
    create_table :deeds do |t|
      t.string :name
      t.integer :user_id
      t.integer :category
      t.text :description

      t.timestamps null: false
    end
  end
end
