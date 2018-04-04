require_relative 'test_helper'
require 'apartment/resolvers/database'

class MultithreadingTest < Apartment::Test
  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      # to test in connection switching mode as if switching between hosts
      config.force_reconnect_on_switch = true
      config.pool_per_config = true
      config.tenant_resolver = Apartment::Resolvers::Database
    end

    super
  end

  def test_thread_safety_of_switching
    assert_tenant_is(Apartment.default_tenant)

    threads = []
    100.times do
      threads << Thread.new do
        db = [@tenant1, @tenant2].sample
        Apartment::Tenant.switch!(db)

        assert_tenant_is(db)

        Apartment.connection_class.clear_active_connections!
      end
    end

    threads.each(&:join)

    assert_tenant_is(Apartment.default_tenant)
  end
end
