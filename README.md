#Lol DBA

lol_dba is a small package of rake tasks that scan your application models and displays a list of columns that probably should be indexed. Also, it can generate .sql migration scripts. Most of the code come from rails_indexes and migration_sql_generator.

Installation
------------

Add lol_dba to your Gemfile:

    gem "lol_dba"

and install gem

    bundle install

Usage
-----

Display a migration for adding/removing all necessary indexes based on associations:

    rake db:find_indexes

Display a migration for adding/removing all necessary indexes based on AR::Base#find calls (including: `find`, `find_by`, `find_all_by`, `find_by_x_and_y`, `find_all_by_x_and_y`):

    rake db:find_query_indexes

Generate .sql files for all your migrations inside db/migrate_sql folder:

    rake db:migrate_sql

*Notice:* At now moment it does not support Arel(the new Rails 3 Active Record Query Interface) calls (including: where, joins, includes, from, select...), but still usefull for indexes based on association.

Note that add index in big database may take a long time.

Compatibility
-------------

Compatible with Ruby 1.9 and Rails 3.x. I think.

Upcoming features/enhancements
------------------------------

  * support Arel(the new Rails 3 Active Record Query Interface) call for `find_query_indexes` action
  * support for `change` migrations

About primary_key
-----------------
>The primary key is always indexed. This is generally true for all storage engines that at all supports indices.

For this reason, no longer displays a gem suggestions about adding indexes to primary keys.

Tests
-----

    bundle install
    rake

to run the tests.

Feedback
--------

All feedback, bug reports and thoughts on this gratefully received.

Contributors
------

* [Diego Plentz](http://plentz.org)
* [Elad Meidar](http://blog.eizesus.com)
* [Eric Davis](http://littlestreamsoftware.com)
* [Jay Fields](http://jayfields.com/)
* [Muness Alrubaie](http://muness.blogspot.com/)
* [Vladimir Sharshov](https://github.com/warpc)

License
-------
Lol DBA is released under the MIT license.
