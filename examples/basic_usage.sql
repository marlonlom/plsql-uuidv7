/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* Basic usage of pl_uuidv7 */
/* Generates a single UUID v7 and prints it. */

SET SERVEROUTPUT ON;

DECLARE
  v_uuid VARCHAR2(36);
BEGIN
  v_uuid := pl_uuidv7.generate_uuid();
  DBMS_OUTPUT.PUT_LINE('Generated UUID v7: ' || v_uuid);
END;
/
SET SERVEROUTPUT OFF;

/* Inline query alternative: */
SELECT pl_uuidv7.generate_uuid() AS uuid_v7 FROM dual;
