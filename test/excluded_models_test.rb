require_relative 'test_helper'
require 'innkeeper/resolvers/database'

class ExcludedModelsTest < Innkeeper::Test
  def setup
    setup_connection("mysql")

    Innkeeper.configure do |config|
      config.tenant_resolver = Innkeeper::Resolvers::Database
      config.excluded_models = %w(Company User)
    end

    super
  end

  def test_model_exclusions
    Innkeeper::Tenant.adapter.process_excluded_models

    assert_equal :_innkeeper_excluded, Company.connection_specification_name

    Innkeeper::Tenant.switch(@tenant1) do
      assert_tenant_is(@tenant1)
      assert_tenant_is(Innkeeper.default_tenant, for_model: Company)
    end
  end

  def test_all_excluded_models_use_same_connection_pool
    Innkeeper::Tenant.adapter.process_excluded_models

    assert_equal Company.connection_pool, User.connection_pool
  end
end
