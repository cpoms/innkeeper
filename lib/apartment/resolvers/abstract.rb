module Apartment
  module Resolvers
    class Abstract
      attr_accessor :init_config

      def initialize(init_config)
        @init_config = init_config.freeze
      end

      def resolve
        raise "Cannot use abstract class directly"
      end
    end
  end
end
