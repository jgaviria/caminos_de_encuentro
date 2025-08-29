# Override the css:build task to skip in test environment
if Rails.env.test?
  namespace :css do
    task :build do
      # Skip CSS build in test environment
      puts "Skipping CSS build in test environment"
    end
  end
end
