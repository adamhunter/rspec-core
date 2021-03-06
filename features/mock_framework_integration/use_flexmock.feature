Feature: mock with flexmock

  As an RSpec user who likes to mock
  I want to be able to use flexmock

  Scenario: Mock with flexmock
    Given a file named "flexmock_example_spec.rb" with:
      """
      Rspec.configure do |config|
        config.mock_framework = :flexmock
      end

      describe "plugging in flexmock" do
        it "allows flexmock to be used" do
          target = Object.new
          flexmock(target).should_receive(:foo).once
          target.foo
        end
      end
      """
    When I run "spec flexmock_example_spec.rb"
    Then the stdout should match "1 example, 0 failures" 
    And the exit code should be 0
