# frozen_string_literal: true

module EasyExports
  module ExcludeAssociationsConfigurations
    extend ActiveSupport::Concern

    class_methods do
      private

      # associations to exclude methods
      def associations_to_exclude(associations = [])
        validate_associations_to_exclude_argument(associations)

        associations.map! do |association|
          association_name = association.to_s.downcase

          association_name.tap do |name|
            if association_from_self_with_association(name).blank?
              raise ArgumentError,
                    "associations_to_exclude array argument '#{name}' is not an association for #{underscored_self_name} model"
            end
          end
        end

        associations_to_exclude_store.merge!(
          underscored_self_name => associations
        )
      end

      def validate_associations_to_exclude_argument(argument)
        raise 'Argument for associations_to_exclude has to be an array' unless argument.is_a? Array

        return if argument.all? { |element| [String, Symbol].include? element.class }

        raise 'Argument array for associations_to_exclude has to be either string or Symbol'
      end
    end
  end
end

ActiveRecord::Base.include EasyExports::ExcludeAssociationsConfigurations
