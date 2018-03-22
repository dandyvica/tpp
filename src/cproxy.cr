require "./cproxy/*"
require "logger"
require "http/server"

require "socket"
require "openssl"

# default configuration file
CONFIG_GILE = "config/tpp.yml"

# reads configuration file and returns the cfg structure
cfg = Config.new(CONFIG_GILE)
p cfg

# this port is read from config file
port_number = cfg.port

# manage http server
server = HTTP::Server.new(port_number) do |context|
  # defined useful variables
  user_agent = context.request.headers["User-Agent"]

  url = context.request.resource
  host = URI.parse(url).host 

  uri = URI.parse(context.request.resource)

  method = context.request.method

  # start logging request
  cfg.log.debug("[client->proxy] #{method} #{url}")

  # if url denied?
  if cfg.deny.is_url_denied?(url)
    # send back deny error code to client
    context.response.status_code = 501
    context.response.print "Denied"
    cfg.log.info("[client->proxy] DENY #{method} #{url}")

    # loop to handle next request
    next 
  end

  # process each method individually
  case context.request.method
    
  # GET is the most common verb
  when "GET"
    client = HTTP::Client.new(uri)

    # weird behaviour for managing zlib data
    client.compress = false
    if context.request.headers.has_key?("Accept-Encoding")
      context.request.headers.delete("Accept-Encoding")
    end

    response = client.get(url, headers=context.request.headers)
    cfg.log.info("[client->proxy] sent headers #{context.request.headers}")
    

    # build request to endpoint
    # response = HTTP::Client.get(
    #   url=context.request.resource,
    #   headers=context.request.headers
    # )
    cfg.log.info("[endpoint->proxy] #{context.request.resource} HTTP_#{response.status_code}")
    
    # build response to send back to client
    response.headers.each {|k, v| context.response.headers[k] = v }
    context.response.status_code = response.status_code
    context.response.print(response.body)
    context.response.flush

    cfg.log.info("[proxy->client] HTTP_#{response.status_code}")
  
  # CONNECT is send when client connect using https
  when "CONNECT"
    cfg.log.info("HTTP method #{context.request.method} denied for #{context.request.resource}")
    
    context.response.status_code = 200
    context.response.print("Connection Established")
    context.response.flush

    socket = TCPSocket.new("www.apple.com", 443)
    p socket
    context = OpenSSL::SSL::Context::Client.new
  
    ssl_socket = OpenSSL::SSL::Socket::Client.new(socket, context)
    p ssl_socket

  # other methods are denied
  else
    context.response.status_code = 501
    context.response.print "Denied"
    cfg.log.info("HTTP method #{context.request.method} denied for #{context.request.resource}")
  end


  
end

# start logging
cfg.log.info("--------------> Starting server, listening on http://127.0.0.1:#{port_number}")

# start server really here
server.listen


