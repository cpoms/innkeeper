require_relative 'test_helper'
require_relative 'mocks/adapter_mock'
require 'innkeeper/elevators/host_hash'

class HostHashElevatorTest < Minitest::Test
  include AdapterMock

  def setup
    @elevator = Innkeeper::Elevators::HostHash.new(Proc.new{}, 'example.com' => 'example_tenant')

    super
  end

  def test_parses_host_from_domain_name
    request = ActionDispatch::Request.new('HTTP_HOST' => 'example.com')
    assert_equal 'example_tenant', @elevator.parse_tenant_name(request)
  end

  def test_raises_exception_if_no_host
    request = ActionDispatch::Request.new('HTTP_HOST' => '')
    assert_raises Innkeeper::TenantNotFound do
      @elevator.parse_tenant_name(request)
    end
  end

  def test_raises_exception_if_host_not_found
    request = ActionDispatch::Request.new('HTTP_HOST' => 'example2.com')
    assert_raises Innkeeper::TenantNotFound do
      @elevator.parse_tenant_name(request)
    end
  end

  def test_switches_to_proper_tenant
    with_adapter_mocked do |adapter|
      adapter.expect :switch, true, ['example_tenant']

      @elevator.call('HTTP_HOST' => 'example.com')

      assert adapter.verify
    end
  end
end
