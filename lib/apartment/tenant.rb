require 'forwardable'

module Apartment
  #   The main entry point to Apartment functions
  #
  module Tenant

    extend self
    extend Forwardable

    def_delegators :adapter, :create, :drop, :drop_schema, :switch, :switch!,
      :current, :each, :reset, :set_callback, :seed, :current_tenant,
      :default_tenant, :config_for

    #   Initialize Apartment config options such as excluded_models
    #
    def init
      adapter.process_excluded_models
    end

    #   Fetch the proper multi-tenant adapter based on Rails config
    #
    #   @return {subclass of Apartment::AbstractAdapter}
    #
    def adapter
      Thread.current[:apartment_adapter] ||= begin
        config = Apartment.default_tenant

        adapter_name =
          if defined?(JRUBY_VERSION)
            if config[:adapter] =~ /mysql/
              'jdbc_mysql_adapter'
            elsif config[:adapter] =~ /postgresql/
              'jdbc_postgresql_adapter'
            end
          else
            "#{config[:adapter]}_adapter"
          end

        begin
          require "apartment/adapters/#{adapter_name}"
          adapter_class = Adapters.const_get(adapter_name.classify)
        rescue LoadError, NameError
          raise AdapterNotFound, "The adapter `#{adapter_name}` is not yet supported"
        end

        adapter_class.new
      end
    end

    def reload!
      Thread.current[:apartment_adapter] = nil
    end
  end
end
