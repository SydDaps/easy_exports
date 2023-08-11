# frozen_string_literal: true

class User < ApplicationRecord
  exportable_associations_aliases user: :user_aliases
  exclude_exportable_attributes all: ['id']
  associations_to_exclude [:users]
end
