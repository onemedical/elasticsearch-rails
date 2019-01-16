module ElasticsearchV2
  module Rails
    module Instrumentation

      # Rails initializer class to require ElasticsearchV2::Rails::Instrumentation files,
      # set up ElasticsearchV2::Model and hook into ActionController to display Elasticsearch-related duration
      #
      # @see http://edgeguides.rubyonrails.org/active_support_instrumentation.html
      #
      class Railtie < ::Rails::Railtie
        initializer "elasticsearch.instrumentation" do |app|
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
        end
      end

    end
  end
end
