require_relative 'test_helper'
require 'innkeeper/resolvers/database'

class RailtieTest < Minitest::Test
  def test_railtie_does_not_hold_onto_connection
    Innkeeper.configure do |config|
      config.tenant_resolver = Innkeeper::Resolvers::Database
      config.excluded_models = %w(Company)
    end

    Innkeeper.connection_class.connection_pool.disconnect!

    before = Innkeeper.connection_class.connection_pool.stat.slice(:busy, :dead, :waiting)

    Innkeeper::Railtie.prep
    Innkeeper::Railtie.config.to_prepare_blocks.map(&:call)

    after = Innkeeper.connection_class.connection_pool.stat.slice(:busy, :dead, :waiting)

    assert_equal before, after
  end

  def test_railtie_sets_default_configuration
    Innkeeper::Railtie.prep

    assert_equal [], Innkeeper.excluded_models
    assert_equal false, Innkeeper.force_reconnect_on_switch
    assert_equal false, Innkeeper.seed_after_create
    assert_instance_of Innkeeper::Resolvers::Database, Innkeeper.tenant_resolver
  end
end
