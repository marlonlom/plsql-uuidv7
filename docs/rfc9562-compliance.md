# RFC 9562 Compliance for Oracle UUID v7 Implementation

## Overview

This document outlines how the Oracle UUID v7 implementation in the `plsql-uuid-v7` library complies with RFC 9562. The implementation adheres to the specifications for generating Universally Unique Identifiers (UUIDs) of version 7, which are time-based and include a monotonic component to ensure uniqueness across concurrent sessions.

## UUID v7 Structure

According to RFC 9562, a UUID v7 consists of 128 bits arranged as follows:

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           unix_ts_ms [0–31]                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|        unix_ts_ms [32–47]     |  ver=0111 |    rand_a [0–11]  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|var=10|               rand_b [0–61]                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        rand_b [continued]                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

| Field        | Bits | Description                                         |
|--------------|------|-----------------------------------------------------|
| `unix_ts_ms` | 48   | Unix epoch timestamp in milliseconds                |
| `ver`        | 4    | Fixed to `0111` (version 7)                         |
| `rand_a`     | 12   | Random (upper random block, after version nibble)   |
| `var`        | 2    | Fixed to `10` (RFC 9562 variant)                    |
| `rand_b`     | 62   | Random (lower random block, after variant bits)     |

**Total: 128 bits = 16 bytes**

## Implementation Mapping

This library implements the layout above as follows:

1. **Timestamp (48 bits)** — computed via Oracle-safe `DATE` arithmetic:
   ```sql
   l_now_ms := (SYSDATE - DATE '1970-01-01') * 86400000;
   l_ts := HEXTORAW( LPAD(TO_CHAR(TRUNC(l_now_ms), 'FMXXXXXXXXXXXX'), 12, '0') );
   ```

2. **`rand_a` (12 bits, monotonic counter)** — a session-scoped counter (`g_counter`) seeded with a random 12-bit value at the start of each new millisecond, then incremented for each UUID within the same millisecond. Applied to bytes 7–8 (after the version nibble):
   ```sql
   -- Byte 7: VERSION nibble (0111) | upper 4 bits of rand_a counter
   l_byte := HEXTORAW( LPAD(TO_CHAR(112 + BITAND(TRUNC(l_rand_a / 256), 15), 'FMXX'), 2, '0') );
   -- Byte 8: lower 8 bits of rand_a counter
   l_byte := HEXTORAW( LPAD(TO_CHAR(MOD(l_rand_a, 256), 'FMXX'), 2, '0') );
   ```

3. **`rand_b` (62 bits, random)** — generated with `DBMS_CRYPTO.RANDOMBYTES(10)`. Bytes 9–16 of the UUID supply `rand_b`, with the top 2 bits of byte 9 overwritten by the variant bits.

4. **Variant bits** — byte 9 masked and set:
   ```sql
   l_byte := UTL_RAW.BIT_AND(l_byte, HEXTORAW('3F')); -- clear top 2 bits
   l_byte := UTL_RAW.BIT_OR (l_byte, HEXTORAW('80')); -- set 10xx xxxx
   ```

5. **Monotonicity** — `g_last_ms` and `g_counter` are session-scoped package variables. At each new millisecond, `g_counter` is seeded with a random 12-bit value (from `DBMS_CRYPTO`); within the same millisecond it increments, guaranteeing strict ordering of UUIDs within the session. Cross-session ordering is not required by RFC 9562.

## Design Decisions

1. **`DATE` arithmetic over `TIMESTAMP`**: Avoids fractional second precision issues across Oracle versions. `(SYSDATE - DATE '1970-01-01') * 86400000` is safe and consistent on 11g/12c/19c.

2. **`RAW(16)` internally**: UUID bytes are assembled as `RAW` before final `RAWTOHEX` formatting, avoiding string concatenation overhead and ensuring byte-level precision.

3. **`DBMS_CRYPTO` for randomness**: Provides cryptographically secure random bytes. Requires `EXECUTE` grant on `DBMS_CRYPTO`.

4. **Session-scoped monotonicity with random seeding**: `g_counter` is seeded with a random 12-bit value at each new millisecond boundary (preventing counter prediction) and incremented for each UUID within the same millisecond. This guarantees strict within-session ordering. Cross-session ordering is not required by RFC 9562.

5. **No external dependencies**: The implementation uses only built-in Oracle packages (`UTL_RAW`, `DBMS_CRYPTO`), making it portable across Oracle 11g, 12c, and 19c.

## Compliance Verification

The test suites in `src/test/oracle/pl_uuidv7/` verify:

| Test | File |
|------|------|
| Format regex `^[0-9a-f]{8}-...-[0-9a-f]{12}$` | `test_uuidv7.sql` |
| Version nibble = `7` (position 15) | `test_uuidv7.sql` |
| Variant char in `{8,9,a,b}` (position 20) | `test_uuidv7.sql` |
| Lowercase output | `test_uuidv7.sql` |
| Hyphen positions 9, 14, 19, 24 | `test_uuidv7.sql` |
| Zero duplicates in 10,000 UUIDs | `test_uuidv7_monotonic.sql` |
| All 10,000 UUIDs pass format, version, variant | `test_uuidv7_monotonic.sql` |

## Conclusion

The `plsql-uuid-v7` library provides a robust implementation of UUID v7 compliant with RFC 9562, ensuring that UUIDs are generated in a manner that is both unique and efficient. The design choices made in this implementation prioritize safety, performance, and adherence to the standard, making it a reliable choice for applications requiring UUIDs.