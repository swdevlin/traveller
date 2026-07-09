namespace :db do
  task ensure_shared_extensions_schema: :environment do
    conn = ActiveRecord::Base.connection
    conn.execute('CREATE SCHEMA IF NOT EXISTS shared_extensions')
    conn.execute('CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA shared_extensions')
  end

  namespace :test do
    task ensure_shared_extensions_schema: :environment do
      config = ActiveRecord::Base.configurations.find_db_config('test')
      ActiveRecord::Base.establish_connection(config)
      conn = ActiveRecord::Base.connection
      conn.execute('CREATE SCHEMA IF NOT EXISTS shared_extensions')
      conn.execute('CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA shared_extensions')
    ensure
      ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    end
  end
end

Rake::Task['db:schema:dump'].enhance do
  file = Rails.root.join('db/structure.sql')
  content = file.read
  content.gsub!(/^CREATE SCHEMA (\w+);/, 'CREATE SCHEMA IF NOT EXISTS \1;')
  file.write(content)
end

Rake::Task['db:schema:load'].enhance(['db:ensure_shared_extensions_schema'])
Rake::Task['db:test:load_schema'].enhance(['db:test:ensure_shared_extensions_schema'])
