/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/*
 * Package body for UUID v7 implementation compliant with RFC 9562
 * This package provides functions to generate UUID v7 and ensures monotonic generation support.
 */
CREATE OR REPLACE PACKAGE BODY pl_uuidv7 AS

  /* =========================================================
  Monotonicity state (session-scoped)
  ========================================================= */
  g_last_ms NUMBER := -1;
  g_counter NUMBER := 0;

  /* Function to generate a UUID v7 */
  FUNCTION generate_uuid
    RETURN VARCHAR2
  IS
    l_uuid    RAW(16);
    l_ts_ms   NUMBER;
    l_ts      RAW(6);
    l_rand    RAW(10);
    l_rand_a  NUMBER;
    l_byte    RAW(1);
    l_now_ms  NUMBER;
  BEGIN
    /* Epoch ms via Oracle-safe DATE arithmetic */
    l_now_ms := (SYSDATE - DATE '1970-01-01') * 86400000;
    l_ts_ms  := TRUNC(l_now_ms);
    /* Random bytes for rand_b and optional rand_a seed */
    l_rand := DBMS_CRYPTO.RANDOMBYTES(10);
    /* Monotonicity: counter seeded from random at each new millisecond */
    IF l_ts_ms = g_last_ms THEN
      g_counter := g_counter + 1;
      IF g_counter > 4095 THEN
        g_counter := 0;  -- overflow: wrap (extremely rare in PL/SQL)
      END IF;
    ELSE
      g_last_ms := l_ts_ms;
      /* Seed rand_a with a random 12-bit value for the new timestamp period */
      g_counter := MOD(
        TO_NUMBER(RAWTOHEX(UTL_RAW.SUBSTR(l_rand, 1, 2)), 'XXXX'),
        4096
      );
    END IF;
    l_rand_a := g_counter;
    /* Timestamp (48 bits) */
    l_ts := HEXTORAW( LPAD(TO_CHAR(l_ts_ms, 'FMXXXXXXXXXXXX'), 12, '0') );
    /* Build UUID base: 6 bytes timestamp + 10 bytes random */
    l_uuid := l_ts || l_rand;
    /* Byte 7: VERSION nibble (0111) | upper 4 bits of rand_a counter */
    l_byte := HEXTORAW( LPAD(TO_CHAR(112 + BITAND(TRUNC(l_rand_a / 256), 15), 'FMXX'), 2, '0') );
    l_uuid := UTL_RAW.SUBSTR(l_uuid, 1, 6) || l_byte || UTL_RAW.SUBSTR(l_uuid, 8);
    /* Byte 8: lower 8 bits of rand_a counter */
    l_byte := HEXTORAW( LPAD(TO_CHAR(MOD(l_rand_a, 256), 'FMXX'), 2, '0') );
    l_uuid := UTL_RAW.SUBSTR(l_uuid, 1, 7) || l_byte || UTL_RAW.SUBSTR(l_uuid, 9);
    /* Byte 9: VARIANT = 10xx xxxx (RFC 9562) */
    l_byte := UTL_RAW.SUBSTR(l_uuid, 9, 1);
    l_byte := UTL_RAW.BIT_AND(l_byte, HEXTORAW('3F'));
    l_byte := UTL_RAW.BIT_OR(l_byte, HEXTORAW('80'));
    l_uuid := UTL_RAW.SUBSTR(l_uuid, 1, 8) || l_byte || UTL_RAW.SUBSTR(l_uuid, 10);
    /* Return formatted UUID */
    RETURN LOWER( REGEXP_REPLACE( RAWTOHEX(l_uuid), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5' ) );
  END generate_uuid;

END pl_uuidv7;
