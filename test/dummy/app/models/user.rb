# frozen_string_literal: true

class User < ApplicationRecord
  exportable_association_aliases users: :user_aliases
  exclude_exportable_attributes all: ['updated_at']
  associations_to_exclude ['userdss']
end
