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

To generate exports, use the `generate_exports(exportable_attributes, ids)` method.

- The `exportable_attributes` argument specifies the chosen attributes from the exportable attributes list.
- The `ids` argument is optional; provide IDs to export data for specific records.
- Omitting `ids` will trigger exports for all records of the given model.

The method returns an `EasyExports::Export` object containing hash data from the records and a `csv_string` that can be written to a CSV file.

```ruby
  user_exportable_attributes = {"User"=>["id", "first name"], "Phones"=>["id", "number"]}
  
  exports_object = User.generate_exports(user_exportable_attributes)
  # => EasyExports::Export(Object)
  
  exports_data = exports_object.data
  # => [{"user_id"=>1, "user_first_name"=>"sydney","phones_id"=>1, "phones_number"=>"(473) 693-8745"},
  #     {"user_id"=>nil, "user_first_name"=>nil, "phones_id"=>2, "phones_number"=>"594-299-0722"},
  #     {"user_id"=>nil, "user_first_name"=>nil, "phones_id"=>3, "phones_number"=>"1-609-662-2028"},
  #     {"user_id"=>2, "user_first_name"=>"Stan", "phones_id"=>4, "phones_number"=>"951-671-9548"},
  #     {"user_id"=>nil, "user_first_name"=>nil, "phones_id"=>5, "phones_number"=>"1-698-432-7489"}]
  
  exports_csv_string = exports_object.csv_string
  # => "user_id,user_first_name,phones_id,phones_number\n1,sydney,1,(473) 693-8745\n,,2,594-299-0722\n,,3,1-609-662-2028\n2,Stan,4,951-671-9548\n,,5,1-698-432-7489\n"

  #writting csv_string to file to visualize the export generated
  File.open(file_path, 'w') do |file|
    file.write(exports_csv_string)
  end
```
<div align="center">
  <img width="346" alt="csv_user_phones" src="https://github.com/SydDaps/easy_exports/assets/51008616/41001ac7-6870-4cad-bf20-048d22585045" />
</div>
Exported CSV showcases data for user "Sydney" with 3 phones and user "Stan" with 2 phones.

The main CSV header follows the pattern `"#{exportable_attributes_association}_#{exportable_attributes_attribute}"`.

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
