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

// --------------------------------------
// utrosak boja kod RAL-a
// --------------------------------------
FUNCTION rpt_ral_calc()

   LOCAL dD_From
   LOCAL dD_To
   LOCAL nOper
   LOCAL cRalList
   LOCAL cColorList

   IF _get_vars( @dD_From, @dD_To, @nOper, ;
         @cRalList, @cColorList ) == 0
      RETURN
   ENDIF

   // kreiraj report
   _cre_report( dD_from, dD_to, nOper, cRalList, cColorList )

   // ispisi report
   _r_ral_calc( dD_From, dD_to, nOper )

   RETURN .T.


// ----------------------------------------------
// uslovi izvjestaja
// ----------------------------------------------
STATIC FUNCTION _get_vars( dD_f, dD_t, nOper, ;
      cRList, cColList )

   dD_t := danasnji_datum()
   dD_f := ( dD_t - 30 )
   nOper := 0
   cRList := Space( 200 )
   cColList := Space( 200 )

   Box(, 6, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od:" GET dD_f
   @ box_x_koord() + 1, Col() + 1 SAY "do:" GET dD_t
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Operater (0 - svi):" GET nOper ;
      VALID {|| nOper == 0  } ;
      PICT "9999999999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY " RAL kodovi (prazno-svi):" GET cRList PICT "@S25"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "boje kodovi (prazno-sve):" GET cColList PICT "@S25"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   RETURN 1



// ---------------------------------------------------------------
// glavna funkcija za kreiranje pomocne tabele
// ---------------------------------------------------------------
STATIC FUNCTION _cre_report( dD_f, dD_t, nOper, cRalLst, cColLst )

   LOCAL aField
   LOCAL cValue := ""
   LOCAL aValue := {}
   LOCAL aRal := {}
   LOCAL nRal := 0
   LOCAL nTick := 0
   LOCAL nRoller := 0
   LOCAL nDoc_no
   LOCAL nDoc_it_no
   LOCAL nDoc_it_el_no
   LOCAL aArt := {}
   LOCAL aArr := {}
   LOCAL aElem := {}
   LOCAL nElement := 0

   // kreiraj tmp tabelu
   aField := _rpt_fields()

   cre_tmp1( aField )

   // otvori tabelu _tmp1
   o_tmp1()

   INDEX ON Str( r_color, 8 ) TAG "1"

   O_RAL
   rnal_o_tables( .F. )

   _main_filter( dD_f, dD_t, nOper )

   Box(, 1, 50 )

   DO WHILE !Eof()

      // uzmi podatke dokumenta da vidis treba li da se generise
      // u izvjestaj ?

      nDoc_no := field->doc_no
      nDoc_it_no := field->doc_it_no
      nDoc_it_el_no := field->doc_it_el_

      SELECT docs
      GO TOP
      SEEK docno_str( nDoc_no )

      // provjeri uslove !!!

      // ako je rejected ili busy... preskoci
      IF ( docs->doc_status == 2 .OR. docs->doc_status == 3 )
         SELECT doc_ops
         SKIP
         LOOP
      ENDIF

      IF nOper <> 0 .AND. ( docs->operater_i <> nOper )
         SELECT doc_ops
         SKIP
         LOOP
      ENDIF

      // datum.....
      IF DToS( docs->doc_date ) > DToS( dD_t ) .OR. ;
            DToS( docs->doc_date ) < DToS( dD_f )
         SELECT doc_ops
         SKIP
         LOOP
      ENDIF

      // vrni se nazad, idemo dalje
      SELECT doc_ops

      // "RAL:1000#4#80"
      cValue := AllTrim( field->aop_value )
      // ukini "RAL:", to nam ne treba !
      cValue := StrTran( cValue, "RAL:", "" )

      // aRal[1] = 1000
      // aRal[2] = 4
      // aRal[3] = 80

      aRal := TokToNiz( cValue, "#" )
      // imamo i vrijednosti
      nRal := Val( aRal[ 1 ] )
      nTick := Val( aRal[ 2 ] )
      nRoller := Val( aRal[ 3 ] )

      // provjeri uslov po listi
      IF !Empty( cRalLst )
         IF !( AllTrim( Str( nRal, 5, 0 ) ) $ AllTrim( cRalLst ) )
            SELECT doc_ops
            SKIP
            LOOP
         ENDIF
      ENDIF

      SELECT ral
      SEEK Str( nRal, 5, 0 ) + Str( nTick, 2, 0 )

      IF !Empty( cColLst ) // provjeri uslov po listi boja
         IF !( AllTrim( Str( field->col_1 ) ) $ AllTrim( cColLst ) ) .OR. ;
               !( AllTrim( Str( field->col_2 ) ) $ AllTrim( cColLst ) ) .OR. ;
               !( AllTrim( Str( field->col_3 ) ) $ AllTrim( cColLst ) ) .OR. ;
               !( AllTrim( Str( field->col_4 ) ) $ AllTrim( cColLst ) )
            SELECT doc_ops
            SKIP
            LOOP
         ENDIF
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "dokument: " + docno_str( nDoc_no )

      SELECT doc_it
      GO TOP
      SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no )

      nArt_id := field->art_id
      // koliko ima kvadrata
      nUm2 := c_ukvadrat( field->doc_it_qtt, ;
         field->doc_it_hei, ;
         field->doc_it_wid )

      // sada imam sve potrebne podatke za obracun
      aArr := rnal_kalkulisi_ral( nRal, nTick, nRoller, nUm2 )

      // dobio sam obracun u aArr sad ga treba upisati u
      // pomocnu tabelu ...

      FOR i := 1 TO Len( aArr )
         app_to_tmp1( aArr[ i, 1 ], aArr[ i, 3 ] )
      NEXT

      // idemo dalje...
      SELECT doc_ops
      SKIP
   ENDDO

   BoxC()

   RETURN .T.


// -------------------------------------------------
// dodaj u pomocnu tabelu
// -------------------------------------------------
STATIC FUNCTION app_to_tmp1( nColor, nTotal )

   LOCAL nTArea := Select()
   LOCAL _rec

   SELECT _tmp1
   GO TOP
   SEEK Str( nColor, 8 )

   IF !Found()
      APPEND BLANK
      _rec := dbf_get_rec()
      _rec[ "r_color" ] := nColor
   ELSE
      _rec := dbf_get_rec()
   ENDIF

   _rec[ "c_total" ] := _rec[ "c_total" ] + nTotal

   dbf_update_rec( _rec )

   SELECT ( nTArea )

   RETURN .T.



// -----------------------------------------
// polja tabele izvjestaja
// -----------------------------------------
STATIC FUNCTION _rpt_fields()

   LOCAL aRet := {}

   AAdd( aRet, { "r_color", "N", 8, 0 } )
   AAdd( aRet, { "c_total", "N", 20, 8 } )

   RETURN aRet


// -------------------------------------------------
// filter
// -------------------------------------------------
STATIC FUNCTION _main_filter( dDFrom, dDTo, nOper )

   LOCAL cFilter := ""

   SELECT doc_ops

   cFilter := "'RAL:' $ aop_value"
   SET FILTER to &cFilter
   GO TOP

   RETURN .T.

// ------------------------------------------------
// ispis reporta
// ------------------------------------------------
STATIC FUNCTION _r_ral_calc( dD_from, dD_to, nOper )

   LOCAL nCnt := 0

   SELECT _tmp1
   IF RECCOUNT2() == 0
      MsgBeep( "nema podataka" )
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP

   START PRINT CRET

   ? "Utrosak boja kod RAL obrade:"
   ?
   ? "Period od " + DToC( dD_from ) + " do " + DToC( dD_to )
   ? "---------------------------------------------------"
   ? "r.br * boja   * utrosak u kg            *"
   ? "----- -------- -------------------------"

   DO WHILE !Eof()

      ++ nCnt

      ? Str( nCnt, 4 ) + "."
      @ PRow(), PCol() + 1 SAY r_color
      @ PRow(), PCol() + 1 SAY Str( c_total, 12, 4 )

      SKIP

   ENDDO

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN .T.
