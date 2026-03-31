namespace :db do
  task check_indexes: :environment do
    ActiveRecord::Base.connection.tables.each do |table|
      # Get foreign key columns
      fk_columns = ActiveRecord::Base.connection.foreign_keys(table).map(&:column)

      # Get indexed columns
      indexed_columns = ActiveRecord::Base.connection.indexes(table).flat_map(&:columns)

      # Find foreign keys without indexes
      missing = fk_columns - indexed_columns

      if missing.any?
        puts "❌ #{table}: Missing indexes on #{missing.join(', ')}"
      end
    end
  end
end