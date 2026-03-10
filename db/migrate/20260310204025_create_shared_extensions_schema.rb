class CreateSharedExtensionsSchema < ActiveRecord::Migration[8.1]
  def up
    execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions'
    execute 'ALTER EXTENSION pg_trgm SET SCHEMA shared_extensions'
  end

  def down
    execute 'ALTER EXTENSION pg_trgm SET SCHEMA public'
    execute 'DROP SCHEMA IF EXISTS shared_extensions'
  end
end
