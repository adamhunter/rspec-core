require 'spec_helper'

class Bar; end
class Foo; end

module Rspec::Core

  describe World do
    
    before do
      @world = Rspec::Core::World.new
      Rspec::Core.stub(:world).and_return(@world)
    end

    describe "example_groups" do
    
      it "should contain all defined example groups" do
        group = Rspec::Core::ExampleGroup.describe("group") {}
        @world.example_groups.should include(group)
      end
    
    end
    
    describe "applying inclusion filters" do
    
      before(:all) do
        options_1 = { :foo => 1, :color => 'blue', :feature => 'reporting' }
        options_2 = { :pending => true, :feature => 'reporting'  }
        options_3 = { :array => [1,2,3,4], :color => 'blue' }      
        @bg1 = Rspec::Core::ExampleGroup.describe(Bar, "find group-1", options_1) { }
        @bg2 = Rspec::Core::ExampleGroup.describe(Bar, "find group-2", options_2) { }
        @bg3 = Rspec::Core::ExampleGroup.describe(Bar, "find group-3", options_3) { }
        @bg4 = Rspec::Core::ExampleGroup.describe(Foo, "find these examples") do
          it('I have no options') {}
          it("this is awesome", :awesome => true) {}
          it("this is too", :awesome => true) {}
          it("not so awesome", :awesome => false) {}
          it("I also have no options") {}
        end
        @example_groups = [@bg1, @bg2, @bg3, @bg4]
      end
      
      it "finds no groups when given no search parameters" do
        @world.apply_inclusion_filters([]).should == []
      end
    
      it "finds matching groups when filtering on :describes (described class or module)" do
        @world.apply_inclusion_filters(@example_groups, :example_group => { :describes => Bar }).should == [@bg1, @bg2, @bg3]
      end
      
      it "finds matching groups when filtering on :description with text" do
        @world.apply_inclusion_filters(@example_groups, :example_group => { :description => 'find group-1' }).should == [@bg1]
      end
      
      it "finds matching groups when filtering on :description with a lambda" do
        @world.apply_inclusion_filters(@example_groups, :example_group => { :description => lambda { |v| v.include?('-1') || v.include?('-3') } }).should == [@bg1, @bg3]
      end
      
      it "finds matching groups when filtering on :description with a regular expression" do
        @world.apply_inclusion_filters(@example_groups, :example_group => { :description => /find group/ }).should == [@bg1, @bg2, @bg3]
      end
      
      it "finds one group when searching for :pending => true" do
        @world.apply_inclusion_filters(@example_groups, :pending => true ).should == [@bg2]
      end
    
      it "finds matching groups when filtering on arbitrary metadata with a number" do
        @world.apply_inclusion_filters(@example_groups, :foo => 1 ).should == [@bg1]
      end
      
      it "finds matching groups when filtering on arbitrary metadata with an array" do
        @world.apply_inclusion_filters(@example_groups, :array => [1,2,3,4]).should == [@bg3]
      end
    
      it "finds no groups when filtering on arbitrary metadata with an array but the arrays do not match" do
        @world.apply_inclusion_filters(@example_groups, :array => [4,3,2,1]).should be_empty
      end    
    
      it "finds matching examples when filtering on arbitrary metadata" do
        @world.apply_inclusion_filters(@bg4.examples, :awesome => true).should == [@bg4.examples[1], @bg4.examples[2]]
      end
      
    end
    
    describe "applying exclusion filters" do
      
      it "should find nothing if all describes match the exclusion filter" do
        options = { :network_access => true }      
        
        group1 = ExampleGroup.create(Bar, "find group-1", options) do
          it("foo") {}
          it("bar") {}
        end
        
        @world.apply_exclusion_filters(group1.examples, :network_access => true).should == []
        
        group2 = ExampleGroup.create(Bar, "find group-1") do
          it("foo", :network_access => true) {}
          it("bar") {}
        end
        
        @world.apply_exclusion_filters(group2.examples, :network_access => true).should == [group2.examples.last]
    
      end
      
      it "should find nothing if a regexp matches the exclusion filter" do
        group = ExampleGroup.create(Bar, "find group-1", :name => "exclude me with a regex", :another => "foo") do
          it("foo") {}
          it("bar") {}
        end
        @world.apply_exclusion_filters(group.examples, :name => /exclude/).should == []
        @world.apply_exclusion_filters(group.examples, :name => /exclude/, :another => "foo").should == []
        @world.apply_exclusion_filters(group.examples, :name => /exclude/, :another => "foo", :example_group => {
          :describes => lambda { |b| b == Bar } } ).should == []
        
        @world.apply_exclusion_filters(group.examples, :name => /exclude not/).should == group.examples
        @world.apply_exclusion_filters(group.examples, :name => /exclude/, "another_condition" => "foo").should == group.examples
        @world.apply_exclusion_filters(group.examples, :name => /exclude/, "another_condition" => "foo1").should == group.examples
      end
      
    end
    
    describe "filtering example groups" do
      
      it "should run matches" do
        @group1 = ExampleGroup.create(Bar, "find these examples") do
          it('I have no options',       :color => :red, :awesome => true) {}
          it("I also have no options",  :color => :red, :awesome => true) {}
          it("not so awesome",          :color => :red, :awesome => false) {}
        end
        Rspec::Core.world.stub(:exclusion_filter).and_return({ :awesome => false })
        Rspec::Core.world.stub(:filter).and_return({ :color => :red })
        Rspec::Core.world.stub(:example_groups).and_return([@group1])
        filtered_example_groups = @world.filter_example_groups
        filtered_example_groups.should == [@group1]
        @group1.examples_to_run.should == @group1.examples[0..1]      
      end
      
    end

  end

end
