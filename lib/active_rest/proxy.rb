module ActiveRest
  class Proxy
    attr_reader :model, :routes

    def initialize model
      @model  = model
    end

    def routes
      @routes ||= {}
    end

    def list limit = 20, offset = 1, options = {}
      route  = routes[:list]
      response = @model.connection.send( route.method, path_replace_variables(options, route.path), { route.options[:offset] => offset.to_i, route.options[:limit] => limit.to_i } )
      route.valid_response(response)
      response
    end

    def find options = {}
      route  = routes[:find]
      response = @model.connection.send( route.method, path_replace_variables(options, route.path), route.options)
      route.valid_response(response)
      response
    end

    def create obj
      route = routes[:create]
      response = method_with_body(route, obj)
      route.valid_response(response)
      response
    end

    def update obj
      route = routes[:update]
      response = method_with_body(route, obj)
      route.valid_response(response)
      response
    end

    def destroy obj
      route  = routes[:destroy]
      response = @model.connection.send( route.method, path_replace_variables(obj, route.path), route.options)
      route.valid_response(response)
      response
    end

    private
      def path_replace_variables object, path       
        splited = path.split('/')

        new_path = splited.map do |key|
          if key[0] == ':'
            key_spplited = key.gsub(':', '').split('.')
            
            new_key = key_spplited.shift
            if object.is_a? Hash
              new_value = object[new_key.to_s] || object[new_key.to_sym]
            else
              new_value = object.send(new_key)
            end

            key_spplited.each do |k|
              new_value = new_value.send(k)
            end

            new_value
          else
            key
          end
        end

        new_path.join('/')
      end

      def method_with_body route, obj
        body = obj.to_remote
        body = body.slice(*obj.changes.keys) if route.method == :patch

        if route.options[:data_type] == :json
          body = body.to_json
          route.headers = { 'Content-Type' => 'application/json' }.merge(route.headers)
        end

        @model.connection.send(route.method, path_replace_variables(obj, route.path), body, route.headers)
      end
  end
end