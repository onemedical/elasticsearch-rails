require 'test_helper'

class ElasticsearchV2::Model::BaseTest < Test::Unit::TestCase
  context "Response base module" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    class DummyBaseClass
      include ElasticsearchV2::Model::Response::Base
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [] } }

    setup do
      @search   = ElasticsearchV2::Model::Searching::SearchRequest.new OriginClass, '*'
      @response = ElasticsearchV2::Model::Response::Response.new OriginClass, @search
      @search.stubs(:execute!).returns(RESPONSE)
    end

    should "access klass, response, total and max_score" do
      r = DummyBaseClass.new OriginClass, @response

      assert_equal OriginClass, r.klass
      assert_equal @response, r.response
      assert_equal RESPONSE,  r.response.response
      assert_equal 123, r.total
      assert_equal 456, r.max_score
    end

    should "have abstract methods results and records" do
      r = DummyBaseClass.new OriginClass, @response

      assert_raise(ElasticsearchV2::Model::NotImplemented) { |e| r.results }
      assert_raise(ElasticsearchV2::Model::NotImplemented) { |e| r.records }
    end

  end
end
