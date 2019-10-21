require 'innkeeper/resolvers/abstract'

module Innkeeper
  module Resolvers
    class Schema < Abstract
      def resolve(tenant)
        schemas = [tenant, Innkeeper.persistent_schemas].flatten
        search_path = schemas.map(&:inspect).join(", ")

        init_config.dup.tap{ |c| c[:schema_search_path] = search_path }
      end
    end
  end
end
