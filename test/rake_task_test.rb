require_relative 'test_helper'
require 'innkeeper/resolvers/database'
require 'rake'

class RakeTaskTest < Innkeeper::Test
  def setup
    setup_connection("mysql")

    Innkeeper.configure do |config|
      config.excluded_models = ["Company"]
      config.tenant_names = lambda{ Company.pluck(:database) }
      config.tenant_resolver = Innkeeper::Resolvers::Database
    end

    super

    @rake = Rake::Application.new
    Rake.application = @rake
    Dummy::Application.load_tasks

    # rails tasks running F up the schema...
    Rake::Task.define_task('db:migrate')
    Rake::Task.define_task('db:seed')
    Rake::Task.define_task('db:rollback')
    Rake::Task.define_task('db:migrate:up')
    Rake::Task.define_task('db:migrate:down')
    Rake::Task.define_task('db:migrate:redo')

    @tenants = [@tenant1, @tenant2]
    @tenants.each{ |t| Company.create(database: t) }
  end

  def teardown
    Rake.application = nil
    Company.delete_all

    super
  end

  def test_all_databases_get_migrated
    assert_received(Innkeeper::Migrator, :migrate, @tenants.size) do
      @rake['innkeeper:migrate'].invoke
    end
  end

  def test_all_databases_get_rolled_back
    assert_received(Innkeeper::Migrator, :rollback, @tenants.size) do
      @rake['innkeeper:rollback'].invoke
    end
  end

  def test_all_databases_get_seeded
    assert_received(Innkeeper::Tenant, :seed, @tenants.size) do
      @rake['innkeeper:seed'].invoke
    end
  end
end
