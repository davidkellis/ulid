require "./spec_helper"

describe ULID do
  describe "#rand128" do
    it "works with Random.new or Random::Secure" do
      ULID.rand128(Random.new(5)).should eq(334081043640913887584633984963796051327_u128)

      ULID.rand128(Random::Secure).should_not eq(0)
    end
  end

  describe "#gen_time" do
    it "returns a UInt64 with the high-order 16 bits zeroed out and the low-order 48 bits representing the number of milliseconds since Unix epoch" do
      t = Time.utc(2016, 2, 15, 10, 20, 30)
      ULID.gen_time(t).should eq(1455531630000_u64)
    end
  end

  describe "#gen_rand" do
    it "returns a random UInt128 with the high-order 48 bits zeroed out" do
      r = Random.new(5)
      ULID.gen_rand(r).should eq(0b111111111000010101011001100000001010010101111111)
    end
  end

  describe "#uint" do
    it "returns a ulid in the form of a UInt128" do
      t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
      r = Random.new(5)                         # first rand128 from this random generator should be 0b111111111000010101011001100000001010010101111111
      expected_ulid = 1455531630000_u128 << 80 | 0b111111111000010101011001100000001010010101111111
      ULID.uint(t, r).should eq(expected_ulid)
    end
  end

  describe "#string" do
    it "returns a ulid in the form of a string" do
      t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
      r = Random.new(5)                         # first rand128 from this random generator should be 0b111111111000010101011001100000001010010101111111
      expected_ulid_string = "01ABJ747DG0000007ZGNCR19BZ"
      ULID.string(t, r).should eq(expected_ulid_string)
    end

    it "should return correct length" do
      ULID.string.size.should eq(26)
    end

    it "should contain only correct chars" do
      (ULID.string =~ /[^0123456789ABCDEFGHJKMNPQRSTVWXYZ]/).should be_nil
    end

    it "should be in upcase" do
      res = ULID.string

      res.should eq(res.upcase)
    end

    it "should be unique" do
      len = 1000
      arr = [] of String

      len.times do
        arr << ULID.string
      end

      arr.uniq!

      arr.size.should eq(len)
    end

    it "should be sortable" do
      1000.times do
        ulid_1 = ULID.string
        sleep 1.millisecond
        ulid_2 = ULID.string

        (ulid_2 > ulid_1).should be_true
      end
    end

    it "should be seedable" do
      1000.times do
        ulid_1 = ULID.string
        sleep 1.millisecond
        ulid_2 = ULID.string(Time.utc - 1.second)

        (ulid_2 < ulid_1).should be_true
      end
    end
  end


end