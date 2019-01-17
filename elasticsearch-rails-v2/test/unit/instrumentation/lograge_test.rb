require 'test_helper'

require 'rails/railtie'
require 'action_pack'
require 'lograge'

require 'elasticsearch_v2/rails/lograge'

class ElasticsearchV2::Rails::LogrageTest < Test::Unit::TestCase
  context "Lograge integration" do
    setup do
      ElasticsearchV2::Rails::Lograge::Railtie.run_initializers
    end

    should "customize the Lograge configuration" do
      assert_not_nil ElasticsearchV2::Rails::Lograge::Railtie.initializers
                       .select { |i| i.name == 'elasticsearch.lograge' }
                       .first
    end
  end
end
