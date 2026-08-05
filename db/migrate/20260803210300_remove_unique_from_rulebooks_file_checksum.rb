class RemoveUniqueFromRulebooksFileChecksum < ActiveRecord::Migration[8.1]
  def change
    remove_index :rulebooks, :file_checksum, unique: true, where: 'file_checksum IS NOT NULL'
    add_index :rulebooks, :file_checksum
  end
end
