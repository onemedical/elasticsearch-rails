require 'test_helper'

class ElasticsearchV2::Persistence::ModuleTest < Test::Unit::TestCase
  context "The Persistence module" do

    context "client" do
      should "have a default client" do
        client = ElasticsearchV2::Persistence.client
        assert_not_nil     client
        assert_instance_of ElasticsearchV2::Transport::Client, client
      end

      should "allow to set a client" do
        begin
          ElasticsearchV2::Persistence.client = "Foobar"
          assert_equal "Foobar", ElasticsearchV2::Persistence.client
        ensure
          ElasticsearchV2::Persistence.client = nil
        end
      end

      should "allow to set a client with DSL" do
        begin
          ElasticsearchV2::Persistence.client "Foobar"
          assert_equal "Foobar", ElasticsearchV2::Persistence.client
        ensure
          ElasticsearchV2::Persistence.client = nil
        end
      end
    end
  end
end
