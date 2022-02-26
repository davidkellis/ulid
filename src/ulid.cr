require "crockford"
require "uuid"

# monkey patch UUID to introduce a new class method onto UUID
struct UUID
  def self.from_u128(u128 : UInt128, version : UUID::Version? = nil, variant : UUID::Variant? = nil) : UUID
    UUID.new(UInt128.bytes(pointerof(u128)), variant, version)
  end
end

# monkey patch UInt128 to introduce a new class method onto UInt128
struct UInt128
  # converts the u128 into a slice of bytes in which bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128
  def self.bytes(u128_p : Pointer(UInt128)) : Slice(UInt8)
    u8_p = u128_p.as(UInt8*)
    u8_p.to_slice(16)     # bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128
  end

  # converts a slice of bytes in which bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128 back into the corresponding u128
  def self.from_bytes(bytes : Bytes | StaticArray(UInt8, 16)) : UInt128
    bytes.to_a.reverse.reduce(0_u128) {|acc, byte| (acc << 8) | byte }
  end

  def self.rand(random : Random = Random) : UInt128
    random.rand(UInt64).to_u128 << 64 | random.rand(UInt64)
  end
end

# this implements ULID generation, as defined at https://github.com/ulid/spec
module ULID
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
      # @random.rand(UInt64).to_u128 << 64 | @random.rand(UInt64)
      UInt128.rand(@random)
    end
  end

  class MonotonicFactory < Factory
    @prev_time : Time
    @prev_rand : UInt128

    def initialize(@random = Random.new)
      @prev_time = Time.utc(1970, 1, 1, 0, 0, 1)
      @prev_rand = rand128()
    end

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

end
