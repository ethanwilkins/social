class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.references :user, index: true
      t.integer :likes
      t.text :text
      
      t.timestamps
    end
  end
end
