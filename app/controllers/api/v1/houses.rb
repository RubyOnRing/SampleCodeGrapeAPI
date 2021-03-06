module Api
  module V1
    class Houses < Base
      include Api::V1::Defaults
      before do
        authenticate!
      end

      resource :houses do
        desc 'Return all houses'
        params do
          requires :entity_subdomain, type: String, desc: 'Entity subdomain'
        end

        get '', root: :houses do
          authorize! :read, House
          current_entity.houses.ransack(params).result(distinct: true).order(created_at: :desc)
                        .page(params[:page]).per(12)
        end

        desc 'Create house'
        params do
          requires :house, type: Hash do
            requires :contract_id, type: Integer
            requires :deposit, type: Float
            requires :rent_price, type: Float
            requires :max_people_allowed, type: Integer
            optional :house_number, type: String
            optional :name, type: String
            optional :address, type: String
            optional :city, type: String
            optional :post_code, type: String
            optional :status, type: String
            optional :description, type: String
            optional :start_hiring_date, type: DateTime
            optional :state, type: String
          end
        end

        post '', root: :houses do
          house = current_user.houses.new permitted_params[:house]
          authorize! :create, house
          if house.save
            house
          else
            error!({ messages: house.errors.messages }, 422)
          end
        end

        desc 'Update house'
        params do
          requires :house, type: Hash do
            requires :house_number, type: String
            optional :name, type: String
            optional :street, type: String
            optional :city, type: String
            optional :post_code, type: String
            optional :max_people, type: Integer
            optional :status, type: String
            optional :description, type: String
            optional :start_at,   type: DateTime
            optional :deposit_amount, type: Integer
            optional :price, type: Integer
            optional :length_of_contract, type: Integer
            optional :state, type: String
          end
        end

        patch '/:id', root: :houses do
          house = current_entity.houses.find(params[:id])
          authorize! :update, House
          house.update!(permitted_params[:house])
          house
        end

        desc 'Destroy house'
        delete '/:id', root: :houses do
          house = current_entity.houses.find(params[:id])
          authorize! :destroy, House
          house.destroy!
        end
      end
    end
  end
end
