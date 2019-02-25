require "sqs_helper/version"

module SqsHelper
  autoload(:Connector, 'sqs_helper/connector')
  autoload(:Poller, 'sqs_helper/poller')
end
