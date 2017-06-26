require_relative 'test_helper'
require_relative 'mocks/adapter_mock'
require 'apartment/elevators/domain'

class DomainElevatorTest < Minitest::Test
  include AdapterMock

  def setup
    @elevator = Apartment::Elevators::Domain.new(Proc.new{})

    super
  end

  def test_parsing_host_for_domain_name
    request = ActionDispatch::Request.new('HTTP_HOST' => 'example.com')
    assert_equal 'example', @elevator.parse_tenant_name(request)
  end

  def test_www_prefix_and_domain_suffix_ignored
    request = ActionDispatch::Request.new('HTTP_HOST' => 'www.example.bc.ca')
    assert_equal 'example', @elevator.parse_tenant_name(request)
  end

  def test_no_host_returns_nil
    request = ActionDispatch::Request.new('HTTP_HOST' => '')
    assert_nil @elevator.parse_tenant_name(request)
  end

  def test_call_switches_tenant
    with_adapter_mocked do |adapter|
      adapter.expect :switch, true, ['example']

      @elevator.call('HTTP_HOST' => 'www.example.com')

      assert adapter.verify
    end
  end
end
