# frozen_string_literal: true

module EasyExports
  module DataLoader
    extend ActiveSupport::Concern

    class_methods do
      private

      def fetch_records(ids, selected_attributes, order = nil, batch_size = EasyExports.batch_size)
        validate_association_attributes(selected_attributes, 'to_exported_data')

        scope = ids.blank? ? all : where(id: ids)
        ordered_ids = apply_export_order(scope, order).pluck(:id)
        associations_to_preload = selected_attributes.keys - [underscored_self_name]

        ordered_ids.each_slice(batch_size).flat_map do |id_slice|
          batch = apply_export_order(where(id: id_slice), order).to_a
          ActiveRecord::Associations::Preloader.new(records: batch, associations: associations_to_preload).call
          batch
        end
      end

      def apply_export_order(records, order)
        return records.order(order) if order.present?
        return records.order(created_at: :desc) if column_names.include?('created_at')

        records
      end
    end
  end
end
