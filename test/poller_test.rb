require_relative 'test_helper'

class PollerTest < Minitest::Test

  def setup
    @connector = SqsHelper::Connector.new(aws_key_id: 'key_id', aws_secret_key: 'secret_key',
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
    messages = (1..10).collect do
      "x" * (rand(100) + 1)
    end
    @message_lengths = Array.new
    messages.each {|message| @connector.send_message(@queue, message)}
    t = Thread.new do
      poller.poll(wait_time_seconds: 0.1) do |message, stats|
        @message_lengths << message.body.length
      end
    end
    sleep 0.2
    assert_equal messages.collect {|message| message.length}, @message_lengths
    @end_polling = true
    t.join
  end

end