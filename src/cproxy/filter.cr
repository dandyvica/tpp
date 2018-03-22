require "http/server"

module UrlFilter

# Checks whether a request coming from client should be denied. It could be denied
# because of undesired URLs, unwanted methods, etc.
def is_request_denied?(request : Request) : Bool

end

end