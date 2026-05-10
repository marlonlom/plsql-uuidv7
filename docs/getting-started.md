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

Once installed, generate a UUID v7 with:

```sql
SELECT pl_uuidv7.generate_uuid() AS uuid_v7 FROM dual;
```

Sample output:

```
uuid_v7
--------------------------------------
0190fea2-3b1c-7a4d-89f3-1c2e4d5f6a7b
```

### Monotonic Generation

Monotonicity is **built into `generate_uuid`** via session-scoped package state. No separate function is needed. When multiple UUIDs are requested within the same millisecond, an internal counter ensures they remain unique and ordered — no extra configuration required.

### Running the Tests

```sql
@src/test/oracle/pl_uuidv7/test_uuidv7.sql
@src/test/oracle/pl_uuidv7/test_uuidv7_monotonic.sql
```

## Additional Resources

- [API Reference](api-reference.md)
- [RFC 9562 Compliance](rfc9562-compliance.md)
- [Examples](../examples/basic_usage.sql)