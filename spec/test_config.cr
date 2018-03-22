require "spec"
require "../src/cproxy/config"

describe "Config" do
    cfg = Config.new("config/tpp.yml")

    describe "#is_method_denied?" do
        it "GET is not a denied method" do
            cfg.is_method_denied?("GET").should be_false
        end

        it "DELETE is a denied method" do
            cfg.is_method_denied?("DELETE").should be_true
        end        
    end


    describe "#is_url_denied?" do
        it "www.google.com is not a denied URL" do
            cfg.is_url_denied?("www.google.com").should be_false
        end

        it "www.doubleclick.net is a denied URL" do
            cfg.is_url_denied?("www.doubleclick.net").should be_true
        end  
        
        it "www.fancy-ads.com is a fancy denied URL" do
            cfg.is_url_denied?("www.fancy-ads.com").should be_true
        end         
    end    


end