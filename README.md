# Apartment

[![Code Climate](https://codeclimate.com/github/influitive/apartment.png)](https://codeclimate.com/github/influitive/apartment)
[![Build Status](https://secure.travis-ci.org/influitive/apartment.png?branch=development)](http://travis-ci.org/influitive/apartment)

*Multitenancy for Rails and ActiveRecord*

Apartment provides tools to help you deal with multiple tenants in your Rails
application. If you need to have certain data sequestered based on account or
company, but still allow some data to exist in a common tenant, Apartment can
help.

## Installation

### Rails

Add the following to your Gemfile:

```ruby
gem 'apartment'
```

Then generate your `Apartment` config file using

```ruby
bundle exec rails generate apartment:install
```

This will create a `config/initializers/apartment.rb` initializer file.
Configure as needed using the docs below.

That's all you need to set up the Apartment libraries. If you want to switch
tenants on a per-user basis, look under "Usage - Switching tenants per request",
below.

## Usage

### Creating new Tenants

Before you can switch to a new apartment tenant, you will need to create it.
Whenever you need to create a new tenant, you can run the following command:

```ruby
Apartment::Tenant.create('tenant_name')
```

If you're using PostgreSQL, this will create the database and schema from the
derived tenant configuration. For example, if you're using the Schema resolver,
this will create a schema named 'tenant_name', assuming you're not using a
decorator. If you're customising the tenant name with a decorator, it is the
decorated name that will be used.

When you create a new tenant, the schema is loaded on to that tenant, so it will
be up to date when create returns.

### Switching Tenants

To switch tenants using Apartment, use the following command:

```ruby
Apartment::Tenant.switch!('tenant_name')
```

When switch is called, all requests coming to ActiveRecord will be routed to the
tenant you specify (with the exception of excluded models, see below). To return
to the 'root' tenant, call switch with no arguments.

### Switching Tenants per request

You can have Apartment route to the appropriate tenant by adding some Rack
middleware. Apartment can support many different "Elevators" that can take care
of this routing to your data.

**NOTE: when switching tenants per-request, keep in mind that the order of your
Rack middleware is important.** See the
[Middleware Considerations](#middleware-considerations) section for more.

The initializer above will generate the appropriate code for the Subdomain
elevator by default. You can see this in `config/initializers/apartment.rb`
after running that generator. If you're *not* using the generator, you can
specify your elevator below. Note that in this case you will **need** to require
the elevator manually in your `application.rb` like so:

```ruby
# config/application.rb
require 'apartment/elevators/subdomain' # or 'domain' or 'generic'
```

#### Switch on subdomain

In house, we use the subdomain elevator, which analyzes the subdomain of the
request and switches to a tenant schema of the same name. It can be used like
so:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Apartment::Elevators::Subdomain'
  end
end
```

If you want to exclude a domain, for example if you don't want your application
to treat www like a subdomain, in an initializer in your application, you can
set the following:

```ruby
# config/initializers/apartment/subdomain_exclusions.rb
Apartment::Elevators::Subdomain.excluded_subdomains = ['www']
```

This functions much in the same way as Apartment.excluded_models. This example
will prevent switching your tenant when the subdomain is www. Handy for
subdomains like: "public", "www", and "admin" :)

#### Switch on domain

To switch based on full domain (excluding subdomains *ie 'www'* and top level
domains *ie '.com'* ) use the following:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Apartment::Elevators::Domain'
  end
end
```

#### Switch on full host using a hash

To switch based on full host with a hash to find corresponding tenant name use
the following:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Apartment::Elevators::HostHash', {'example.com' => 'example_tenant'}
  end
end
```

#### Custom Elevator

A Generic Elevator exists that allows you to pass a `Proc` (or anything that
responds to `call`) to the middleware. This Object will be passed in an
`ActionDispatch::Request` object when called for you to do your magic. Apartment
will use the return value of this proc to switch to the appropriate tenant. Use
like so:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    # Obviously not a contrived example
    config.middleware.use 'Apartment::Elevators::Generic', Proc.new { |request| request.host.reverse }
  end
end
```

Your other option is to subclass the Generic elevator and implement your own
switching mechanism. This is exactly how the other elevators work. Look at the
`subdomain.rb` elevator to get an idea of how this should work. Basically all
you need to do is subclass the generic elevator and implement your own
`parse_tenant_name` method that will ultimately return the name of the tenant
based on the request being made. It *could* look something like this:

```ruby
# app/middleware/my_custom_elevator.rb
class MyCustomElevator < Apartment::Elevators::Generic

  # @return {String} - The tenant to switch to
  def parse_tenant_name(request)
    # request is an instance of Rack::Request

    # example: look up some tenant from the db based on this request
    tenant_name = SomeModel.from_request(request)

    return tenant_name
  end
end
```

#### Middleware Considerations

In the examples above, we show the Apartment middleware being appended to the
Rack stack with

```ruby
Rails.application.config.middleware.use 'Apartment::Elevators::Subdomain'
```

By default, the Subdomain middleware switches into a Tenant based on the
subdomain at the beginning of the request, and when the request is finished, it
switches back to the "public" Tenant. This happens in the
[Generic](https://github.com/influitive/apartment/blob/development/lib/apartment/elevators/generic.rb#L22)
elevator, so all elevators that inherit from this elevator will operate as such.

It's also good to note that Apartment switches back to the "public" tenant any
time an error is raised in your application.

This works okay for simple applications, but it's important to consider that you
may want to maintain the "selected" tenant through different parts of the Rack
application stack. For example, the
[Devise](https://github.com/plataformatec/devise) gem adds the `Warden::Manager`
middleware at the end of the stack in the examples above, our
`Apartment::Elevators::Subdomain` middleware would come after it. Trouble is,
Apartment resets the selected tenant after the request is finish, so some 
edirects (e.g. authentication) in Devise will be run in the context of the
"public" tenant. The same issue would also effect a gem such as the
[better_errors](https://github.com/charliesome/better_errors) gem which inserts
a middleware quite early in the Rails middleware stack.

To resolve this issue, consider adding the Apartment middleware at a location
in the Rack stack that makes sense for your needs, e.g.:

```ruby
Rails.application.config.middleware.insert_before 'Warden::Manager', 'Apartment::Elevators::Subdomain'
```

Now work done in the Warden middleware is wrapped in the
`Apartment::Tenant.switch` context started in the Generic elevator.

### Dropping Tenants

To drop tenants using Apartment, use the following command:

```ruby
Apartment::Tenant.drop('tenant_name')
```

When method is called, the schema is dropped and all data from itself will be
lost. Be careful with this method.

## Config

The following config options should be set up in a Rails initializer such as:

    config/initializers/apartment.rb

To set config options, add this to your initializer:

```ruby
Apartment.configure do |config|
  # set your options (described below) here
end
```

### Excluding models

If you have some models that should always access the 'public' tenant, you can
specify this by configuring Apartment using `Apartment.configure`. This will
yield a config object for you. You can set excluded models like so:

```ruby
config.excluded_models = ["User", "Company"] # these models will not be multi-tenanted, but remain in the global (public) namespace
```

Note that a string representation of the model name is now the standard so that
models are properly constantized when reloaded in development.

Rails will always access the 'public' tenant when accessing these models, but
note that tables will be created in all schemas. This may not be ideal, but its
done this way because otherwise rails wouldn't be able to properly generate the
schema.rb file.

> **NOTE - Many-To-Many Excluded Models:**
> Since model exclusions must come from referencing a real ActiveRecord model,
`has_and_belongs_to_many` is NOT supported. In order to achieve a many-to-many
relationship for excluded models, you MUST use `has_many :through`. This way you
can reference the join model in the excluded models configuration.

### Postgresql Schemas

## Providing a Different default_schema

By default, ActiveRecord will use `"$user", public` as the default
`schema_search_path`. This can be modified if you wish to use a different
default schema be setting:

```ruby
config.default_schema = "some_other_schema"
```

With that set, all excluded models will use this schema as the table name prefix
instead of `public` and `reset` on `Apartment::Tenant` will return to this
schema as well.

## Persistent Schemas

Apartment will normally just switch the `schema_search_path` whole hog to the
one passed in. This can lead to problems if you want other schemas to always be
searched as well. Enter `persistent_schemas`. You can configure a list of other
schemas that will always remain in the search path, while the default gets
swapped out:

```ruby
config.persistent_schemas = ['some', 'other', 'schemas']
```

### Installing Extensions into Persistent Schemas

Persistent Schemas have numerous useful applications.
[Hstore](http://www.postgresql.org/docs/9.1/static/hstore.html), for instance,
is a popular storage engine for Postgresql. In order to use extensions such as
Hstore, you have to install it to a specific schema and have that always in the
`schema_search_path`.

When using extensions, keep in mind:

* Extensions can only be installed into one schema per database, so we will want
  to install it into a schema that is always available in the
  `schema_search_path`
* The schema and extension need to be created in the database *before* they are
  referenced in migrations, database.yml or apartment.
* There does not seem to be a way to create the schema and extension using
  standard rails migrations.
* Rails db:test:prepare deletes and recreates the database, so it needs to be
  easy for the extension schema to be recreated here.

#### 1. Ensure the extensions schema is created when the database is created

```ruby
# lib/tasks/db_enhancements.rake

####### Important information ####################
# This file is used to setup a shared extensions #
# within a dedicated schema. This gives us the   #
# advantage of only needing to enable extensions #
# in one place.                                  #
#                                                #
# This task should be run AFTER db:create but    #
# BEFORE db:migrate.                             #
##################################################

namespace :db do
  desc 'Also create shared_extensions Schema'
  task :extensions => :environment  do
    # Create Schema
    ActiveRecord::Base.connection.execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions;'
    # Enable Hstore
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS HSTORE SCHEMA shared_extensions;'
    # Enable UUID-OSSP
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA shared_extensions;'
  end
end

Rake::Task["db:create"].enhance do
  Rake::Task["db:extensions"].invoke
end

Rake::Task["db:test:purge"].enhance do
  Rake::Task["db:extensions"].invoke
end
```

#### 2. Ensure the schema is in Rails' default connection

Next, your `database.yml` file must mimic what you've set for your default and
persistent schemas in Apartment. When you run migrations with Rails, it won't
know about the extensions schema because Apartment isn't injected into the
default connection, it's done on a per-request basis, therefore Rails doesn't
know about `hstore` or `uuid-ossp` during migrations.  To do so, add the
following to your `database.yml` for all environments

```yaml
# database.yml
...
adapter: postgresql
schema_search_path: "public,shared_extensions"
...
```

This would be for a config with `default_schema` set to `public` and
`persistent_schemas` set to `['shared_extensions']`.

#### 3. Ensure the schema is in the apartment config

```ruby
# config/initializers/apartment.rb
...
config.persistent_schemas = ['shared_extensions']
...
```

#### Alternative: Creating schema by default

Another way that we've successfully configured hstore for our applications is to
add it into the postgresql template1 database so that every tenant that gets
created has it by default.

One caveat with this approach is that it can interfere with other projects in
development using the same extensions and template, but not using apartment with
this approach.

You can do so using a command like so:

```bash
psql -U postgres -d template1 -c "CREATE SCHEMA shared_extensions AUTHORIZATION some_username;"
psql -U postgres -d template1 -c "CREATE EXTENSION IF NOT EXISTS hstore SCHEMA shared_extensions;"
```

The *ideal* setup would actually be to install `hstore` into the `public` schema
and leave the public schema in the `search_path` at all times. We won't be able
to do this though until public doesn't also contain the tenanted tables, which
is an open issue with no real milestone to be completed. Happy to accept PR's on
the matter.

### Managing Migrations

In order to migrate all of your tenants (or postgresql schemas) you need to
provide a list of dbs to Apartment. You can make this dynamic by providing a
Proc object to be called on migrations. This object should yield an array of
string representing each tenant name. Example:

```ruby
# Dynamically get tenant names to migrate
config.tenant_names = lambda{ Customer.pluck(:tenant_name) }

# Use a static list of tenant names for migrate
config.tenant_names = ['tenant1', 'tenant2']
```

You can then migrate your tenants using the normal rake task:

```ruby
rake db:migrate
```

This just invokes `Apartment::Tenant.migrate(#{tenant_name})` for each tenant
name supplied from `Apartment.tenant_names`.

#### Parallel Migrations

Apartment supports parallelizing migrations into multiple threads when
you have a large number of tenants. By default, parallel migrations is
turned off. You can enable this by setting `parallel_migration_threads` to 
the number of threads you want to use in your initializer.

Keep in mind that because migrations are going to access the database,
the number of threads indicated here should be less than the pool size
that Rails will use to connect to your database.

## Tenants on different servers

Apartment supports tenant-based sharding at the application level. The `switch`,
`create`, and `drop` methods all support full database configurations (as a
hash) as well as tenant names. In fact, even when you pass a tenant name, it
gets resolved to a full configuration using the configured `tenant_resolver`. If
you wish to switch to a tenant on a different host, you can pass the full config
with the host key.

Apartment will compare the config to it's current one and work out whether it
needs to switch host, database, schema, etc, and only do the minimal switch. For
tenants (databases for mysql, schemas for pg) on the same host, the switch will
be a lightweight 'local' switch, which is one that occurs as a SQL query only,
rather than a re-establishment of the database connection.

You could make use of a custom resolver to do multi-host tenant switching by
name. You could map tenant names to a host (shard) IP via the hash of the host
name, or something similar, and divide the hash space across available hosts.

## Sidekiq

See [apartment-sidekiq](https://github.com/influitive/apartment-sidekiq)

## Contributing

* In `test/`, you will see `databases.yml.sample` files
  * Copy them into the same directory but with the name `databases.yml`
  * Edit them to fit your own settings
* Rake tasks (see the Rakefile) will help you setup your dbs necessary to run
  tests
* Please issue pull requests to the `development` branch. All development
  happens here, master is used for releases.
* Ensure that your code is accompanied with tests. No code will be merged
  without tests

## License

Apartment is released under the [MIT License](http://www.opensource.org/licenses/MIT).

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/influitive/apartment/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
