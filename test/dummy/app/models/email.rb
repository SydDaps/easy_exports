# frozen_string_literal: true

class Email < ApplicationRecord
  has_and_belongs_to_many :users

  exclude_exportable_attributes all: [:created_at], users: [:first_name]

  # exportable_association_aliases user: :user_aliases


end
