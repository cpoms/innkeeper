require_relative 'test_helper'
require 'innkeeper/resolvers/database'

class DecoratorTest < Innkeeper::Test
  def setup
    setup_connection("mysql")

    Innkeeper.configure do |config|
      config.tenant_resolver = Innkeeper::Resolvers::Database
      config.tenant_decorator = ->(tenant){ "#{Rails.env}_#{tenant}" }
    end

    super
  end

  def test_decorator_proc
    decorated = Innkeeper::Tenant.adapter.decorate("foobar")

    assert_equal "test_foobar", decorated
  end
end
