require_relative 'test_helper'
require 'apartment/resolvers/database'

class ExcludedModelsTest < Apartment::Test
  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      config.tenant_resolver = Apartment::Resolvers::Database
      config.excluded_models = %w(Company User)
    end

    super
  end

  def test_model_exclusions
    Apartment::Tenant.adapter.process_excluded_models

    assert_equal :_apartment_excluded, Company.connection_specification_name

    Apartment::Tenant.switch(@tenant1) do
      assert tenant_is(@tenant1)
      assert tenant_is(Apartment.default_tenant, for_model: Company)
    end
  end

  def test_all_excluded_models_use_same_connection_pool
    Apartment::Tenant.adapter.process_excluded_models

    assert_equal Company.connection_pool, User.connection_pool
  end
end
