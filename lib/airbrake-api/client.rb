module Airbrake
  class Base
    include HTTParty
    format :xml

    private

    def self.setup
      base_uri Airbrake.account_path
      default_params :auth_token => Airbrake.auth_token

      check_configuration
    end

    def self.check_configuration
      raise AirbrakeError.new('API Token cannot be nil') if default_options.nil? || default_options[:default_params].nil? || !default_options[:default_params].has_key?(:auth_token)
      raise AirbrakeError.new('Account cannot be nil') unless default_options.has_key?(:base_uri)
    end

    def self.fetch(path, options)
      response = get(path, { :query => options })
      if response.code == 403
        raise AirbrakeError.new('SSL should be enabled - use Airbrake.secure = true in configuration')
      end

      Hashie::Mash.new(response)
    end

  end
end

# airbrake sometimes returns broken xml with strange utmz stuff
# so we remove this
require 'httparty/parser'
class HTTParty::Parser
  alias utmz_unaware_xml xml
  def xml
    body.gsub!(/<__utmz>.*?<\/__utmz>/m,'')
    utmz_unaware_xml
  end
end
