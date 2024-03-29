# lol_dba [![ci](https://github.com/plentz/lol_dba/actions/workflows/build.yml/badge.svg)](https://github.com/plentz/lol_dba/actions) [![Maintainability](https://api.codeclimate.com/v1/badges/a5cc1172ec1291536904/maintainability)](https://codeclimate.com/github/plentz/lol_dba/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/a5cc1172ec1291536904/test_coverage)](https://codeclimate.com/github/plentz/lol_dba/test_coverage)

lol_dba is a small package of rake tasks that scan your application models and displays a list of columns that probably should be indexed. Also, it can generate .sql migration scripts.

### Quick example

To use lol_dba in the easiest way possible you have to do two things:

	gem install lol_dba

Then run one of the following commands...

To display a migration for adding/removing all necessary indexes based on associations:

	lol_dba db:find_indexes

To generate .sql files for your migrations inside db/migrate_sql folder:

	lol_dba db:migrate_sql # defaults to all migrations
	lol_dba db:migrate_sql[pending] # only pending migrations
	lol_dba db:migrate_sql[20120221205526] # generate sql only for migration 20120221205526

### Not-so-quick example

If you want to use lol_dba with rake, you should do a few more steps:

Add lol_dba to your Gemfile

    gem "lol_dba"

Run the install command

    bundle install

Use it the same way you use other rake commands

	rake db:find_indexes
	rake db:migrate_sql # defaults to all migrations
	rake db:migrate_sql[pending] # only pending migrations
	rake db:migrate_sql[20120221205526] # generate sql only for migration 20120221205526

### Compatibility

Compatible with Ruby 2.x, Ruby 3.x and Rails 3.x, 4.x, 5.x, 6.x, and 7.x.

### About primary_key

>The primary key is always indexed. This is generally true for all storage engines that at all supports indexes.

For this reason, we no longer suggest to add indexes to primary keys.

### Tests

To run lol_dba tests, just clone the repo and run:

    bundle install && rake

### Contributors
Most of the initial code came from [rails_indexes](https://github.com/warpc/rails_indexes) and [migration_sql_generator](https://github.com/muness/migration_sql_generator). [Other people helped as well](https://github.com/plentz/lol_dba/graphs/contributors).

### License

Lol DBA is released under the MIT license.
