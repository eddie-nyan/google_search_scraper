class CreateKeywordFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :keyword_files do |t|
      t.string :filename, null: false
      t.string :status, default: 'pending'
      t.integer :total_keywords, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
