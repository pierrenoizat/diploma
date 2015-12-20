class AddIssuerToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :issuer, :string
  end
end
