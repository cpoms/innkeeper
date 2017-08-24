module SharedAdapterTests
  def test_switch
    assert_tenant_is(Apartment.default_tenant)

    Apartment::Tenant.switch(@tenant1){
      assert_tenant_is(@tenant1)
    }

    assert_tenant_is(Apartment.default_tenant)
  end

  def test_local_switch_doesnt_modify_connection
    assert_tenant_is(Apartment.default_tenant)

    conn_id = Apartment.connection.object_id

    Apartment::Tenant.switch!(@tenant1)

    assert_tenant_is(@tenant1)
    assert_equal conn_id, Apartment.connection.object_id
  end

  def test_remote_switch_modifies_connection
    assert_tenant_is(Apartment.default_tenant)

    conn_id = Apartment.connection.object_id

    Apartment::Tenant.switch!(@config.dup.tap{ |c| c[:host] = 'localhost' })

    assert_equal @config[:database], Apartment.connection.current_database
    refute_equal conn_id, Apartment.connection.object_id
  end

  def test_force_reconnect
    Apartment.configure{ |config| config.force_reconnect_on_switch = true }

    assert_tenant_is(Apartment.default_tenant)

    conn_id = Apartment.connection.object_id

    Apartment::Tenant.switch!(@tenant1)

    assert_tenant_is(@tenant1)
    refute_equal conn_id, Apartment.connection.object_id
  end

  def test_switch_raises_error_for_unknown_database
    assert_raises Apartment::TenantNotFound do
      Apartment::Tenant.switch!("invalid")
    end
  end

  def test_drop_raises_error_for_unknown_database
    assert_raises Apartment::TenantNotFound do
      if Apartment::Tenant.adapter.respond_to?(:drop_schema)
        Apartment::Tenant.drop_schema("invalid")
      else
        Apartment::Tenant.drop("invalid")
      end
    end
  end

  def test_default_tenant_configuration_is_used
    prev_default = Apartment.default_tenant

    Apartment.configure do |config|
      config.default_tenant = @tenant1
    end

    assert_equal @tenant1, Apartment.default_tenant

    @adapter.reset

    assert_tenant_is(@tenant1)
  ensure
    Apartment.default_tenant = prev_default
  end

  def test_ActiveRecord_QueryCache_cleared_after_switching_databases
    [@tenant1, @tenant2].each do |tenant|
      Apartment::Tenant.switch(tenant) do
        User.create!(name: tenant)
      end
    end
    Apartment.connection.enable_query_cache!

    Apartment::Tenant.switch(@tenant1) do
      assert User.find_by(name: @tenant1)
    end

    Apartment::Tenant.switch(@tenant2) do
      assert_nil User.find_by(name: @tenant1)
    end
  end
end
