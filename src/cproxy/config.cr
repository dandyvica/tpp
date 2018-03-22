require "logger"
require "yaml"
require "http/request"


class Deny
    # list of denied urls in basic form
    property url_basic : Array(String)

    # list of denied urls but more sophisticated by using regexes
    property url_fancy : Array(Regex)

    # list of denies methods
    property method : Array(String)

    def initialize
        @url_basic = Array(String).new
        @url_fancy = Array(Regex).new
        @method = Array(String).new
    end

    # Returns **true** if the **url** parameter is found in any of the deny list
    def is_url_denied?(url : String) : Bool
        @url_basic.any?{|u| url.includes?(u) } ||
        @url_fancy.any?{|u| u.match(url) }
    end

    # Returns **true** if the **mzthod** parameter is found in the deny list
    def is_method_denied?(method : String) : Bool
        @method.includes?(method)
    end     
end

# Represents the global configuration used throughout the proxy
class Config
    # port number to bind the proxy
    @port : Int32

    # logger build from YAML configuration
    @log : Logger

    # list of denied objects
    property deny : Deny

    # port number to bind the proxy
    getter port

    # log handle
    getter log

    # Builds the configuration settings which controls URL filtering
    def initialize(cfg_file : String)
        # read YAML file one shot
        @cfg_file = cfg_file
        @data = YAML.parse(File.read(cfg_file))

        # save port number
        @port = @data["port"].as_i

        # manage denied stuff
        @deny = Deny.new

        # build list of URLs regexes from what is found in the configuration file
        @deny.url_basic = @data["url_deny"]["basic"].map{|u| u.as_s}

        # build list of URLs regexes from what is found in the configuration file
        @deny.url_fancy = @data["url_deny"]["fancy"].map{|u| Regex.new(u.as_s)}

        # build the list of methods to deny
        @deny.method = @data["method_deny"].map{|u| u.as_s}        

        # build the logger
        @log = Logger.new(File.new(@data["log"]["file"].as_s, "a"))
        @log.level = Logger::DEBUG
        @log.formatter = Logger::Formatter.new {|severity, datetime, progname, message, io|
            label = severity.unknown? ? "ANY" : severity.to_s
            io << datetime << " [" << label.rjust(5) << "] " << message
        }


    end
    
    # Checks whether a request coming from client should be denied. It could be denied
    # because of undesired URLs, unwanted methods, etc.
    def is_request_denied?(request : HTTP::Request) : Bool
        # check method first
        if deny.is_method_denied?(request.method) 
            @log.info("[client->proxy] METHOD DENIED #{request.method}")
            return true
        end

        # check URL
        if deny.is_url_denied?(request.resource)
            @log.info("[client->proxy] URL DENIED #{request.method} #{request.resource}")
            return true
        end 
        
        false
    end    

end