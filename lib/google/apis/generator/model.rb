# Copyright 2015 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'active_support/inflector'
require 'google/apis/discovery_v1'

# Extend the discovery API classes with additional data needed to make
# code generation produce better results
module Google
  module Apis
    module DiscoveryV1
      TYPE_MAP = {
        'string' => 'String',
        'boolean' => 'Boolean',
        'number' => 'Float',
        'integer' => 'Fixnum',
        'any' => 'Object'
      }

      class JsonSchema
        attr_accessor :name
        attr_accessor :generated_name
        attr_accessor :generated_class_name
        attr_accessor :base_ref
        attr_accessor :parent
        attr_accessor :discriminant
        attr_accessor :discriminant_value
        attr_accessor :path

        def properties
          @properties ||= {}
        end

        def qualified_name
          parent.qualified_name + '::' + generated_class_name
        end

        def generated_type
          case type
          when 'string', 'boolean', 'number', 'integer', 'any'
            return 'DateTime' if format == 'date-time'
            return 'Date' if format == 'date'
            return TYPE_MAP[type]
          when 'array'
            return sprintf('Array<%s>', items.generated_type)
          when 'hash'
            return sprintf('Hash<String,%s>', additional_properties.generated_type)
          when 'object'
            return qualified_name
          end
        end
      end

      class RestMethod
        attr_accessor :generated_name
        attr_accessor :parent

        def path_parameters
          return [] if parameter_order.nil? || parameters.nil?
          parameter_order.map { |name| parameters[name] }.select { |param| param.location == 'path' }
        end

        def query_parameters
          return [] if parameters.nil?
          parameters.values.select { |param| param.location == 'query' }
        end
      end

      class RestResource
        attr_accessor :parent

        def all_methods
          m = []
          m << api_methods.values unless api_methods.nil?
          m << resources.map { |_k, r| r.all_methods } unless resources.nil?
          m.flatten
        end
      end

      class RestDescription
        def version
          ActiveSupport::Inflector.camelize(@version.gsub(/\W/, '-')).gsub(/-/, '_')
        end

        def name
          ActiveSupport::Inflector.camelize(@name)
        end

        def module_name
          name + version
        end

        def qualified_name
          sprintf('Google::Apis::%s', module_name)
        end

        def service_name
          class_name = (canonical_name || name).gsub(/\W/, '')
          ActiveSupport::Inflector.camelize(sprintf('%sService', class_name))
        end

        def all_methods
          m = []
          m << api_methods.values unless api_methods.nil?
          m << resources.map { |_k, r| r.all_methods } unless resources.nil?
          m.flatten
        end

        class Auth
          class Oauth2
            class Scope
              attr_accessor :constant
            end
          end
        end
      end
    end
  end
end
