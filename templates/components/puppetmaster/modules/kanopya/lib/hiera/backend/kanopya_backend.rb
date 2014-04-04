# Class Kanopya_backend
# Description: Kanopya REST back end to Hiera.
# Author: Sylvain Baubeau <sylvain.baubeau@hederatech.com>
#
class Hiera
  module Backend
    class Kanopya_backend

      require 'active_support'
      @@cache = ActiveSupport::Cache::MemoryStore.new()

      def initialize
        require "net/https"   # use instead of rest-client so we can set SSL options

        # I think this connection can be reused like this. If not, move it to the query and make it local
        @http = Net::HTTP.new(Config[:kanopya][:server], Config[:kanopya][:port])

        if Config[:kanopya].has_key?(:cacrt)
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  
          store = OpenSSL::X509::Store.new
          store.add_cert(OpenSSL::X509::Certificate.new(File.read(Config[:kanopya][:cacrt])))
          @http.cert_store = store
  
          @http.key = OpenSSL::PKey::RSA.new(File.read(Config[:kanopya][:crt]))
          @http.cert = OpenSSL::X509::Certificate.new(File.read(Config[:kanopya][:crtkey]))
        else
          @http.use_ssl = false
        end

        url = "/login?login=#{Config[:kanopya][:login]}&password=#{Config[:kanopya][:password]}"
        request = Net::HTTP::Post.new(url)
        response = @http.request(request)

        @cookie = response['Set-Cookie']
        debug("Got cookie #{@cookie}")

        debug ("Loaded Kanopya_backend")
      end

      def debug(msg)
        Hiera.debug("[REST]: #{msg}")
      end

      def warn(msg)
        Hiera.warn("[REST]:  #{msg}")
      end

      def lookup(key, scope, order_override, resolution_type)
        debug("Looking up '#{key}', resolution type is #{resolution_type}")
        answer = nil
        data = nil

        Backend.datasources(scope, order_override) do |source|
          debug("Looking for data in #{source}")

          case source
          when /kanopya\/([^\/]*)$/
            fqdn = "#{$1}"
            hostname = fqdn.split('.')[0]

            if key != 'components'
              data = @@cache.fetch(fqdn)
            end

            if data == nil
              data = restquery(hostname)
              @@cache.write(fqdn, data)
            end
          else
            debug("Got a query we can't handle yet!")
            next
          end

          # if we want to support array responses, this will have to be more intelligent
          next unless data.include?(key)
          debug ("Key '#{key}' found in REST response, Passing answer to hiera")

          parsed_answer = Backend.parse_answer(data[key], scope)

          begin
            case resolution_type
            when :array
              debug("Appending answer array")
              raise Exception, "Hiera type mismatch: expected Array and got #{parsed_answer.class}" unless parsed_answer.kind_of? Array or parsed_answer.kind_of? String
              answer ||= []
              answer << parsed_answer
            when :hash
              debug("Merging answer hash")
              raise Exception, "Hiera type mismatch: expected Hash and got #{parsed_answer.class}" unless parsed_answer.kind_of? Hash
              answer ||= {}
              answer = parsed_answer.merge answer
            else
              debug("Assigning answer variable")
              answer = parsed_answer
              break
            end
          rescue NoMethodError
            raise Exception, "Resolution type is #{resolution_type} but parsed_answer is a #{parsed_answer.class}"
          end
        end

        return answer
      end

      def restquery(node)

        query = "#{Config[:kanopya][:api]}/api/node?expand=puppet_manifest&node_hostname=#{node}"
        debug("Query: #{query}")
        request = Net::HTTP::Get.new("#{query}")
        request["Cookie"] = @cookie
        response = ActiveSupport::JSON.decode(@http.request(request).body)

        return response.length ? response[0]["puppet_manifest"] : {}
      end
    end
  end
end
