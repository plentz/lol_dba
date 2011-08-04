#Rails Indexes

Rails indexes is a small package of 2 rake tasks that scan your application models and displays a list of columns that _probably_ should be indexed.

*Note:* there should be mode fields depending on your application design and custom queries.


Installation
------------

Add rails_indexes to your Gemfile:

    gem "rails_indexes", :git => "https://github.com/warpc/rails_indexes"

Usage
-----

Display a migration for adding/removing all necessary indexes based on associations:

    rake db:index_migration

Display a migration for adding/removing all necessary indexes based on AR::Base#find calls (including: `find`, `find_by`, `find_all_by`, `find_by_x_and_y`, `find_all_by_x_and_y`):

    rake db:find_query_indexes

*Notice:* At now moment it does not support Arel(the new Rails 3 Active Record Query Interface) calls (including: where, joins, includes, from, select...), but still usefull for indexes based on association

Note that add index in big database may take a long time.

Compatibility
-------------

Compatible with Ruby 1.9 and Rails 3.

Upcoming features/enhancements
------------------------------

  *   Support Arel(the new Rails 3 Active Record Query Interface) call for `find_query_indexes` action
  *   Support `has_many :through` analize for indexes based on associations

About primary_key
-----------------
>The primary key is always indexed. This is generally true for all storage engines that at all supports indices.

For this reason, no longer displays a gem suggestions about adding indexes to primary keys.


Tests
-----

    bundle install
    rake
  
to run the tests.

*Notice:* At now moment tests not working in Ruby 1.9, use 1.8.7. 

Feedback
--------

All feedback, bug reports and thoughts on this gratefully received.

Author:
------
Elad Meidar - [http://blog.eizesus.com](http://blog.eizesus.com)

Thanks:
Eric Davis - [http://littlestreamsoftware.com](http://littlestreamsoftware.com)

License
-------
Released under the same license as Ruby. No Support. No Warranty, no Pain.
