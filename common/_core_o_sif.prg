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

FIELD id, naz


FUNCTION find_partner_by_naz_or_id( cId )

   LOCAL cAlias := "PARTN"
   LOCAL cSqlQuery := "select * from fmk.partn"
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql
   cSqlQuery += " OR mjesto ilike " + cIdSql

   IF !use_sql( "partn", cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()


FUNCTION find_partner_max_numeric_id()

      LOCAL cAlias := "PARTN_MAX"
      LOCAL cSqlQuery := "select MAX(id) AS MAXID from fmk.partn WHERE id ~ '\d+\s*'" // where zadovoljava: '0001  ', '000100'
      LOCAL cMaxId := ""

      PushWa()
      SELECT F_POM
      IF !use_sql( "partn", cSqlQuery, cAlias )
         PopWa()
         RETURN ""
      ENDIF

      cMaxId := field->MAXID
      USE
      PopWa()

      RETURN cMaxId

FUNCTION o_partner( cId )

   LOCAL cTabela := "partn"

   SELECT ( F_PARTN )
   IF !use_sql_sif  ( cTabela, .T., "PARTN", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()



FUNCTION select_o_partner( cId )

   SELECT ( F_PARTN )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_partner( cId )




FUNCTION find_konto_by_naz_or_id( cId )

   LOCAL cAlias := "KONTO"
   LOCAL cSqlQuery := "select * from fmk.konto"
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql

   IF !use_sql( "konto", cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()



FUNCTION o_konto( cId )

   LOCAL cTabela := "konto"

   SELECT ( F_KONTO )
   IF !use_sql_sif  ( cTabela, .T., "KONTO", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_konto( cId )

   SELECT ( F_KONTO )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_konto( cId )




FUNCTION o_vrste_placanja()

   LOCAL cTabela := "vrstep"

   SELECT ( F_VRSTEP )
   IF !use_sql_sif  ( cTabela )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "ID"

   RETURN !Eof()


/*

FUNCTION o_vrnal()

--   LOCAL cTabela := "vrnal"

   SELECT ( F_VRNAL )
   IF !use_sql_sif  ( cTabela )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF

   RETURN .T.
  */

/*
--FUNCTION o_relac()

   LOCAL cTabela := "relac"

   SELECT ( F_RELAC )
   IF !use_sql_sif  ( cTabela )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF

   RETURN .T.
*/


FUNCTION o_tdok( cId )

   LOCAL cTabela := "tdok"

   SELECT ( F_TDOK )
   IF !use_sql_sif  ( cTabela, .T., "TDOK", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_tdok( cId )

   SELECT ( F_TDOK )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_tdok( cId )




FUNCTION o_tnal( cId )

   LOCAL cTabela := "tnal"

   SELECT ( F_TNAL )
   IF !use_sql_sif  ( cTabela, .T., "TNAL", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()



FUNCTION select_o_tnal( cId )

   SELECT ( F_TNAL )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_tnal( cId )



FUNCTION o_valute( cId )

   LOCAL cTabela := "valute"

   SELECT ( F_TNAL )
   // IF !use_sql_sif  ( cTabela, .T., "VALUTE", cId  )
   IF !use_sql_valute( cId )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()



FUNCTION select_o_valute( cId )

   SELECT ( F_VALUTE )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_valute( cId )


FUNCTION o_refer()

   SELECT ( F_REFER )
   use_sql_sif  ( "refer" )
   SET ORDER TO TAG "ID"

   RETURN .T.


FUNCTION o_ops( cId )

   SELECT ( F_OPS )
   use_sql_opstine( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_ops( cId )

   SELECT ( F_OPS )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_ops( cId )


/*
         use_sql_opstine() => otvori šifarnik tarifa sa prilagođenim poljima
*/

FUNCTION use_sql_opstine( cId )

   LOCAL cSql
   LOCAL cTable := "ops"

   SELECT ( F_OPS )
   IF !use_sql_sif( cTable, .T., "OPS", cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION o_rj( cId )

   SELECT ( F_RJ )
   use_sql_rj( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_rj( cId )

   SELECT ( F_RJ )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_rj( cId )



FUNCTION use_sql_rj( cId )

   LOCAL cSql
   LOCAL cTable := "rj"

   SELECT ( F_RJ )
   IF !use_sql_sif( cTable, .T., "RJ", cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION find_rj_by_id( cId )

   LOCAL cAlias := "RJ"
   LOCAL cTable := "rj"
   LOCAL cSqlQuery := "select * from fmk." + cTable
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql

   IF !use_sql( cTable, cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()



FUNCTION o_trfp()

   SELECT ( F_TRFP )
   use_sql_trfp()
   SET ORDER TO TAG "ID"

   RETURN .T.


FUNCTION o_trfp2()

   SELECT ( F_TRFP2 )
   use_sql_trfp2()
   SET ORDER TO TAG "ID"

   RETURN .T.
