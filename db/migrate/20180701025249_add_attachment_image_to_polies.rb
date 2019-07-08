class AddAttachmentImageToPolies < ActiveRecord::Migration
  def self.up
    change_table :polies do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :polies, :image
  end
end
