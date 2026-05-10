/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/*
 * Package specification for UUID v7 implementation compliant with RFC 9562
 * This package provides functions to generate UUID v7 and ensures monotonic generation support.
 */
CREATE OR REPLACE PACKAGE pl_uuidv7 AS

  /* Function to generate a UUID v7 */
  FUNCTION generate_uuid RETURN VARCHAR2;

END pl_uuidv7;
