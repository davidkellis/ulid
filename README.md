# ulid

This library implements the ULID specification as defined at https://github.com/ulid/spec.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ulid:
       github: davidkellis/ulid
   ```

2. Run `shards install`

## Usage

```crystal
require "ulid"

puts ULID.string                # 01FWW2EFES00000005WZ2S1FJ4
puts ULID.uint                  # 1989788620795904033538720336259049107
puts ULID.uuid                  # 017f3827-3dd9-0000-0000-e11234e44a25

puts ULID.monotonic_string      # 01FWW2EFES0000003V8EMT3N0N
puts ULID.monotonic_uint        # 1989788620795904033538533323464025266
puts ULID.monotonic_uuid        # 017f3827-3dd9-0000-0000-2eee411f7b89


t = Time.utc
puts t                          # 2022-02-26 22:29:30 UTC

puts ULID.string(t)             # 01FWW2EFES0000005JH7TWRY67
puts ULID.uint(t)               # 1989788620795904033538751739225489211
puts ULID.uuid(t)               # 017f3827-3dd9-0000-0000-70b68bfe74d9

puts ULID.monotonic_string(t)   # 01FWW2EFES0000002REBEWA7QP
puts ULID.monotonic_uint(t)     # 1989788620795904033538608261870460663
puts ULID.monotonic_uuid(t)     # 017f3827-3dd9-0000-0000-5872ddc51ef8
```

## Specification (per https://github.com/ulid/spec as of 2022-02-24)

Below is the current specification of ULID as implemented in [ulid/javascript](https://github.com/ulid/javascript).

*Note: the binary format has not been implemented in JavaScript as of yet.*

```
 01AN4Z07BY      79KA1307SR9X4MV3

|----------|    |----------------|
 Timestamp          Randomness
   48bits             80bits
```

### Components

**Timestamp**
- 48 bit integer
- UNIX-time in milliseconds
- Won't run out of space 'til the year 10889 AD.

**Randomness**
- 80 bits
- Cryptographically secure source of randomness, if possible

### Sorting

The left-most character must be sorted first, and the right-most character sorted last (lexical order). The default ASCII character set must be used. Within the same millisecond, sort order is not guaranteed

### Canonical String Representation

```
ttttttttttrrrrrrrrrrrrrrrr

where
t is Timestamp (10 characters)
r is Randomness (16 characters)
```

#### Encoding

Crockford's Base32 is used as shown. This alphabet excludes the letters I, L, O, and U to avoid confusion and abuse.

```
0123456789ABCDEFGHJKMNPQRSTVWXYZ
```

### Monotonicity

When generating a ULID within the same millisecond, we can provide some
guarantees regarding sort order. Namely, if the same millisecond is detected, the `random` component is incremented by 1 bit in the least significant bit position (with carrying). For example:

```javascript
import { monotonicFactory } from 'ulid'

const ulid = monotonicFactory()

// Assume that these calls occur within the same millisecond
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVRZ
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVS0
```

If, in the extremely unlikely event that, you manage to generate more than 2<sup>80</sup> ULIDs within the same millisecond, or cause the random component to overflow with less, the generation will fail.

```javascript
import { monotonicFactory } from 'ulid'

const ulid = monotonicFactory()

// Assume that these calls occur within the same millisecond
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVRY
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVRZ
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVS0
ulid() // 01BX5ZZKBKACTAV9WEVGEMMVS1
...
ulid() // 01BX5ZZKBKZZZZZZZZZZZZZZZX
ulid() // 01BX5ZZKBKZZZZZZZZZZZZZZZY
ulid() // 01BX5ZZKBKZZZZZZZZZZZZZZZZ
ulid() // throw new Error()!
```

#### Overflow Errors when Parsing Base32 Strings

Technically, a 26-character Base32 encoded string can contain 130 bits of information, whereas a ULID must only contain 128 bits. Therefore, the largest valid ULID encoded in Base32 is `7ZZZZZZZZZZZZZZZZZZZZZZZZZ`, which corresponds to an epoch time of `281474976710655` or `2 ^ 48 - 1`.

Any attempt to decode or encode a ULID larger than this should be rejected by all implementations, to prevent overflow bugs.

### Binary Layout and Byte Order

The components are encoded as 16 octets. Each component is encoded with the Most Significant Byte first (network byte order).

```
0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      32_bit_uint_time_high                    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     16_bit_uint_time_low      |       16_bit_uint_random      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       32_bit_uint_random                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       32_bit_uint_random                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```


## Test

```bash
crystal spec
```

## Contributors

- [David Ellis](https://github.com/davidkellis) - creator and maintainer
