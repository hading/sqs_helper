module SqsHelper
  class Poller

    attr_accessor :connector, :aws_poller, :end_polling_flag, :wait_time_seconds

    def initialize(connector, queue_name, args = {})
      self.connector = connector
      self.aws_poller = connector.create_aws_poller(queue_name)
      self.end_polling_flag = false
      self.wait_time_seconds = args[:wait_time_seconds] || 60
      initialize_aws_poller
    end

    def initialize_aws_poller
      aws_poller.before_request do
        throw :stop_polling if self.end_polling_flag
      end
    end

    def stop_polling
      self.end_polling_flag = true
    end

    def start_polling(action_callback, args = {})
      aws_poller.poll(wait_time_seconds: wait_time_seconds) do |message, stats|
        action_callback.call(message.body)
      end
    end

  end
end