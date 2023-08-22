# frozen_string_literal: true

module EasyExports
  module ExportsGenerable
    extend ActiveSupport::Concern

    included do
      include EasyExports::DataLoader
      include EasyExports::DataAttributesResolver
    end

    class_methods do
      def generate_exports(fields_to_export = {}, ids = [])
        validate_exclude_exportable_attributes_argument(fields_to_export, 'generate_exports')

        selected_exportable_attributes = revert_transformed_names(fields_to_export)
        selected_exportable_attributes = rearrange_selected_attributes(selected_exportable_attributes)

        export_row_template = generate_export_row_template(selected_exportable_attributes)

        selected_attributes = revert_exportable_attributes_aliases(selected_exportable_attributes)
        records = fetch_records(ids, selected_attributes)

        exported_data = records.each_with_object([]) do |record, hash_to_export|
          hash_to_export << value_from_selected_attributes(selected_attributes, record, export_row_template.dup)
        end.flatten

        csv_string = write_exported_data_to_csv(exported_data, export_row_template)

        EasyExports::Export.new(exported_data, csv_string)
      end

      def write_exported_data_to_csv(exported_data, export_row_template)
        CSV.generate(headers: true) do |csv|
          csv << export_row_template.keys

          exported_data.each do |data|
            csv << data.values
          end
        end
      end

      def rearrange_selected_attributes(selected_attributes)
        selected_attributes = selected_attributes.to_a
        self_alias_name = associations_aliases_store[underscored_self_name]&.fetch(underscored_self_name, nil)
        self_name = self_alias_name || underscored_self_name

        self_exportable_attributes = selected_attributes.find do |selected_attribute|
          selected_attribute.first == self_name
        end

        if self_exportable_attributes.blank? || selected_attributes[0] == self_exportable_attributes
          return selected_attributes.to_h
        end

        selected_attributes.delete(self_exportable_attributes)
        selected_attributes.unshift(self_exportable_attributes).to_h
      end

      def generate_export_row_template(selected_attributes)
        selected_attributes.each_with_object({}) do |(association_name, attributes), export_row|
          attributes.each do |attribute|
            export_row.merge!("#{association_name}_#{attribute}" => nil)
          end
        end
      end

      def revert_exportable_attributes_aliases(attributes_with_aliases)
        attributes_with_aliases.transform_keys { |key| reversed_associations_name_aliases[key] || key }
      end

      def reversed_associations_name_aliases
        associations_aliases = associations_aliases_store[underscored_self_name]
        return {} if associations_aliases.blank?

        associations_aliases_store[underscored_self_name].with_indifferent_access.to_a.map(&:reverse).to_h
      end

      def revert_transformed_names(fields)
        fields.transform_keys! { |key| key.parameterize(separator: '_') }

        fields.transform_values do |value|
          value.map { |v| v.parameterize(separator: '_') }.uniq
        end
      end
    end
  end
end
