require 'rails'
module Statify
  class Railtie < Rails::Railtie
    # The config object available to the Railtie is the application configuration object.
    config.statify = ActiveSupport::OrderedOptions.new

    initializer "statify.configure" do |app|
      Statify.configure do |config|
        config.categories = app.config.statify[:categories]
        config.statsd = app.config.statify[:statsd]
      end
    end

    initializer "statify.initialize", :after => "statify.configure" do |app|
      if Statify.categories.include?(:sql)
        # This should give us reports on response times to queries
        ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          # Don't include explains or schema DB calls
          unless ["EXPLAIN", "SCHEMA"].include?(event.payload[:name])
            # # We are hoping this gives us basic metris for query durations for us to track.
            @@statsd.timing "#{event.name}", event.duration
          end
        end
      end

      if Statify.categories.include?(:garbage_collection) || Statify.categories.include?(:controller)
        # This should give us reports on average response times by controller and action
        ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|      
          event = ActiveSupport::Notifications::Event.new(*args)
          
          if Statify.categories.include?[:garbage_collection]
            # Let's log the GC
            gc_stats = GC::stat 
            @@statsd.count('gc_count', gc_stats[:count])
            @@statsd.count('gc_heap_used', gc_stats[:heap_used])
            @@statsd.count('gc_heap_length', gc_stats[:heap_length])
            @@statsd.count('gc_heap_increment', gc_stats[:heap_increment])
            @@statsd.count('gc_heap_live_num', gc_stats[:heap_live_num])
            @@statsd.count('gc_heap_free_num', gc_stats[:heap_live_num])
            @@statsd.count('gc_heap_final_num', gc_stats[:heap_live_num])
          end

          if Statify.categories.include?[:controller]
            # Track overall, db and view durations
            @@statsd.timing "overall_duration|#{event.payload[:controller]}/#{event.payload[:action]}", event.duration
            @@statsd.timing "db_runtime|#{event.payload[:controller]}/#{event.payload[:action]}", event.payload[:db_runtime]
            @@statsd.timing "view_runtime|#{event.payload[:controller]}/#{event.payload[:action]}", event.payload[:view_runtime]
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
end