require "minitest/autorun"

module Apartment
  class Test < Minitest::Test
    def setup_connection(db)
      @config = Apartment::TestHelper.config['connections'][db].symbolize_keys
      ActiveRecord::Base.establish_connection(@config)
      # `establish_connection` sets @connection_specification_name on
      # ActiveRecord::Base, this causes it to override our Thread local.
      # `establish_connection` should never be used in a productiion app
      # for this reason.
      Apartment.connection_class.connection_specification_name = nil
      Apartment.reset
    end

    def setup
      Apartment::Tenant.reload!
      @adapter = Apartment::Tenant.adapter
      @tenant1 = self.class.next_db
      @tenant2 = self.class.next_db
      @adapter.create(@tenant1)
      @adapter.create(@tenant2)
    end

    def teardown
      @adapter.reset

      tenants = [@tenant1, @tenant2]

      if @adapter.class.name == "Apartment::Adapters::PostgresqlAdapter"
        @postgres_dbs ? drop(tenants, :database) : drop(tenants, :schema)
      else
        drop(tenants)
      end

      Apartment.excluded_models.each do |excl|
        excl.constantize.connection_specification_name = nil
      end

      Apartment.connection_class.clear_all_connections!
      # unless we remove the connection pools, the connection pools from
      # previous tests containing configs with deleted databases,
      # persist and cause bugs for future tests using the same
      # host/adapter (so the spec name is the same)
      Apartment.connection_class.connection_handler.tap do |ch|
        ch.send(:owner_to_pool).each_key do |k|
          ch.remove_connection(k) if k =~ /^_apartment/
        end
      end
      Apartment.reset
      Apartment::Tenant.reload!
    end

    def drop(tenants, type = nil)
      meth = "drop"
      meth += "_#{type}" if type

      tenants.each{ |t| @adapter.send(meth, t) }
    end

    def self.next_db
      @@x ||= 0
      "db%d" % @@x += 1
    end

    def tenant_is(tenant, for_model: Apartment.connection_class)
      config = Apartment::Tenant.config_for(tenant)

      if @adapter.class.name == "Apartment::Adapters::PostgresqlAdapter"
        current_search_path = for_model.connection.schema_search_path
      end

      config[:database] == for_model.connection.current_database &&
        (!current_search_path || (current_search_path == config[:schema_search_path]) || current_search_path == "\"$user\", public") &&
        (for_model != Apartment.connection_class || Apartment::Tenant.current == tenant)
    end

    def assert_tenant_is(tenant, for_model: Apartment.connection_class)
      res = tenant_is(tenant, for_model: for_model)

      if !res && @adapter.class.name == "Apartment::Adapters::PostgresqlAdapter"
        schema = for_model.connection.schema_search_path
      end

      assert res, "Expected: #{tenant}\nActual: #{{ db: for_model.connection.current_database, schema: schema }}"
    end

    def assert_received(klass, meth, count = 1)
      migrator_mock = Minitest::Mock.new
      count.times{ migrator_mock.expect meth, true }
      klass.stub(meth, ->(*){ migrator_mock.send(meth) }){ yield }

      assert migrator_mock.verify
    end
  end
end
