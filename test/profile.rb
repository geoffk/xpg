#!/usr/bin/ruby
require 'rubygems'
#require 'ruby-debug'
require 'xpg'
require 'ruby-prof'

@xdb = XPGconn.open(:dbname => 'xpg')

@xdb.exec('drop table if exists speed')
@xdb.exec('create table speed( i1 integer, i2 integer, f1 float, f2 float, a1 text, a2 text);')

100.times do 
  @xdb.insert('speed',
     { :i1 => rand(9999),
       :i2 => rand(9999),
       :f1 => rand(9999)/3,
       :f2 => rand(9999)/3,
       :a1 => 'hello' * 10,
       :a2 => 'hello' * 10 })
end


pgres = @xdb.exec('select * from speed')

RubyProf.start
pgres[0]
pgres[1]
pgres[2]
result = RubyProf.stop
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, 0)

@xdb.exec('drop table speed')
