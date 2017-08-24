require_relative 'test_helper'

class ConfigTest < Minitest::Test
  def teardown
    Apartment.reset
  end

  def test_configure_yields_apartment
    Apartment.configure{ |config| assert_equal Apartment, config }
  end

  def test_setting_excluded_models
    Apartment.configure{ |c| c.excluded_models = ["Company"] }

    assert_equal ["Company"], Apartment.excluded_models
  end

  def test_setting_force_reconnect_on_switch
    Apartment.configure{ |c| c.force_reconnect_on_switch = true }

    assert_equal true, Apartment.force_reconnect_on_switch
  end

  def test_setting_seed_data_file
    Apartment.configure{ |c| c.seed_data_file = "#{Rails.root}/db/seeds/import.rb" }

    assert_equal "#{Rails.root}/db/seeds/import.rb", Apartment.seed_data_file
  end

  def test_setting_seed_after_create
    Apartment.configure{ |c| c.seed_after_create = true }

    assert_equal true, Apartment.seed_after_create
  end

  def test_setting_tenant_names_to_array
    Apartment.configure{ |c| c.tenant_names = ['tenant_a', 'tenant_b'] }

    assert_equal ['tenant_a', 'tenant_b'], Apartment.tenant_names
  end

  def test_setting_tenant_names_to_proc
    tenant_names = ["foo", "bar"]
    tenant_names.each{ |db| Company.create!(database: db) }

    Apartment.configure{ |c| c.tenant_names = ->{ Company.pluck(:database) } }

    assert_equal tenant_names, Apartment.tenant_names
  ensure
    Company.delete_all
  end
end
