module SharedAdapterTests
  def test_switch
    assert_tenant_is(Innkeeper.default_tenant)

    Innkeeper::Tenant.switch(@tenant1){
      assert_tenant_is(@tenant1)
    }

    assert_tenant_is(Innkeeper.default_tenant)
  end

  def test_local_switch_doesnt_modify_connection
    assert_tenant_is(Innkeeper.default_tenant)

    conn_id = Innkeeper.connection.object_id

    Innkeeper::Tenant.switch!(@tenant1)

    assert_tenant_is(@tenant1)
    assert_equal conn_id, Innkeeper.connection.object_id
  end

  def test_remote_switch_modifies_connection
    assert_tenant_is(Innkeeper.default_tenant)

    conn_id = Innkeeper.connection.object_id

    Innkeeper::Tenant.switch!(@config.dup.tap{ |c| c[:host] = 'localhost' })

    assert_equal @config[:database], Innkeeper.connection.current_database
    refute_equal conn_id, Innkeeper.connection.object_id
  end

  def test_force_reconnect
    Innkeeper.configure{ |config| config.force_reconnect_on_switch = true }

    assert_tenant_is(Innkeeper.default_tenant)

    conn_id = Innkeeper.connection.object_id

    Innkeeper::Tenant.switch!(@tenant1)

    assert_tenant_is(@tenant1)
    refute_equal conn_id, Innkeeper.connection.object_id
  end

  def test_switch_raises_error_for_unknown_database
    assert_raises Innkeeper::TenantNotFound do
      Innkeeper::Tenant.switch!("invalid")
    end
  end

  def test_drop_raises_error_for_unknown_database
    assert_raises Innkeeper::TenantNotFound do
      if Innkeeper::Tenant.adapter.respond_to?(:drop_schema)
        Innkeeper::Tenant.drop_schema("invalid")
      else
        Innkeeper::Tenant.drop("invalid")
      end
    end
  end

  def test_default_tenant_configuration_is_used
    prev_default = Innkeeper.default_tenant

    Innkeeper.configure do |config|
      config.default_tenant = @tenant1
    end

    assert_equal @tenant1, Innkeeper.default_tenant

    @adapter.reset

    assert_tenant_is(@tenant1)
  ensure
    Innkeeper.default_tenant = prev_default
  end

  def test_ActiveRecord_QueryCache_cleared_after_switching_databases
    [@tenant1, @tenant2].each do |tenant|
      Innkeeper::Tenant.switch(tenant) do
        User.create!(name: tenant)
      end
    end
    Innkeeper.connection.enable_query_cache!

    Innkeeper::Tenant.switch(@tenant1) do
      assert User.find_by(name: @tenant1)
    end

    Innkeeper::Tenant.switch(@tenant2) do
      assert_nil User.find_by(name: @tenant1)
    end
  end
end
