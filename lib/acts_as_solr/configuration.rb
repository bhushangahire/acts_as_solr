module ActsAsSolr
  class Configuration
    attr_accessor :configuration, :klazz
    
    def initialize(klazz, options = {})
      @klazz = klazz
      @configuration = { 
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
        :default_boost => 1.0
      }
      @configuration.update(options)
      
      configuration[:solr_fields] = {}
      configuration[:solr_includes] = {}
      
      klazz.class_eval do
        after_save :solr_save
        after_destroy :solr_destroy
      end
      
      if configuration[:fields].respond_to?(:each)
        process_fields(configuration[:fields])
      else
        process_fields(@klazz.column_names.map {|k| k.to_sym})
        process_fields(configuration[:additional_fields])
      end

      if configuration[:include].respond_to?(:each)
        process_includes(configuration[:include])
      end
    end
    
    def [](key)
      configuration[key]
    end
    
    def []=(key, value)
      configuration[key] = value
    end
   
    private
    
    def get_field_value(field)
      field_name, options = determine_field_name_and_options(field)
      configuration[:solr_fields][field_name] = options
      @klazz.class_eval do
        define_method("#{field_name}_for_solr".to_sym) do
          begin
            value = self[field_name] || instance_variable_get("@#{field_name.to_s}".to_sym) || send(field_name.to_sym)
            case options[:type] 
              # format dates properly; return nil for nil dates 
              when :date
                value ? (value.respond_to?(:utc) ? value.utc : value).strftime("%Y-%m-%dT%H:%M:%SZ") : nil 
              else value
            end
          rescue
            puts $!
            logger.debug "There was a problem getting the value for the field '#{field_name}': #{$!}"
            value = ''
          end
        end
      end
    end
    
    def process_fields(raw_field)
      if raw_field.respond_to?(:each)
        raw_field.each do |field|
          next if configuration[:exclude_fields].include?(field)
          get_field_value(field)
        end                
      end
    end
    
    def process_includes(includes)
      if includes.respond_to?(:each)
        includes.each do |assoc|
          field_name, options = determine_field_name_and_options(assoc)
          configuration[:solr_includes][field_name] = options
        end
      end
    end

    def determine_field_name_and_options(field)
      if field.is_a?(Hash)
        name = field.keys.first
        options = field.values.first
        if options.is_a?(Hash)
          [name, {:type => type_for_field(field)}.merge(options)]
        else
          [name, {:type => options}]
        end
      else
        [field, {:type => type_for_field(field)}]
      end
    end
    
    def type_for_field(field)
      if configuration[:facets] && configuration[:facets].include?(field)
        :facet
      elsif column = @klazz.columns_hash[field.to_s]
        case column.type
        when :string then :text
        when :datetime then :date
        when :time then :date
        else column.type
        end
      else
        :text
      end
    end
  end
end