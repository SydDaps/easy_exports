# frozen_string_literal: true

module EasyExports
  module ExportableAttributes
    extend ActiveSupport::Concern

    included do
      cattr_accessor :excluded_exportable_attributes_store, default: {}, instance_writer: false
      cattr_accessor :associations_aliases_store, default: {}, instance_writer: false
      cattr_accessor :associations_to_exclude_store, default: {}, instance_writer: false

      include EasyExports::ExportableAssociationAliasesConfigurations
      include EasyExports::ExportableAttributeResolvers
      include EasyExports::ExcludeExportableAttributesConfigurations
      include EasyExports::ExportsGenerable
    end

    class_methods do
      def exportable_attributes
        self_with_associations.each_with_object({}) do |association, attributes|
          association_name = association.name.to_s.downcase
          next if associations_to_exclude_store[underscored_self_name]&.include? association_name

          association_attributes = resolve_attributes_for_association(association)

          association_name = resolve_associations_names_aliases(association_name)
          attributes[humanize_model_name(association_name)] = humanize_attribute_names(association_attributes)
        end
      end

      private

      def self_with_associations
        mock_self_as_reflection = OpenStruct.new(class_name: name, name: underscored_self_name)
        reflect_on_all_associations.unshift(mock_self_as_reflection)
      end

      def association_from_self_with_association(association_name)
        self_with_associations.find { |association| association.name.to_s.downcase == association_name.to_s.downcase }
      end

      def underscored_self_name
        name.underscore.downcase
      end

      def humanize_model_name(model_name)
        model_name.underscore.humanize(keep_id_suffix: true)
      end

      def humanize_attribute_names(attributes)
        attributes.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }.sort
      end
    end
  end
end

ActiveRecord::Base.include EasyExports::ExportableAttributes
