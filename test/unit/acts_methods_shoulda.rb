require File.dirname(__FILE__) + '/test_helper'
require 'acts_as_solr/acts_methods'
require 'mocha'

class ActsMethodsTest < Test::Unit::TestCase
  class Model
    attr_accessor :birthdate
    
    def initialize(birthdate)
      @birthdate = birthdate
    end
    
    def self.configuration
      @configuration ||= {:solr_fields => {}}
    end

    def self.columns_hash=(columns_hash)
      @columns_hash = columns_hash
    end
    
    def self.columns_hash
      @columns_hash
    end
    
    def [](key)
      @birthday
    end
    
    self.extend ActsAsSolr::ActsMethods
  end  
end