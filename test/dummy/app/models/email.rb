# frozen_string_literal: true

class Email < ApplicationRecord
  # exportable_associations_aliases 'test' => 'f'

  has_and_belongs_to_many :users
end
