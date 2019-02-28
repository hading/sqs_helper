require_relative 'test_helper'

class ConnectorTest < Minitest::Test

  def setup
    @connection_args = {aws_key_id: 'key_id', aws_secret_key: 'secret_key',
                        endpoint: 'http://localhost:9324', region: 'us-east-2'}
    @connector = SqsHelper::Connector.new(@connection_args)
    @queue = 'sqs_helper_test'
  end

  def teardown
    @connector.clear_all_queues
  end

  def test_send_and_receive_message
    @connector.send_message(@queue, 'raw_message')
    @connector.with_message(@queue) do |payload|
      assert_equal 'raw_message', payload
    end
  end

  def test_send_and_receive_json_message
    message_hash = {'key' => 'value', 'other_key' => 'other_value'}
    @connector.send_message(@queue, message_hash)
    @connector.with_parsed_message(@queue) do |received_message|
      assert received_message.is_a?(Hash)
      assert_equal 'value', received_message['key']
      assert_equal 'other_value', received_message['other_key']
    end
  end

  def test_get_message_from_empty_queue
    @connector.with_message(@queue) do |payload|
      assert_nil payload
    end
  end

  def test_get_json_message_from_empty_queue
    @connector.with_parsed_message(@queue) do |payload|
      assert_nil payload
    end
  end

  def test_connector_set
    connector_set = SqsHelper::ConnectorSet.new
    connector_set.create_connector(:key, @connection_args)
    assert_equal SqsHelper::Connector, connector_set.at(:key).class
    assert_equal connector_set[:key], connector_set.at(:key)
    connector_set.add_connector(:existing, @connector)
    assert_equal @connector, connector_set.at(:existing)
    connector_set.delete_connector(:key)
    assert_equal nil, connector_set.at(:key)
  end

end