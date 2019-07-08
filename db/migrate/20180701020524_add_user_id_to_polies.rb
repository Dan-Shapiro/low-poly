class AddUserIdToPolies < ActiveRecord::Migration
  def change
    add_column :polies, :user_id, :integer
  end
end
