#!/usr/bin/env ruby
require 'rubygems'
require '../lib/xpg'
require 'benchmark'
include Benchmark


@xdb = XPGconn.open(:dbname => 'xpg', :host => '/tmp/')
@db = PGconn.open(:dbname => 'xpg', :host => '/tmp/')

@xdb.exec('drop table if exists speed')
@xdb.exec('create table speed( i1 integer, i2 integer, f1 float, f2 float, a1 text, a2 text);')

10000.times do 
  @xdb.insert('speed',
     { :i1 => rand(9999),
       :i2 => rand(9999),
       :f1 => rand(9999)/3,
       :f2 => rand(9999)/3,
       :a1 => 'hello' * 10,
       :a2 => 'hello' * 10 })
end


def select(conn)
  conn.exec('select * from speed').each do |r|
    r['i1'] + r['i2']
    r['f1'] + r['f2']
    r['a1'] + r['a2']
  end
end


n = 50000
Benchmark.benchmark(" "*7 + CAPTION, 7, FMTSTR, ">total:", ">avg:") do |x|
  tf = x.report("pg:")   { select(@db) }
  tf = x.report("xpg:")   { select(@xdb) }
end

 


@xdb.exec('drop table speed')
