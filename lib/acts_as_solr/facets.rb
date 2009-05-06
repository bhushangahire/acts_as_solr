module ActsAsSolr
  module Facets
    def add_facets(options, query_options)
      query_options[:facets] = {}
      query_options[:facets][:limit] = -1
      query_options[:facets][:limit] = options[:facets][:limit] if options[:facets][:limit]
      query_options[:facets][:offset] = options[:facets][:offset] if options[:facets][:offset]
      query_options[:facets][:sort] = :count if options[:facets][:sort]
      query_options[:facets][:mincount] = 0
      query_options[:facets][:mincount] = 1 if options[:facets][:zeros] == false
      # override the :zeros (it's deprecated anyway) if :mincount exists
      query_options[:facets][:mincount] = options[:facets][:mincount] if options[:facets][:mincount]
      query_options[:filter_queries] = replace_types([*options[:facets][:browse]].collect{|k| "#{k.sub!(/ *: */,"_facet:")}"}) if options[:facets][:browse]
      query_options[:facets][:queries] = replace_types(options[:facets][:query].collect{|k| "#{k.sub!(/ *: */,"_t:")}"}) if options[:facets][:query]
      
      add_facet_fields(options, query_options) if options[:facets][:fields]
      add_date_facets(options, query_options) if options[:facets][:dates]
    end

    def add_facet_fields(options, query_options)
      valid_options = [:sort, :limit, :offset, :prefix, :mincount, :missing]

      query_options[:facets][:fields] = []
      options[:facets][:fields].each do |f|
        if f.kind_of? Hash
          field, field_options = f.to_a.first
          raise "Invalid parameters: #{(field_options.keys - valid_options).join(',')}" unless (field_options.keys - valid_options).empty?
          query_options[:facets][:fields] << {"#{field}_facet" => field_options}
        else
          query_options[:facets][:fields] << "#{f}_facet"
        end
      end
    end
    
    def add_date_facets(options, query_options)
      query_options[:date_facets] = {}
      # if options[:facets][:dates][:fields] exists then :start, :end, and :gap must be there
      if options[:facets][:dates][:fields]
        [:start, :end, :gap].each { |k| raise "#{k} must be present in faceted date query" unless options[:facets][:dates].include?(k) }
        query_options[:date_facets][:fields] = []
        options[:facets][:dates][:fields].each { |f|
          if f.kind_of? Hash
            key = f.keys[0]
            query_options[:date_facets][:fields] << {"#{key}_d" => f[key]}
            validate_date_facet_other_options(f[key][:other]) if f[key][:other]
          else
            query_options[:date_facets][:fields] << "#{f}_d"
          end
        }
      end
      
      query_options[:date_facets][:start]   = options[:facets][:dates][:start] if options[:facets][:dates][:start]
      query_options[:date_facets][:end]     = options[:facets][:dates][:end] if options[:facets][:dates][:end]
      query_options[:date_facets][:gap]     = options[:facets][:dates][:gap] if options[:facets][:dates][:gap]
      query_options[:date_facets][:hardend] = options[:facets][:dates][:hardend] if options[:facets][:dates][:hardend]
      query_options[:date_facets][:filter]  = replace_types([*options[:facets][:dates][:filter]].collect{|k| "#{k.sub!(/ *:(?!\d) */,"_d:")}"}) if options[:facets][:dates][:filter]

      if options[:facets][:dates][:other]
        validate_date_facet_other_options(options[:facets][:dates][:other])
        query_options[:date_facets][:other]   = options[:facets][:dates][:other]
      end
    end
  end
end