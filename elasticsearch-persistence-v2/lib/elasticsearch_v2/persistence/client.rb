module ElasticsearchV2
  module Persistence
    module Repository

      # Wraps the Elasticsearch Ruby
      # [client](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch#usage)
      #
      module Client

        # Get or set the default client for this repository
        #
        # @example Set and configure the client for the repository class
        #
        #     class MyRepository
        #       include ElasticsearchV2::Persistence::Repository
        #       client ElasticsearchV2::Client.new host: 'http://localhost:9200', log: true
        #     end
        #
        # @example Set and configure the client for this repository instance
        #
        #     repository.client ElasticsearchV2::Client.new host: 'http://localhost:9200', tracer: true
        #
        # @example Perform an API request through the client
        #
        #     MyRepository.client.cluster.health
        #     repository.client.cluster.health
        #     # => { "cluster_name" => "elasticsearch" ... }
        #
        def client client=nil
          @client = client || @client || ElasticsearchV2::Persistence.client
        end

        # Set the default client for this repository
        #
        # @example Set and configure the client for the repository class
        #
        #     MyRepository.client = ElasticsearchV2::Client.new host: 'http://localhost:9200', log: true
        #
        # @example Set and configure the client for this repository instance
        #
        #     repository.client = ElasticsearchV2::Client.new host: 'http://localhost:9200', tracer: true
        #
        def client=(client)
          @client = client
          @client
        end
      end

    end
  end
end
