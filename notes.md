# Notes

- API:

    Apartment::Tenant.switch("blah") do ...
      -> - pass "blah" into `config_for`
         - `config_for` uses the configured resolver to return a config hash
            (either database or schema by default)
         - connect_to_new determines what's different in the config with the
           current
         - if a 'local' switch is possible (e.g. host is unchanged), do that,
           otherwise reconnect
    Apartment::Tenant.switch({ host: etc }) do ...
      -> - pass straight through to connection_handler


    Apartment.configure do |config|
      config.tenants = proc{ Customer.map(&:subdomain) }
      config.tenant_decorator = ->(tenant){ "#{Rails.env}_#{tenant}" }
      config.tenant_resolver = Resolvers::Database
    end

## Todo

- rewrite generator
- finish config tests (tenant resolver specifically)
- write multi-threading tests
- remove deprecated silencers?
- rewrite readme
