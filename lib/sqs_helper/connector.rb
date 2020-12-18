require 'json'
require 'aws-sdk-sqs'

module SqsHelper
  class Connector < Object
    attr_accessor :queue_urls, :endpoint, :region, :client

    def initialize(config)
      config_hash = config.to_h
      config_hash = config_hash.symbolize_keys if config_hash.respond_to?(:symbolize_keys)
      self.queue_urls = Hash.new
      self.endpoint = config_hash[:endpoint]
      self.region = config_hash[:region]
      initialize_client
    end

    def initialize_client
      self.client = Aws::SQS::Client.new(endpoint: endpoint, region: region)
    end

    def clear_all_queues
      self.clear_queues(*queue_names.to_a)
    end

    def queue_names
      self.queue_urls.keys
    end

    def clear_queues(*queue_names)
      queue_names.each do |queue_name|
        clear_queue(queue_name)
      end
    end

    def clear_queue(queue_name)
      while true
        with_message(queue_name) do |message|
          return unless message
          puts "#{self.class} clearing: #{message} from: #{queue_name}" if message
        end
      end
    end

    def with_message(queue_name)
      with_queue(queue_name) do |queue_url|
        messages = client.receive_message(queue_url: queue_url, max_number_of_messages: 1).messages
        message = messages[0]
        if message
          client.delete_message(queue_url: queue_url, receipt_handle: message.receipt_handle)
          yield message.body
        else
          yield nil
        end
      end
    end

    def with_parsed_message(queue_name)
      with_message(queue_name) do |message|
        json_message = message ? JSON.parse(message) : nil
        yield json_message
      end
    end

    def send_message(queue_name, message)
      with_queue(queue_name) do |queue_url|
        message = message.to_json if message.is_a?(Hash)
        client.send_message(queue_url: queue_url, message_body: message)
      end
    end

    def with_queue(queue_name)
      unless queue_urls[queue_name]
        queue_urls[queue_name] = get_queue_url(queue_name)
      end
      yield queue_urls[queue_name]
    end

    def get_queue_url(queue_name)
      client.get_queue_url(queue_name: queue_name).queue_url
    rescue Aws::SQS::Errors::NonExistentQueue
      client.create_queue(queue_name: queue_name).queue_url
    end

    def create_aws_poller(queue_name)
      with_queue(queue_name) do |queue_url|
        Aws::SQS::QueuePoller.new(queue_url, client: client)
      end
    end

  end

end