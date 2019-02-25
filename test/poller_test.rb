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
    my_poller = SqsHelper::Poller.new(@connector, @queue, wait_time_seconds: 0.1)
    poller = my_poller.aws_poller
    messages = (1..10).collect do
      "x" * (rand(100) + 1)
    end
    @message_lengths = Array.new
    messages.each {|message| @connector.send_message(@queue, message)}
    p = Proc.new {|message| @message_lengths << message.length}
    t = Thread.new do
      my_poller.start_polling(p)
      # poller.poll(wait_time_seconds: 0.1) do |message, stats|
      #   p.call(message)
      #   #@message_lengths << message.body.length
      #end
    end

    sleep 1
    assert_equal messages.collect {|message| message.length}, @message_lengths
    my_poller.stop_polling
    t.join
  end

end