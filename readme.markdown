xpg
===

What is it?
--------
xpg is a wrapper for Ruby's pg gem for connecting to Postgresql
databases.  It offers three features:

1. Attributes of each row can be accessed as methods on the row object.
   So you can use _user.username_ instead of _user['username']_.
2. Attributes of each row are converted into the appropriate Ruby
   object.
3. A simple insert method.

There is a major downside, however.  Converting the database fields into
the correct Ruby objects slows everything down significantly.  Using xpg
can be an order of magnitude slower that using pg alone.

Usage
-----
Just require 'xpg' and use it like pg, except use XPGconn instead of PGconn.
It should be totally compatible with every function of pg.

Example
-------

    reguire 'xpg'

    @db = XPGconn.open(:dbname => 'xpg')

    @db.insert('users', :username => 'geoffk', :active => false)

    @db.exec('select username, active from users').each do |u|
      puts u['username']
      puts u[:username]
      puts u.username

      # Active has been converted into a boolean
      if u.active
        puts "Is active"
      else
        puts "Is not active"
      end
    end


