require_relative "sqs_helper/version"

module SqsHelper
  autoload(:Connector, 'sqs_helper/connector')
  autoload(:ConnectorSet, 'sqs_helper/connector_set')
  autoload(:Poller, 'sqs_helper/poller')
end
