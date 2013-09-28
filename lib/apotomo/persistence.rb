module Apotomo
  # Methods needed to serialize the widget tree and back.
  module Persistence
    module Freeze
      ### FIXME: rewrite so that root might be stateless as well.
      def freeze
        ivars = {}
        freezable_ivars.each { |ivar| ivars[ivar.to_sym] = instance_variable_get(ivar) }

        children = self.children.select(&:freeze?).collect(&:freeze)

        { :class_name => self.class.to_s, :name => self.name, :ivars => ivars, :children => children }
      end
    end

    module Thaw
      def thaw(branches_data)
        branches_data.each do |branch_data|
          node = self << parent_controller.widget(prefix_for(branch_data[:class_name]), branch_data[:name], branch_data[:ivars].delete(:@options) || {}) do |node|
            branch_data[:ivars].each { |k, v| node.instance_variable_set(k, v) }
          end
          node.thaw(branch_data[:children]) if branch_data[:children]
        end
      end
    end

    module StorageMethods
      def freezable_ivars
        []
      end

      def frozen_widgets_in?(storage) # DISCUSS get rid?
        !storage[:apotomo_stateful_widgets].blank?
      end

      def flush_storage(storage)
        storage[:apotomo_stateful_widgets] = nil
      end
    end

    include StorageMethods

    # Dump the shit to storage.
    def freeze_for(storage, root)
      storage[:apotomo_stateful_widgets] = [ root.freeze ]
    end

    # Create tree from storage and add branches to root/stateless parents.
    def thaw_for(storage, root)
      branch_data = storage.delete(:apotomo_stateful_widgets)
      root.thaw(branch_data[0][:children]) if branch_data # don't thaw root widget # DISCUSS thaw root widget?
    end

  end
end
