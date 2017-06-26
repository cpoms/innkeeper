require 'apartment/adapters/abstract_adapter'

module Apartment
  module Adapters
    class Mysql2Adapter < AbstractAdapter
      def switch_tenant(config)
        difference = current_difference_from(config)

        if difference[:host]
          Apartment.connection_class.connection_handler.establish_connection(config)
        else
          simple_switch(config) if difference[:database]
        end
      end

      def create_tenant!(config)
        Apartment.connection.create_database(config[:database], config)
      end

      def simple_switch(config)
        Apartment.connection.execute("use `#{config[:database]}`")
      rescue ActiveRecord::StatementInvalid => exception
        raise_connect_error!(config[:database], exception)
      end

      private
        def database_exists?(database)
          result = Apartment.connection.exec_query(<<-SQL).try(:first)
            SELECT 1 AS `exists`
            FROM INFORMATION_SCHEMA.SCHEMATA
            WHERE SCHEMA_NAME = #{Apartment.connection.quote(database)}
          SQL
          result.present? && result['exists'] == 1
        end
    end
  end
end
