require_relative 'test_helper'
require 'innkeeper/resolvers/database'
require 'innkeeper/resolvers/schema'

class ResolverTest < Minitest::Test
  def test_database_resolver
    resolver = Innkeeper::Resolvers::Database.new(Innkeeper.connection_config)
    new_config = resolver.resolve("foobar")

    assert_equal "foobar", new_config[:database]
  end

  def test_schema_resolver
    Innkeeper.configure{ |config| config.persistent_schemas = ['a', 'b', 'c'] }

    resolver = Innkeeper::Resolvers::Schema.new(Innkeeper.connection_config)
    new_config = resolver.resolve("foobar")

    assert_equal '"foobar", "a", "b", "c"', new_config[:schema_search_path]
  end
end
