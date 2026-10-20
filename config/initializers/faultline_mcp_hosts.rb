# frozen_string_literal: true

# Faultline builds its MCP transport without allowed_hosts, so the mcp gem's
# DNS-rebinding protection rejects every non-loopback Host header with
# "Forbidden: Invalid Host header". Rebuild the transport with our public host.
Rails.application.config.after_initialize do
  next unless defined?(Faultline::Mcp)

  Faultline::Mcp.singleton_class.prepend(Module.new do
    private

    def build_transport
      require 'mcp'
      require 'mcp/server/transports/streamable_http_transport'
      ::MCP::Server::Transports::StreamableHTTPTransport.new(
        ::MCP::Server.new(name: Faultline::Mcp::SERVER_NAME, tools: build_mcp_tools),
        stateless: true,
        allowed_hosts: ['mytravelleruniverse.net']
      )
    end
  end)
end
