require_relative 'test_helper'
require 'innkeeper/resolvers/database'
require_relative 'shared/shared_adapter_tests'

class Mysql2AdapterTest < Innkeeper::Test
  include SharedAdapterTests

  def setup
    setup_connection("mysql")

    Innkeeper.configure do |config|
      config.tenant_resolver = Innkeeper::Resolvers::Database
    end

    super
  end
end
