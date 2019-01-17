module ElasticsearchV2
  module Persistence
    module Repository

      # The default repository class, to be used either directly, or as a gateway in a custom repository class
      #
      # @example Standalone use
      #
      #     repository = ElasticsearchV2::Persistence::Repository::Class.new
      #     # => #<ElasticsearchV2::Persistence::Repository::Class ...>
      #     repository.save(my_object)
      #     # => {"_index"=> ... }
      #
      # @example Shortcut use
      #
      #     repository = ElasticsearchV2::Persistence::Repository.new
      #     # => #<ElasticsearchV2::Persistence::Repository::Class ...>
      #
      # @example Configuration via a block
      #
      #     repository = ElasticsearchV2::Persistence::Repository.new do
      #       index 'my_notes'
      #     end
      #
      #     # => #<ElasticsearchV2::Persistence::Repository::Class ...>
      #     # > repository.save(my_object)
      #     # => {"_index"=> ... }
      #
      # @example Accessing the gateway in a custom class
      #
      #     class MyRepository
      #       include ElasticsearchV2::Persistence::Repository
      #     end
      #
      #     repository = MyRepository.new
      #
      #     repository.gateway.client.info
      #     # => {"status"=>200, "name"=>"Venom", ... }
      #
      class Class
        include ElasticsearchV2::Persistence::Repository::Client
        include ElasticsearchV2::Persistence::Repository::Naming
        include ElasticsearchV2::Persistence::Repository::Serialize
        include ElasticsearchV2::Persistence::Repository::Store
        include ElasticsearchV2::Persistence::Repository::Find
        include ElasticsearchV2::Persistence::Repository::Search

        include ElasticsearchV2::Model::Indexing::ClassMethods

        attr_reader :options

        def initialize(options={}, &block)
          @options = options
          index_name options.delete(:index)
          block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
        end

        # Return the "host" class, if this repository is a gateway hosted in another class
        #
        # @return [nil, Class]
        #
        # @api private
        #
        def host
          options[:host]
        end
      end

    end
  end
end
