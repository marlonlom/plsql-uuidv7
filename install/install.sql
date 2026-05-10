/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/* Installation of pl_uuidv7 */
/* Usage: @install.sql */
/* Installs into the currently connected schema */

PROMPT Installing pl_uuidv7 in current schema...

@@../src/main/oracle/packages/pl_uuidv7.pks
@@../src/main/oracle/packages/pl_uuidv7.pkb

PROMPT Installation complete.
