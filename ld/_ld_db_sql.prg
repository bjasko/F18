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


FUNCTION o_tippr()

   SELECT ( F_TIPPR )

   IF !use_sql_sif ( "tippr" )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"

FUNCTION o_tippr_ili_tippr2( cObracun )

   SELECT ( F_TIPPR )
   IF Used()
      USE
   ENDIF

   SELECT ( F_TIPPR2 )
   IF Used()
      USE
   ENDIF

   IF cObracun <> "1" .AND. !Empty( cObracun )
      SELECT ( F_TIPPR2 )
      IF !use_sql_sif ( "tippr", .T., "TIPPR2" )
         RETURN .F.
      ENDIF
   ELSE
      SELECT ( F_TIPPR )
      IF !use_sql_sif ( "tippr" )
         RETURN .F.
      ENDIF
   ENDIF

   SELECT TIPPR
   SET ORDER TO TAG "ID"

   RETURN .T.



FUNCTION use_sql_ld_ld( nGodina, nMjesec, nMjesecDo, nVrInvalid, nStInvalid, cFilter )

   LOCAL cSql
   LOCAL aDbf := a_dbf_ld_ld()
   LOCAL cTable := "ld_ld"
   LOCAL hIndexes, cKey

   hb_default( @cFilter, ".t." )

   cSql := "SELECT "
   cSql += sql_from_adbf( @aDbf, cTable )

   cSql += ", ld_radn.vr_invalid, ld_radn.st_invalid "
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + cTable
   cSql += " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + "ld_radn ON ld_ld.idradn = ld_radn.id"

   cSql += " WHERE godina =" + sql_quote( nGodina ) + ;
      " AND mjesec>=" + sql_quote( nMjesec ) + " AND mjesec<=" + sql_quote( nMjesecDo )

   IF nVrInvalid > 0
      cSql += "AND vr_invalid = " + sql_quote( nVrInvalid )
   ENDIF

   IF nStInvalid > 0
      cSql += "AND st_invalid >= " + sql_quote( nStInvalid )
   ENDIF

   SELECT F_LD
   use_sql( cTable, cSql, "LD" )

   IF F18_DBF_ENCODING  != "UTF8"
      dbEval( {|| field->idRadn := hb_UTF8ToStr( field->idradn ) } )
   ENDIF

   hIndexes := h_ld_ld_indexes()

   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( cTable ) FOR &cFilter
   NEXT
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.
