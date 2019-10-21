require 'innkeeper/resolvers/abstract'

module Innkeeper
  module Resolvers
    class Database < Abstract
      def resolve(tenant)
        init_config.dup.tap{ |c| c[:database] = tenant }
      end
    end
  end
end
