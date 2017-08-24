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

    thread = Thread.new do
      Apartment::Tenant.switch!(@tenant1)

      assert_tenant_is(@tenant1)

      # it's necessary to check connections back in from threads, else
      # you'll leak connections.
      Apartment.connection_class.clear_active_connections!
    end

    thread.join

    assert_tenant_is(Apartment.default_tenant)
  end
end
