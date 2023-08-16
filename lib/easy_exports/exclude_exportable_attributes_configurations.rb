# frozen_string_literal: true

module EasyExports
  module ExcludeExportableAttributesConfigurations
    extend ActiveSupport::Concern

    class_methods do
      private

      def exclude_exportable_attributes(association_attributes = {})
        validate_exclude_exportable_attributes_argument(association_attributes)
        association_attributes.transform_values! { |values| values.map(&:to_s) }

        validate_association_attributes(association_attributes, 'exclude_exportable_attributes')

        excluded_exportable_attributes_store.merge!(
          underscored_self_name => association_attributes.stringify_keys
        )
      end

      def validate_association_attributes(association_attributes, method = '')
        association_attributes.each do |association_name, attributes|
          association = association_from_self_with_association(association_name)

          if association.blank?
            next if association_name.to_s.downcase == 'all'

            raise ArgumentError,
                  "#{method} argument key '#{association_name}' is not an association for #{underscored_self_name} model"
          end

          invalid_attributes = attributes - association.class_name.constantize.attribute_names
          next if invalid_attributes.empty?

          raise ArgumentError, "#{method} #{invalid_attributes.join(', ')} not defined for #{association.name}"
        end
      end

      def validate_exclude_exportable_attributes_argument(argument, method_name = 'exclude_exportable_attributes')
        raise 'Argument for exclude_exportable_attributes has to be a hash' unless argument.is_a? Hash

        argument.to_a.each do |arg|
          case arg
          in [*, [*]] if arg[1].all? { |element| [String, Symbol].include? element.class }
            next
          else
            raise ArgumentError, "Invalid Arguments pattern for #{method_name}"
          end
        end
      end
    end
  end
end

ActiveRecord::Base.include EasyExports::ExcludeExportableAttributesConfigurations
