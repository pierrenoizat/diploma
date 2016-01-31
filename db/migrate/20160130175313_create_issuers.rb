class CreateIssuers < ActiveRecord::Migration
  def change
    create_table :issuers do |t|
      t.string :name
      t.string :batch
      t.string :mpk

      t.timestamps null: false
    end
  end
end
