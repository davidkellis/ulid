require "crockford"
require "extlib"
require "uuid"

require "./factory"

# this implements ULID generation, as defined at https://github.com/ulid/spec
class ULID
  @@factory = Factory.new
  @@monotonic_factory = MonotonicFactory.new

  def self.string(seed_time : Time = Time.utc)
    @@factory.string(seed_time)
  end

  def self.uint(seed_time : Time = Time.utc)
    @@factory.uint(seed_time)
  end

  def self.uuid(seed_time : Time = Time.utc)
    @@factory.uuid(seed_time)
  end

  def self.monotonic_string(seed_time : Time = Time.utc)
    @@monotonic_factory.string(seed_time)
  end

  def self.monotonic_uint(seed_time : Time = Time.utc)
    @@monotonic_factory.uint(seed_time)
  end

  def self.monotonic_uuid(seed_time : Time = Time.utc)
    @@monotonic_factory.uuid(seed_time)
  end


  property value : UInt128

  def initialize(@value : UInt128)
  end

  def to_i
    @value
  end

  def to_s
    Crockford.encode(@value).rjust(26, '0')
  end

  def to_uuid
    UUID.from_u128(@value)
  end

end
