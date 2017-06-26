require_relative 'test_helper'
require_relative 'mocks/adapter_mock'
require 'apartment/elevators/generic'

class GenericElevatorTest < Minitest::Test
  include AdapterMock

  class MyElevator < Apartment::Elevators::Generic
    def parse_tenant_name(*)
      'tenant2'
    end
  end

  def setup
    @elevator = Apartment::Elevators::Generic.new(Proc.new{})

    super
  end

  def test_processor_is_called_if_given
    elevator = Apartment::Elevators::Generic.new(Proc.new{}, Proc.new{'tenant1'})

    with_adapter_mocked do |adapter|
      adapter.expect :switch, true, ['tenant1']

      elevator.call('HTTP_HOST' => 'foo.bar.com')

      assert adapter.verify
    end
  end

  def test_raises_if_parse_tenant_name_not_implemented
    assert_raises RuntimeError do
      @elevator.call('HTTP_HOST' => 'foo.bar.com')
    end
  end

  def test_switches_to_the_parsed_db_name
    elevator = MyElevator.new(Proc.new{})

    with_adapter_mocked do |adapter|
      adapter.expect :switch, true, ['tenant2']

      elevator.call('HTTP_HOST' => 'foo.bar.com')

      assert adapter.verify
    end
  end

  def test_does_not_call_switch_if_no_database_given
    app_mock = Minitest::Mock.new
    app_mock.expect :call, true, [{'HTTP_HOST' => 'foo.bar.com'}]
    elevator = MyElevator.new(app_mock, Proc.new{})

    with_adapter_mocked do |adapter|
      elevator.call('HTTP_HOST' => 'foo.bar.com')

      assert adapter.verify
    end

    assert app_mock.verify
  end
end