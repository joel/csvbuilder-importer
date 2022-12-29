# Csvbuilder::Importer

[Csvbuilder::Importer](https://github.com/joel/csvbuilder-importer) is part of the [csvbuilder-collection](https://github.com/joel/csvbuilder)

The importer contains the implementation for importing data from a CSV file.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add csvbuilder-importer

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install csvbuilder-importer

# Usage

Importing data from a CSV is critical and requires two validation layers. First, you need to ensure data from the CSV are correct, and Second, you need to check that data respects the business logic before inserting it into the system.

To do that, `Csvbuilder::Import` use `ActiveModel::Validations` so you can write your validations in the `CsvImportModel`.

```ruby
class UserCsvImportModel
  include Csvbuilder::Model
  include Csvbuilder::Import

  column :first_name
  column :last_name

  validates :first_name, presence: true, length: { minimum: 2 }

  def abort?
    "#{first_name} #{last_name}" == "Bill Gates"
  end
end
```

The import takes the CSV file and the Import class.

```ruby
rows = Csvbuilder::Import::File.new(file.path, UserCsvImportModel).each
row = rows.next
```

`Csvbuilder::Import` implement two essential methods:

1. skip?
2. abort?

You have to provide your implementation of the method `abort?`. If the method `abort?` returns true, the iteration will stop.

By default, `skip?` return true if the `CsvImportClass` is invalid, but it is safe to override. This means the previous iteration will not return any invalid row.

# Integration

Let's say we want to do something useful and add users if those users are valid.

Let's extract the `CsvRowModel` for more clarity:

```ruby
class UserCsvRowModel
  include Csvbuilder::Model

  column :first_name
  column :last_name
end
```

```ruby
class UserCsvImportModel < UserCsvRowModel
  include Csvbuilder::Import

  validates :first_name, presence: true, length: { minimum: 2 }
  validates :last_name, presence: true, length: { minimum: 2 }

  def user
    User.new(first_name: first_name, last_name: last_name)
  end

  # Skip if the row is not valid,
  # the user is not valid or
  # the user already exists
  def skip?
    super || !user.valid? || user.exists?
  end
end
```

Now, we can safely import our users.

```ruby
[
  ["First name", "Last name"],
  ["John"      , "Doe"      ],
]

Csvbuilder::Import::File.new(file.path, UserCsvImportModel).each do |row_model|
  row_model.user.save
end
```

# Advance Integration

`Csvbuilder::Import::File` implement callbacks. It provides the following:

1.  before_each_iteration
2.  around_each_iteration
3.  after_each_iteration
4.  before_next
5.  around_next
6.  after_next
7.  before_abort
8.  before_skip

Let's extend `Csvbuilder::Import::File`

```ruby
class Importer < Csvbuilder::Import::File
  attr_reader :row_in_errors

  def initialize(*args)
    super
    @row_in_errors = RowErrors.new
  end

  after_next do
    next true unless current_row_model # End of File
    next true if current_row_model.valid? # No Errors To Collect

    row_in_errors.append_errors(current_row_model)
  end
end
```

Now the importer can report the errors encountered instead of ignoring them.

For documentation purposes, here is a possible implementation of the errors collector:

```ruby
class RowErrors
  attr_reader :headers, :errors

  def initialize
    @errors = []
  end

  def append_errors(row_model)
    @headers ||= begin
      errors << row_model.class.headers
      row_model.class.headers
    end

    row_in_error = []
    row_model.source_attributes.map do |key, value|
      row_in_error << if row_model.errors.messages[key].present?
                        "Initial Value: [#{value}] - Errors: #{row_model.errors.messages[key].join(", ")}"
                      else
                        value
                      end
    end
    errors << row_in_error
  end
end
```

Now we can nicely show the errors which occur over the import.

```ruby
[
  ["First name", "Last name"],
  ["J", "Doe"]
]

importer.row_in_errors.errors
# => [
# =>   ["First Name", "Last Name"],
# =>   ["Initial Value: [J] - Errors: is too short (minimum is 2 characters)", "Doe"]
# => ]
```

Thanks to the callback mechanism, the opportunities to interact with the import are immense. For instance, you can show the errors on a Web Form and offer the chance to the user to change the data and re-attempt.

For long imports, you can show a progress bar to help customers cope with the import time; as you know, if errors have occurred, you can change the colour of the progress bar accordingly and offer the possibility to stop the import earlier.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joel/csvbuilder-importer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/csvbuilder-importer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Csvbuilder::Importer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/csvbuilder-importer/blob/main/CODE_OF_CONDUCT.md).
