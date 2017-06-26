require_relative 'test_helper'
require 'apartment/resolvers/database'

class RailtieTest < Minitest::Test
  def test_railtie_does_not_hold_onto_connection
    Apartment.tenant_resolver = Apartment::Resolvers::Database
    Apartment.connection_class.connection_pool.disconnect!

    Apartment::Railtie.config.to_prepare_blocks.map(&:call)

    num_available_connections = Apartment.connection_class.connection_pool
      .instance_variable_get(:@available)
      .instance_variable_get(:@queue)
      .size

    assert_equal 1, num_available_connections
  end
end
