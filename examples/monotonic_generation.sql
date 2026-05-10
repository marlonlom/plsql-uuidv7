/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* Monotonic generation example for pl_uuidv7 */
/* Generates 10 UUIDs in rapid succession. */
/* Monotonicity is guaranteed within the session by package-level state. */

SET SERVEROUTPUT ON;

DECLARE
  v_uuid VARCHAR2(36);
BEGIN
  FOR i IN 1..10 LOOP
    v_uuid := pl_uuidv7.generate_uuid();
    DBMS_OUTPUT.PUT_LINE('UUID ' || LPAD(i, 2) || ': ' || v_uuid);
  END LOOP;
END;
/
SET SERVEROUTPUT OFF;

/* Bulk insert example: generate 1000 UUIDs directly into a table */
/*
 * INSERT INTO my_table (id, created_at)
 * SELECT pl_uuidv7.generate_uuid(), SYSDATE
 * FROM dual
 * CONNECT BY LEVEL <= 1000;
 */
