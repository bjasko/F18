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

/*
   ftxt uzorci teksta fakture
*/

FUNCTION o_fakt_txt()

   RETURN o_dbf_table( F_FTXT, "ftxt", "ID" )



FUNCTION o_dest()

   LOCAL cTabela := "dest"

   SELECT ( F_DEST )
   IF !use_sql_sif  ( cTabela )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "ID"

   RETURN .T.
