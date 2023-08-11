# frozen_string_literal: true

module EasyExports
  module ExportsProcessable
    extend ActiveSupport::Concern

    class_methods do
      def to_exported_csv(_fields_to_export = {}, ids = [])
        selected_exportable_fields = revert_transformed_names(exportable_fields)
        export_row_template = generate_export_row_template(selected_exportable_fields)

        selected_fields = revert_exportable_field_aliases(selected_exportable_fields)
        records = fetch_records(ids, selected_fields)

        records.each_with_object([]) do |record, hash_to_export|
          hash_to_export << value_from_selected_fields(selected_fields, record, export_row_template)
        end.flatten

        # CSV.open('./test.csv', 'wb') do |csv|
        #   csv << export_row_template.keys

        #   data_to_export.each do |data|
        #     csv << data.values
        #   end
        # end
      end

      def generate_export_row_template(selected_fields)
        selected_fields.each_with_object({}) do |(association_name, attributes), export_row|
          attributes.each do |attribute|
            export_row.merge!("#{association_name}_#{attribute}" => nil)
          end
        end
      end

      def fetch_records(ids, selected_fields)
        validate_fields(selected_fields)

        records_with_preloaded_associations(ids, selected_fields)
      end

      def validate_fields(selected_fields)
        selected_fields.each do |association_name, attributes|
          unless (association? association_name) || (underscored_self_name == association_name)
            raise StandardError, "Not valid association_name: #{association_name}"
          end

          invalid_attributes = attributes - association_attributes(association_name)
          next if invalid_attributes.empty?

          raise StandardError, "attributes not valid #{invalid_attributes.join(', ')}"
        end
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

      def records_with_preloaded_associations(ids, selected_fields)
        records = ids.blank? ? all : where(id: ids)

        associations_to_preload = selected_fields.keys
        associations_to_preload.delete(underscored_self_name)

        ActiveRecord::Associations::Preloader.new(
          records: records,
          associations: associations_to_preload
        ).call

        records
      end

      def value_from_selected_fields(selected_fields, record, export_row_template)
        selected_fields.each_with_object([export_row_template]) do |(association_name, selected_attributes), export_rows|
          objects = objects_for_attribute(association_name, record)

          selected_attributes.each do |attribute|
            attribute_values = resolve_attributes(attribute, objects)

            attribute_values.each_with_index do |value, index|
              export_column = export_rows[index] || export_row_template

              export_header = "#{association_name_alias(association_name)}_#{attribute}"

              export_rows[index] = export_column.merge(export_header => value)
            end
          end
        end
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

      def revert_exportable_field_aliases(fields_with_aliases)
        association_aliases = reverse_association_name_alias
        fields_with_aliases.transform_keys { |key| association_aliases[key] || key }
      end

      def reverse_association_name_alias
        association_name_aliases = "#{name}::EXPORTABLE_ASSOCIATIONS_ALIASES".safe_constantize
        return {} unless association_name_aliases.is_a? Hash

        association_name_aliases.with_indifferent_access.to_a.map(&:reverse).to_h
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

ActiveRecord::Base.include EasyExports::ExportsProcessable
