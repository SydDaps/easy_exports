# frozen_string_literal: true

module EasyExports
  module DataLoader
    extend ActiveSupport::Concern

    class_methods do
      private

      def fetch_records(ids, selected_attributes)
        validate_association_attributes(selected_attributes, 'to_exported_data')

        records_with_preloaded_associations(ids, selected_attributes)
      end

      def association_attributes(association_name)
        association_name = if association_name == underscored_self_name
                             association_name.classify
                           else
                             reflect_on_all_associations.find do |association|
                               association.name.to_s == association_name
                             end&.class_name
                           end

        raise ArgumentError "Invalid Association: #{association_name}" unless association

        association_name.constantize.attribute_names
      end

      def records_with_preloaded_associations(ids, selected_attributes)
        records = ids.blank? ? all : where(id: ids)

        associations_to_preload = selected_attributes.keys
        associations_to_preload.delete(underscored_self_name)

        ActiveRecord::Associations::Preloader.new(
          records: records,
          associations: associations_to_preload
        ).call

        records
      end
    end
  end
end
