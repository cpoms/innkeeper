require_relative 'test_helper'
require 'apartment/resolvers/database'

class MultithreadingTest < Apartment::Test
  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      # to test in connection switching mode as if switching between hosts
      config.force_reconnect_on_switch = true
      config.tenant_resolver = Apartment::Resolvers::Database
    end

    puts "BEFORE"
    super
    puts "AFTER"
  end

  def test_thread_safety_of_switching
    assert tenant_is(Apartment.default_tenant)

    thread = Thread.new do
      Apartment::Tenant.switch!(@tenant1)

      assert tenant_is(@tenant1)
    end

    thread.join

    assert tenant_is(Apartment.default_tenant)
  end
end
