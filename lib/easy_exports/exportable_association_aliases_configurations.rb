# frozen_string_literal: true

module EasyExports
  module ExportableAssociationAliasesConfigurations
    extend ActiveSupport::Concern

    class_methods do
      private

      def exportable_association_aliases(aliases = {})
        validate_exportable_association_aliases_argument(aliases)

        aliases.transform_values!(&:to_s)
        aliases.stringify_keys!

        aliases.each do |association_name, _alias_name|
          next if association_from_self_with_association(association_name).present?

          error_message = <<~MESSAGE
            exportable_association_aliases argument '#{association_name}' is not an association for #{underscored_self_name} model
          MESSAGE

          raise ArgumentError, error_message
        end

        associations_aliases_store.merge!(underscored_self_name => aliases.stringify_keys)
      end

      def validate_exportable_association_aliases_argument(argument)
        raise 'Argument for exportable_associations_aliases has to be a hash' unless argument.is_a? Hash

        argument.to_a.each do |arg|
          case arg
          in [*, String | Symbol]
            next
          else
            raise 'Invalid Arguments pattern for exportable_associations_aliases'
          end
        end
      end
    end
  end
end

# ActiveRecord::Base.include EasyExports::ExportableAssociationAliasesConfigurations
