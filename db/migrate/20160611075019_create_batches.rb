class CreateBatches < ActiveRecord::Migration
  def change
    create_table :batches do |t|
      t.string :title
      t.integer :issuer_id
      t.string :address

      t.timestamps null: false
    end
  end
end
