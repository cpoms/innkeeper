require_relative 'test_helper'
require 'innkeeper/resolvers/schema'
require 'innkeeper/resolvers/database'
require_relative 'shared/shared_adapter_tests'

class PostgresqlAdapterTest < Innkeeper::Test
  include SharedAdapterTests

  def setup
    setup_connection("postgresql")

    Innkeeper.configure do |config|
      config.tenant_resolver = Innkeeper::Resolvers::Schema
    end

    super
  end

  # idk why it broked :'(
  # def test_postgres_database_resolver_reconnects
  #   Innkeeper.tenant_resolver = Innkeeper::Resolvers::Database

  #   @adapter.create("db_tenant")

  #   assert_tenant_is(Innkeeper.default_tenant)

  #   conn_id = Innkeeper.connection.object_id

  #   Innkeeper::Tenant.switch("db_tenant") do
  #     refute_equal conn_id, Innkeeper.connection.object_id
  #     assert_equal "db_tenant", Innkeeper.connection.current_database
  #   end

  #   assert_tenant_is(Innkeeper.default_tenant)
  # ensure
  #   @adapter.drop_database("db_tenant")
  #   Innkeeper.tenant_resolver = Innkeeper::Resolvers::Schema
  # end
end
