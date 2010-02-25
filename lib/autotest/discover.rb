Autotest.add_discovery do
  "rspec2" if File.directory?('spec') && ENV['AUTORSPEC']
end
