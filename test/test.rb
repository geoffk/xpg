#!/usr/bin/env ruby
require 'rubygems'
require '../lib/xpg'
require 'test/unit'


class TC_x_pg < Test::Unit::TestCase

  def setup
    @db = XPGconn.open(:dbname => 'xpg', :host => '/tmp/')

    @db.exec <<-SQL
      create temp table xpg_table (
        id serial primary key,
        string text,
        number integer,
        b boolean,
        d date,
        t timestamp
      );
      insert into xpg_table(string,number, b, d, t) values ('my string', 10, true, 
        '1/1/2010', '1/1/2010 14:23:01');
      insert into xpg_table(string,number) values (null, 20);
      insert into xpg_table(string,number) values ('my second string', 30);
    SQL
  end

  def teardown
    @db.close
  end

  def test_exec
    res = @db.exec('select * from xpg_table order by number')
    assert_equal res.ntuples, res.length
    assert_equal 'my string', res[0][:string]
    assert res[1][:string].nil?
    assert_equal 10, res[0][:number]
    assert res[0][:b]
    assert_equal 2010, res[0][:d].year
    assert_equal 2010, res[0][:t].year
    assert_equal 23, res[0][:t].min
    res.each do |r|
      assert_equal XPGrow,r.class
      h = r.to_hash
      assert_equal Hash,h.class
      assert_equal h['string'], r['string']
      assert_equal h['string'], r[:string]
      assert_equal h['string'], r.string
    end
  end 

  def test_formats
    res = @db.exec('select * from xpg_table order by number')
    assert_equal String, res[0].string.class
    assert res[0].number.kind_of? Integer
    assert_equal TrueClass, res[0].b.class
    assert_equal Date, res[0].d.class
    assert_equal Time, res[0].t.class
  end

  def test_insert
    id = @db.insert('xpg_table',{:string => 'my string', :number => 5},'id')
    assert_equal 4,id.to_i
    r = @db.exec("select * from xpg_table where id = $1", [id])[0]
    assert_equal 'my string', r.string
    assert_equal 5, r.number.to_i

    id = @db.insert('xpg_table',{:string => nil, :number => 80},'id')
    assert_equal 5,id.to_i
    r = @db.exec("select * from xpg_table where id = $1", [id])[0]
    assert r.string.nil?
  end

  def test_bad_row
    res =  @db.exec('select * from xpg_table order by number')
    assert_nil res[res.length]
  end

end

