require_relative 'test_helper'

class ConfigTest < Minitest::Test
  def teardown
    Innkeeper.reset
  end

  def test_configure_yields_innkeeper
    Innkeeper.configure{ |config| assert_equal Innkeeper, config }
  end

  def test_setting_excluded_models
    Innkeeper.configure{ |c| c.excluded_models = ["Company"] }

    assert_equal ["Company"], Innkeeper.excluded_models
  end

  def test_setting_force_reconnect_on_switch
    Innkeeper.configure{ |c| c.force_reconnect_on_switch = true }

    assert_equal true, Innkeeper.force_reconnect_on_switch
  end

  def test_setting_seed_data_file
    Innkeeper.configure{ |c| c.seed_data_file = "#{Rails.root}/db/seeds/import.rb" }

    assert_equal "#{Rails.root}/db/seeds/import.rb", Innkeeper.seed_data_file
  end

  def test_setting_seed_after_create
    Innkeeper.configure{ |c| c.seed_after_create = true }

    assert_equal true, Innkeeper.seed_after_create
  end

  def test_setting_tenant_names_to_array
    Innkeeper.configure{ |c| c.tenant_names = ['tenant_a', 'tenant_b'] }

    assert_equal ['tenant_a', 'tenant_b'], Innkeeper.tenant_names
  end

  def test_setting_tenant_names_to_proc
    tenant_names = ["foo", "bar"]
    tenant_names.each{ |db| Company.create!(database: db) }

    Innkeeper.configure{ |c| c.tenant_names = ->{ Company.pluck(:database) } }

    assert_equal tenant_names, Innkeeper.tenant_names
  ensure
    Company.delete_all
  end
end
