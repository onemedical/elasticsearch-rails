require 'test_helper'

class ElasticsearchV2::Model::ModuleTest < Test::Unit::TestCase
  context "The main module" do

    context "client" do
      should "have a default" do
        client = ElasticsearchV2::Model.client
        assert_not_nil     client
        assert_instance_of ElasticsearchV2::Transport::Client, client
      end

      should "be settable" do
        begin
          ElasticsearchV2::Model.client = "Foobar"
          assert_equal "Foobar", ElasticsearchV2::Model.client
        ensure
          ElasticsearchV2::Model.client = nil
        end
      end
    end

    context "when included in module/class, " do
      class ::DummyIncludingModel; end
      class ::DummyIncludingModelWithSearchMethodDefined
        def self.search(query, options={})
          "SEARCH"
        end
      end

      should "include and set up the proxy" do
        DummyIncludingModel.__send__ :include, ElasticsearchV2::Model

        assert_respond_to DummyIncludingModel,     :__elasticsearch__
        assert_respond_to DummyIncludingModel.new, :__elasticsearch__
      end

      should "delegate important methods to the proxy" do
        DummyIncludingModel.__send__ :include, ElasticsearchV2::Model

        assert_respond_to DummyIncludingModel, :search
        assert_respond_to DummyIncludingModel, :mappings
        assert_respond_to DummyIncludingModel, :settings
        assert_respond_to DummyIncludingModel, :index_name
        assert_respond_to DummyIncludingModel, :document_type
        assert_respond_to DummyIncludingModel, :import
      end

      should "not override existing method" do
        DummyIncludingModelWithSearchMethodDefined.__send__ :include, ElasticsearchV2::Model

        assert_equal 'SEARCH', DummyIncludingModelWithSearchMethodDefined.search('foo')
      end
    end

    context "settings" do
        should "access the settings" do
          assert_not_nil ElasticsearchV2::Model.settings
        end

        should "allow to set settings" do
          assert_nothing_raised { ElasticsearchV2::Model.settings[:foo] = 'bar' }
          assert_equal 'bar', ElasticsearchV2::Model.settings[:foo]
        end
    end

  end
end
