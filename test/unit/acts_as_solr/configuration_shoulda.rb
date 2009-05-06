require "#{File.join(File.dirname(__FILE__), "..", "test_helper")}"
require 'acts_as_solr/configuration'

class ConfigurationTest < Test::Unit::TestCase
  context "a fresh clazz" do
    setup do
      @klazz = Test::User
    end
    
    context "with a simple configuration" do
      setup do
        @config = ActsAsSolr::Configuration.new(@klazz, :fields => [:birthdate])
      end
      
      should "store the specified configuration" do
        assert_equal [:birthdate], @config.configuration[:fields]
      end
      
      should "store the class" do
        assert_equal Test::User, @config.klazz
      end

      should "set after_destroy and after_save callbacks" do
        assert @klazz.callbacks[:solr_save]
        assert @klazz.callbacks[:solr_destroy]
      end

    end
    
    context "with no configuration" do
      setup do
        @config = ActsAsSolr::Configuration.new(@klazz)
      end
      
      should "store default values" do
        defaults = { 
          :fields => nil,
          :additional_fields => nil,
          :exclude_fields => [],
          :auto_commit => true,
          :include => nil,
          :facets => nil,
          :boost => nil,
          :if => "true",
          :offline => false,
          :type_field => "type_s",
          :primary_key_field => "pk_i",
          :default_boost => 1.0,
          :solr_fields => {:birthdate=>{:type=>:date}},
          :solr_includes => {}
        }
        assert_equal defaults, @config.configuration
      end
    end
    
    context "when getting field values" do
      setup do
        @config = ActsAsSolr::Configuration.new(@klazz)
      end
      
      should "define an accessor methods for a solr converted value" do
        assert @klazz.instance_methods.include?("birthdate_for_solr")
      end

      context "for date types" do
        setup do
          @model = @klazz.new
        end

        should "return nil when field is nil" do
          @model.birthdate = nil
          assert_nil @model.birthdate_for_solr
        end

        should "return the formatted date" do
          @model.birthdate = Date.today
          assert_equal Date.today.strftime("%Y-%m-%dT%H:%M:%SZ"), @model.birthdate_for_solr
        end
      end

      context "for timestamp types" do
        setup do
          @now = Time.now
          @model = @klazz.new(:birthdate => @now)
        end

        should "return a formatted timestamp string for timestamps" do
          assert_equal @now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), @model.birthdate_for_solr
        end
      end
    end
  end
end