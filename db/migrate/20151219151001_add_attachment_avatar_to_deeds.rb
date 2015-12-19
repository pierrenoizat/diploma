class AddAttachmentAvatarToDeeds < ActiveRecord::Migration
  def self.up
    change_table :deeds do |t|
      t.attachment :avatar
    end
  end

  def self.down
    remove_attachment :deeds, :avatar
  end
end
