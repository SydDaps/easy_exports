# frozen_string_literal: true

module EasyExports
  module ExportableAttributeFormattersConfigurations
    extend ActiveSupport::Concern

    class_methods do
      private

      def format_exportable_attribute(attribute, formatter = nil, &block)
        formatter ||= block
        unless formatter.respond_to?(:call)
          raise ArgumentError, 'format_exportable_attribute requires a callable (proc or block)'
        end

        exportable_attribute_formatters_store[underscored_self_name] ||= {}
        exportable_attribute_formatters_store[underscored_self_name][attribute.to_s] = formatter
      end

      def disable_exportable_type_formatter(*types)
        validate_known_type_formatter!(types, 'disable_exportable_type_formatter')

        disabled_type_formatters_store[underscored_self_name] ||= []
        disabled_type_formatters_store[underscored_self_name] |= types.map(&:to_sym)
      end

      def format_exportable_type(type, formatter = nil, &block)
        formatter ||= block
        unless formatter.respond_to?(:call)
          raise ArgumentError, 'format_exportable_type requires a callable (proc or block)'
        end
        validate_known_type_formatter!([type], 'format_exportable_type')

        overridden_type_formatters_store[underscored_self_name] ||= {}
        overridden_type_formatters_store[underscored_self_name][type.to_sym] = formatter
      end

      def validate_known_type_formatter!(types, method)
        invalid = types.map(&:to_sym) - EasyExports::TYPE_MATCHERS.keys
        return if invalid.empty?

        raise ArgumentError,
              "#{method} unknown type(s): #{invalid.join(', ')}. " \
              "Known types: #{EasyExports::TYPE_MATCHERS.keys.join(', ')}"
      end
    end
  end
end
