# frozen_string_literal: true

class User < ApplicationRecord
  # exportable_association_aliases user: :user_aliases
  # exclude_exportable_attributes all: ['updated_at']
  # associations_to_exclude ['user']

  has_and_belongs_to_many :emails
  has_many :phones
end
