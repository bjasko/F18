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


FUNCTION pos_brisi_dokument( cIdPos, cIdTipDok, dDatDok, cBrDok )

   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hRec
   LOCAL nDbfArea := Select()
   LOCAL cDokument
   LOCAL hParams

   IF !pos_dokument_postoji( cIdPos, cIdTipDok, dDatDok, cBrDok )
      RETURN lRet
   ENDIF

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "pos_pos", "pos_doks" }, .T. )
      run_sql_query( "ROLLBACK" )
      SELECT ( nDbfArea )
      RETURN lRet
   ENDIF

   MsgO( "Brisanje dokumenta iz glavne tabele u toku ..." )

   cDokument := ALLTRIM( cIdPos ) + "-" + cIdTipDok + "-" + ALLTRIM( cBrDok ) + " " + DTOC( dDatDok )

   SELECT pos
   SET ORDER TO TAG "1"
   GO TOP

   SEEK cIdPos + cIdTipDok + DToS( dDatDok ) + cBrDok

   IF Found()
      hRec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( "pos_pos", hRec, 2, "CONT" )
   ENDIF

   IF lOk
      SELECT pos_doks
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdPos + cIdTipDok + DToS( dDatDok ) + cBrDok

      IF Found()
         hRec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )
      ENDIF
   ENDIF

   MsgC()

   IF lOk
      lRet := .T.
      hParams := hb_hash()
      hParams[ "unlock" ] := { "pos_doks", "pos_pos" }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER, izbrisan pos dokument: " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER, greška sa brisanjem pos dokumenta: " + cDokument, 2 )
   ENDIF

   SELECT ( nDbfArea )

   RETURN lRet





FUNCTION pos_dokument_postoji( cIdPos, cIdvd, dDatum, cBroj )

   LOCAL lRet := .F.
   LOCAL cWhere

   cWhere := "idpos = " + sql_quote( cIdPos )
   cWhere += " AND idvd = " + sql_quote( cIdVd )
   cWhere += " AND datum = " + sql_quote( dDatum )
   cWhere += " AND brdok = " + sql_quote( cBroj )

   IF table_count( F18_PSQL_SCHEMA_DOT + "pos_doks", cWhere ) > 0
      lRet := .T.
   ENDIF

   IF !lRet
      IF table_count( F18_PSQL_SCHEMA_DOT + "pos_pos", cWhere ) > 0
         lRet := .T.
      ENDIF
   ENDIF

   RETURN lRet





FUNCTION pos_povrat_rn( cSt_rn, dSt_date )

   LOCAL nTArea := Select()
   LOCAL hRec
   LOCAL nCount := 0
   PRIVATE GetList := {}

   IF Empty( cSt_rn )
      SELECT ( nTArea )
      RETURN
   ENDIF

   cSt_rn := PadL( AllTrim( cSt_rn ), 6 )

   SELECT pos
   SEEK gIdPos + "42" + DToS( dSt_date ) + cSt_rn

   MsgO( "Povrat dokumenta u pripremu ... " )

   DO WHILE !Eof() .AND. field->idpos == gIdPos ;
         .AND. field->brdok == cSt_rn ;
         .AND. field->idvd == "42"

      cT_roba := field->idroba
      select_o_roba( cT_roba )

      SELECT pos

      hRec := dbf_get_rec()
      hb_HDel( hRec, "rbr" )

      SELECT _pos_pripr
      APPEND BLANK

      hRec[ "robanaz" ] := roba->naz

      dbf_update_rec( hRec )

      ++ nCount

      SELECT pos

      SKIP

   ENDDO

   msgC()

   IF nCount > 0
      log_write( "F18_DOK_OPER, povrat dokumenta u pripremu: " + ;
             ALLTRIM( gIdPos ) + "-" + VD_RN + "-" + ALLTRIM( cSt_rn ) + " " + DTOC( dSt_date), 2 )
   ENDIF

   pos_brisi_dokument( gIdPos, VD_RN, dSt_date, cSt_rn )

   SELECT ( nTArea )

   RETURN




STATIC FUNCTION odaberi_opciju_povrata_dokumenta()

   LOCAL _ch := "1"

   Box(, 3, 50 )
   @ m_x + 1, m_y + 2 SAY8 "Priprema nije prazna, šta dalje ? "
   @ m_x + 2, m_y + 2 SAY " (1) brisati pripremu  "
   @ m_x + 3, m_y + 2 SAY8 " (2) spojiti na postojeći dokument " GET _ch VALID _ch $ "12"
   READ
   BoxC()

   IF LastKey() == K_ESC
      _ch := "0"
      RETURN _ch
   ENDIF

   RETURN _ch




FUNCTION pos_povrat_dokumenta_u_pripremu()

   LOCAL cDokument
   LOCAL nCount := 0
   LOCAL hRec
   LOCAL nDbfArea := Select()
   LOCAL _oper := "1"
   LOCAL _exist, _rec2

   o_pos_priprz()
   SELECT priprz

   IF RecCount() <> 0
      _oper := odaberi_opciju_povrata_dokumenta()
   ENDIF

   IF _oper == "1"
      my_dbf_zap()
   ENDIF

   IF _oper == "2"
      _rec2 := dbf_get_rec()
   ENDIF

   MsgO( "Vršim povrat dokumenta u pripremu ..." )

   cDokument := ALLTRIM( pos_doks->idpos ) + "-" + pos_doks->idvd + "-" + ALLTRIM( pos_doks->brdok ) + " " + DToC( pos_doks->datum )

   SELECT pos
   SEEK pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

   DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == ;
         pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

      hRec := dbf_get_rec()

      hb_HDel( hRec, "rbr" )

      select_o_roba( hRec[ "idroba" ] )

      hRec[ "robanaz" ] := roba->naz
      hRec[ "jmj" ] := roba->jmj
      hRec[ "barkod" ] := roba->barkod

      IF _oper == "2"
         hRec[ "idpos" ] := _rec2[ "idpos" ]
         hRec[ "idvd" ] := _rec2[ "idvd" ]
         hRec[ "brdok" ] := _rec2[ "brdok" ]
      ENDIF

      SELECT priprz

      IF _oper <> "2"
         APPEND BLANK
      ENDIF

      IF _oper == "2"

         SET ORDER TO TAG "1"
         HSEEK hRec[ "idroba" ]

         IF !Found()
            APPEND BLANK
         ELSE
            _exist := dbf_get_rec()
            hRec[ "kol2" ] := hRec[ "kol2" ] + _exist[ "kol2" ]
         ENDIF

      ENDIF

      dbf_update_rec( hRec )

      ++ nCount

      SELECT pos
      SKIP

   ENDDO

   MsgC()

   SELECT ( nDbfArea )

   IF nCount > 0
      log_write( "F18_DOK_OPER: povrat dokumenta u pripremu: " + cDokument, 2 )
   ENDIF

   RETURN
