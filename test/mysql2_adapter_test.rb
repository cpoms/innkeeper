require_relative 'test_helper'
require 'apartment/resolvers/database'
require_relative 'shared/shared_adapter_tests'

class Mysql2AdapterTest < Apartment::Test
  include SharedAdapterTests

  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      config.tenant_resolver = Apartment::Resolvers::Database
    end

    super
  end
end
