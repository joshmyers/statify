require 'statify/version'
require 'statify/railtie'
require 'statsd'

# Statify.configure do |config|
#  config.statsd = StatD.new...
# end
# Statify.statsd = 
module Statify
  def self.configure
    yield self
  end

  # This takes an instance of a StatsD
  # Statsd.new('127.1.1.1', 8125)
  def self.statsd=(statsd)
    @@statsd = statsd
  end

  def self.statsd
    @@statsd
  end

  def self.categories=(categories)
    @@categories = categories

    # If you're running ruby-1.8.7 and your trying to get GC stats
    if @@categories.include?(:garbage_collection)
      if RUBY_VERSION < '1.9'
        # Fail and tell the user to remove the GC stats
        fail "The GC stats don't work in Ruby 1.8.7.  Please remove the :grabage_collection from the categories"
        @@stats.delete(:garbage_collection)
      end
    end
  end

  def self.categories
    @@categories
  end

  def self.subscribe
    if Statify.categories.include?(:sql)
      # This should give us reports on response times to queries
      ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        # Don't include explains or schema DB calls
        unless ["EXPLAIN", "SCHEMA"].include?(event.payload[:name])
          # # We are hoping this gives us basic metris for query durations for us to track.
          @@statsd.measure "#{event.name}", event.duration
        end
      end
    end

    if Statify.categories.include?(:garbage_collection) || Statify.categories.include?(:controller)
      # This should give us reports on average response times by controller and action
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)

        if Statify.categories.include?(:garbage_collection)
          # Let's log the GC
          gc_stats = GC::stat
          @@statsd.increment('gc_count', gc_stats[:count])
          @@statsd.increment('gc_heap_used', gc_stats[:heap_used])
          @@statsd.increment('gc_heap_length', gc_stats[:heap_length])
          @@statsd.increment('gc_heap_increment', gc_stats[:heap_increment])
          @@statsd.increment('gc_heap_live_slot', gc_stats[:heap_live_slot])
          @@statsd.increment('gc_heap_free_slot', gc_stats[:heap_free_slot])
          @@statsd.increment('gc_heap_final_slot', gc_stats[:heap_final_slot])
          @@statsd.increment('gc_heap_swept_slot', gc_stats[:heap_swept_slot])
          @@statsd.increment('gc_heap_eden_page_length', gc_stats[:heap_eden_page_length])
          @@statsd.increment('gc_heap_tomb_page_length', gc_stats[:heap_tomb_page_length])
          @@statsd.increment('gc_total_allocated_object', gc_stats[:total_allocated_object])
          @@statsd.increment('gc_total_freed_object', gc_stats[:total_freed_object])
          @@statsd.increment('gc_malloc_increase', gc_stats[:malloc_increase])
          @@statsd.increment('gc_malloc_limit', gc_stats[:malloc_limit])
          @@statsd.increment('gc_minor_gc_count', gc_stats[:minor_gc_count])
          @@statsd.increment('gc_major_gc_count', gc_stats[:major_gc_count])
          @@statsd.increment('gc_remembered_shady_object', gc_stats[:remembered_shady_object])
          @@statsd.increment('gc_remembered_shady_object_limit', gc_stats[:remembered_shady_object_limit])
          @@statsd.increment('gc_old_object', gc_stats[:old_object])
          @@statsd.increment('gc_old_object_limit', gc_stats[:old_object_limit])
          @@statsd.increment('gc_old_malloc_increase', gc_stats[:oldmalloc_increase])
          @@statsd.increment('gc_old_malloc_limit', gc_stats[:oldmalloc_limit])
        end

        if Statify.categories.include?(:controller)
          # Track overall, db and view durations
          @@statsd.measure "overall_duration|#{event.payload[:controller]}/#{event.payload[:action]}", event.duration
          @@statsd.measure "db_runtime|#{event.payload[:controller]}/#{event.payload[:action]}", event.payload[:db_runtime]
          @@statsd.measure "view_runtime|#{event.payload[:controller]}/#{event.payload[:action]}", event.payload[:view_runtime]
        end
      end
    end

    if Statify.categories.include?(:cache)
      # I want to keep track of how many cache hits we get as opposed to cache misses
      ActiveSupport::Notifications.subscribe "cache_fetch_hit.active_support" do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        @@statsd.increment('cache_hit', 1)
      end

      # I want to keep track of how many cache misses we get as opposed to cache hits
      ActiveSupport::Notifications.subscribe "cache_write.active_support" do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        @@statsd.increment('cache_miss', 1)
      end
    end
  end
end
