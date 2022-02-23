require "crockford"

# this implements ULID generation, as defined at https://github.com/ulid/spec
module ULID
  extend self
  
  # Generate a ULID
  #
  # ```
  # ULID.string
  # # => "01B3EAF48P97R8MP9WS6MHDTZ3"
  # ```
  def string(seed_time : Time = Time.utc, rand = Random.new) : String
    Crockford.encode(uint(seed_time, rand)).rjust(26, '0')
  end

  def uint(seed_time : Time = Time.utc, rand = Random.new) : UInt128
    # in these two operations, we put the 48 low-order bits from the unix timestamp in milliseconds into the 48 high-order bits of the 128-bit ulid
    ulid : UInt128 = UInt128::MAX & gen_time(seed_time)
    ulid = ulid << 80
    
    # at this point, the low-order 80 bits of the ulid are 0

    # in the following step, we put the 80 low-order bits from the random component (uint128) into the 80 low-order bits of the 128-bit ulid;
    # we perform a simple bitwise OR because the high-order 48 bits of the random component are guaranteed to be zero
    ulid = ulid | gen_rand(rand)
    ulid
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
  def gen_rand(rand) : UInt128
    rand128(rand) << 80 >> 80
  end

  def rand128(rand : Random | Random::Secure) : UInt128
    rand.rand(UInt64).to_u128 << 64 | rand.rand(UInt64)
  end

end
