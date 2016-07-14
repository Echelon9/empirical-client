require 'hashie'

module Empirical
  module Client
    class Endpoint < ::Hashie::Mash
      include Hashie::Extensions::Mash::SafeAssignment

      attr_accessor :id, :token, :client, :config, :api_base

      def initialize(options = {})
        super

        @id = options.fetch(:id, nil)
        @config = Empirical::Client.configuration
        @api_base = "#{config.api_host}/api/v1".gsub(%r{(?<!:)//}, "/")
      end


      # class methods for singleton access

      class << self

        attr_accessor :endpoint_path, :api_key_list

        def api_keys(*keys)
          @api_key_list ||= keys.flatten
        end

        def endpoint_name(name)
          @endpoint_path = name
        end

        def inherited(subclass)
          super
          subclass.api_keys(api_key_list) unless api_key_list.nil?
          subclass.endpoint_name(endpoint_path)
        end

        def attributes(*args)
          #FIXME - noop currently

        end

        # gets a list of all items, paginate style
        def all(limit = 25, offset = 0)
          raise NotImplementedError
        end

        # finds an item for a single id
        def find(id, params = {})
          item = new(uid: id)
          item.request(:get, "#{endpoint_path}/#{id}")
        end

      end

      def as_json
        rv = {data: {}}

        self.class.api_keys.each { |x| rv[x] = self.send(x) }
        data_keys.map { |x| rv[:data][x] = self.send(x).to_yaml }
        return rv
      end

      def to_json
        JSON.dump(as_json)
      end

      def save
        tries ||= 3

        begin
          result = self.id.nil? ? post : put

        rescue Faraday::ConnectionFailed => e
          # download failed
          @config.logger.warn "API Connection Failed, try: #{3- tries} - #{e}"
          retry unless (tries -= 1).zero?

          raise Empirical::Client::ApiException.new("API Connection Failed - #{e}")
        rescue Faraday::TimeoutError => e
          # api timed out
          @config.logger.warn "API Timed Out, try: #{3- tries} - #{e}"
          retry unless (tries -= 1).zero?

          raise Empirical::Client::ApiException.new("API Connection Timed Out - #{e}")
        end

        # process the response
        case result.status

        when 200..310

          self.merge!(result.body)

          if meta.status == 'success'
            return self
          else
            raise Empirical::Client::EndpointException.new("message: #{meta.message}")
          end
        when 404
          raise Empirical::Client::EndpointException.new("Missing Record")
        else
          raise Empirical::Client::ApiException.new("[Status: #{result.status}] Missing response body or API failure")
        end

      end

      def request(verb, path)
        tries ||= 3

        begin
          result = client.send(verb, path) do |req|

            yield if block_given?
          end
        rescue Faraday::ConnectionFailed => e
          # download failed
          @config.logger.warn "API Connection Failed, try: #{3- tries} - #{e}"
          retry unless (tries -= 1).zero?

          raise Empirical::Client::ApiException.new("API Connection Failed - #{e}")
        rescue Faraday::TimeoutError => e
          # api timed out
          @config.logger.warn "API Timed Out, try: #{3- tries} - #{e}"
          retry unless (tries -= 1).zero?

          raise Empirical::Client::ApiException.new("API Connection Timed Out - #{e}")
        rescue Faraday::ParsingError => e
          @config.logger.warn "API Parsing Error: #{e}"
          raise Empirical::Client::ApiException.new("API Parsing Error - #{e}")

        end

        # process the response
        case result.status

        when 200..310

          self.merge!(result.body)

          if meta.status == 'success'
            return self
          else
            raise Empirical::Client::EndpointException.new("message: #{meta.message}")
          end
        when 404
          raise Empirical::Client::EndpointException.new("Missing Record")
        else
          raise Empirical::Client::ApiException.new("[Status: #{result.status}] Missing response body or API failure")
        end

      end

      private

      def data_keys
        keys.map(&:to_sym) - ignored_keys - self.class.api_keys
      end

      def ignored_keys
        # don't persist these over the air
        [self.class.endpoint_path.singularize.to_sym, :meta, :id]
      end

      def post
        client.post do |req|
          req.url self.class.endpoint_path
          req.headers['Content-Type'] = 'application/json'
          req.body = self.to_json
        end
      end

      def put
        client.put do |req|
          req.url "#{self.class.endpoint_path}/#{id}"
          req.headers['Content-Type'] = 'application/json'
          req.body = self.to_json
        end
      end

      def client
        @client ||= Faraday.new @api_base do |conn|
          conn.request :oauth2, @config.access_token
          conn.request :json

          conn.response :json, content_type: /\bjson$/

          conn.adapter :patron # Faraday.default_adapter
        end
      end
    end
  end
end

