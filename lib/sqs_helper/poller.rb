module SqsHelper
  class Poller

    attr_accessor :connector, :aws_poller, :end_polling_flag, :wait_time_seconds, :unparsed_messages,
                  :logger, :queue_name, :visibility_timeout

    def initialize(connector, queue_name, args = {})
      self.connector = connector
      self.aws_poller = connector.create_aws_poller(queue_name)
      self.end_polling_flag = false
      self.wait_time_seconds = args[:wait_time_seconds] || 60
      self.unparsed_messages = args[:unparsed_messages]
      self.queue_name = queue_name
      self.visibility_timeout = args[:visibility_timeout]
      initialize_logger(args[:logger])
      initialize_aws_poller
    end

    def initialize_aws_poller
      aws_poller.before_request do
        throw :stop_polling if self.end_polling_flag
      end
    end

    def initialize_logger(maybe_logger)
      self.logger = if maybe_logger
                      maybe_logger
                    elsif defined?(Rails) and Rails.respond_to?(:logger)
                      Rails.logger
                    else
                      nil
                    end
    end

    def stop_polling
      self.end_polling_flag = true
    end

    def start_polling(action_callback, args = {})
      logger.info "Starting SQS polling for #{queue_name}" if logger
      aws_poller.poll(wait_time_seconds: wait_time_seconds, visibility_timeout: visibility_timeout) do |message, stats|
        payload = message.body
        begin
          payload = JSON.parse(payload) unless self.unparsed_messages
          action_callback.call(payload)
        rescue Exception => e
          logger.error "Failed to handle #{queue_name} response #{payload}: #{e}" if logger
        end
      end
    end

  end
end