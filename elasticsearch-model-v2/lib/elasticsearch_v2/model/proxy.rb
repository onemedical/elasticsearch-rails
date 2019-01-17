module ElasticsearchV2
  module Model

    # This module provides a proxy interfacing between the including class and
    # {ElasticsearchV2::Model}, preventing the pollution of the including class namespace.
    #
    # The only "gateway" between the model and ElasticsearchV2::Model is the
    # `__elasticsearch_v2__` class and instance method.
    #
    # The including class must be compatible with
    # [ActiveModel](https://github.com/rails/rails/tree/master/activemodel).
    #
    # @example Include the {ElasticsearchV2::Model} module into an `Article` model
    #
    #     class Article < ActiveRecord::Base
    #       include ElasticsearchV2::Model
    #     end
    #
    #     Article.__elasticsearch_v2__.respond_to?(:search)
    #     # => true
    #
    #     article = Article.first
    #
    #     article.respond_to? :index_document
    #     # => false
    #
    #     article.__elasticsearch_v2__.respond_to?(:index_document)
    #     # => true
    #
    module Proxy

      # Define the `__elasticsearch_v2__` class and instance methods in the including class
      # and register a callback for intercepting changes in the model.
      #
      # @note The callback is triggered only when `ElasticsearchV2::Model` is included in the
      #       module and the functionality is accessible via the proxy.
      #
      def self.included(base)
        base.class_eval do
          # {ClassMethodsProxy} instance, accessed as `MyModel.__elasticsearch_v2__`
          #
          def self.__elasticsearch_v2__ &block
            @__elasticsearch_v2__ ||= ClassMethodsProxy.new(self)
            @__elasticsearch_v2__.instance_eval(&block) if block_given?
            @__elasticsearch_v2__
          end

          # {InstanceMethodsProxy}, accessed as `@mymodel.__elasticsearch_v2__`
          #
          def __elasticsearch_v2__ &block
            @__elasticsearch_v2__ ||= InstanceMethodsProxy.new(self)
            @__elasticsearch_v2__.instance_eval(&block) if block_given?
            @__elasticsearch_v2__
          end

          # Register a callback for storing changed attributes for models which implement
          # `before_save` and `changed_attributes` methods (when `ElasticsearchV2::Model` is included)
          #
          # @see http://api.rubyonrails.org/classes/ActiveModel/Dirty.html
          #
          before_save do |i|
            changed_attr = i.__elasticsearch_v2__.instance_variable_get(:@__changed_attributes) || {}
            i.__elasticsearch_v2__.instance_variable_set(:@__changed_attributes,
                                                      changed_attr.merge(Hash[ i.changes.map { |key, value| [key, value.last] } ]))
          end if respond_to?(:before_save) && instance_methods.include?(:changed_attributes)
        end
      end

      # @overload dup
      #
      # Returns a copy of this object. Resets the __elasticsearch_v2__ proxy so
      # the duplicate will build its own proxy.
      def initialize_dup(_)
        @__elasticsearch_v2__ = nil
        super
      end

      # Common module for the proxy classes
      #
      module Base
        attr_reader :target

        def initialize(target)
          @target = target
        end

        # Delegate methods to `@target`
        #
        def method_missing(method_name, *arguments, &block)
          target.respond_to?(method_name) ? target.__send__(method_name, *arguments, &block) : super
        end

        # Respond to methods from `@target`
        #
        def respond_to?(method_name, include_private = false)
          target.respond_to?(method_name) || super
        end

        def inspect
          "[PROXY] #{target.inspect}"
        end
      end

      # A proxy interfacing between ElasticsearchV2::Model class methods and model class methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave?
      #
      class ClassMethodsProxy
        include Base
      end

      # A proxy interfacing between ElasticsearchV2::Model instance methods and model instance methods
      #
      # TODO: Inherit from BasicObject and make Pry's `ls` command behave?
      #
      class InstanceMethodsProxy
        include Base

        def klass
          target.class
        end

        def class
          klass.__elasticsearch_v2__
        end

        # Need to redefine `as_json` because we're not inheriting from `BasicObject`;
        # see TODO note above.
        #
        def as_json(options={})
          target.as_json(options)
        end
      end

    end
  end
end
