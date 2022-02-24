require "./spec_helper"

describe ULID do
  describe "Factory" do
    describe "#uint" do
      it "returns a ulid in the form of a UInt128" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)                         # first rand128 from this random generator should be 0b111111111000010101011001100000001010010101111111
        expected_ulid = 1455531630000_u128 << 80 | 0b111111111000010101011001100000001010010101111111
        ULID::Factory.new(r).uint(t).should eq(expected_ulid)
      end

      it "returns random ulids if run multiple times within the same millisecond" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)
        factory = ULID::Factory.new(r)
        5.times.map { factory.uint(t) }.to_a.should eq([1759629768772767174505916072544216447_u128, 1759629768772767174505897016764511964_u128, 1759629768772767174505895313516421663_u128, 1759629768772767174505780691930843447_u128, 1759629768772767174505885374298214181_u128] of UInt128)
      end
    end

    describe "#string" do
      it "returns a ulid in the form of a string" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)                         # first rand128 from this random generator should be 0b111111111000010101011001100000001010010101111111
        expected_ulid_string = "01ABJ747DG0000007ZGNCR19BZ"
        ULID::Factory.new(r).string(t).should eq(expected_ulid_string)
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

    describe "#rand128" do
      it "works with Random.new or Random::Secure" do
        ULID::Factory.new(Random.new(5)).rand128.should eq(334081043640913887584633984963796051327_u128)

        ULID::Factory.new(Random::Secure).rand128.should_not eq(0)
      end
    end

    describe "#gen_time" do
      it "returns a UInt64 with the high-order 16 bits zeroed out and the low-order 48 bits representing the number of milliseconds since Unix epoch" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)
        ULID::Factory.new.gen_time(t).should eq(1455531630000_u64)
      end
    end

    describe "#gen_rand" do
      it "returns a random UInt128 with the high-order 48 bits zeroed out" do
        r = Random.new(5)
        ULID::Factory.new(r).gen_rand(Time.utc).should eq(0b111111111000010101011001100000001010010101111111)
      end
    end
  end

  describe "MonotonicFactory" do
    describe "#uint" do
      it "returns sequential ulids if run multiple times within the same millisecond" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)
        factory = ULID::MonotonicFactory.new(r)
        5.times.map { factory.uint(t) }.to_a.should eq([1759629768772767174505897016764511964_u128, 1759629768772767174505897016764511965_u128, 1759629768772767174505897016764511966_u128, 1759629768772767174505897016764511967_u128, 1759629768772767174505897016764511968_u128] of UInt128)
      end
    end
  end
end