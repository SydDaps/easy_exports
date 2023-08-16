# frozen_string_literal: true

module EasyExports
  module ExportsGenerable
    extend ActiveSupport::Concern

    class_methods do
      def generate_exports(fields_to_export = {}, ids = [])
        validate_exclude_exportable_attributes_argument(fields_to_export, 'generate_exports')

        selected_exportable_attributes = revert_transformed_names(fields_to_export)
        export_row_template = generate_export_row_template(selected_exportable_attributes)

        selected_attributes = revert_exportable_attributes_aliases(selected_exportable_attributes)
        records = fetch_records(ids, selected_attributes)

        exported_data = records.each_with_object([]) do |record, hash_to_export|
          hash_to_export << value_from_selected_attributes(selected_attributes, record, export_row_template)
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

      def generate_export_row_template(selected_attributes)
        selected_attributes.each_with_object({}) do |(association_name, attributes), export_row|
          attributes.each do |attribute|
            export_row.merge!("#{association_name}_#{attribute}" => nil)
          end
        end
      end

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
        end
      end

      def export_header(association_name, attribute)
        "#{associations_aliases_store[underscored_self_name][association_name] || association_name}_#{attribute}"
      end

      def resolve_attributes(attribute, objects)
        objects.empty? ? [nil] : objects.map { |object| parse_attribute_value(object.send(attribute)) }.flatten
      end

      def parse_attribute_value(value)
        value_class = value.class

        if value_class.eql?(ActiveSupport::TimeWithZone)
          DateTime.parse(value.to_s).strftime('%Y-%m-%d %H:%M:%S')
        elsif !value_class.eql?(String)
          value
        else
          value.start_with?('0') ? "'#{value}" : value
        end
      end

      def objects_for_attribute(association_name, record)
        object = association_name == underscored_self_name ? record : record.send(association_name)
        object.respond_to?(:each) ? object : [object].compact
      end

      def revert_exportable_attributes_aliases(attributes_with_aliases)
        attributes_with_aliases.transform_keys { |key| reversed_associations_name_aliases[key] || key }
      end

      def reversed_associations_name_aliases
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

ActiveRecord::Base.include EasyExports::ExportsGenerable
