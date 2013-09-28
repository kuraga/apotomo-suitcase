require 'apotomo/persistence'

module Apotomo
  # Create widget trees using the #widget DSL.
  module WidgetShortcuts
    include Persistence::Thaw

    module Naming
      def class_name_for(prefix)  # TODO: use Cell.class_from_cell_name. 
        "#{prefix}_widget".classify
      end

      def module_name_for(class_name) 
        class_name.to_s.gsub(/Widget/, '')
      end

      def prefix_for(class_name) 
        class_name.to_s.gsub(/Widget/, '').underscore
      end

      def module_nesting(module_name)
        module_name_parts = module_name.to_s.split('::')
        module_name_parts.length.downto(1).collect { |i| module_name_parts.first(i).join('::') }
      end

      def constant_for(prefix, base_parent)
        prefix_class_name = class_name_for(prefix)

        base_superclasses = base_parent.ancestors.select { |ancestor| ancestor < ApplicationWidget }
        base_superclasses_modules_names = base_superclasses.collect { |base_superclass| module_name_for(base_superclass) }
        base_superclasses_nestingmodules_names = base_superclasses_modules_names.collect { |base_superclass_module_name| module_nesting(base_superclass_module_name) }.flatten

        (base_superclasses_modules_names + base_superclasses_nestingmodules_names).uniq.each do |base_class_name|
          return base_class_name.constantize.qualified_const_get(prefix_class_name) rescue NameError
        end
        prefix_class_name.classify.constantize
      end
    end

    include Naming

    # Shortcut for creating an instance of <tt>class_name+"_widget"</tt> named +id+. Yields self.
    # Note that this creates a proxy object, only. The actual widget is built not until you added 
    # it, e.g. using #<<.
    #
    # Example:
    # 
    #   root << widget(:comments)
    # 
    # will create a +CommentsWidget+ with id :comments attached to +root+.
    #
    #   widget(:comments, 'post-comments', :user => current_user)
    #
    # sets id to 'posts_comments' and #options to the hash.
    #
    # You can also use namespaces.
    #
    #   widget('jquery/tabs', 'panel')
    #
    # Add a block if you need to grab the created widget right away.
    #
    #   root << widget(:comments) do |comments|
    #     comments.markdown!
    #   end
    #
    # Using #widget is just a shortcut, you can always use the constructor as well.
    #
    #   CommentsWidget.new(root, :comments) 
    def widget(*args, &block)
      FactoryProxy.new(*args, &block)
    end
    
    class FactoryProxy
      def initialize(prefix, *args, &block)
        options = args.extract_options!
        id      = args.shift || prefix
        
        @prefix, @id, @options, @block = prefix, id, options, block
      end
      
      def build(parent)
        widget = constant_for(@prefix, parent.class).new(parent, @id, @options)
        @block.call(widget) if @block
        widget
      end
      
    private

      include Naming
    end
    
    # Mixed into Widget.      
    module DSL
      def <<(child)
        child.build(self)
      end
    end
  end
end
