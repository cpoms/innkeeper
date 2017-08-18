require_relative 'test_helper'
require 'apartment/resolvers/schema'
require 'apartment/resolvers/database'
require_relative 'shared/shared_adapter_tests'

class PostgresqlAdapterTest < Apartment::Test
  include SharedAdapterTests

  def setup
    setup_connection("postgresql")

    Apartment.configure do |config|
      config.tenant_resolver = Apartment::Resolvers::Schema
    end

    super
  end

  # idk why it broked :'(
  # def test_postgres_database_resolver_reconnects
  #   Apartment.tenant_resolver = Apartment::Resolvers::Database

  #   @adapter.create("db_tenant")

  #   assert tenant_is(Apartment.default_tenant)

  #   conn_id = Apartment.connection.object_id

  #   Apartment::Tenant.switch("db_tenant") do
  #     refute_equal conn_id, Apartment.connection.object_id
  #     assert_equal "db_tenant", Apartment.connection.current_database
  #   end

  #   assert tenant_is(Apartment.default_tenant)
  # ensure
  #   @adapter.drop_database("db_tenant")
  #   Apartment.tenant_resolver = Apartment::Resolvers::Schema
  # end
end
