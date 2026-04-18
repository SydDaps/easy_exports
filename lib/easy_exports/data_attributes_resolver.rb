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
        return [nil] if objects.empty?

        objects.map do |object|
          raw_value = object.send(attribute)
          format_value_for_export(object.class, attribute, raw_value)
        end.flatten
      end

      def format_value_for_export(klass, attribute, value)
        custom = exportable_attribute_formatter_for(klass, attribute)
        return custom.call(value) if custom
        return value if value.nil?

        type_formatter = type_formatter_for(klass, value)
        type_formatter ? type_formatter.call(value) : value
      end

      def exportable_attribute_formatter_for(klass, attribute)
        store = exportable_attribute_formatters_store[klass.name.underscore.downcase]
        store && store[attribute.to_s]
      end

      def type_formatter_for(klass, value)
        klass_key = klass.name.underscore.downcase
        disabled = disabled_type_formatters_store[klass_key] || []
        overrides = overridden_type_formatters_store[klass_key] || {}

        EasyExports::TYPE_MATCHERS.each do |type, matcher|
          next if disabled.include?(type)
          next unless matcher.call(value)

          formatter = overrides[type] || EasyExports.type_formatters[type]
          return formatter if formatter
        end

        nil
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
