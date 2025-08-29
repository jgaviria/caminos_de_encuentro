# Disable automatic CSS builds in test environment
# This significantly speeds up test runs by preventing redundant CSS compilation
if Rails.env.test?
  # Monkey patch to skip the build step
  if defined?(Cssbundling::Rails)
    module Cssbundling
      module Rails
        class Engine < ::Rails::Engine
          # Override the test task enhancer to skip CSS builds
          initializer "cssbundling.skip_build_in_test" do |app|
            if Rails.env.test?
              # Remove the enhance block that adds css:build to test task
              Rake::Task["test:prepare"].prerequisites.delete("css:build") rescue nil
              Rake::Task["test"].prerequisites.delete("css:build") rescue nil
              Rake::Task["spec"].prerequisites.delete("css:build") rescue nil
            end
          end
        end
      end
    end
  end
end