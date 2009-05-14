require File.dirname(__FILE__) + '/test_helper'
require 'mocha'
require 'acts_as_solr'

RAILS_ROOT = "/tmp"

class ActsAsSolrTest < Test::Unit::TestCase

  context "Post.url" do

    should "return the URL to Solr" do
      assert_equal "http://localhost:8982/solr", ActsAsSolr::Post.url
    end

    should "only check the config file once" do
      File.expects(:exists?).once
      2.times { ActsAsSolr::Post.url }
    end

  end

end