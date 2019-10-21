require_relative 'test_helper'
require 'innkeeper/resolvers/database'

class MultithreadingTest < Innkeeper::Test
  def setup
    setup_connection("mysql")

    Innkeeper.configure do |config|
      # to test in connection switching mode as if switching between hosts
      config.force_reconnect_on_switch = true
      config.pool_per_config = true
      config.tenant_resolver = Innkeeper::Resolvers::Database
    end

    super
  end

  def test_thread_safety_of_switching
    assert_tenant_is(Innkeeper.default_tenant)

    threads = []
    100.times do
      threads << Thread.new do
        db = [@tenant1, @tenant2].sample
        Innkeeper::Tenant.switch!(db)

        assert_tenant_is(db)

        Innkeeper.connection_class.clear_active_connections!
      end
    end

    threads.each(&:join)

    assert_tenant_is(Innkeeper.default_tenant)
  end
end
