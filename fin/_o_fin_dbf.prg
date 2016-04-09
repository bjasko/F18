/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION o_ulimit()
   RETURN o_dbf_table( F_ULIMIT, "ulimit", "ID" )


FUNCTION o_vrnal()
   RETURN o_dbf_table( F_VRNAL, "vrnal", "1" )

FUNCTION o_relac()
   RETURN o_dbf_table( F_RELAC, "relac", "ID" )

FUNCTION o_funk()
   RETURN o_dbf_table( F_FUNK, "funk", "ID" )

FUNCTION o_fond()
   RETURN o_dbf_table( F_FOND, "fond", "ID" )


FUNCTION o_ostav()
   RETURN o_dbf_table( F_OSTAV, "ostav", "1" )