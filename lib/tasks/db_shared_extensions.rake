namespace :db do
  task ensure_shared_extensions_schema: :environment do
    ActiveRecord::Base.connection.execute('CREATE SCHEMA IF NOT EXISTS shared_extensions')
  end

  namespace :test do
    task ensure_shared_extensions_schema: :environment do
      config = ActiveRecord::Base.configurations.find_db_config('test')
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.execute('CREATE SCHEMA IF NOT EXISTS shared_extensions')
    ensure
      ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    end
  end
end

Rake::Task['db:schema:load'].enhance(['db:ensure_shared_extensions_schema'])
Rake::Task['db:test:load_schema'].enhance(['db:test:ensure_shared_extensions_schema'])
