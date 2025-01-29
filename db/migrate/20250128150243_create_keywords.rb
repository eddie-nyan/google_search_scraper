class CreateKeywords < ActiveRecord::Migration[8.0]
  def change
    create_table :keywords do |t|
      t.references :keyword_file, null: false, foreign_key: true
      t.string :name
      t.integer :search_volume
      t.integer :adwords_advertisers_count
      t.integer :total_links_count
      t.text :html_content
      t.string :status
      t.datetime :processed_at
      t.text :error_message
      t.jsonb :search_metadata

      t.timestamps
    end
  end
end
