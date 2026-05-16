/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 marlonlom */

/*
 * Package specification for UUID v7 implementation compliant with RFC 9562
 * This package provides functions to generate UUID v7 and ensures monotonic generation support.
 */
CREATE OR REPLACE PACKAGE pl_uuidv7 AS

  /*
   * Package semantic version string.
   */
  VERSION CONSTANT VARCHAR2(10) := '1.2.0';

  /*
   * Returns the current package version string.
   *
   * Returns:
   *   VARCHAR2(10) - Semantic version of the pl_uuidv7 package.
   */
  FUNCTION get_version RETURN VARCHAR2;

  /*
   * Generates a UUID version 7 using the current system timestamp.
   *
   * Returns:
   *   VARCHAR2(36) - RFC 9562 compliant UUID v7 string.
   */
  FUNCTION generate_uuid RETURN VARCHAR2;

  /*
   * Generates a UUID version 7 using the provided Unix epoch timestamp.
   *
   * Parameters:
   *   p_epoch_ms - Timestamp in milliseconds since 1970-01-01 00:00:00 UTC.
   *
   * Returns:
   *   VARCHAR2(36) - RFC 9562 compliant UUID v7 string.
   */
  FUNCTION generate_uuid (p_epoch_ms IN NUMBER) RETURN VARCHAR2;

END pl_uuidv7;
