require 'elasticsearch_v2'
require 'elasticsearch_v2/model/indexing'
require 'elasticsearch_v2/model/searching'
require 'hashie'

require 'active_support/inflector'

require 'elasticsearch_v2/persistence/version'

require 'elasticsearch_v2/persistence/client'
require 'elasticsearch_v2/persistence/repository/response/results'
require 'elasticsearch_v2/persistence/repository/naming'
require 'elasticsearch_v2/persistence/repository/serialize'
require 'elasticsearch_v2/persistence/repository/store'
require 'elasticsearch_v2/persistence/repository/find'
require 'elasticsearch_v2/persistence/repository/search'
require 'elasticsearch_v2/persistence/repository/class'
require 'elasticsearch_v2/persistence/repository'

module ElasticsearchV2

  # Persistence for Ruby domain objects and models in Elasticsearch
  # ===============================================================
  #
  # `ElasticsearchV2::Persistence` contains modules for storing and retrieving Ruby domain objects and models
  # in Elasticsearch.
  #
  # == Repository
  #
  # The repository patterns allows to store and retrieve Ruby objects in Elasticsearch.
  #
  #     require 'elasticsearch_v2/persistence'
  #
  #     class Note
  #       def to_hash; {foo: 'bar'}; end
  #     end
  #
  #     repository = ElasticsearchV2::Persistence::Repository.new
  #
  #     repository.save Note.new
  #     # => {"_index"=>"repository", "_type"=>"note", "_id"=>"mY108X9mSHajxIy2rzH2CA", ...}
  #
  # Customize your repository by including the main module in a Ruby class
  #     class MyRepository
  #       include ElasticsearchV2::Persistence::Repository
  #
  #       index 'my_notes'
  #       klass Note
  #
  #       client ElasticsearchV2::Client.new log: true
  #     end
  #
  #     repository = MyRepository.new
  #
  #     repository.save Note.new
  #     # 2014-04-04 22:15:25 +0200: POST http://localhost:9200/my_notes/note [status:201, request:0.009s, query:n/a]
  #     # 2014-04-04 22:15:25 +0200: > {"foo":"bar"}
  #     # 2014-04-04 22:15:25 +0200: < {"_index":"my_notes","_type":"note","_id":"-d28yXLFSlusnTxb13WIZQ", ...}
  #
  # == Model
  #
  # The active record pattern allows to use the interface familiar from ActiveRecord models:
  #
  #     require 'elasticsearch_v2/persistence'
  #
  #     class Article
  #       attribute :title, String, mapping: { analyzer: 'snowball' }
  #     end
  #
  #     article = Article.new id: 1, title: 'Test'
  #     article.save
  #
  #     Article.find(1)
  #
  #     article.update_attributes title: 'Update'
  #
  #     article.destroy
  #
  module Persistence

    # :nodoc:
    module ClassMethods

      # Get or set the default client for all repositories and models
      #
      # @example Set and configure the default client
      #
      #     ElasticsearchV2::Persistence.client ElasticsearchV2::Client.new host: 'http://localhost:9200', tracer: true
      #
      # @example Perform an API request through the client
      #
      #     ElasticsearchV2::Persistence.client.cluster.health
      #     # => { "cluster_name" => "elasticsearch" ... }
      #
      def client client=nil
        @client = client || @client || ElasticsearchV2::Client.new
      end

      # Set the default client for all repositories and models
      #
      # @example Set and configure the default client
      #
      #     ElasticsearchV2::Persistence.client = ElasticsearchV2::Client.new host: 'http://localhost:9200', tracer: true
      #     => #<ElasticsearchV2::Transport::Client:0x007f96a6dd0d80 @transport=... >
      #
      def client=(client)
        @client = client
      end
    end

    extend ClassMethods
  end
end
