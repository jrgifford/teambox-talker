class CreateRooms < ActiveRecord::Migration
  def self.up
    create_table :rooms do |t|
      t.string :name
      t.string :medium
      t.text :description
      t.belongs_to :account
      t.timestamps
    end
  end

  def self.down
    drop_table :rooms
  end
end
