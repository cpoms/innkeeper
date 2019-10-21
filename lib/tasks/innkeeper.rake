require 'innkeeper/migrator'
require 'parallel'

innkeeper_namespace = namespace :innkeeper do

  desc "Create all tenants"
  task create: 'db:migrate' do
    tenants.each do |tenant|
      begin
        quietly { Innkeeper::Tenant.create(tenant) }
      rescue Innkeeper::TenantExists => e
        puts e.message
      end
    end
  end

  desc "Migrate all tenants"
  task :migrate do
    warn_if_tenants_empty

    each_tenant do |tenant|
      begin
        Innkeeper::Migrator.migrate tenant
      rescue Innkeeper::TenantNotFound => e
        puts e.message
      end
    end
  end

  desc "Seed all tenants"
  task :seed do
    warn_if_tenants_empty

    each_tenant do |tenant|
      begin
        Innkeeper::Tenant.switch(tenant) do
          Innkeeper::Tenant.seed
        end
      rescue Innkeeper::TenantNotFound => e
        puts e.message
      end
    end
  end

  desc "Rolls the migration back to the previous version (specify steps w/ STEP=n) across all tenants."
  task :rollback do
    warn_if_tenants_empty

    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    each_tenant do |tenant|
      begin
        Innkeeper::Migrator.rollback tenant, step
      rescue Innkeeper::TenantNotFound => e
        puts e.message
      end
    end
  end

  namespace :migrate do
    desc 'Runs the "up" for a given migration VERSION across all tenants.'
    task :up do
      warn_if_tenants_empty

      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      each_tenant do |tenant|
        begin
          Innkeeper::Migrator.run :up, tenant, version
        rescue Innkeeper::TenantNotFound => e
          puts e.message
        end
      end
    end

    desc 'Runs the "down" for a given migration VERSION across all tenants.'
    task :down do
      warn_if_tenants_empty

      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      each_tenant do |tenant|
        begin
          Innkeeper::Migrator.run :down, tenant, version
        rescue Innkeeper::TenantNotFound => e
          puts e.message
        end
      end
    end

    desc  'Rolls back the tenant one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo do
      if ENV['VERSION']
        innkeeper_namespace['migrate:down'].invoke
        innkeeper_namespace['migrate:up'].invoke
      else
        innkeeper_namespace['rollback'].invoke
        innkeeper_namespace['migrate'].invoke
      end
    end
  end

  def each_tenant(&block)
    Parallel.each(tenants, in_threads: Innkeeper.parallel_migration_threads) do |tenant|
      block.call(tenant)
    end
  end

  def tenants
    ENV['DB'] ? ENV['DB'].split(',').map { |s| s.strip } : Innkeeper.tenant_names || []
  end

  def warn_if_tenants_empty
    if tenants.empty?
      puts <<-WARNING
        [WARNING] - The list of tenants to migrate appears to be empty. This could mean a few things:

          1. You may not have created any, in which case you can ignore this message
          2. You've run `innkeeper:migrate` directly without loading the Rails environment
            * `innkeeper:migrate` is now deprecated. Tenants will automatically be migrated with `db:migrate`

        Note that your tenants currently haven't been migrated. You'll need to run `db:migrate` to rectify this.
      WARNING
    end
  end
end
