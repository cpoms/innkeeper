require_relative 'test_helper'
require_relative 'mocks/adapter_mock'
require 'apartment/elevators/host_hash'

class SubdomainElevatorTest < Minitest::Test
  include AdapterMock

  def setup
    @elevator = Apartment::Elevators::Subdomain.new(Proc.new{})

    super
  end

  def test_parses_subdomain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.bar.com')
    assert_equal 'foo', @elevator.parse_tenant_name(request)
  end

  def test_returns_nil_when_no_subdomain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'bar.com')
    assert_nil @elevator.parse_tenant_name(request)
  end

  def test_parses_subdomain_in_three_level_domain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.bar.co.uk')
    assert_equal "foo", @elevator.parse_tenant_name(request)
  end

  def test_returns_nil_when_no_subdomain_in_three_level_domain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'bar.co.uk')
    assert_nil @elevator.parse_tenant_name(request)
  end

  def test_parses_two_subdomains_in_two_level_domain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.xyz.bar.com')
    assert_equal "foo", @elevator.parse_tenant_name(request)
  end

  def test_parses_two_subdomains_in_three_level_domain
    request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.xyz.bar.co.uk')
    assert_equal "foo", @elevator.parse_tenant_name(request)
  end

  def test_returns_nil_for_localhost
    request = ActionDispatch::Request.new('HTTP_HOST' => 'localhost')
    assert_nil @elevator.parse_tenant_name(request)
  end

  def test_returns_nil_for_an_ip
    request = ActionDispatch::Request.new('HTTP_HOST' => '127.0.0.1')
    assert_nil @elevator.parse_tenant_name(request)
  end

  def test_switches_to_tenant
    with_adapter_mocked do |adapter|
      adapter.expect :switch, true, ['tenant1']

      @elevator.call('HTTP_HOST' => 'tenant1.example.com')

      assert adapter.verify
    end
  end

  def test_excluded_subdomain_ignored
    Apartment::Elevators::Subdomain.excluded_subdomains = %w{foo}

    with_adapter_mocked do |adapter|
      @elevator.call('HTTP_HOST' => 'foo.bar.com')

      assert adapter.verify
    end
  ensure
    Apartment::Elevators::Subdomain.excluded_subdomains = nil
  end
end
