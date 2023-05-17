require "crockford"
require "extlib"
require "uuid"

# this implements ULID generation, as defined at https://github.com/ulid/spec
class ULID
  class Factory
    property random : Random

    def initialize(@random = Random.new)
    end

    # Generate a ULID
    #
    # ```
    # ULID.string
    # # => "01B3EAF48P97R8MP9WS6MHDTZ3"
    # ```
    def string(seed_time : Time = Time.utc) : String
      Crockford.encode(uint(seed_time)).rjust(26, '0')
    end

    def uint(seed_time : Time = Time.utc) : UInt128
      # in these two operations, we put the 48 low-order bits from the unix timestamp in milliseconds into the 48 high-order bits of the 128-bit ulid
      ulid : UInt128 = UInt128::MAX & gen_time(seed_time)
      ulid = ulid << 80

      # at this point, the low-order 80 bits of the ulid are 0

      # in the following step, we put the 80 low-order bits from the random component (uint128) into the 80 low-order bits of the 128-bit ulid;
      # we perform a simple bitwise OR because the high-order 48 bits of the random component are guaranteed to be zero
      ulid = ulid | gen_rand(seed_time)
      ulid
    end

    def ulid(seed_time : Time = Time.utc) : ULID
      ULID.new(uint(seed_time))
    end

    def uuid(seed_time : Time = Time.utc) : UUID
      uint_ulid = uint(seed_time)
      UUID.from_u128(uint_ulid)
    end

    # returns a UInt64 with the high-order 16 bits zeroed out and the low-order 48 bits representing the number of milliseconds since Unix epoch
    def gen_time(time : Time) : UInt64
      # since 2^48 milliseconds is roughly 8920 years, we know we can just drop the 16 high-order bits from this 64-bit integer,
      # because they will all be zero until until roughly January 1 in the year 10,890 (8920+1970), at which point unix time in ms
      # will take more than 48 bits to represent
      current_time_unix_ms : Int64 = time.to_unix_ms
      current_time_unix_ms.to_u64
    end

    # returns a random UInt128 with the high-order 48 bits zeroed out
    def gen_rand(seed_time : Time) : UInt128
      rand128() << 80 >> 80
    end

    def rand128 : UInt128
      UInt128.rand(@random)
    end
  end

  class MonotonicFactory < Factory
    @prev_time : Time
    @prev_rand : UInt128

    def initialize(random = Random.new)
      super(random)
      @prev_time = Time.utc(1970, 1, 1, 0, 0, 1)
      @prev_rand = 0_u128
    end

    # returns a random UInt128 with the high-order 48 bits zeroed out
    def gen_rand(seed_time : Time) : UInt128
      new_rand = if seed_time == @prev_time
        @prev_rand + 1
      else
        @prev_time = seed_time
        rand128()
      end
      new_rand = new_rand << 80 >> 80
      @prev_rand = new_rand
      new_rand
    end
  end


  @@factory = Factory.new
  @@monotonic_factory = MonotonicFactory.new

  def self.ulid(seed_time : Time = Time.utc)
    @@factory.ulid(seed_time)
  end

  def self.string(seed_time : Time = Time.utc)
    @@factory.string(seed_time)
  end

  def self.uint(seed_time : Time = Time.utc)
    @@factory.uint(seed_time)
  end

  def self.uuid(seed_time : Time = Time.utc)
    @@factory.uuid(seed_time)
  end

  def self.monotonic_ulid(seed_time : Time = Time.utc)
    @@monotonic_factory.ulid(seed_time)
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


  include Comparable(ULID)

  property value : UInt128

  # Define a hash(hasher) method based on @value
  # Between #hash and #==, we can use ULID objects as values in Hashes
  def_hash @value

  def self.new(value : String)
    new(Crockford.decode128(value))
  end

  def self.new(uuid : UUID)
    new(uuid.to_u128)
  end

  def initialize(@value : UInt128)
  end

  def to_i
    @value
  end

  def to_s(io : IO) : Nil
    io << Crockford.encode(@value).rjust(26, '0')
  end

  def to_uuid
    UUID.from_u128(@value)
  end

  # implementing <=> and including Comparable will give us == for free
  def <=>(other : ULID)
    @value <=> other.value
  end
end
