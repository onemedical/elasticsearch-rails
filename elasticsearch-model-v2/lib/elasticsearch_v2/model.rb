require 'elasticsearch_v2'

require 'hashie'

require 'active_support/core_ext/module/delegation'

require 'elasticsearch_v2/model/version'

require 'elasticsearch_v2/model/client'

require 'elasticsearch_v2/model/multimodel'

require 'elasticsearch_v2/model/adapter'
require 'elasticsearch_v2/model/adapters/default'
require 'elasticsearch_v2/model/adapters/active_record'
require 'elasticsearch_v2/model/adapters/mongoid'
require 'elasticsearch_v2/model/adapters/multiple'

require 'elasticsearch_v2/model/importing'
require 'elasticsearch_v2/model/indexing'
require 'elasticsearch_v2/model/naming'
require 'elasticsearch_v2/model/serializing'
require 'elasticsearch_v2/model/searching'
require 'elasticsearch_v2/model/callbacks'

require 'elasticsearch_v2/model/proxy'

require 'elasticsearch_v2/model/response'
require 'elasticsearch_v2/model/response/base'
require 'elasticsearch_v2/model/response/result'
require 'elasticsearch_v2/model/response/results'
require 'elasticsearch_v2/model/response/records'
require 'elasticsearch_v2/model/response/pagination'
require 'elasticsearch_v2/model/response/aggregations'
require 'elasticsearch_v2/model/response/suggestions'

require 'elasticsearch_v2/model/ext/active_record'

case
when defined?(::Kaminari)
  ElasticsearchV2::Model::Response::Response.__send__ :include, ElasticsearchV2::Model::Response::Pagination::Kaminari
when defined?(::WillPaginate)
  ElasticsearchV2::Model::Response::Response.__send__ :include, ElasticsearchV2::Model::Response::Pagination::WillPaginate
end

module ElasticsearchV2

  # Elasticsearch integration for Ruby models
  # =========================================
  #
  # `ElasticsearchV2::Model` contains modules for integrating the Elasticsearch search and analytical engine
  # with ActiveModel-based classes, or models, for the Ruby programming language.
  #
  # It facilitates importing your data into an index, automatically updating it when a record changes,
  # searching the specific index, setting up the index mapping or the model JSON serialization.
  #
  # When the `ElasticsearchV2::Model` module is included in your class, it automatically extends it
  # with the functionality; see {ElasticsearchV2::Model.included}. Most methods are available via
  # the `__elasticsearch_v2__` class and instance method proxies.
  #
  # It is possible to include/extend the model with the corresponding
  # modules directly, if that is desired:
  #
  #     MyModel.__send__ :extend,  ElasticsearchV2::Model::Client::ClassMethods
  #     MyModel.__send__ :include, ElasticsearchV2::Model::Client::InstanceMethods
  #     MyModel.__send__ :extend,  ElasticsearchV2::Model::Searching::ClassMethods
  #     # ...
  #
  module Model
    METHODS = [:search, :mapping, :mappings, :settings, :index_name, :document_type, :import]

    # Adds the `ElasticsearchV2::Model` functionality to the including class.
    #
    # * Creates the `__elasticsearch_v2__` class and instance methods, pointing to the proxy object
    # * Includes the necessary modules in the proxy classes
    # * Sets up delegation for crucial methods such as `search`, etc.
    #
    # @example Include the module in the `Article` model definition
    #
    #     class Article < ActiveRecord::Base
    #       include ElasticsearchV2::Model
    #     end
    #
    # @example Inject the module into the `Article` model during run time
    #
    #     Article.__send__ :include, ElasticsearchV2::Model
    #
    #
    def self.included(base)
      base.class_eval do
        include ElasticsearchV2::Model::Proxy

        ElasticsearchV2::Model::Proxy::ClassMethodsProxy.class_eval do
          include ElasticsearchV2::Model::Client::ClassMethods
          include ElasticsearchV2::Model::Naming::ClassMethods
          include ElasticsearchV2::Model::Indexing::ClassMethods
          include ElasticsearchV2::Model::Searching::ClassMethods
        end

        ElasticsearchV2::Model::Proxy::InstanceMethodsProxy.class_eval do
          include ElasticsearchV2::Model::Client::InstanceMethods
          include ElasticsearchV2::Model::Naming::InstanceMethods
          include ElasticsearchV2::Model::Indexing::InstanceMethods
          include ElasticsearchV2::Model::Serializing::InstanceMethods
        end

        ElasticsearchV2::Model::Proxy::InstanceMethodsProxy.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def as_indexed_json(options={})
            target.respond_to?(:as_indexed_json) ? target.__send__(:as_indexed_json, options) : super
          end
        CODE

        # Delegate important methods to the `__elasticsearch_v2__` proxy, unless they are defined already
        #
        class << self
          METHODS.each do |method|
            delegate method, to: :__elasticsearch_v2__ unless self.public_instance_methods.include?(method)
          end
        end

        # Mix the importing module into the proxy
        #
        self.__elasticsearch_v2__.class_eval do
          include ElasticsearchV2::Model::Importing::ClassMethods
          include Adapter.from_class(base).importing_mixin
        end

        # Add to the registry if it's a class (and not in intermediate module)
        Registry.add(base) if base.is_a?(Class)
      end
    end

    # Access the module settings
    #
    def self.settings
      @settings ||= {}
    end

    module ClassMethods
      # Get the client common for all models
      #
      # @example Get the client
      #
      #     ElasticsearchV2::Model.client
      #     => #<ElasticsearchV2::Transport::Client:0x007f96a7d0d000 @transport=... >
      #
      def client
        @client ||= ElasticsearchV2::Client.new
      end

      # Set the client for all models
      #
      # @example Configure (set) the client for all models
      #
      #     ElasticsearchV2::Model.client = ElasticsearchV2::Client.new host: 'http://localhost:9200', tracer: true
      #     => #<ElasticsearchV2::Transport::Client:0x007f96a6dd0d80 @transport=... >
      #
      # @note You have to set the client before you call Elasticsearch methods on the model,
      #       or set it directly on the model; see {ElasticsearchV2::Model::Client::ClassMethods#client}
      #
      def client=(client)
        @client = client
      end

      # Search across multiple models
      #
      # By default, all models which include the `ElasticsearchV2::Model` module are searched
      #
      # @param query_or_payload [String,Hash,Object] The search request definition
      #                                              (string, JSON, Hash, or object responding to `to_hash`)
      # @param models [Array] The Array of Model objects to search
      # @param options [Hash] Optional parameters to be passed to the Elasticsearch client
      #
      # @return [ElasticsearchV2::Model::Response::Response]
      #
      # @example Search across specific models
      #
      #     ElasticsearchV2::Model.search('foo', [Author, Article])
      #
      # @example Search across all models which include the `ElasticsearchV2::Model` module
      #
      #     ElasticsearchV2::Model.search('foo')
      #
      def search(query_or_payload, models=[], options={})
        models = Multimodel.new(models)
        request = Searching::SearchRequest.new(models, query_or_payload, options)
        Response::Response.new(models, request)
      end

      # Check if inheritance is enabled
      #
      # @note Inheritance is disabled by default.
      #
      def inheritance_enabled
        @inheritance_enabled ||= false
      end

      # Enable inheritance of index_name and document_type
      #
      # @example Enable inheritance
      #
      #     ElasticsearchV2::Model.inheritance_enabled = true
      #
      def inheritance_enabled=(inheritance_enabled)
        @inheritance_enabled = inheritance_enabled
      end
    end
    extend ClassMethods

    class NotImplemented < NoMethodError; end
  end
end
