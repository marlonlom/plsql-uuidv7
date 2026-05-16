# Getting Started with plsql-uuid-v7

Welcome to the plsql-uuid-v7 library! This library provides an implementation of UUID version 7 compliant with RFC 9562, designed for Oracle databases that do not have native support for UUID v7. This guide will help you get started with installation and basic usage.

## Installation

1. **Connect to your target schema** using SQL*Plus, SQLcl, or SQL Developer.

2. **Grant the required privilege** (if not already done):

   ```sql
   GRANT EXECUTE ON DBMS_CRYPTO TO <your_schema>;
   ```

3. **Run the installation script**:

   ```sql
   @install/install.sql
   ```

   This compiles `pl_uuidv7.pks` and `pl_uuidv7.pkb` into the connected schema.

4. **To uninstall**:

   ```sql
   @install/uninstall.sql
   ```

## Basic Usage

Once installed, verify the installation and check the package version:

```sql
SELECT pl_uuidv7.get_version() AS version FROM dual;
```

Expected output: `1.2.0`

Generate a UUID v7 with:

```sql
SELECT pl_uuidv7.generate_uuid() AS uuid_v7 FROM dual;
```

Sample output:

```
uuid_v7
--------------------------------------
0190fea2-3b1c-7a4d-89f3-1c2e4d5f6a7b
```

### Epoch-Based Generation

When you need a UUID anchored to a specific point in time — for example, backfilling historical records — pass a Unix epoch millisecond value directly:

```sql
DECLARE
  v_epoch NUMBER;
  v_uuid  VARCHAR2(36);
BEGIN
  v_epoch := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
  v_uuid  := pl_uuidv7.generate_uuid(v_epoch);
  DBMS_OUTPUT.PUT_LINE('UUID v7: ' || v_uuid);
END;
/
```

The leading 48 bits of the returned UUID encode the supplied `p_epoch_ms` value, so the UUID is time-ordered relative to that timestamp.

### Monotonic Generation

Monotonicity is **built into both overloads of `generate_uuid`** via session-scoped package state. No separate function is needed. When multiple UUIDs are requested within the same millisecond — whether using the system clock or the same `p_epoch_ms` value — an internal counter ensures they remain unique and ordered — no extra configuration required.

### Running the Tests

```sql
@src/test/oracle/pl_uuidv7/test_uuidv7.sql
@src/test/oracle/pl_uuidv7/test_uuidv7_monotonic.sql
```

## Additional Resources

- [API Reference](api-reference.md)
- [RFC 9562 Compliance](rfc9562-compliance.md)
- [Examples](../examples/basic_usage.sql)