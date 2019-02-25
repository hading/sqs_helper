require_relative 'test_helper'

class PollerTest < Minitest::Test

  def setup
    @connector = SqsHelper::Connector.new( aws_key_id: 'key_id', aws_secret_key: 'secret_key',
                                           endpoint: 'http://localhost:9324', region: 'us-east-2')
    @queue = 'sqs_helper_polling_test'
  end

  def teardown
    @connector.clear_all_queues
  end

  def test_create_and_use_poller
    poller = @connector.create_aws_poller(@queue)
    @end_polling = false
    poller.before_request do
      throw :stop_polling if @end_polling
    end
    message = 'joebob'
    @message_length = nil
    @connector.send_message(@queue, message)
    poller.poll(wait_time_seconds: 0.1) do |message, stats|
      @message_length = message.body.length
      @end_polling = true
    end
    sleep 0.2
    assert_equal 6, @message_length
  end

end