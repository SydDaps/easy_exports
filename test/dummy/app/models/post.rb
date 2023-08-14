# frozen_string_literal: true

class Post < ApplicationRecord
  exportable_association_aliases user: :user_alias
end
