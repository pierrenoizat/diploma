class AddAvatarFingerprintToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :avatar_fingerprint, :string
  end
end
