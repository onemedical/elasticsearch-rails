module ElasticsearchV2
  module Persistence
    module Model
      class DocumentNotSaved     < StandardError; end
      class DocumentNotPersisted < StandardError; end
    end
  end
end
