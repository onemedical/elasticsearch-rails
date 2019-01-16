require 'active_support/core_ext/module/delegation'

require 'active_model'
require 'virtus'

require 'elasticsearch_v2/persistence'
require 'elasticsearch_v2/persistence/model/base'
require 'elasticsearch_v2/persistence/model/errors'
require 'elasticsearch_v2/persistence/model/store'
require 'elasticsearch_v2/persistence/model/find'

module ElasticsearchV2
  module Persistence

    # When included, extends a plain Ruby class with persistence-related features via the ActiveRecord pattern
    #
    # @example Include the repository in a custom class
    #
    #     require 'elasticsearch_v2/persistence/model'
    #
    #     class MyObject
    #       include ElasticsearchV2::Persistence::Repository
    #     end
    #
    module Model
      def self.included(base)
        base.class_eval do
          include ActiveModel::Naming
          include ActiveModel::Conversion
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON
          include ActiveModel::Validations

          include Virtus.model

          extend  ActiveModel::Callbacks
          define_model_callbacks :create, :save, :update, :destroy
          define_model_callbacks :find, :touch, only: :after

          include ElasticsearchV2::Persistence::Model::Base::InstanceMethods

          extend  ElasticsearchV2::Persistence::Model::Store::ClassMethods
          include ElasticsearchV2::Persistence::Model::Store::InstanceMethods

          extend  ElasticsearchV2::Persistence::Model::Find::ClassMethods

          class << self
            # Re-define the Virtus' `attribute` method, to configure Elasticsearch mapping as well
            #
            def attribute(name, type=nil, options={}, &block)
              mapping = options.delete(:mapping) || {}
              super

              gateway.mapping do
                indexes name, {type: Utils::lookup_type(type)}.merge(mapping)
              end

              gateway.mapping(&block) if block_given?
            end

            # Return the {Repository::Class} instance
            #
            def gateway(&block)
              @gateway ||= ElasticsearchV2::Persistence::Repository::Class.new host: self
              block.arity < 1 ? @gateway.instance_eval(&block) : block.call(@gateway) if block_given?
              @gateway
            end

            # Delegate methods to repository
            #
            delegate :settings,
                     :mappings,
                     :mapping,
                     :document_type=,
                     :index_name,
                     :index_name=,
                     :find,
                     :exists?,
                     :create_index!,
                     :refresh_index!,
              to: :gateway

            # forward document type to mappings when set
            def document_type(type = nil)
              return gateway.document_type unless type
              gateway.document_type type
              mapping.type = type
            end
          end

          # Configure the repository based on the model (set up index_name, etc)
          #
          gateway do
            klass         base
            index_name    base.model_name.collection.gsub(/\//, '-')
            document_type base.model_name.element

            def serialize(document)
              document.to_hash.except(:id, 'id')
            end

            def deserialize(document)
              object = klass.new document['_source']

              # Set the meta attributes when fetching the document from Elasticsearch
              #
              object.instance_variable_set :@_id,      document['_id']
              object.instance_variable_set :@_index,   document['_index']
              object.instance_variable_set :@_type,    document['_type']
              object.instance_variable_set :@_version, document['_version']
              object.instance_variable_set :@_source,  document['_source']

              # Store the "hit" information (highlighting, score, ...)
              #
              object.instance_variable_set :@hit,
                 Hashie::Mash.new(document.except('_index', '_type', '_id', '_version', '_source'))

              object.instance_variable_set(:@persisted, true)
              object
            end
          end

          # Set up common attributes
          #
          attribute :created_at, Time, default: lambda { |o,a| Time.now.utc }
          attribute :updated_at, Time, default: lambda { |o,a| Time.now.utc }

          attr_reader :hit
        end

      end
    end

  end
end
