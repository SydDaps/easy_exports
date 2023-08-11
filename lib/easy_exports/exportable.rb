# frozen_string_literal: true

module EasyExports
  module Exportable
    extend ActiveSupport::Concern

    class_methods do
      cattr_accessor :associations_aliases_store, default: {}, instance_writer: false
      cattr_accessor :associations_to_exclude_store, default: {}, instance_writer: false
      cattr_accessor :excluded_exportable_attributes_store, default: {}, instance_writer: false

      def exportable_fields
        self_with_associations.each_with_object({}) do |association, fields|
          association_name = association.name.to_s.downcase
          next if associations_to_exclude_store[underscored_self_name].include? association_name

          association_attributes = attributes_for_association(association)

          association_name = resolve_associations_names_aliases(association_name)
          fields[humanize_model_name(association_name)] = humanize_attribute_names(association_attributes)
        end
      end

      def self_with_associations
        mock_self_as_reflection = OpenStruct.new(class_name: name, name: underscored_self_name)
        reflect_on_all_associations.unshift(mock_self_as_reflection)
      end

      # associations to exclude methods
      def associations_to_exclude(associations = [])
        validate_associations_to_exclude_argument(associations)

        associations_to_exclude_store.merge!(
          underscored_self_name => associations.map { |association| association.to_s.downcase }
        )
      end

      def validate_associations_to_exclude_argument(argument)
        raise 'Argument for associations_to_exclude has to be an array' unless argument.is_a? Array

        return if argument.all? { |element| element.is_a?(String || Symbol) }

        raise 'Argument array for associations_to_exclude has to be a string or Symbol'
      end

      # exportable attributes methods
      def exclude_exportable_attributes(association_attributes = {})
        validate_exclude_exportable_attributes_argument(association_attributes)

        association_attributes.transform_values! { |value| value.map(&:to_s) }

        excluded_exportable_attributes_store.merge!(
          underscored_self_name => association_attributes.stringify_keys
        )
      end

      def validate_exclude_exportable_attributes_argument(argument)
        raise 'Argument for exclude_exportable_attributes has to be a hash' unless argument.is_a? Hash

        argument.to_a.each do |arg|
          case arg
          in [*, [*]] if arg[1].all? { |element| element.is_a?(String || Symbol) }
            next
          else
            raise 'Invalid Arguments pattern for exclude_exportable_attributes'
          end
        end
      end

      def resolve_excluded_exportable_attributes(association_name)
        exclude_exportable_attributes_for_self = excluded_exportable_attributes_store[underscored_self_name]

        return [] if exclude_exportable_attributes_for_self.blank?

        exclude_exportable_attributes_for_self.with_indifferent_access.slice(
          association_name,
          'all'
        ).values.compact.flatten.uniq
      end

      def attributes_for_association(association)
        association_attributes = association.class_name.constantize.attribute_names
        association_attributes - resolve_excluded_exportable_attributes(association.name.to_s.downcase)
      end

      # association aliases methods
      def exportable_associations_aliases(aliases = {})
        validate_exportable_associations_aliases_argument(aliases)

        aliases.transform_values!(&:to_s)
        associations_aliases_store.merge!(underscored_self_name => aliases.stringify_keys)
      end

      def validate_exportable_associations_aliases_argument(argument)
        raise 'Argument for exportable_associations_aliases has to be a hash' unless argument.is_a? Hash

        argument.to_a.each do |arg|
          case arg
          in [*, String | Symbol]
            next
          else
            raise 'Invalid Arguments pattern for exportable_associations_aliases'
          end
        end
      end

      def resolve_associations_names_aliases(association_name)
        association_aliases_for_self = associations_aliases_store[underscored_self_name]
        return association_name if association_aliases_for_self.blank?

        association_aliases_for_self[association_name] || association_name
      end

      def underscored_self_name
        name.underscore.downcase
      end

      def humanize_model_name(model_name)
        model_name.underscore.humanize(keep_id_suffix: true)
      end

      def humanize_attribute_names(attributes)
        attributes.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }
      end

      def ensure_argument_is_array(argument)
        case argument
        in [*]
          return
        else
          raise 'input has to be an array'
        end
      end
    end
  end
end

ActiveRecord::Base.include EasyExports::Exportable
