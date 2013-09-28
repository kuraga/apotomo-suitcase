require 'apotomo/persistence'

module Apotomo
  class RequestProcessor

    class InvalidSourceWidget < RuntimeError; end

    include Hooks
    include Persistence
    
    define_hook :after_initialize
    define_hook :after_fire
    
    attr_reader :root, :session
    
    
    def initialize(controller, session, options={}, has_widgets_blocks=[])
      @session = session
      @root    = Widget.new(controller, 'root', :display)
       
      attach_stateless_blocks_for(has_widgets_blocks, @root, controller)
      
      if !options.fetch(:flush_widgets, false) and frozen_widgets_in?(@session)  
        thaw_for(@session, @root)
      else
        flush_storage(@session) ### FIXME: set internal mode to flushed 
      end

      run_hook :after_initialize, self
    end
    
    def attach_stateless_blocks_for(blocks, root, controller)
      blocks.each { |blk| controller.instance_exec(root, &blk) }
    end
    
    # Called when the browser wants an url_for_event address. This fires the request event in 
    # the widget tree and collects the rendered page updates.
    def process_for(request_params)
      source = self.root.find_widget(request_params[:source]) or raise InvalidSourceWidget, "Source #{request_params[:source].inspect} non-existent."
      
      source.fire(request_params[:type].to_sym, request_params) # set data to params for now.
      
      run_hook :after_fire, self
      source.root.page_updates ### DISCUSS: that's another dependency.
    end
    
    # Serializes the current widget tree to the storage that was passed in the constructor.
    # Call this at the end of a request.
    def freeze!
      freeze_for(@session, root)
    end
     
    # Renders the widget named +widget_id+. Any additional args is passed through to Widget#invoke.
    def render_widget_for(*args)
      root.render_widget(*args)
    end
    
    # Computes the address hash for a +:source+ widget and an event +:type+.
    # Additional parameters will be merged.
    def address_for(options)
      raise "You forgot to provide :source or :type" unless options.has_key?(:source) and options.has_key?(:type)
      options
    end
  end
end
