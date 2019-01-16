require 'test_helper'

class ElasticsearchV2::Model::ResultsTest < Test::Unit::TestCase
  context "Response results" do
    class OriginClass
      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end

    RESPONSE = { 'hits' => { 'total' => 123, 'max_score' => 456, 'hits' => [{'foo' => 'bar'}] } }

    setup do
      @search   = ElasticsearchV2::Model::Searching::SearchRequest.new OriginClass, '*'
      @response = ElasticsearchV2::Model::Response::Response.new OriginClass, @search
      @results  = ElasticsearchV2::Model::Response::Results.new  OriginClass, @response
      @search.stubs(:execute!).returns(RESPONSE)
    end

    should "access the results" do
      assert_respond_to @results, :results
      assert_equal 1, @results.results.size
      assert_equal 'bar', @results.results.first.foo
    end

    should "delegate Enumerable methods to results" do
      assert ! @results.empty?
      assert_equal 'bar', @results.first.foo
    end

  end
end
