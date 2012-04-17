require 'pg'
require 'time'
require 'date'

# xpg is a wrapper for the postgres 'pg' module that adds some convenient
# extra features.

# The connection class. From a user's perspective you can just treat it
# as pg's PGconn class.
class XPGconn < PGconn
  BOOL_CONVERT = Proc.new{|value| 't' == value ? true : false }
  INT_CONVERT = Proc.new{|value| value.to_i }
  FLOAT_CONVERT = Proc.new{|value| value.to_f }
  DATE_CONVERT = Proc.new{|value| Date.parse(value) }
  TIME_CONVERT = Proc.new{|value| Time.parse(value) }
  STRING_CONVERT = Proc.new{|value| value }
  XPG_VERSION = 0.7

  alias parent_exec exec
  def exec(*args)
    XPGresult.new(super,self)
  end
  alias execute exec

  def initialize(*args)
    super
    setup_type_hash
  end

  # Convenience function for performing inserts.  Using this method you 
  # don't need to construct the sql yourself, simply pass in a hash of
  # values.
  #
  # For example:
  #   xpg.insert('users',{:name => 'barry', :uid => 7})
  #
  # Use the optional 'returning' parameter to return a single column 
  # from the insert.
  #
  def insert(table_name,value_hash,returning = nil)
    cols = Array.new
    vals = Array.new

    value_hash.each_pair do |col,val|
      cols << quote_ident(col.to_s)
      vals << val
    end

    sql = "insert into #{table_name}(#{cols.join(',')}) " +
          "values (#{(1 .. cols.length).map{|i| '$' + i.to_s}.join(',')})"

    begin
      if returning
        sql += " returning #{quote_ident returning.to_s}"
        return exec(sql,vals)[0][returning]
      else
        return exec(sql,vals)
      end
    rescue PGError => e
      raise e.to_s + "\nSQL:#{sql}\nHash: " + vals.inspect
    end
  end

  def oid_type_hash
    @oid_type_hash
  end

  private
 
  # Builds a hash with the oid as the key and a data conversion anonymous
  # function as the value.  Used to convert data to Ruby types. 
  def setup_type_hash
    @oid_type_hash = {}
    parent_exec('select typname,oid from pg_catalog.pg_type').each do |r|
      @oid_type_hash[r['oid'].to_i] = case r['typname'] 
        when /bool/ 
          BOOL_CONVERT
        when /^int/
          INT_CONVERT
        when /^float/, /money/, /numeric/ 
          FLOAT_CONVERT
        when /^date/ 
          DATE_CONVERT
        when /^time/ 
          TIME_CONVERT
        else STRING_CONVERT
      end
    end
  end
end

# Similar to the hash returned by PGresult except that all of the data
# values will be converted to their appropriate Ruby type.  You can also
# access the values using method names or a symbol.
#
# For example, to access the 'name' field of a row you can use any of the
# following:
#
#  row['name']
#  row[:name]
#  row.name
#
class XPGrow
  def initialize(tuple,xpgresult)
    @tuple = tuple
    @xpgresult = xpgresult
    @values = []
  end

  def [](col)
    value(col.to_s)
  end

  def method_missing(symbol)
    value(symbol.to_s)
  end

  def to_hash
    h = {}
    @xpgresult.fields.each do |k|
      h[k] = value(k)
    end
    h
  end

  private

  def value(col)
    return nil unless @xpgresult.valid_field?(col)

    index = @xpgresult.field_index(col)

    unless @values[index]
      if @xpgresult.getvalue(@tuple,index)
        @values[index] = @xpgresult.type_function(col).call(@xpgresult.getvalue(@tuple,index))
      else
        @values[index] = nil 
      end
    end

    return @values[index]
  end
end

# xpg's equivalent of pg's PGresult.  You can use it in exactly
# the same way that you would use PGresult.
class XPGresult
  def initialize(pgr,xpgconn)
    @pgr = pgr
    @xpgconn = xpgconn

    @columns = {}
    (0 ... nfields).map do |i|
      @columns[fname(i)] = {:index => i, :type => ftype(i)}
    end
  end

  def type(column)
    @columns[column][:type]
  end

  def type_function(column)
    @xpgconn.oid_type_hash[type(column)]
  end

  def valid_field?(column)
    return !!@columns[column]
  end

  def field_index(column)
    @columns[column][:index]
  end

  def method_missing(symbol,*args)
    @pgr.send(symbol,*args) if @pgr.respond_to?(symbol)
  end

  # Why is it called ntuples again?
  def length
    @pgr.ntuples
  end

  def empty?
    length == 0
  end

  # Operates identically to PGresult's method except that it returns
  # the new XPGrow.  Also it's about an order of magnitude slower because
  # it is converting each value to its appropriate Ruby type.
  def [](index)
    return row(index)
  end

  # Operates identically to PGresult's method except that it returns
  # the new XPGrow.  Also it's about an order of magnitude slower because
  # it is converting each value to it's appropriate Ruby type.
  def each
    @pgr.ntuples.times do |index|
      yield(row(index))
    end
  end

  private

  def row(tuple)
    return nil unless tuple < length
    XPGrow.new(tuple,self)
  end
end

