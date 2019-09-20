require 'apartment/railtie' if defined?(Rails)
require 'active_support/core_ext/object/blank'
require 'forwardable'
require 'active_record'
require 'apartment/tenant'

module Apartment
  class << self
    extend Forwardable

    ACCESSOR_METHODS = [
      :use_sql, :seed_after_create, :tenant_decorator,
      :force_reconnect_on_switch, :pool_per_config
    ]
    WRITER_METHODS   = [
      :tenant_names, :database_schema_file, :excluded_models,
      :persistent_schemas, :connection_class, :tld_length, :db_migrate_tenants,
      :seed_data_file, :default_tenant, :parallel_migration_threads
    ]
    OTHER_METHODS    = [:tenant_resolver, :resolver_class]

    attr_accessor(*ACCESSOR_METHODS)
    attr_writer(*WRITER_METHODS)

    def_delegators :connection_class, :connection, :connection_config,
      :establish_connection, :connection_handler

    def configure
      yield self if block_given?
    end

    def tenant_resolver
      @tenant_resolver ||= @resolver_class.new(connection_config)
    end

    def tenant_resolver=(resolver_class)
      remove_instance_variable(:@tenant_resolver) if instance_variable_defined?(:@tenant_resolver)
      @resolver_class = resolver_class
    end

    def tenant_names
      @tenant_names.respond_to?(:call) ? @tenant_names.call : (@tenant_names || [])
    end

    def tenants_with_config
      extract_tenant_config
    end

    # Whether or not db:migrate should also migrate tenants
    # defaults to true
    def db_migrate_tenants
      return @db_migrate_tenants if defined?(@db_migrate_tenants)

      @db_migrate_tenants = true
    end

    # Default to empty array
    def excluded_models
      @excluded_models || []
    end

    def default_tenant
      @default_tenant || tenant_resolver.init_config
    end

    def parallel_migration_threads
      @parallel_migration_threads || 0
    end

    def persistent_schemas
      @persistent_schemas || []
    end

    def connection_class
      @connection_class || ActiveRecord::Base
    end

    def database_schema_file
      return @database_schema_file if defined?(@database_schema_file)

      @database_schema_file = Rails.root.join('db', 'schema.rb')
    end

    def seed_data_file
      return @seed_data_file if defined?(@seed_data_file)

      @seed_data_file = Rails.root.join('db', 'seeds.rb')
    end

    def reset
      (ACCESSOR_METHODS + WRITER_METHODS + OTHER_METHODS).each do |method|
        remove_instance_variable(:"@#{method}") if instance_variable_defined?(:"@#{method}")
      end

      Thread.current[:_apartment_connection_specification_name] = nil
    end
  end

  # Exceptions
  ApartmentError = Class.new(StandardError)

  # Raised when apartment cannot find the adapter specified in <tt>config/database.yml</tt>
  AdapterNotFound = Class.new(ApartmentError)

  # Tenant specified is unknown
  TenantNotFound = Class.new(ApartmentError)

  # The Tenant attempting to be created already exists
  TenantExists = Class.new(ApartmentError)
end
