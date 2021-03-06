/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC __doc_no


FUNCTION rnal_pregled_loga_za_nalog( nDoc_no )

   LOCAL nTArea

   nTArea := Select()

   __doc_no := nDoc_no

   rnal_o_tables( .F. )

   tabelarni_pregled_loga()

   SELECT ( nTArea )

   RETURN



STATIC FUNCTION tabelarni_pregled_loga()

   LOCAL cFooter
   LOCAL cHeader

   PRIVATE ImeKol
   PRIVATE Kol

   cHeader := " Nalog broj: " + docno_str( __doc_no ) + " "
   cFooter := " Pregled promjena na nalogu... "

   Box(, 20, 77 )

   box_header_footer()

   use_sql_doc_log( __doc_no )

   setuj_browse_kolone( @ImeKol, @Kol )

   Beep( 2 )

   my_browse( "lstlog", 20, 77, {|| pregled_loga_key_handler() }, cHeader, cFooter,,,,, 5 )

   BoxC()

   RETURN


STATIC FUNCTION box_header_footer()

   LOCAL cLine1 := ""
   LOCAL cLine2 := ""
   LOCAL nOptLen := 24
   LOCAL cOptSep := "|"

   cLine1 := PadR( "<ESC> Izlaz", nOptLen )
   cLine1 += cOptSep + " "
   cLine1 += PadR( "<c-P> Stampa liste", nOptLen )

   @ box_x_koord() + 20, box_y_koord() + 2 SAY cLine1

   RETURN




STATIC FUNCTION pregled_loga_key_handler()

   LOCAL nTblFilt
   LOCAL cLogDesc := ""
   LOCAL cPom

   cLogDesc := opis_loga( doc_log->doc_no, doc_log->doc_log_no, doc_log->doc_log_ty )

   cPom := StrTran( cLogDesc, "#", "," )

   prikazi_status_loga_u_dnu( cPom )

   DO CASE

   CASE ( Ch == K_UP ) .OR. ;
         ( Ch == K_PGUP ) .OR. ;
         ( Ch == K_DOWN ) .OR. ;
         ( Ch == K_PGDN )

      RETURN DE_REFRESH

   CASE ( Ch == K_ENTER )

      prikazi_promjene_unutar_boxa( cLogDesc )

      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT



STATIC FUNCTION setuj_browse_kolone( aImeKol, aKol )

   aImeKol := {}

   AAdd( aImeKol, { "dat./vr./oper.", {|| DToC( doc_log_da ) + " / " + PadR( doc_log_ti, 5 ) + " " + PadR( getusername( operater_i ), 10 ) + ".." }, "datum", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "prom.tip", {|| PadRU( tip_loga_opis( doc_log_ty ), 12 ) }, "tip", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "kratki opis", {|| PadRU( doc_log_de, 30 ) + ".." }, "opis", {|| .T. }, {|| .T. } } )

   aKol := {}

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


STATIC FUNCTION tip_loga_opis( cType )

   LOCAL xRet := ""

   cType := AllTrim( cType )

   DO CASE
   CASE cType == "01"
      xRet := "otvoren"
   CASE cType == "99"
      xRet := "realizovan"
   CASE cType == "98"
      xRet := "real.dio"
   CASE cType == "97"
      xRet := "poništen"
   CASE cType == "96"
      xRet := "nije ispor."
   CASE cType == "10"
      xRet := "osn.podaci"
   CASE cType == "11"
      xRet := "pod.isporuka"
   CASE cType == "12"
      xRet := "kontakti"
   CASE cType == "13"
      xRet := "plaćanje"
   CASE cType == "20"
      xRet := "artikli"
   CASE cType == "21"
      xRet := "lom"
   CASE cType == "30"
      xRet := "d.operacije"
   ENDCASE

   RETURN xRet



STATIC FUNCTION prikazi_status_loga_u_dnu( cLogText )

   LOCAL aLogArr := {}
   LOCAL cRow1
   LOCAL cRow2
   LOCAL cRow3
   LOCAL nLenText := 76
   LOCAL cOpis

   cRow1 := Space( nLenText )
   cRow2 := Space( nLenText )
   cRow3 := Space( nLenText )

   aLogArr := SjeciStr( cLogText, nLenText )

   IF Len( aLogArr ) > 0

      cRow1 := aLogArr[ 1 ]

      IF Len( aLogArr ) > 1
         cRow2 := aLogArr[ 2 ]
      ENDIF

      IF Len( aLogArr ) > 2
         cRow3 := aLogArr[ 3 ]
      ENDIF
   ENDIF

   @ box_x_koord() + 16, box_y_koord() + 2 SAY Space( nLenText )
   @ box_x_koord() + 16, box_y_koord() + 2 SAY8 PadR( cRow1, nLenText ) COLOR f18_color_i()
   @ box_x_koord() + 17, box_y_koord() + 2 SAY Space( nLenText )
   @ box_x_koord() + 17, box_y_koord() + 2 SAY8 PadR( cRow2, nLenText ) COLOR f18_color_i()
   @ box_x_koord() + 18, box_y_koord() + 2 SAY Space( nLenText )
   @ box_x_koord() + 18, box_y_koord() + 2 SAY8 PadR( cRow3, nLenText ) COLOR f18_color_i()

   RETURN



STATIC FUNCTION opis_loga( nDoc_no, nDoc_log_no, cDoc_log_type )

   LOCAL cRet := ""

   cDoc_log_type := AllTrim( cDoc_log_type )

   DO CASE
   CASE cDoc_log_type == "01"
      cRet := rnal_log_tip_01_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type $ "96#97#98#99"
      cRet := rnal_log_tip_99_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "10"
      cRet := rnal_log_tip_10_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "11"
      cRet := rnal_log_tip_11_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "12"
      cRet := rnal_log_tip_12_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "13"
      cRet := rnal_log_tip_13_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "20"
      cRet := rnal_log_tip_20_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "21"
      cRet := rnal_log_tip_21_get( nDoc_no, nDoc_log_no )
   CASE cDoc_log_type == "30"
      cRet := rnal_log_tip_30_get( nDoc_no, nDoc_log_no )
   ENDCASE

   SELECT doc_log

   RETURN cRet




STATIC FUNCTION prikazi_promjene_unutar_boxa( cLogTxt )

   LOCAL aBoxTxt := {}
   LOCAL cPom
   LOCAL cResp := "OK"
   PRIVATE GetList := {}

   aBoxTxt := toktoniz( cLogTxt, "#" )

   IF Len( aBoxTxt ) == 0
      RETURN
   ENDIF

   Box(, Len( aBoxTxt ) + 2, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Detaljni prikaz promjene: " COLOR f18_color_i()

   FOR i := 1 TO Len( aBoxTxt )
      @ box_x_koord() + ( i + 1 ), box_y_koord() + 2 SAY8 PadR( aBoxTxt[ i ], 65 )
   NEXT

   @ box_x_koord() + Len( aBoxTxt ) + 2, box_y_koord() + 2 GET cResp

   READ
   BoxC()

   IF LastKey() == K_ESC .OR. cResp == "OK"
      RETURN
   ENDIF

   RETURN
