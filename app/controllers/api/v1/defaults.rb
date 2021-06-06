module Api
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix 'api'
        version 'v1', using: :path
        default_format :json
        format :json
        formatter :json,
                  Grape::Formatter::ActiveModelSerializers

        helpers do
          def current_entity
            @current_entity || Entity.find_by(subdomain: subdomain)
          end

          def current_user
            @current_user
          end

          # def try_authenticate!
          #   begin
          #     unless headers['Authorization'].empty?
          #       decoded = JsonWebToken.decode(headers['Authorization'])
          #       resource_class = decoded[:resource_type].constantize
          #       user = resource_class.find(decoded[:resource_id])
          #       authenticate!
          #     end
          #   rescue => exception
          #     # Do nothing
          #   end
          # end

          def authenticate!
            error!('Authorization header is required', :unauthorized) unless headers['Authorization']
            @decoded = JsonWebToken.decode(headers['Authorization'])

            if subdomain && subdomain != @decoded[:subdomain]
              error!('Invalid authorization token', :unauthorized)
            end

            @current_entity = Entity.find_by!(subdomain: @decoded[:subdomain])
            resource_class = @decoded[:resource_type].constantize
            @current_user = resource_class.find(@decoded[:resource_id])
          rescue ActiveRecord::RecordNotFound => e
            error!('Invalid authorization token', :unauthorized)
          rescue JWT::DecodeError => e
            error!('Invalid authorization token', :unauthorized)
          end

          def permitted_params
            @permitted_params ||= declared(params,
                                           include_missing: false)
          end

          def logger
            Rails.logger
          end

          def subdomain
            ActionDispatch::Http::URL.extract_subdomains(request.env['SERVER_NAME'], Settings.tld_length).first
          end
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          error_response(message: e.message, status: 404)
        end

        rescue_from ActiveRecord::RecordInvalid do |e|
          error_response(message: e.message, status: 422)
        end
      end
    end
  end
end
