require_relative 'connector'

module SqsHelper
  class ConnectorSet

    attr_accessor :connectors

    def initialize
      self.connectors = Hash.new
    end

    def create_connector(key, config)
      connectors[key] = Connector.new(config)
    end

    def add_connector(key, connector)
      connectors[key] = connector
    end

    def delete_connector(key)
      connectors.delete(key)
    end

    def at(key)
      connectors[key]
    end

    def [](key)
      at(key)
    end

  end
end