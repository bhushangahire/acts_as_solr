module ActsAsSolr
  module Rebuild
    def rebuild_solr_index(batch_size = 0, &finder)
      finder ||= lambda { |ar, options| ar.find(:all, options.merge({:order => self.primary_key})) }
      start_time = Time.now

      if batch_size > 0
        items_processed = 0
        items_skipped = 0
        limit = batch_size
        offset = 0
        begin
          iteration_start = Time.now
          items = finder.call(self, {:limit => limit, :offset => offset})
          add_batch = items.collect { |item| item.to_solr_doc unless item.indexing_disabled? }.compact

          if items.size > 0
            solr_add add_batch
            solr_commit
          end

          items_processed += add_batch.size
          items_skipped += items.size - add_batch.size
          last_id = items.last.id if items.last
          time_so_far = Time.now - start_time
          iteration_time = Time.now - iteration_start
          logger.info "#{Process.pid}: #{items_processed} items for #{self.name} have been batch added to index in #{'%.3f' % time_so_far}s at #{'%.3f' % (items_processed / time_so_far)} items/sec (#{'%.3f' % (items.size / iteration_time)} items/sec for the last batch). Last id: #{last_id}. Skipped items: #{items_skipped}"
          offset += items.size
        end while items.nil? || items.size > 0
      else
        items = finder.call(self, {})
        items.each { |content| content.solr_save }
        items_processed = items.size
      end
      solr_optimize
      logger.info items_processed > 0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
    end
  end
end