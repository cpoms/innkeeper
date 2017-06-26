require_relative 'test_helper'
require 'apartment/resolvers/database'
require 'apartment/resolvers/schema'

class ResolverTest < Minitest::Test
  def test_database_resolver
    resolver = Apartment::Resolvers::Database.new(Apartment.connection_config)
    new_config = resolver.resolve("foobar")

    assert_equal "foobar", new_config[:database]
  end

  def test_schema_resolver
    Apartment.configure{ |config| config.persistent_schemas = ['a', 'b', 'c'] }

    resolver = Apartment::Resolvers::Schema.new(Apartment.connection_config)
    new_config = resolver.resolve("foobar")

    assert_equal '"foobar", "a", "b", "c"', new_config[:schema_search_path]
  end
end
