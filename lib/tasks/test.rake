# Override test:prepare to skip CSS build
Rake::Task["test:prepare"].enhance do
  # This runs after test:prepare
end

# Remove CSS build from test dependencies if it exists
if Rake::Task.task_defined?("css:build")
  Rake::Task["test:prepare"].prerequisites.delete("css:build")
  Rake::Task["test"].prerequisites.delete("css:build")

  # Override css:build to be a no-op in test
  Rake::Task["css:build"].clear

  namespace :css do
    task :build do
      if Rails.env.test?
        puts "Skipping CSS build in test environment (assets should be precompiled)"
      else
        # Run the actual build in non-test environments
        sh "yarn build:css"
      end
    end
  end
end
