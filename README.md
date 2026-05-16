# plsql-uuid-v7

[![Version](https://img.shields.io/badge/version-1.2.0-informational)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![RFC 9562](https://img.shields.io/badge/RFC%209562-compliant-brightgreen)](docs/rfc9562-compliance.md)
[![Oracle](https://img.shields.io/badge/Oracle-12c%2B-red?logo=oracle)](docs/getting-started.md)

UUID v7 implementation compliant with RFC 9562 with monotonic generation support for Oracle databases without native UUID v7 support.

## Overview

The `plsql-uuid-v7` library provides a PL/SQL implementation of UUID version 7, which is designed to be compliant with RFC 9562. This library allows developers to generate unique identifiers that are both time-based and monotonic, ensuring that UUIDs can be generated in a consistent manner across different sessions and instances.

## Features

- **UUID v7 Generation**: Generate UUIDs that are compliant with RFC 9562.
- **Epoch-Based Generation**: Generate UUIDs anchored to a caller-supplied Unix epoch millisecond timestamp, useful for backfilling historical records.
- **Monotonic Generation**: Ensure that UUIDs are generated in a monotonic sequence, preventing duplicates during bulk operations.
- **Version Introspection**: Query the installed package version at runtime via `pl_uuidv7.get_version()`.
- **Oracle Compatibility**: Works seamlessly with Oracle databases that do not have native support for UUID v7.

## Installation

> **Prerequisite:** `EXECUTE` privilege on `DBMS_CRYPTO` is required. See the [Getting Started guide](docs/getting-started.md) for full setup steps.

Connect to your target schema and run:

```sql
@install/install.sql
```

This compiles the package specification and body into the connected schema.

To remove the package:

```sql
@install/uninstall.sql
```

## Usage

The `pl_uuidv7` package exposes a version constant, a version function, and two UUID generation functions:

**Check the installed package version:**

```sql
SELECT pl_uuidv7.get_version() AS version FROM dual;
```

**Generate a UUID v7 using the current system timestamp:**

```sql
SELECT pl_uuidv7.generate_uuid() AS uuid FROM dual;
```

**Generate a UUID v7 using a caller-supplied Unix epoch timestamp (milliseconds):**

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

This overload is useful for backfilling historical records with UUIDs anchored to a specific point in time. The session-scoped monotonicity counter is shared across both overloads.

For more advanced usage, including monotonic generation and benchmarking, refer to the examples provided in the `examples/` directory.

| Example | Description |
|---------|-------------|
| [basic_usage.sql](examples/basic_usage.sql) | Generate a single UUID v7 |
| [monotonic_generation.sql](examples/monotonic_generation.sql) | Generate UUIDs in a loop |
| [benchmark_sysguid_vs_uuidv7.sql](examples/benchmark_sysguid_vs_uuidv7.sql) | Full benchmark: inserts/sec, index fragmentation, ordering I/O |

## Documentation

- [Getting Started](docs/getting-started.md)
- [API Reference](docs/api-reference.md)
- [RFC 9562 Compliance](docs/rfc9562-compliance.md)

## Performance

UUID v7 has measurable advantages over `SYS_GUID()` in Oracle:

| Metric | SYS_GUID() | UUID v7 |
|--------|-----------|--------|
| Key ordering | Random | Time-ordered |
| Index fragmentation | High (random inserts scatter pages) | Low (sequential inserts fill pages) |
| `ORDER BY` I/O | Requires sort (higher consistent gets) | Index full scan (no sort needed) |
| Insert throughput | Baseline | Comparable, slight overhead from `DBMS_CRYPTO` |

Run the included benchmark to measure results on your specific hardware and Oracle version:

```sql
@examples/benchmark_sysguid_vs_uuidv7.sql
```

The script tests 50,000 row inserts, index fragmentation via `ANALYZE INDEX ... VALIDATE STRUCTURE`, and `ORDER BY` logical reads via `V$MYSTAT`.

> **Requirement:** `SELECT` privilege on `V$MYSTAT` and `V$STATNAME` for the I/O metric.

## Known Limitations

- The implementation relies on the underlying database's capabilities for handling concurrent sessions. Ensure that your database configuration is optimized for high concurrency if you plan to use this library in a multi-user environment.

## Project Structure

```
plsql-uuid-v7/
├── src/
│   ├── main/oracle/packages/      # pl_uuidv7.pks, pl_uuidv7.pkb
│   └── test/oracle/pl_uuidv7/     # test_uuidv7.sql, test_uuidv7_monotonic.sql
├── install/                       # install.sql, uninstall.sql
├── examples/                      # basic_usage.sql, monotonic_generation.sql, benchmark_sysguid_vs_uuidv7.sql
├── docs/                          # getting-started.md, api-reference.md, rfc9562-compliance.md
├── .editorconfig
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
