require_relative 'test_helper'
require 'apartment/resolvers/database'

class RailtieTest < Minitest::Test
  def test_railtie_does_not_hold_onto_connection
    Apartment.configure do |config|
      config.tenant_resolver = Apartment::Resolvers::Database
      config.excluded_models = %w(Company)
    end

    Apartment.connection_class.connection_pool.disconnect!

    before = Apartment.connection_class.connection_pool.stat.slice(:busy, :dead, :waiting)

    Apartment::Railtie.prep
    Apartment::Railtie.config.to_prepare_blocks.map(&:call)

    after = Apartment.connection_class.connection_pool.stat.slice(:busy, :dead, :waiting)

    assert_equal before, after
  end

  def test_railtie_sets_default_configuration
    Apartment::Railtie.prep

    assert_equal [], Apartment.excluded_models
    assert_equal false, Apartment.force_reconnect_on_switch
    assert_equal false, Apartment.seed_after_create
    assert_instance_of Apartment::Resolvers::Database, Apartment.tenant_resolver
  end
end
