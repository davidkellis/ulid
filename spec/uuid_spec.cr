require "./spec_helper"

describe UUID do

  describe "#to_i" do
    it "returns the UInt128 that it was initialized with" do
      t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
      r = Random.new(5)   # first rand64 is 1111101101010101101010110010100000001111010111011110_101110101001, second rand64 is 01_11110001111010111111111000010101011001100000001010010101111111

      expected_uuid_int = 1455531630000_u128 << 80 | 0b01111011101010011011110001111010111111111000010101011001100000001010010101111111_u128
      uuid_int = UUID::V7Factory.new(r).uint(t)
      (uuid_int >> 80).should eq(1455531630000_u128)
      uuid_int.should eq(expected_uuid_int)
    end
  end

  describe "#to_ulid" do
    it "returns the UUID encoded representation of the UInt128 that it was initialized with" do
      t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
      r = Random.new(5)   # first rand64 is 1111101101010101101010110010100000001111010111011110_101110101001, second rand64 is 01_11110001111010111111111000010101011001100000001010010101111111

      expected_uuid_int = 1455531630000_u128 << 80 | 0b01111011101010011011110001111010111111111000010101011001100000001010010101111111_u128
      uuid = UUID::V7Factory.new(r).uuid(t)
      # ulid_u128 = ulid.value
      # ulid_with_zero_version_and_variant    = ulid_u128 & 0xFFFFFFFFFFFF0FFF3FFFFFFFFFFFFFFF_u128
      # ulid_with_uuid_v7_version_and_variant = ulid_u128 | 0x00000000000070008000000000000000_u128
      ulid = uuid.to_ulid
      ulid.to_u128.should eq(expected_uuid_int)
    end
  end


  describe "Factory" do
    describe "#uint" do
      it "returns a UUID represented as a UInt128" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)   # first rand64 is 1111101101010101101010110010100000001111010111011110_101110101001, second rand64 is 01_11110001111010111111111000010101011001100000001010010101111111

        expected_uuid_int = 1455531630000_u128 << 80 | 0b01111011101010011011110001111010111111111000010101011001100000001010010101111111_u128
        uuid_int = UUID::V7Factory.new(r).uint(t)
        uuid_int.should eq(expected_uuid_int)
      end

      it "returns random uuids if run multiple times within the same millisecond" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)
        factory = UUID::V7Factory.new(r)
        5.times.map { factory.uint(t) }.to_a.should eq([1759629768773351156664225122108876159_u128,
                                                        1759629768773338151579029711901538012_u128,
                                                        1759629768773317157488385392502006303_u128,
                                                        1759629768773345140999183354841663799_u128,
                                                        1759629768773301663717422713640603429_u128] of UInt128)
      end

      it "should be sortable across different times" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        1000.times do
          t2 = t + 1.millisecond
          uuid_1 = UUID.uint(t)
          uuid_2 = UUID.uint(t2)

          (uuid_2 > uuid_1).should be_true

          t += 1.millisecond
        end
      end

      it "should not be sortable across multiple invocations at the same millisecond mark" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        uuids = 1000.times.map { UUID.uint(t) }.to_a
        sorted = uuids.sort
        uuids.should_not eq(sorted)
      end

      it "should be seedable" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        1000.times do
          uuid_1 = UUID.uint(t)
          uuid_2 = UUID.uint(t - 1.second)

          (uuid_2 < uuid_1).should be_true

          t += 1.millisecond
        end
      end
    end

    describe "#uuid" do
      it "returns a UUID represented as a UUID object" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)   # first rand64 is 1111101101010101101010110010100000001111010111011110_101110101001, second rand64 is 01_11110001111010111111111000010101011001100000001010010101111111

        expected_uuid_int = 1455531630000_u128 << 80 | 0b01111011101010011011110001111010111111111000010101011001100000001010010101111111_u128
        expected_uuid = UUID.from_u128(expected_uuid_int)
        uuid = UUID::V7Factory.new(r).uuid(t)
        uuid.should eq(expected_uuid)
      end

      it "returns random uuids if run multiple times within the same millisecond" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)     # 1455531630000_u128 milliseconds past unix epoch
        r = Random.new(5)
        factory = UUID::V7Factory.new(r)
        5.times.map { factory.uuid(t) }.to_a.should eq(([1759629768773351156664225122108876159_u128,
                                                         1759629768773338151579029711901538012_u128,
                                                         1759629768773317157488385392502006303_u128,
                                                         1759629768773345140999183354841663799_u128,
                                                         1759629768773301663717422713640603429_u128] of UInt128).map{|i| UUID.from_u128(i) })
      end

      it "should be sortable across different times" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        1000.times do
          t2 = t + 1.millisecond
          uuid_1 = UUID.v7(t)
          uuid_2 = UUID.v7(t2)

          (uuid_2 > uuid_1).should be_true

          t += 1.millisecond
        end
      end

      it "should not be sortable across multiple invocations at the same millisecond mark" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        uuids = 1000.times.map { UUID.v7(t) }.to_a
        sorted = uuids.sort
        uuids.should_not eq(sorted)
      end

      it "should be seedable" do
        t = Time.utc(2001, 1, 1, 12, 0, 0)
        1000.times do
          uuid_1 = UUID.uint(t)
          uuid_2 = UUID.uint(t - 1.second)

          (uuid_2 < uuid_1).should be_true

          t += 1.millisecond
        end
      end
    end

    describe "#rand64" do
      it "works with Random.new or Random::Secure" do
        UUID::V7Factory.new(Random.new(5)).rand64.should eq(18110569665085172649_u64)

        UUID::V7Factory.new(Random::Secure).rand64.should_not eq(0)
      end
    end

    describe "#gen_time" do
      it "returns a UInt64 with the high-order 16 bits zeroed out and the low-order 48 bits representing the number of milliseconds since Unix epoch" do
        t = Time.utc(2016, 2, 15, 10, 20, 30)
        UUID::V7Factory.new.gen_time(t).should eq(1455531630000_u64)
      end
    end

  end

end
