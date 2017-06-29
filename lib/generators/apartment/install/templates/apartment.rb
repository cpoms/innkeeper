# You can have Apartment route to the appropriate Tenant by adding some Rack middleware.
# Apartment can support many different "Elevators" that can take care of this routing to your data.
# Require whichever Elevator you're using below or none if you have a custom one.
#
# require 'apartment/elevators/generic'
# require 'apartment/elevators/domain'
require 'apartment/elevators/subdomain'
# require 'apartment/resolvers/schema'

#
# Apartment Configuration
#
Apartment.configure do |config|
  # Add any models that you do not want to be multi-tenanted, but remain in the global (public) namespace.
  # A typical example would be a Customer or Tenant model that stores each Tenant's information.
  #
  # config.excluded_models = %w{ Tenant }

  # In order to migrate all of your Tenants you need to provide a list of Tenant names to Apartment.
  # You can make this dynamic by providing a Proc object to be called on migrations.
  # This object should yield either:
  # - an array of strings representing each Tenant name.
  # - a hash which keys are tenant names, and values custom db config (must contain all key/values required in database.yml)
  #
  # config.tenant_names = lambda{ Customer.pluck(:tenant_name) }
  # config.tenant_names = ['tenant1', 'tenant2']
  # config.tenant_names = [
  #   {
  #     adapter: 'postgresql',
  #     host: 'some_server',
  #     port: 5555,
  #     database: 'postgres' # this is not the name of the tenant's db
  #                          # but the name of the database to connect to before creating the tenant's db
  #                          # mandatory in postgresql
  #     schema_search_path: '"tenant1"'
  #   },
  #   'tenant2' => {
  #     adapter:  'postgresql',
  #     database: 'postgres' # this is not the name of the tenant's db
  #                          # but the name of the database to connect to before creating the tenant's db
  #                          # mandatory in postgresql
  #     
  #   }
  # }
  #
  config.tenant_names = lambda { ToDo_Tenant_Or_User_Model.pluck :database }

  # The tenant decorator setting should be a callable which receives the tenant
  # as an argument, and returns the a modified version of the tenant name which
  # you want to use in the resolver as a database or schema name, for example.
  #
  # A typical use-case might be prepending or appending the rails environment,
  # as shown below.
  #
  # config.tenant_decorator = ->(tenant){ "#{Rails.env}_#{tenant}" }

  # The resolver is used to convert a tenant name into a full spec. The two
  # provided resolvers are Database and Schema. When you issue
  # Apartment.switch("some_tenant"){ ... }, Apartment passes "some_tenant" to
  # the selected resolver (after it's been decorated). The Database resolver
  # takes the decorated tenant name, and inserts it into the :database key of a
  # full connection specification (the full spec is whatever the database spec
  # was at Apartment initialization. The schema resolver, does the same but
  # for the :schema_search_path option in the configuration.
  #
  # config.tenant_resolver = Apartment::Resolvers::Schema
end

# Setup a custom Tenant switching middleware. The Proc should return the name of the Tenant that
# you want to switch to.
# Rails.application.config.middleware.use 'Apartment::Elevators::Generic', lambda { |request|
#   request.host.split('.').first
# }

# Rails.application.config.middleware.use 'Apartment::Elevators::Domain'
Rails.application.config.middleware.use 'Apartment::Elevators::Subdomain'
