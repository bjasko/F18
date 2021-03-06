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


// ---------------------------------------------------------------
// pregled ucinka po operaterima, koliko naloga su ostvarili
// u periodu
// ---------------------------------------------------------------
FUNCTION r_op_docs()

   LOCAL dD_From := CToD( "" )
   LOCAL dD_to := danasnji_datum()
   LOCAL nOper := 0

   // rnal_o_sif_tables()

   // daj uslove izvjestaja
   IF _g_vars( @dD_From, @dD_To, @nOper ) == 0
      RETURN
   ENDIF

   // kreiraj report
   _cre_op( dD_from, dD_to, nOper )

   // filuj nazive operatera
   _fill_op()

   // stampaj izvjestaj
   _p_op_docs( dD_from, dD_to )

   RETURN


// ----------------------------------------------------
// stampanje izvjestaja
// ----------------------------------------------------
STATIC FUNCTION _p_op_docs( dD_from, dD_to )

   LOCAL cLine
   LOCAL nCount := 0
   LOCAL nT_op := 0
   LOCAL nT_cl := 0
   LOCAL nT_re := 0
   LOCAL nT_to := 0
   LOCAL nCol := 1

   START PRINT CRET

   ?

   _rpt_descr( dD_from, dD_to )
   _rpt_head( @cLine )

   SELECT _tmp1
   GO TOP

   DO WHILE !Eof()

      ++ nCount

      ? PadL( AllTrim( Str( nCount ) ), 3 ) + "."

      @ PRow(), PCol() + 1 SAY PadR( AllTrim( field->op_desc ) + ;
         " (" + AllTrim( Str( field->operater ) ) + ")", 40 )

      @ PRow(), nCol := PCol() + 1 SAY field->o_count
      @ PRow(), PCol() + 1 SAY field->c_count
      @ PRow(), PCol() + 1 SAY field->r_count
      @ PRow(), PCol() + 1 SAY field->d_total

      nT_op += field->o_count
      nT_cl += field->c_count
      nT_re += field->r_count
      nT_to += field->d_total

      SKIP
   ENDDO

   // ispisi total
   ? cLine

   ? "UKUPNO:"
   @ PRow(), nCol SAY nT_op
   @ PRow(), PCol() + 1 SAY nT_cl
   @ PRow(), PCol() + 1 SAY nT_re
   @ PRow(), PCol() + 1 SAY nT_to

   ? cLine

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN


// ------------------------------------------------
// ispisi naziv izvjestaja po varijanti
// ------------------------------------------------
STATIC FUNCTION _rpt_descr( dD1, dD2 )

   LOCAL cTmp := "rpt: "

   cTmp += "Pregled obradjenih naloga po operaterima "

   ? cTmp

   cTmp := "za period od " + DToC( dD1 ) + " do " + DToC( dD2 )

   ? cTmp

   RETURN


// -------------------------------------------------
// header izvjestaja
// -------------------------------------------------
STATIC FUNCTION _rpt_head( cLine )

   cLine := ""
   cTxt := ""

   cLine += Replicate( "-", 4 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )

   cTxt += PadR( "r.br", 4 )
   cTxt += Space( 1 )
   cTxt += PadR( "Operater", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "Otvoreni", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "Zatvoreni", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "Odbaceni", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ukupno", 10 )

   ? cLine
   ? cTxt
   ? cLine

   RETURN

// ----------------------------------------------
// filuj nazive operatera u tabeli
// ----------------------------------------------
STATIC FUNCTION _fill_op()

   SELECT _tmp1
   GO TOP

   // prodji kroz tabelu i napuni nazive
   DO WHILE !Eof()

      RREPLACE field->op_desc with ;
         AllTrim( getfullusername( field->operater ) )

      SKIP
   ENDDO

   GO TOP

   RETURN



// ------------------------------------------------------------------------
// uslovi izvjestaja specifikacije
// ------------------------------------------------------------------------
STATIC FUNCTION _g_vars( dDatFrom, dDatTo, nOperater )

   LOCAL nRet := 1
   LOCAL nBoxX := 7
   LOCAL nBoxY := 70
   LOCAL nX := 1
   LOCAL nTArea := Select()
   LOCAL nVar1 := 1
   PRIVATE GetList := {}

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** Pregled naloga po operaterima"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Obuhvatiti period od:" GET dDatFrom
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dDatTo


   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Operater (0 - svi op.):" GET nOperater VALID {|| nOperater == 0 } PICT "9999999999"

   READ
   BoxC()

   IF LastKey() == K_ESC
      nRet := 0
   ENDIF

   RETURN nRet



// ----------------------------------------------
// kreiraj specifikaciju
// izvjestaj se primarno puni u _tmp0 tabelu
// ----------------------------------------------
STATIC FUNCTION _cre_op( dD_from, dD_to, nOper  )

   LOCAL nDoc_no

   // kreiraj tmp tabelu
   aField := _op_fields()

   cre_tmp1( aField )
   o_tmp1()

   // kreiraj indekse
   INDEX ON Str( operater, 10 ) TAG "1"

   rnal_o_tables( .F. )

   SELECT docs
   GO TOP

   Box(, 1, 50 )

   DO WHILE !Eof()

      nDoc_no := field->doc_no

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "... vrsim odabir stavki ... nalog: " + AllTrim( Str( nDoc_no ) )

      nOp_id := field->operater_i

      // provjeri da li ovaj dokument zadovoljava kriterij

      // ovo su busy nalozi...
      IF field->doc_status > 2
         SKIP
         LOOP
      ENDIF

      IF DToS( field->doc_date ) > DToS( dD_To ) .OR. ;
            DToS( field->doc_date ) < DToS( dD_From )

         // datumski period
         SKIP
         LOOP

      ENDIF

      IF nOper <> 0

         // po operateru

         IF AllTrim( Str( field->operater_i ) ) <> ;
               AllTrim( Str( nOper ) )

            SKIP
            LOOP

         ENDIF
      ENDIF

      // ubaci u tabelu
      _a_to_op( field->operater_i, field->doc_status )

      SELECT docs
      SKIP

   ENDDO

   BoxC()

   RETURN


// ------------------------------------------------
// ubaci u tabelu
// ------------------------------------------------
STATIC FUNCTION _a_to_op( nOp_id, nStatus )

   LOCAL nTArea := Select()

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   SEEK Str( nOp_id, 10 )

   IF !Found()
      APPEND BLANK
      REPLACE field->operater WITH nOp_id
   ENDIF

   DO CASE
   CASE nStatus == 0
      RREPLACE field->o_count with ( field->o_count + 1 )
   CASE nStatus == 1
      RREPLACE field->c_count with ( field->c_count + 1 )
   CASE nStatus == 2
      RREPLACE field->r_count with ( field->r_count + 1 )

   ENDCASE

   // total uvijek saberi
   RREPLACE field->d_total with ( field->o_count + ;
      field->c_count + field->r_count )

   SELECT ( nTArea )

   RETURN



// -----------------------------------------------
// vraca strukturu polja tabele _tmp1
// -----------------------------------------------
STATIC FUNCTION _op_fields()

   LOCAL aDbf := {}

   AAdd( aDbf, { "operater", "N",  10, 0 } )
   AAdd( aDbf, { "op_desc",  "C",  40, 0 } )
   AAdd( aDbf, { "o_count",  "N",  10, 0 } )
   AAdd( aDbf, { "c_count",  "N",  10, 0 } )
   AAdd( aDbf, { "r_count",  "N",  10, 0 } )
   AAdd( aDbf, { "d_total",  "N",  10, 0 } )

   RETURN aDbf
