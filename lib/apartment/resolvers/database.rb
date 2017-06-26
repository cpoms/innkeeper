require 'apartment/resolvers/abstract'

module Apartment
  module Resolvers
    class Database < Abstract
      def resolve(tenant)
        init_config.dup.tap{ |c| c[:database] = tenant }
      end
    end
  end
end
