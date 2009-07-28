require 'acts_as_solr/configuration'

module ActsAsSolr #:nodoc:
  
  module ActsMethods
    
    # declares a class as solr-searchable
    # 
    # ==== options:
    # fields:: This option can be used to specify only the fields you'd
    #          like to index. If not given, all the attributes from the 
    #          class will be indexed. You can also use this option to 
    #          include methods that should be indexed as fields
    # 
    #           class Movie < ActiveRecord::Base
    #             acts_as_solr :fields => [:name, :description, :current_time]
    #             def current_time
    #               Time.now.to_s
    #             end
    #           end
    #          
    #          Each field passed can also be a hash with the value being a field type
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => :range_float}]
    #             def current_time
    #               Time.now
    #             end
    #           end
    # 
    #          The field types accepted are:
    # 
    #          :float:: Index the field value as a float (ie.: 12.87)
    #          :integer:: Index the field value as an integer (ie.: 31)
    #          :boolean:: Index the field value as a boolean (ie.: true/false)
    #          :date:: Index the field value as a date (ie.: Wed Nov 15 23:13:03 PST 2006)
    #          :string:: Index the field value as a text string, not applying the same indexing
    #                    filters as a regular text field
    #          :range_integer:: Index the field value for integer range queries (ie.:[5 TO 20])
    #          :range_float:: Index the field value for float range queries (ie.:[14.56 TO 19.99])
    # 
    #          Setting the field type preserves its original type when indexed
    # 
    #          The field may also be passed with a hash value containing options
    #
    #          class Author < ActiveRecord::Base
    #            acts_as_solr :fields => [{:full_name => {:type => :text, :as => :name}}]
    #            def full_name
    #              self.first_name + ' ' + self.last_name
    #            end
    #          end
    #
    #          The options accepted are:
    #
    #          :type:: Index the field using the specified type
    #          :as:: Index the field using the specified field name
    #
    # additional_fields:: This option takes fields to be include in the index
    #                     in addition to those derived from the database. You
    #                     can also use this option to include custom fields 
    #                     derived from methods you define. This option will be
    #                     ignored if the :fields option is given. It also accepts
    #                     the same field types as the option above
    # 
    #                      class Movie < ActiveRecord::Base
    #                       acts_as_solr :additional_fields => [:current_time]
    #                       def current_time
    #                         Time.now.to_s
    #                       end
    #                      end
    # 
    # exclude_fields:: This option taks an array of fields that should be ignored from indexing:
    # 
    #                    class User < ActiveRecord::Base
    #                      acts_as_solr :exclude_fields => [:password, :login, :credit_card_number]
    #                    end
    # 
    # include:: This option can be used for association indexing, which 
    #           means you can include any :has_one, :has_many, :belongs_to 
    #           and :has_and_belongs_to_many association to be indexed:
    # 
    #            class Category < ActiveRecord::Base
    #              has_many :books
    #              acts_as_solr :include => [:books]
    #            end
    # 
    #           Each association may also be specified as a hash with an option hash as a value
    #
    #           class Book < ActiveRecord::Base
    #             belongs_to :author
    #             has_many :distribution_companies
    #             has_many :copyright_dates
    #             has_many :media_types
    #             acts_as_solr(
    #               :fields => [:name, :description],
    #               :include => [
    #                 {:author => {:using => :fullname, :as => :name}},
    #                 {:media_types => {:using => lambda{|media| type_lookup(media.id)}}}
    #                 {:distribution_companies => {:as => :distributor, :multivalued => true}},
    #                 {:copyright_dates => {:as => :copyright, :type => :date}}
    #               ]
    #             ]
    #
    #           The options accepted are:
    #
    #           :type:: Index the associated objects using the specified type
    #           :as:: Index the associated objects using the specified field name
    #           :using:: Index the associated objects using the value returned by the specified method or proc.  If a method
    #                    symbol is supplied, it will be sent to each object to look up the value to index; if a proc is
    #                    supplied, it will be called once for each object with the object as the only argument
    #           :multivalued:: Index the associated objects using one field for each object rather than joining them
    #                          all into a single field
    #
    # facets:: This option can be used to specify the fields you'd like to
    #          index as facet fields
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :facets => [:category, :manufacturer]  
    #           end
    # 
    # boost:: You can pass a boost (float) value that will be used to boost the document and/or a field. To specify a more
    #         boost for the document, you can either pass a block or a symbol. The block will be called with the record
    #         as an argument, a symbol will result in the according method being called:
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => {:boost => 5.0}}], :boost => 10.0
    #           end
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => {:boost => 5.0}}], :boost => proc {|record| record.id + 120*37}
    #           end
    #
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => {:boost => :price_rating}}], :boost => 10.0
    #           end
    #
    # if:: Only indexes the record if the condition evaluated is true. The argument has to be 
    #      either a symbol, string (to be eval'ed), proc/method, or class implementing a static 
    #      validation method. It behaves the same way as ActiveRecord's :if option.
    # 
    #        class Electronic < ActiveRecord::Base
    #          acts_as_solr :if => proc{|record| record.is_active?}
    #        end
    # 
    # offline:: Assumes that your using an outside mechanism to explicitly trigger indexing records, e.g. you only
    #           want to update your index through some asynchronous mechanism. Will accept either a boolean or a block
    #           that will be evaluated before actually contacting the index for saving or destroying a document. Defaults
    #           to false. It doesn't refer to the mechanism of an offline index in general, but just to get a centralized point
    #           where you can control indexing. Note: This is only enabled for saving records. acts_as_solr doesn't always like
    #           it, if you have a different number of results coming from the database and the index. This might be rectified in
    #           another patch to support lazy loading.
    #
    #             class Electronic < ActiveRecord::Base
    #               acts_as_solr :offline => proc {|record| record.automatic_indexing_disabled?}
    #             end
    #
    # auto_commit:: The commit command will be sent to Solr only if its value is set to true:
    # 
    #                 class Author < ActiveRecord::Base
    #                   acts_as_solr :auto_commit => false
    #                 end
    # 
    def acts_as_solr(options={}, solr_options={})
      extend ClassMethods
      include InstanceMethods
      
      cattr_accessor :solr_configuration
      
      begin
        self.solr_configuration = Configuration.new(self, options.merge(solr_options))
      rescue ActiveRecord::StatementInvalid => e
        if e.message =~ /Table .* doesn't exist/
          $stderr.puts "** Skipping acts_as_solr initialization, as the table is not present"
        else
          raise
        end
      end
    end
  end
end
