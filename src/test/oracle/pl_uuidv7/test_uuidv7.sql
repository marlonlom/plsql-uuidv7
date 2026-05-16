/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* ============================================================= */
/* Test: UUID v7 format, version and variant validation */
/* Package: pl_uuidv7 */
/* Compatible: Oracle 11g / 12c / 19c */
/* ============================================================= */

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

SET SERVEROUTPUT ON;

DECLARE
  v_uuid      VARCHAR2(36);
  v_version   VARCHAR2(1);
  v_variant   VARCHAR2(2);
  v_passed    NUMBER := 0;
  v_failed    NUMBER := 0;

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
  DBMS_OUTPUT.PUT_LINE('=== UUID v7 Tests ===');
  DBMS_OUTPUT.PUT_LINE('');

  v_uuid := pl_uuidv7.generate_uuid();
  DBMS_OUTPUT.PUT_LINE('Generated UUID: ' || v_uuid);
  DBMS_OUTPUT.PUT_LINE('');

  /* ========================================================= */
  /* Test 1: Length = 36 */
  /* ========================================================= */
  assert('Length is 36', LENGTH(v_uuid) = 36);

  /* ========================================================= */
  /* Test 2: Format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx */
  /* ========================================================= */
  assert(
      'Format matches UUID pattern',
      REGEXP_LIKE(v_uuid, '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
  );

  /* ========================================================= */
  /* Test 3: Version = 7 (13th character) */
  /* ========================================================= */
  v_version := SUBSTR(v_uuid, 15, 1);
  assert('Version nibble = 7', v_version = '7');

  /* ========================================================= */
  /* Test 4: Variant RFC 9562 (10xx = 8, 9, a, b) */
  /* First hex digit of 4th group (position 20) */
  /* ========================================================= */
  v_variant := SUBSTR(v_uuid, 20, 1);
  assert(
      'Variant is RFC 9562 (8, 9, a or b)',
      v_variant IN ('8', '9', 'a', 'b')
  );

  /* ========================================================= */
  /* Test 5: Output is lowercase */
  /* ========================================================= */
  assert('UUID is lowercase', v_uuid = LOWER(v_uuid));

  /* ========================================================= */
  /* Test 6: Hyphens at correct positions */
  /* ========================================================= */
  assert(
      'Hyphens at positions 9, 14, 19, 24',
      SUBSTR(v_uuid, 9,  1) = '-' AND
      SUBSTR(v_uuid, 14, 1) = '-' AND
      SUBSTR(v_uuid, 19, 1) = '-' AND
      SUBSTR(v_uuid, 24, 1) = '-'
  );

  /* ========================================================= */
  /* Test 7: Two consecutive UUIDs are different */
  /* ========================================================= */
  assert(
      'Two consecutive UUIDs are different',
      v_uuid != pl_uuidv7.generate_uuid()
  );

  /* ========================================================= */
  /* Test 8: generate_uuid(p_epoch_ms) returns valid UUID */
  /* ========================================================= */
  DECLARE
    v_fixed_ms  NUMBER;
    v_uuid2     VARCHAR2(36);
  BEGIN
    v_fixed_ms := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
    v_uuid2    := pl_uuidv7.generate_uuid(v_fixed_ms);

    assert(
        'generate_uuid(epoch_ms) length is 36',
        LENGTH(v_uuid2) = 36
    );
    assert(
        'generate_uuid(epoch_ms) matches UUID format',
        REGEXP_LIKE(v_uuid2, '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
    );
    assert(
        'generate_uuid(epoch_ms) version nibble = 7',
        SUBSTR(v_uuid2, 15, 1) = '7'
    );
    assert(
        'generate_uuid(epoch_ms) variant is RFC 9562',
        SUBSTR(v_uuid2, 20, 1) IN ('8', '9', 'a', 'b')
    );
    assert(
        'generate_uuid(epoch_ms) timestamp encodes provided epoch',
        SUBSTR(REPLACE(v_uuid2, '-', ''), 1, 12) =
          LPAD(TO_CHAR(v_fixed_ms, 'FMXXXXXXXXXXXX'), 12, '0')
    );
  END;

  /* ========================================================= */
  /* Test 9: Two generate_uuid(same epoch) calls are different */
  /* ========================================================= */
  DECLARE
    v_fixed_ms  NUMBER;
    v_uuid_a    VARCHAR2(36);
    v_uuid_b    VARCHAR2(36);
  BEGIN
    v_fixed_ms := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
    v_uuid_a   := pl_uuidv7.generate_uuid(v_fixed_ms);
    v_uuid_b   := pl_uuidv7.generate_uuid(v_fixed_ms);
    assert(
        'Two generate_uuid(same epoch) calls produce different UUIDs',
        v_uuid_a != v_uuid_b
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
