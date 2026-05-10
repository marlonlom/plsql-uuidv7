# API Reference for plsql-uuid-v7

## Overview

The `pl_uuidv7` package exposes a single function for UUID v7 generation. Monotonicity is handled automatically via session-scoped package state — no separate function is required.

## Package: `pl_uuidv7`

### `generate_uuid`

```sql
FUNCTION generate_uuid RETURN VARCHAR2;
```

#### Description

Generates a UUID version 7 compliant with RFC 9562. Each call returns a lowercase, hyphen-separated UUID string. Within a session, UUIDs are guaranteed to be monotonically increasing: if two calls occur within the same millisecond, an internal counter ensures uniqueness and order.

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

## Usage Examples

### Inline query

```sql
SELECT pl_uuidv7.generate_uuid() AS uuid_v7 FROM dual;
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

### Bulk insert

```sql
INSERT INTO orders (order_id, created_at)
SELECT pl_uuidv7.generate_uuid(), SYSDATE
FROM dual
CONNECT BY LEVEL <= 1000;
```

## Error Handling

`generate_uuid` raises a standard Oracle exception if `DBMS_CRYPTO.RANDOMBYTES` is unavailable (missing `EXECUTE` grant). Grant it with:

```sql
GRANT EXECUTE ON DBMS_CRYPTO TO <your_schema>;
```

## Compliance

See [RFC 9562 Compliance](rfc9562-compliance.md) for full bit-level documentation.