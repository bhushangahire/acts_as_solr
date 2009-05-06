require File.dirname(__FILE__) + '/rebuild'
require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/parser_methods'
require File.dirname(__FILE__) + '/facets'

module ActsAsSolr
  class Index
    attr_reader :klass
    
    include ParserMethods
    include CommonMethods
    include Rebuild
    include Facets
    
    def initialize(klass)
      @klass = klass
    end
    
    def find_by_solr(query, options = {})
      data = parse_query(query, options)
      parse_results(data, options) if data
    end
    
    def find_id_by_solr(query, options = {})
      data = parse_query(query, options)
      parse_results(data, {:format => :ids}) if data
    end
    
    def multi_solr_search(query, options = {})
      models = multi_model_suffix(options)
      options.update(:results_format => :objects) unless options[:results_format]
      data = parse_query(query, options, models)
      
      if data.nil? or data.total_hits == 0
        return SearchResults.new(:docs => [], :total => 0)
      end
      
      result = find_multi_search_objects(data, options)

      if options[:scores] and options[:results_format] == :objects
        add_scores(result, data) 
      end
      SearchResults.new :docs => result, :total => data.total_hits
    end
    
    def count_by_solr(query, options = {})
      data = parse_query(query, options)
      data.total_hits
    end

    def method_missing(name, *args)
      if klass.respond_to?(name)
        klass.send(name, *args)
      else
        super
      end
    end
    
    protected
    
    def find_multi_search_objects(data, options)
      result = []
      if options[:results_format] == :objects
        data.hits.each do |doc| 
          k = doc.fetch('id').first.to_s.split(':')
          result << k[0].constantize.find_by_id(k[1])
        end
      elsif options[:results_format] == :ids
        data.hits.each do |doc|
          doc_id = doc.fetch('id')
          doc_id = doc_id.first if doc_id.is_a?(Array)
          result << {"id" => doc_id}
        end
      end
      result
    end
    
    def multi_model_suffix(options)
      models = "AND (#{solr_configuration[:type_field]}:#{self.name}"
      models << " OR " + options[:models].collect {|m| "#{solr_configuration[:type_field]}:" + m.to_s}.join(" OR ") if options[:models].is_a?(Array)
      models << ")"
    end
    
  end
end