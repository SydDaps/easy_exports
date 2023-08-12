# frozen_string_literal: true

module EasyExports
  module ExportableAttributeResolvers
    extend ActiveSupport::Concern

    class_methods do
      private

      def resolve_excluded_exportable_attributes(association_name)
        exclude_exportable_attributes_for_self = excluded_exportable_attributes_store[underscored_self_name]

        return [] if exclude_exportable_attributes_for_self.blank?

        exclude_exportable_attributes_for_self.with_indifferent_access.slice(
          association_name,
          'all'
        ).values.compact.flatten.uniq
      end

      def resolve_attributes_for_association(association)
        association_attributes = association.class_name.constantize.attribute_names
        association_attributes - resolve_excluded_exportable_attributes(association.name.to_s.downcase)
      end

      def resolve_associations_names_aliases(association_name)
        association_aliases_for_self = associations_aliases_store[underscored_self_name]
        return association_name if association_aliases_for_self.blank?

        association_aliases_for_self[association_name] || association_name
      end
    end
  end
end

ActiveRecord::Base.include EasyExports::ExportableAttributeResolvers
