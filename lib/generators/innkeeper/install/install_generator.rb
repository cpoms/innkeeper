module Innkeeper
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      template "innkeeper.rb", File.join("config", "initializers", "innkeeper.rb")
    end

  end
end
