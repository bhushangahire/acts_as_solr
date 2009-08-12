require File.dirname(__FILE__) + '/instance'

module ActsAsSolr #:nodoc:
  
  module InstanceMethods

    # Solr id is <class.name>:<id> to be unique across all models
    def solr_id
      "#{self.class.name}:#{solr_index.record_id(self)}"
    end

    # saves to the Solr index
    def solr_save
      solr_index.save
    end

    # remove from index
    def solr_destroy
      solr_index.destroy
    end

    # convert instance to Solr document
    def to_solr_doc
      solr_index.to_solr_doc
    end
    
    def solr_commit
      solr_index.solr_commit
    end

    def indexing_disabled?
      solr_index.indexing_disabled?
    end
    
    private
    
    def solr_index
      @__solr_index ||= ActsAsSolr::Instance.new(self)
    end
    

  end
end