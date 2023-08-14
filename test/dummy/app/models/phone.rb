# frozen_string_literal: true

class Phone < ApplicationRecord
  belongs_to :user

  associations_to_exclude ['user']
end
