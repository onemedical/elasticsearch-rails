module ElasticsearchV2
  module Rails
    module Lograge

      # Rails initializer class to require ElasticsearchV2::Rails::Instrumentation files,
      # set up ElasticsearchV2::Model and add Lograge configuration to display Elasticsearch-related duration
      #
      # Require the component in your `application.rb` file and enable Lograge:
      #
      #     require 'elasticsearch_v2/rails/lograge'
      #
      # You should see the full duration of the request to Elasticsearch as part of each log event:
      #
      #     method=GET path=/search ... status=200 duration=380.89 view=99.64 db=0.00 es=279.37
      #
      # @see https://github.com/roidrage/lograge
      #
      class Railtie < ::Rails::Railtie
        initializer "elasticsearch.lograge" do |app|
          require 'elasticsearch_v2/rails/instrumentation/publishers'
          require 'elasticsearch_v2/rails/instrumentation/log_subscriber'
          require 'elasticsearch_v2/rails/instrumentation/controller_runtime'

          ElasticsearchV2::Model::Searching::SearchRequest.class_eval do
            include ElasticsearchV2::Rails::Instrumentation::Publishers::SearchRequest
          end if defined?(ElasticsearchV2::Model::Searching::SearchRequest)

          ElasticsearchV2::Persistence::Model::Find::SearchRequest.class_eval do
            include ElasticsearchV2::Rails::Instrumentation::Publishers::SearchRequest
          end if defined?(ElasticsearchV2::Persistence::Model::Find::SearchRequest)

          ActiveSupport.on_load(:action_controller) do
            include ElasticsearchV2::Rails::Instrumentation::ControllerRuntime
          end

          config.lograge.custom_options = lambda do |event|
            { es: event.payload[:elasticsearch_runtime].to_f.round(2) }
          end
        end
      end

    end
  end
end
