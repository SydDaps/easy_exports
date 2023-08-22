# frozen_string_literal: true

module EasyExports
  module DataAttributesResolver
    extend ActiveSupport::Concern

    class_methods do
      private

      def value_from_selected_attributes(selected_attributes, record, export_row_template)
        selected_attributes.each_with_object([export_row_template]) do |(association_name, attributes), export_rows|
          objects = objects_for_attribute(association_name, record)

          attributes.each do |attribute|
            attribute_values = resolve_attributes(attribute, objects)

            attribute_values.each_with_index do |value, index|
              export_column = export_rows[index] || export_row_template

              export_rows[index] = export_column.merge(export_header(association_name, attribute) => value)
            end
          end

          export_row_template.merge!(export_rows.first) if association_name == underscored_self_name
        end
      end

      def resolve_attributes(attribute, objects)
        objects.empty? ? [nil] : objects.map { |object| parse_attribute_value(object.send(attribute)) }.flatten
      end

      def parse_attribute_value(value)
        return DateTime.parse(value.to_s).strftime('%Y-%m-%d %H:%M:%S') if value.is_a?(ActiveSupport::TimeWithZone)

        return "'#{value}" if value.is_a?(String) && value&.start_with?('0')

        value
      end

      def objects_for_attribute(association_name, record)
        object = association_name == underscored_self_name ? record : record.send(association_name)
        object.respond_to?(:each) ? object : [object].compact
      end

      def export_header(association_name, attribute)
        association_alias = associations_aliases_store[underscored_self_name]
        association_alias = association_alias.blank? ? nil : association_alias[association_name]

        "#{association_alias || association_name}_#{attribute}"
      end
    end
  end
end
