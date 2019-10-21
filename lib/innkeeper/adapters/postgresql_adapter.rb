require 'innkeeper/adapters/abstract_adapter'
require 'digest'

module Innkeeper
  module Adapters
    class PostgresqlAdapter < AbstractAdapter
      # -- ABSTRACT OVERRIDES --
      def drop(tenant)
        raise NotImplementedError,
          "Please use either drop_database or drop_schema for PG adapter"
      end
      # -- END ABSTRACT OVERRIDES --

      def drop_database(tenant)
        # Innkeeper.connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{tenant}' AND state='idle';"
        self.class.superclass.instance_method(:drop).bind(self).call(tenant)
      end

      def drop_schema(tenant)
        previous_tenant = @current

        config = config_for(tenant)
        difference = current_difference_from(config)

        if difference[:host] || difference[:database]
          connection_switch!(config)
        end

        schema = first_schema(config[:schema_search_path]) if config[:schema_search_path]

        Innkeeper.connection.execute(%{DROP SCHEMA "#{schema}" CASCADE}) if schema

        @current = tenant
      rescue ActiveRecord::StatementInvalid => exception
        raise TenantNotFound, "Error while dropping schema #{schema} for tenant #{tenant}: #{exception.message}"
      ensure
        switch!(previous_tenant) rescue reset
      end

      def switch_tenant(config)
        current_config = config_for(@current)
        difference = config.select{ |k, v| current_config[k] != v }

        # PG doesn't have the ability to switch DB without reconnecting
        if difference[:host] || difference[:database]
          connection_switch!(config)
        else
          simple_switch(config) if difference[:schema_search_path]
        end
      end

      def simple_switch(config)
        return unless config[:schema_search_path]

        tenant = first_schema(config[:schema_search_path])

        unless Innkeeper.connection.schema_exists?(tenant)
          raise Innkeeper::TenantNotFound, "Could not find schema #{tenant}"
        end

        Innkeeper.connection.schema_search_path = config[:schema_search_path]
      end

      def create_tenant!(config)
        unless database_exists?(config[:database])
          Innkeeper.connection.create_database(config[:database], config)
          connection_switch!(config, without_keys: [:schema_search_path])
        end

        schema = first_schema(config[:schema_search_path]) if config[:schema_search_path]

        if schema && !schema_exists?(schema)
          Innkeeper.connection.execute(%{CREATE SCHEMA "#{schema}"})
        end
      end

      def connection_specification_name(config)
        if Innkeeper.pool_per_config
          "_innkeeper_#{config.hash}".to_sym
        else
          host_hash = Digest::MD5.hexdigest(config[:host] || config[:url] || "127.0.0.1")
          "_innkeeper_#{host_hash}_#{config[:adapter]}_#{config[:database]}".to_sym
        end
      end

      private
        def database_exists?(database)
          result = Innkeeper.connection.exec_query(<<-SQL).try(:first)
            SELECT EXISTS(
              SELECT 1
              FROM pg_catalog.pg_database
              WHERE datname = #{Innkeeper.connection.quote(database)}
            )
          SQL

          result.present? && result['exists']
        end

        def schema_exists?(schema)
          Innkeeper.connection.schema_exists?(schema)
        end

        def first_schema(search_path)
          strip_quotes(search_path.split(",").first)
        end

        def strip_quotes(string)
          string[0] == '"' ? string[1..-2] : string
        end
    end
  end
end
