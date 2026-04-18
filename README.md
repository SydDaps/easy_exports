# EasyExports
EasyExports is a rails ActiveRecord ORM extension dedicated to streamlining and simplifying the model data export process by eliminating common complexities.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "easy_exports"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install easy_exports
```
## Usage
Upon installation, EasyExports seamlessly integrates with ```ActiveRecord::Base```, granting all models immediate access to its efficient export methods.

### Generating Exportable Attributes

Retrieve exportable attributes using the `exportable_attributes` method. This method retrieves attributes of the model itself and those of all its associations.

```ruby
  # Example Models and Exportable Attributes
  
  # User model with columns: first_name, last_name, created_at, updated_at
  class User < ApplicationRecord
    has_and_belongs_to_many :emails
    has_many :phones
  end
  
  # Exportable attributes for the User model
  User.exportable_attributes
    # =>
    # {
    #   "User" => ["id", "first name", "last name", "created at", "updated at"],
    #   "Emails" => ["id", "address", "created at", "updated at"],
    #   "Phones" => ["id", "number", "user id", "created at", "updated at"]
    # }
  
  # Phone model with columns: number, user_id, created_at, updated_at
  class Phone < ApplicationRecord
    belongs_to :user
  end
  
  # Exportable attributes for the Phone model
  Phone.exportable_attributes
    # =>
    # {
    #   "Phone" => ["id", "number", "user id", "created at", "updated at"],
    #   "User" => ["id", "first name", "last name", "created at", "updated at"]
    # }
```

### Generating Exports from Exportable Attributes

To generate exports, use the `generate_exports(exportable_attributes, ids, order:)` method.

- The `exportable_attributes` argument specifies the chosen attributes from the exportable attributes list.
- The `ids` argument is optional; provide IDs to export data for specific records.
- Omitting `ids` will trigger exports for all records of the given model.
- The `order:` keyword argument is optional; see [Ordering Exports](#ordering-exports) for details.

The method returns an `EasyExports::Export` object containing hash data from the records and a `csv_string` that can be written to a CSV file.

```ruby
user_exportable_attributes = {"User"=>["id", "first name"], "Phones"=>["id", "number"], "Emails"=>["id", "address"]}

exports_object = User.generate_exports(user_exportable_attributes)
# => EasyExports::Export(Object)

exports_data = exports_object.data
# =>
# [
#   {"user_id"=>1, "user_first_name"=>"Sydney", "phones_id"=>1, "phones_number"=>"(473) 693-8745", "emails_id"=>5, "emails_address"=>"blake_armstrong@bahringer.test"},
#   {"user_id"=>1, "user_first_name"=>"Sydney", "phones_id"=>2, "phones_number"=>"594-299-0722", "emails_id"=>6, "emails_address"=>"dulce@mertz.example"},
#   {"user_id"=>1, "user_first_name"=>"Sydney", "phones_id"=>3, "phones_number"=>"1-609-662-2028", "emails_id"=>nil, "emails_address"=>nil},
#   {"user_id"=>2, "user_first_name"=>"Stan", "phones_id"=>4, "phones_number"=>"951-671-9548", "emails_id"=>7, "emails_address"=>"dominick@durgan.example"},
#   {"user_id"=>2, "user_first_name"=>"Stan", "phones_id"=>5, "phones_number"=>"1-698-432-7489", "emails_id"=>nil, "emails_address"=>nil}
# ]

exports_csv_string = exports_object.csv_string
# =>
# "user_id,user_first_name,phones_id,phones_number,emails_id,emails_address\n
# 1,Sydney,1,(473) 693-8745,5,blake_armstrong@bahringer.test\n
# 1,Sydney,2,594-299-0722,6,dulce@mertz.example\n
# 1,Sydney,3,1-609-662-2028,,\n
# 2,Stan,4,951-671-9548,7,dominick@durgan.example\n
# 2,Stan,5,1-698-432-7489,,\n"

# Writing csv_string to a file to visualize the generated export
File.open(file_path, 'w') do |file|
  file.write(exports_csv_string)
end
```
<div align="center">
  <img width="600" alt="csv_with_emails" src="https://github.com/SydDaps/easy_exports/assets/51008616/8b9df43c-419d-4ca0-8cb1-6217025b8050">
</div>

Exported CSV showcases data for:

- User "Sydney" with 3 phones and 2 emails
- User "Stan" with 2 phones and 1 email.
- The main CSV header includes association names and attribute names.


### Ordering Exports

Control the order of rows in the generated export using the `order:` keyword argument on `generate_exports`.

- `order:` accepts any value ActiveRecord's `order` accepts — a hash, string, symbol, or array.
- When `order:` is omitted and the model has a `created_at` column, exports default to newest first (`created_at DESC`).
- When `order:` is omitted and no `created_at` column exists, no ordering is applied.

```ruby
  # Example: explicit ordering

  # Order by first_name ascending
  User.generate_exports(user_exportable_attributes, [], order: { first_name: :asc })

  # Order by a raw SQL fragment
  User.generate_exports(user_exportable_attributes, [], order: 'last_name DESC, id ASC')

  # Default ordering (newest first when created_at exists)
  User.generate_exports(user_exportable_attributes)
```

For performance, records are fetched in batches of 1,000 internally while preserving the requested order across the full result set. The batch size is configurable — see [Configuration](#configuration).

### Configuration

Configure gem-wide defaults using `EasyExports.configure`.

```ruby
  # config/initializers/easy_exports.rb
  EasyExports.configure do |c|
    c.batch_size = 500                                          # default: 1000
    c.sensitive_attributes += %w[internal_note ssn]             # extends the default list
    c.type_formatters[:datetime] = ->(v) { v.strftime('%d/%m/%Y') }
    c.csv_header_formatter = ->(key) { key.humanize.upcase }    # or set to nil to disable
  end
```

- `batch_size` — number of records fetched per database round trip during export. Override per call with `generate_exports(..., batch_size: 2_000)`.
- `sensitive_attributes` — attributes auto-excluded from every export. See [Sensitive Attributes](#sensitive-attributes) for the default list and per-model opt-out.
- `type_formatters` — per-type value formatters applied before a raw value is written to CSV. See [Type Formatters](#type-formatters).
- `csv_header_formatter` — callable applied to every header in the CSV row. Defaults to `humanize.titleize` (e.g. `registration_email` → `Registration Email`). Set to `nil` to keep raw snake_case headers.

### Sensitive Attributes

EasyExports automatically excludes commonly sensitive attributes from all exports. The default list is:

```ruby
  %w[
    password_digest
    encrypted_password
    remember_token
    reset_password_token
    confirmation_token
    session_token
    api_key
    secret_token
  ]
```

To include these on a specific model (e.g. for admin-only exports), opt in at the class level:

```ruby
  class AdminLogin < ApplicationRecord
    self.include_sensitive_exportable_attributes = true
  end
```

Extend or replace the default list through [Configuration](#configuration).

### Type Formatters

EasyExports applies type-based formatters automatically, so you don't have to write a lambda for every boolean or timestamp column.

| Type | Matches | Shipped formatter | Example output |
|------|---------|-------------------|----------------|
| `boolean` | `true` / `false` | `->(v) { v ? 'Yes' : 'No' }` | `Yes`, `No` |
| `datetime` | `Date`, `Time`, `DateTime`, `ActiveSupport::TimeWithZone` | `->(v) { v.strftime('%A, %B %-d, %Y %H:%M') }` | `Sunday, January 5, 2025 09:17` |
| `leading_zero_string` | `String` starting with `0` | `->(v) { "'#{v}" }` | `'0244867596` (preserves leading zero in spreadsheets) |
| `string` | `String` not containing `@` | *(none — opt in per model)* | — |

`nil` values always pass through untouched.

**Turn off a type formatter for a specific model:**

```ruby
  class Transaction < ApplicationRecord
    disable_exportable_type_formatter :datetime               # one type
    disable_exportable_type_formatter :boolean, :datetime     # multiple types
  end
```

**Replace a type formatter for a specific model** — apply a different format to *all* values of that type on this one model:

```ruby
  class Registration < ApplicationRecord
    # Every datetime on Registration renders as "January 5, 2025" — no time portion
    format_exportable_type :datetime, ->(v) { v.strftime('%B %-d, %Y') }

    # Capitalize the first letter of every plain string (emails are skipped automatically)
    format_exportable_type :string, ->(v) { v.sub(/^./, &:upcase) }

    # Block form
    format_exportable_type(:boolean) { |v| v ? '✓' : '✗' }
  end
```

**Change or disable a type formatter globally** — see [Configuration](#configuration).

### Custom Value Formatters

For a specific attribute, override the default with your own formatter using `format_exportable_attribute`.

- Declare it on the class that owns the attribute. It applies whenever that attribute is exported, whether from the owner model directly or through an association.
- Accepts either a callable (lambda/proc) or a block.
- A custom formatter takes precedence over any default formatter for that attribute.

```ruby
  class Registration < ApplicationRecord
    # Override the global datetime default with a shorter format for this attribute
    format_exportable_attribute :registered_on, ->(v) { v&.strftime('%Y-%m-%d') }

    # Override the global boolean default with custom glyphs
    format_exportable_attribute :is_archived, ->(v) { v ? '✓' : '' }

    # Block form
    format_exportable_attribute(:status) { |v| v.to_s.titleize }
  end
```

**Precedence** (top wins):
1. Per-attribute `format_exportable_attribute`
2. Per-model `disable_default_formatter` (if disabled → raw value)
3. Per-model `override_default_formatter` (if overridden → override wins)
4. Global `EasyExports.default_formatters[:type]`
5. Raw value

### Exportable Attributes Aliases

Configure an alternative association name for exportable attributes using the `exportable_association_aliases(aliases)` model method.

- Invoke this method below all association definitions.
- `aliases` should be a hash in the pattern: `{valid_association_name or model_name: "alternative_name"}`.
- Ensure all hash arguments are snake-cased.

```ruby
# Example Model with exportable_association_aliases

# User model with columns: first_name, last_name, created_at, updated_at
  class User < ApplicationRecord
    has_many :phones
  
    exportable_association_aliases phones: :mobile_phones
  end
  
  # Exportable attributes for the User model will now be
  User.exportable_attributes
  # =>
  # {
  #   "User" => ["id", "first name", "last name", "created at", "updated at"],
  #   "Mobile phones" => ["id", "number", "user id", "created at", "updated at"]
  # }
```
With the exportable_association_aliases configured, the phones association has been renamed to "Mobile phones". This new name will appear in the export header when generating exports with this alias for exportable attributes.

### Excluding Specific Exportable Attributes

Configure associations to exclude certain attributes from exportable attributes using the `exclude_exportable_attributes(association_attributes)` model method.

- Invoke this method below all association declarations.
- `association_attributes` should follow the pattern `{valid_association_name or model_name: [valid_attributes_to_remove]}`.
- For removing attributes across all associations and the model itself, use the "all" key as the association_name.

```ruby
  # Example Model with exclude_exportable_attributes
  
  # User model with columns: first_name, last_name, created_at, updated_at
  class User < ApplicationRecord
    has_many :phones
  
    exclude_exportable_attributes all: [:id], user: [:last_name], phones: [:user_id]
  end
  
  # Exportable attributes for the User model will now be
  User.exportable_attributes
  # =>
  # {
  #   "User" => ["first name", "created at", "updated at"],
  #   "Phones" => ["number", "created at", "updated at"]
  # }
```
In this example, note that:
- All associations exclude the id attribute.
- The User model excludes the last_name attribute.
- The Phones association excludes the user_id attribute.
  

### Excluding Specific Exportable Attribute Associations

Configure model's exportable attributes to exclude certain associations using the `associations_to_exclude(associations)` model method.

- Apply this method below all association declarations.
- `associations` should follow the pattern `['association_name']`.

```ruby
  # Example Model with associations_to_exclude
  
  # User model with columns: first_name, last_name, created_at, updated_at
  class User < ApplicationRecord
    has_many :phones
    
    associations_to_exclude [:phones]
  end
  
  # Exportable attributes for the User model will now be
  User.exportable_attributes
  # =>
  # {
  #   "User" => ["id", "first name", "last name", "created at", "updated at"]
  # }
```
In this example, the attributes of the phones association are excluded from the exportable attributes of the User model.


### Adding Custom Attribute to Exportable Attributes

Leverage a handy Rails method to transform a model instance method into an attribute, incorporating it into the exportable attributes.

```ruby
# Example Model with Custom Virtual Attribute

# User model with columns: first_name, last_name, created_at, updated_at
class User < ApplicationRecord
  attribute :total_number_of_phones

  has_many :phones
    
  associations_to_exclude [:phones]

  def total_number_of_phones
    phones.size
  end
end

# Exportable attributes for the User model will now include
User.exportable_attributes
# =>
# {
#   "User" => ["id", "first name", "last name", "created at", "updated at", "total number of phones"]
# }
```
In this example, the custom attribute "total number of phones" has been seamlessly integrated into the exportable attributes, showcasing the flexibility of Rails' capabilities.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
