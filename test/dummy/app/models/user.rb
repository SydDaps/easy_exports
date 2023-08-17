# frozen_string_literal: true

class User < ApplicationRecord
  attribute :total_number_of_phones

  has_and_belongs_to_many :emails
  has_many :phones

  exportable_association_aliases user: :user_aliases

  def total_number_of_phones
    phones.size
  end
end