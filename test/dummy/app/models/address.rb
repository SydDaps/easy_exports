class Address < ApplicationRecord
  belongs_to :user

  exportable_association_aliases user: :user_alias
end
