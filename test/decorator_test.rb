require_relative 'test_helper'
require 'apartment/resolvers/database'

class DecoratorTest < Apartment::Test
  def setup
    setup_connection("mysql")

    Apartment.configure do |config|
      config.tenant_resolver = Apartment::Resolvers::Database
      config.tenant_decorator = ->(tenant){ "#{Rails.env}_#{tenant}" }
    end

    super
  end

  def test_decorator_proc
    decorated = Apartment::Tenant.adapter.decorate("foobar")

    assert_equal "test_foobar", decorated
  end
end
