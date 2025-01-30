class ChangeSearchVolumeColumnSize < ActiveRecord::Migration[8.0]
  def up
    change_column :keywords, :search_volume, :string, limit: 20
  end

  def down
    change_column :keywords, :search_volume, :string
  end
end
