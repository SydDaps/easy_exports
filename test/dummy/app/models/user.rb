# frozen_string_literal: true

class User < ApplicationRecord
  attribute :total_number_of_phones

  has_and_belongs_to_many :emails
  has_many :phones

  def total_number_of_phones
    phones.size
  end
end
