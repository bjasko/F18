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

STATIC s_nLastNC := 0
STATIC s_cIdArtikal := "XX"

FUNCTION get_nabavna_cijena( cIdKonto, cIdArtikal, dDatum )

LOCAL oSrv := pg_server()
LOCAL cQuery, oRet, nRet
LOCAL nNv_u, nNV_i, nUlaz, nIzlaz

IF cIdKonto == NIL
 cIdKonto := PADR( "1320", 7)
ENDIF

IF s_cIdArtikal == cIdArtikal
   nRet := s_nLastNC
   RETURN nRet
ENDIF

cQuery := "SELECT nv_u, nv_i, ulaz, izlaz from public.sp_konto_stanje(" + ;
  _sql_quote("m") + "," +;
  _sql_quote(cIdKonto) + "," +;
  _sql_quote(cIdArtikal) + "," +;
  _sql_quote(dDatum) + ")"

oRet := _sql_query( oSrv, cQuery )

IF VALTYPE( oRet ) != "O"
   nRet := -9999
ELSE
   nNV_u := oRet:FieldGet(1)
   nNV_i := oRet:FieldGet(2)
   nUlaz := oRet:FieldGet(3)
   nIzlaz := oRet:FieldGet(4)

   IF ROUND( nUlaz - nIzlaz, 4) == 0
      nRet := 0
   ELSE
      nRet := ( nNv_u - nNv_i) / (nUlaz - nIzlaz)
      nRet := ROUND( nRet, 3)
   ENDIF

ENDIF

s_nLastNC := nRet
s_cIdArtikal := cIdArtikal

RETURN nRet


FUNCTION get_realizovana_marza( cIdKonto, cIdArtikal, dDatum, nCijena )

LOCAL nNC

IF s_cIdArtikal == cIdArtikal
   nNC := s_nLastNC
ELSE
   nNC := get_nabavna_cijena( cIdKonto, cIdArtikal, dDatum )
ENDIF

IF ROUND(nNC, 0) == -9999
   RETURN 0
ENDIF

IF ROUND(nNC, 4) == 0
   RETURN -99999
ENDIF

RETURN ROUND( (nCijena/nNC - 1) * 100.00, 2)