require_relative 'test_helper'
require 'apartment/resolvers/database'
require 'rake'

class RakeTaskTest < Apartment::Test
  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      config.excluded_models = ["Company"]
      config.tenant_names = lambda{ Company.pluck(:database) }
      config.tenant_resolver = Apartment::Resolvers::Database
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
    assert_received(Apartment::Migrator, :migrate, @tenants.size) do
      @rake['apartment:migrate'].invoke
    end
  end

  def test_all_databases_get_rolled_back
    assert_received(Apartment::Migrator, :rollback, @tenants.size) do
      @rake['apartment:rollback'].invoke
    end
  end

  def test_all_databases_get_seeded
    assert_received(Apartment::Tenant, :seed, @tenants.size) do
      @rake['apartment:seed'].invoke
    end
  end
end
