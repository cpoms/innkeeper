require 'forwardable'

module Innkeeper
  #   The main entry point to Innkeeper functions
  #
  module Tenant

    extend self
    extend Forwardable

    def_delegators :adapter, :create, :drop, :drop_schema, :switch, :switch!,
      :current, :each, :reset, :set_callback, :seed, :current_tenant,
      :default_tenant, :config_for

    #   Initialize Innkeeper config options such as excluded_models
    #
    def init
      adapter.setup_connection_specification_name
      adapter.process_excluded_models
    end

    #   Fetch the proper multi-tenant adapter based on Rails config
    #
    #   @return {subclass of Innkeeper::AbstractAdapter}
    #
    def adapter
      Thread.current[:innkeeper_adapter] ||= begin
        config = Innkeeper.default_tenant

        adapter_name = "#{config[:adapter]}_adapter"

        begin
          require "innkeeper/adapters/#{adapter_name}"
          adapter_class = Adapters.const_get(adapter_name.classify)
        rescue LoadError, NameError
          raise AdapterNotFound, "The adapter `#{adapter_name}` is not yet supported"
        end

        adapter_class.new
      end
    end

    def reload!
      Thread.current[:innkeeper_adapter] = nil
    end
  end
end
