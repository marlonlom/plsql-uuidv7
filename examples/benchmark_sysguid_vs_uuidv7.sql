/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* ================================================================
   Benchmark: SYS_GUID() vs pl_uuidv7.generate_uuid()
   Metrics  : inserts/sec, index fragmentation, ordering performance
   Compatible: Oracle 12c / 19c
   Usage    : @examples/benchmark_sysguid_vs_uuidv7.sql
   ================================================================ */

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR  EXIT FAILURE

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF

/* ================================================================
   Configuration
   ================================================================ */
DECLARE
  c_rows    CONSTANT PLS_INTEGER := 50000;  /* rows to insert per test */

  /* ================================================================
     Internal variables
     ================================================================ */
  v_t0          NUMBER;
  v_t1          NUMBER;
  v_elapsed_ms  NUMBER;
  v_rows_sec    NUMBER;
  v_height_sg   NUMBER;
  v_height_uv7  NUMBER;
  v_height_ep   NUMBER;
  v_frag_sg     NUMBER;
  v_frag_uv7    NUMBER;
  v_frag_ep     NUMBER;
  v_cr_sg       NUMBER;
  v_cr_uv7      NUMBER;
  v_stat_before NUMBER;
  v_stat_after  NUMBER;

  /* ================================================================
     Helper: print a separator line
     ================================================================ */
  PROCEDURE sep IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
  END sep;

  /* ================================================================
     Helper: get consistent gets for current session
     ================================================================ */
  FUNCTION get_consistent_gets RETURN NUMBER IS
    v_val NUMBER;
  BEGIN
    SELECT value
      INTO v_val
      FROM v$mystat s
      JOIN v$statname n ON s.statistic# = n.statistic#
     WHERE n.name = 'consistent gets';
    RETURN v_val;
  END get_consistent_gets;

BEGIN

  /* ============================================================
     SETUP: drop and recreate benchmark tables
     ============================================================ */
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_sg  PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_uv7 PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_ep  PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;

  EXECUTE IMMEDIATE '
    CREATE TABLE uuidv7_bench_sg (
      id  RAW(16)      NOT NULL,
      val VARCHAR2(100) NOT NULL,
      CONSTRAINT uuidv7_bench_sg_pk PRIMARY KEY (id)
    )';

  EXECUTE IMMEDIATE '
    CREATE TABLE uuidv7_bench_uv7 (
      id  VARCHAR2(36)  NOT NULL,
      val VARCHAR2(100) NOT NULL,
      CONSTRAINT uuidv7_bench_uv7_pk PRIMARY KEY (id)
    )';

  EXECUTE IMMEDIATE '
    CREATE TABLE uuidv7_bench_ep (
      id  VARCHAR2(36)  NOT NULL,
      val VARCHAR2(100) NOT NULL,
      CONSTRAINT uuidv7_bench_ep_pk PRIMARY KEY (id)
    )';

  DBMS_OUTPUT.PUT_LINE('BENCHMARK: SYS_GUID() vs pl_uuidv7.generate_uuid()');
  DBMS_OUTPUT.PUT_LINE('Rows per test: ' || c_rows);
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     TEST 1: INSERT PERFORMANCE — SYS_GUID()
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[1] INSERT PERFORMANCE — SYS_GUID()');
  sep;

  v_t0 := DBMS_UTILITY.GET_TIME;
  FOR i IN 1..c_rows LOOP
    INSERT INTO uuidv7_bench_sg (id, val)
    VALUES (SYS_GUID(), 'benchmark-row-' || i);
  END LOOP;
  COMMIT;
  v_t1 := DBMS_UTILITY.GET_TIME;

  v_elapsed_ms := (v_t1 - v_t0) * 10;
  v_rows_sec   := ROUND(c_rows / (v_elapsed_ms / 1000));
  DBMS_OUTPUT.PUT_LINE('  Rows inserted : ' || c_rows);
  DBMS_OUTPUT.PUT_LINE('  Elapsed (ms)  : ' || v_elapsed_ms);
  DBMS_OUTPUT.PUT_LINE('  Rows/second   : ' || v_rows_sec);
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     TEST 2: INSERT PERFORMANCE — pl_uuidv7.generate_uuid()
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[2] INSERT PERFORMANCE — pl_uuidv7.generate_uuid()');
  sep;

  v_t0 := DBMS_UTILITY.GET_TIME;
  FOR i IN 1..c_rows LOOP
    INSERT INTO uuidv7_bench_uv7 (id, val)
    VALUES (pl_uuidv7.generate_uuid(), 'benchmark-row-' || i);
  END LOOP;
  COMMIT;
  v_t1 := DBMS_UTILITY.GET_TIME;

  v_elapsed_ms := (v_t1 - v_t0) * 10;
  v_rows_sec   := ROUND(c_rows / (v_elapsed_ms / 1000));
  DBMS_OUTPUT.PUT_LINE('  Rows inserted : ' || c_rows);
  DBMS_OUTPUT.PUT_LINE('  Elapsed (ms)  : ' || v_elapsed_ms);
  DBMS_OUTPUT.PUT_LINE('  Rows/second   : ' || v_rows_sec);
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     TEST 3: INSERT PERFORMANCE — generate_uuid(p_epoch_ms)
     Sequential epoch per row simulates a historical backfill.
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[3] INSERT PERFORMANCE — pl_uuidv7.generate_uuid(epoch_ms)');
  sep;

  DECLARE
    v_base_epoch NUMBER := (DATE '2024-01-01' - DATE '1970-01-01') * 86400000;
  BEGIN
    v_t0 := DBMS_UTILITY.GET_TIME;
    FOR i IN 1..c_rows LOOP
      INSERT INTO uuidv7_bench_ep (id, val)
      VALUES (pl_uuidv7.generate_uuid(v_base_epoch + i), 'benchmark-row-' || i);
    END LOOP;
    COMMIT;
    v_t1 := DBMS_UTILITY.GET_TIME;
  END;

  v_elapsed_ms := (v_t1 - v_t0) * 10;
  v_rows_sec   := ROUND(c_rows / (v_elapsed_ms / 1000));
  DBMS_OUTPUT.PUT_LINE('  Rows inserted : ' || c_rows);
  DBMS_OUTPUT.PUT_LINE('  Elapsed (ms)  : ' || v_elapsed_ms);
  DBMS_OUTPUT.PUT_LINE('  Rows/second   : ' || v_rows_sec);
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     TEST 4: INDEX FRAGMENTATION
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[4] INDEX FRAGMENTATION');
  sep;

  EXECUTE IMMEDIATE 'ANALYZE INDEX uuidv7_bench_sg_pk VALIDATE STRUCTURE';
  SELECT height, ROUND(del_lf_rows / NULLIF(lf_rows, 0) * 100, 2)
    INTO v_height_sg, v_frag_sg
    FROM index_stats;

  EXECUTE IMMEDIATE 'ANALYZE INDEX uuidv7_bench_uv7_pk VALIDATE STRUCTURE';
  SELECT height, ROUND(del_lf_rows / NULLIF(lf_rows, 0) * 100, 2)
    INTO v_height_uv7, v_frag_uv7
    FROM index_stats;

  EXECUTE IMMEDIATE 'ANALYZE INDEX uuidv7_bench_ep_pk VALIDATE STRUCTURE';
  SELECT height, ROUND(del_lf_rows / NULLIF(lf_rows, 0) * 100, 2)
    INTO v_height_ep, v_frag_ep
    FROM index_stats;

  DBMS_OUTPUT.PUT_LINE('  Metric              SYS_GUID     UUID v7   epoch_ms');
  DBMS_OUTPUT.PUT_LINE('  ----------------  ----------  ----------  ----------');
  DBMS_OUTPUT.PUT_LINE('  Index height    : ' ||
    LPAD(v_height_sg, 10) || '  ' || LPAD(v_height_uv7, 10) || '  ' || LPAD(v_height_ep, 10));
  DBMS_OUTPUT.PUT_LINE('  Fragmentation % : ' ||
    LPAD(NVL(TO_CHAR(v_frag_sg),  '0'), 10) || '  ' ||
    LPAD(NVL(TO_CHAR(v_frag_uv7), '0'), 10) || '  ' ||
    LPAD(NVL(TO_CHAR(v_frag_ep),  '0'), 10));
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('  Note: lower height and lower fragmentation % is better.');
  DBMS_OUTPUT.PUT_LINE('  UUID v7 and epoch_ms (time-ordered) should show lower fragmentation.');
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     TEST 4: ORDERING — logical reads for ORDER BY
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[5] ORDERING PERFORMANCE (consistent gets for ORDER BY)');
  sep;

  DECLARE
    v_dummy VARCHAR2(36);
  BEGIN
    /* SYS_GUID ordering */
    v_stat_before := get_consistent_gets;
    FOR r IN (SELECT RAWTOHEX(id) FROM uuidv7_bench_sg ORDER BY id) LOOP
      v_dummy := r.rawtohex_id_;
    END LOOP;
    v_stat_after := get_consistent_gets;
    v_cr_sg := v_stat_after - v_stat_before;

    /* UUID v7 ordering */
    v_stat_before := get_consistent_gets;
    FOR r IN (SELECT id FROM uuidv7_bench_uv7 ORDER BY id) LOOP
      v_dummy := r.id;
    END LOOP;
    v_stat_after := get_consistent_gets;
    v_cr_uv7 := v_stat_after - v_stat_before;
  END;

  DBMS_OUTPUT.PUT_LINE('  Metric              SYS_GUID     UUID v7');
  DBMS_OUTPUT.PUT_LINE('  ----------------  ----------  ----------');
  DBMS_OUTPUT.PUT_LINE('  Consistent gets : ' ||
    LPAD(v_cr_sg, 10) || '  ' || LPAD(v_cr_uv7, 10));
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('  Note: fewer consistent gets = less I/O for ORDER BY.');
  DBMS_OUTPUT.PUT_LINE('  UUID v7 index is time-ordered; range scan avoids sort.');
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     SUMMARY
     ============================================================ */
  sep;
  DBMS_OUTPUT.PUT_LINE('[SUMMARY] Benchmark complete. Tests: SYS_GUID (1), generate_uuid (2), generate_uuid(epoch_ms) (3), fragmentation (4), ordering (5).');
  sep;
  DBMS_OUTPUT.PUT_LINE('  Run EXPLAIN PLAN on ORDER BY queries to confirm');
  DBMS_OUTPUT.PUT_LINE('  INDEX FULL SCAN (UUID v7) vs SORT ORDER BY (SYS_GUID).');
  DBMS_OUTPUT.PUT_LINE('');

  /* ============================================================
     CLEANUP
     ============================================================ */
  EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_sg  PURGE';
  EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_uv7 PURGE';
  EXECUTE IMMEDIATE 'DROP TABLE uuidv7_bench_ep  PURGE';
  DBMS_OUTPUT.PUT_LINE('  Benchmark tables dropped.');
  DBMS_OUTPUT.PUT_LINE('');

END;
/
