/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* Monotonic generation example for pl_uuidv7 */
/* Demonstrates both overloads of generate_uuid in rapid succession. */
/* Monotonicity is guaranteed within the session by package-level state. */

SET SERVEROUTPUT ON;

/* ================================================================
   Example 1: generate_uuid() — current system timestamp
   Generates 10 UUIDs using SYSDATE. Each call within the same
   millisecond increments the internal counter, ensuring ordering.
   ================================================================ */
DECLARE
  v_uuid VARCHAR2(36);
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- generate_uuid() ---');
  FOR i IN 1..10 LOOP
    v_uuid := pl_uuidv7.generate_uuid();
    DBMS_OUTPUT.PUT_LINE('UUID ' || LPAD(i, 2) || ': ' || v_uuid);
  END LOOP;
END;
/

/* ================================================================
   Example 2: generate_uuid(p_epoch_ms) — caller-supplied epoch ms
   Generates 10 UUIDs tied to the same fixed millisecond.
   The shared session-scoped counter guarantees each UUID is unique
   and monotonically ordered even when p_epoch_ms is identical.
   ================================================================ */
DECLARE
  v_uuid     VARCHAR2(36);
  v_epoch_ms NUMBER;
BEGIN
  v_epoch_ms := (SYSDATE - DATE '1970-01-01') * 86400000;
  DBMS_OUTPUT.PUT_LINE('--- generate_uuid(p_epoch_ms) ---');
  FOR i IN 1..10 LOOP
    v_uuid := pl_uuidv7.generate_uuid(TRUNC(v_epoch_ms));
    DBMS_OUTPUT.PUT_LINE('UUID ' || LPAD(i, 2) || ': ' || v_uuid);
  END LOOP;
END;
/

SET SERVEROUTPUT OFF;

/* ================================================================
   Bulk insert examples: generate 1000 UUIDs directly into a table
   ================================================================ */

/* Using generate_uuid() — timestamp from SYSDATE at each call */
/*
 * INSERT INTO my_table (id, created_at)
 * SELECT pl_uuidv7.generate_uuid(), SYSDATE
 * FROM dual
 * CONNECT BY LEVEL <= 1000;
 */

/* Using generate_uuid(p_epoch_ms) — backfill with a fixed timestamp */
/*
 * DECLARE
 *   v_epoch NUMBER := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
 * BEGIN
 *   INSERT INTO my_table (id, created_at)
 *   SELECT pl_uuidv7.generate_uuid(v_epoch), DATE '2024-01-01'
 *   FROM dual
 *   CONNECT BY LEVEL <= 1000;
 *   COMMIT;
 * END;
 * /
 */
