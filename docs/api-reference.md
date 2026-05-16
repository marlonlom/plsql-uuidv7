# API Reference for plsql-uuid-v7

## Overview

The `pl_uuidv7` package exposes a version constant, a version function, and two overloaded UUID generation functions. Monotonicity is handled automatically via session-scoped package state — no separate function is required.

## Package: `pl_uuidv7`

### `VERSION`

```sql
VERSION CONSTANT VARCHAR2(10) := '1.2.0';
```

#### Description

A package-level constant exposing the library version string. Queryable at runtime:

```sql
SELECT pl_uuidv7.VERSION FROM dual;
```

---

### `get_version`

```sql
FUNCTION get_version RETURN VARCHAR2;
```

#### Description

Returns the package version string. Equivalent to reading the `VERSION` constant directly but available as a callable function, which is useful in PL/SQL contexts where a function call is required.

#### Parameters

None.

#### Returns

`VARCHAR2(10)` — Semantic version string (e.g. `'1.2.0'`).

#### Example

```sql
-- As a function call in PL/SQL
DECLARE
  v_ver VARCHAR2(10);
BEGIN
  v_ver := pl_uuidv7.get_version();
  DBMS_OUTPUT.PUT_LINE('Package version: ' || v_ver);
END;
/

-- Or inline
SELECT pl_uuidv7.get_version() AS version FROM dual;
```

---

### `generate_uuid`

```sql
FUNCTION generate_uuid RETURN VARCHAR2;
```

#### Description

Generates a UUID version 7 compliant with RFC 9562 using the current system timestamp (`SYSDATE`). Each call returns a lowercase, hyphen-separated UUID string. Within a session, UUIDs are guaranteed to be monotonically increasing: if two calls occur within the same millisecond, an internal counter ensures uniqueness and order.

#### Parameters

None.

#### Returns

`VARCHAR2(36)` — UUID in canonical format: `xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx`

Where:
- `7` is the fixed version nibble at position 15
- `y` is one of `8`, `9`, `a`, `b` (RFC 9562 variant)

#### Dependencies

- `DBMS_CRYPTO.RANDOMBYTES` — requires `EXECUTE` privilege on `DBMS_CRYPTO`
- `UTL_RAW` — available by default in Oracle 11g+

#### Example

```sql
DECLARE
  v_uuid VARCHAR2(36);
BEGIN
  v_uuid := pl_uuidv7.generate_uuid();
  DBMS_OUTPUT.PUT_LINE('UUID v7: ' || v_uuid);
END;
/
```

---

### `generate_uuid` (epoch-based)

```sql
FUNCTION generate_uuid(p_epoch_ms IN NUMBER) RETURN VARCHAR2;
```

#### Description

Generates a UUID version 7 compliant with RFC 9562 using a caller-supplied Unix epoch timestamp in milliseconds. Useful when you need UUIDs tied to a specific point in time — for example, backfilling historical records. Within the same session and millisecond value, the internal monotonic counter still guarantees uniqueness and strict ordering.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `p_epoch_ms` | `NUMBER` | Unix epoch timestamp in milliseconds (milliseconds elapsed since 1970-01-01 00:00:00 UTC). |

#### Returns

`VARCHAR2(36)` — UUID in canonical format: `xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx`

Where:
- `7` is the fixed version nibble at position 15
- `y` is one of `8`, `9`, `a`, `b` (RFC 9562 variant)
- The leading 48 bits encode the provided `p_epoch_ms` value

#### Dependencies

- `DBMS_CRYPTO.RANDOMBYTES` — requires `EXECUTE` privilege on `DBMS_CRYPTO`
- `UTL_RAW` — available by default in Oracle 11g+

#### Example

```sql
DECLARE
  v_epoch NUMBER;
  v_uuid  VARCHAR2(36);
BEGIN
  -- Unix epoch ms for 2024-01-01 00:00:00 UTC
  v_epoch := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
  v_uuid  := pl_uuidv7.generate_uuid(v_epoch);
  DBMS_OUTPUT.PUT_LINE('UUID v7: ' || v_uuid);
END;
/
```

## Usage Examples

### Inline query

```sql
SELECT pl_uuidv7.generate_uuid() AS uuid_v7 FROM dual;
```

### Inline query (epoch-based)

```sql
SELECT pl_uuidv7.generate_uuid(
         (DATE '2024-01-01' - DATE '1970-01-01') * 86400000
       ) AS uuid_v7 FROM dual;
```

### PL/SQL block

```sql
DECLARE
  v_uuid VARCHAR2(36);
BEGIN
  v_uuid := pl_uuidv7.generate_uuid();
  DBMS_OUTPUT.PUT_LINE('UUID v7: ' || v_uuid);
END;
/
```

### PL/SQL block (epoch-based)

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

### Bulk insert

```sql
INSERT INTO orders (order_id, created_at)
SELECT pl_uuidv7.generate_uuid(), SYSDATE
FROM dual
CONNECT BY LEVEL <= 1000;
```

### Bulk insert (epoch-based backfill)

```sql
DECLARE
  v_epoch NUMBER := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
BEGIN
  INSERT INTO orders (order_id, created_at)
  SELECT pl_uuidv7.generate_uuid(v_epoch), DATE '2024-01-01'
  FROM dual
  CONNECT BY LEVEL <= 1000;
  COMMIT;
END;
/
```

## Error Handling

`generate_uuid` raises a standard Oracle exception if `DBMS_CRYPTO.RANDOMBYTES` is unavailable (missing `EXECUTE` grant). Grant it with:

```sql
GRANT EXECUTE ON DBMS_CRYPTO TO <your_schema>;
```

## Compliance

See [RFC 9562 Compliance](rfc9562-compliance.md) for full bit-level documentation.