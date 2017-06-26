require 'apartment/resolvers/abstract'

module Apartment
  module Resolvers
    class Schema < Abstract
      def resolve(tenant)
        schemas = [tenant, Apartment.persistent_schemas].flatten
        search_path = schemas.map(&:inspect).join(", ")

        init_config.dup.tap{ |c| c[:schema_search_path] = search_path }
      end
    end
  end
end