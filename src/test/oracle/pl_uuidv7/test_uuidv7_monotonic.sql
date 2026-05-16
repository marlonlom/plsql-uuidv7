/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* ============================================================= */
/* Test: Monotonic generation - no duplicates in bulk UUID v7 */
/* Package: pl_uuidv7 */
/* Compatible: Oracle 11g / 12c / 19c */
/* ============================================================= */

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

SET SERVEROUTPUT ON;

DECLARE
  v_uuid        VARCHAR2(36);
  v_prev_uuid   VARCHAR2(36);
  v_count       NUMBER := 10000;
  v_duplicates  NUMBER := 0;
  v_passed      NUMBER := 0;
  v_failed      NUMBER := 0;
  v_uuid_table  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();

  PROCEDURE assert(p_label VARCHAR2, p_condition BOOLEAN) IS
  BEGIN
      IF p_condition THEN
          DBMS_OUTPUT.PUT_LINE('  PASS: ' || p_label);
          v_passed := v_passed + 1;
      ELSE
          DBMS_OUTPUT.PUT_LINE('  FAIL: ' || p_label);
          v_failed := v_failed + 1;
      END IF;
  END assert;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== UUID v7 Monotonic / Bulk Tests ===');
  DBMS_OUTPUT.PUT_LINE('Generating ' || v_count || ' UUIDs...');
  DBMS_OUTPUT.PUT_LINE('');

  /* ========================================================= */
  /* Generate UUIDs and store in collection */
  /* ========================================================= */
  FOR i IN 1..v_count LOOP
      v_uuid := pl_uuidv7.generate_uuid();
      v_uuid_table.EXTEND;
      v_uuid_table(v_uuid_table.COUNT) := v_uuid;
  END LOOP;

  /* ========================================================= */
  /* Test 1: No duplicates in bulk generation */
  /* ========================================================= */
  SELECT COUNT(*) - COUNT(DISTINCT column_value)
    INTO v_duplicates
    FROM TABLE(v_uuid_table);

  assert('No duplicates in ' || v_count || ' UUIDs', v_duplicates = 0);

  /* ========================================================= */
  /* Test 2: All UUIDs have correct length */
  /* ========================================================= */
  DECLARE
      v_bad_length NUMBER;
  BEGIN
      SELECT COUNT(*)
        INTO v_bad_length
        FROM TABLE(v_uuid_table)
       WHERE LENGTH(column_value) != 36;

      assert('All UUIDs have length 36', v_bad_length = 0);
  END;

  /* ========================================================= */
  /* Test 3: All UUIDs match UUID format */
  /* ========================================================= */
  DECLARE
      v_bad_format NUMBER;
  BEGIN
      SELECT COUNT(*)
        INTO v_bad_format
        FROM TABLE(v_uuid_table)
       WHERE NOT REGEXP_LIKE(column_value, '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

      assert('All UUIDs match UUID format', v_bad_format = 0);
  END;

  /* ========================================================= */
  /* Test 4: All UUIDs have version = 7 */
  /* ========================================================= */
  DECLARE
      v_bad_version NUMBER;
  BEGIN
      SELECT COUNT(*)
        INTO v_bad_version
        FROM TABLE(v_uuid_table)
       WHERE SUBSTR(column_value, 15, 1) != '7';

      assert('All UUIDs have version 7', v_bad_version = 0);
  END;

  /* ========================================================= */
  /* Test 5: All UUIDs have valid RFC 9562 variant */
  /* ========================================================= */
  DECLARE
      v_bad_variant NUMBER;
  BEGIN
      SELECT COUNT(*)
        INTO v_bad_variant
        FROM TABLE(v_uuid_table)
       WHERE SUBSTR(column_value, 20, 1) NOT IN ('8', '9', 'a', 'b');

      assert('All UUIDs have valid RFC 9562 variant', v_bad_variant = 0);
  END;

  /* ========================================================= */
  /* Test 6: No duplicates when bulk-calling generate_uuid      */
  /*         with a fixed epoch (same-ms monotonic counter)     */
  /* Uses 4095 calls — one below the counter wrap boundary.     */
  /* ========================================================= */
  DECLARE
    v_epoch_table  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
    v_fixed_epoch  NUMBER;
    v_epoch_dupes  NUMBER;
    v_epoch_count  NUMBER := 4095;
  BEGIN
    v_fixed_epoch := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;

    FOR i IN 1..v_epoch_count LOOP
      v_epoch_table.EXTEND;
      v_epoch_table(v_epoch_table.COUNT) := pl_uuidv7.generate_uuid(v_fixed_epoch);
    END LOOP;

    SELECT COUNT(*) - COUNT(DISTINCT column_value)
      INTO v_epoch_dupes
      FROM TABLE(v_epoch_table);

    assert(
      'No duplicates in ' || v_epoch_count || ' generate_uuid(epoch_ms) calls',
      v_epoch_dupes = 0
    );
  END;

  /* ========================================================= */
  /* Test 7: All generate_uuid(epoch_ms) UUIDs encode the      */
  /*         provided epoch in the first 12 hex digits          */
  /* ========================================================= */
  DECLARE
    v_epoch_table2  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
    v_fixed_epoch   NUMBER;
    v_expected_ts   VARCHAR2(12);
    v_bad_ts        NUMBER;
    v_epoch_count   NUMBER := 100;
  BEGIN
    v_fixed_epoch := (DATE '2025-06-15' - DATE '1970-01-01') * 86400000;
    v_expected_ts := LPAD(TO_CHAR(v_fixed_epoch, 'FMXXXXXXXXXXXX'), 12, '0');

    FOR i IN 1..v_epoch_count LOOP
      v_epoch_table2.EXTEND;
      v_epoch_table2(v_epoch_table2.COUNT) := pl_uuidv7.generate_uuid(v_fixed_epoch);
    END LOOP;

    SELECT COUNT(*)
      INTO v_bad_ts
      FROM TABLE(v_epoch_table2)
     WHERE SUBSTR(REPLACE(column_value, '-', ''), 1, 12) != v_expected_ts;

    assert(
      'All generate_uuid(epoch_ms) UUIDs encode the correct timestamp',
      v_bad_ts = 0
    );
  END;

  /* ========================================================= */
  /* Summary */
  /* ========================================================= */
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== Results: ' || v_passed || ' passed, ' || v_failed || ' failed ===');

  IF v_failed > 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Test suite failed: ' || v_failed || ' test(s) failed.');
  END IF;

END;
/

SET SERVEROUTPUT OFF;
