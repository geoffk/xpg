XPG
===

Usage
-----

Just require 'xpg' and use it like pg, except use XPGconn instead of PGconn.
It should be totally compatible with pg, albeit slower because it
converts the fields to the appropriate Ruby objects.

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


