# frozen_string_literal: true

class Email < ApplicationRecord
  exportable_associations_aliases 'test' => 'f'
end
