## [Unreleased]

## [Released]

## [0.2.0] - 2025-03-02 Sun 2 Mar 2025

- Check if the headers from the CSV match the Csvbuilder::Model headers definitions.

If you are expecting the Headers "First Name" and "Last Name"

```ruby
class BasicRowModel
  include Csvbuilder::Model

  column :first_name, header: "First Name"
  column :last_name, header: "Last Name"
end
```

and the CSV provide

```CSV
"First Name","LastName"
John,Doe
```

You will get the following error:

```
"Headers mismatch. Given headers (First Name, LastName). Expected headers (First Name, Last Name). Unrecognized headers (LastName)."
```

This is a potential break change, that why I bump of from 1.x to 2.x

If you use the formatted headers, `format_header(column_name, _context)`, do keep in mind that it applies to the Model definition, not the CSV Headers. I would recommend not using `formatted headers` for importing anyway.

## [0.1.5.1] - 2023-07-26

- Revert: Using Less Memory And Quicker Line Counter https://github.com/joel/csvbuilder-importer/pull/11

## [0.1.5] - 2023-07-26

- Add a way to abort at the importer level, handy to handle wrong headers check https://github.com/joel/csvbuilder-importer/pull/12
- Using Less Memory And Quicker Line Counter https://github.com/joel/csvbuilder-importer/pull/11

## [0.1.4] - 2023-04-21

- Potential Security Fix

https://github.com/joel/csvbuilder-importer/compare/v0.1.2...v0.1.4

## [0.1.0] - 2022-12-16

- Initial release
