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

FUNCTION sif_ral( cId, dx, dy )

   LOCAL cHeader := "RAL"
   PRIVATE ImeKol
   PRIVATE Kol

   O_RAL

   set_kolone( @ImeKol, @Kol )

   p_sifra( F_RAL, 1, f18_max_rows() - 15, f18_max_cols() - 15, cHeader, @cId, dx, dy, {|| key_handler( Ch ) } )

   RETURN .T.


STATIC FUNCTION key_handler( cCh )
   RETURN DE_CONT


STATIC FUNCTION set_kolone( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "RAL", 5 ), {|| id }, "id", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "Debljina", 8 ), {|| gl_tick }, "gl_tick", ;
      {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "Naziv", 20 ), {|| PadR( descr, 20 ) }, "descr" } )
   AAdd( aImeKol, { PadC( "En.naziv", 20 ), {|| PadR( en_desc, 20 ) }, "en_desc" } )
   AAdd( aImeKol, { PadC( "Boja 1", 10 ), {|| col_1 }, "col_1" } )
   AAdd( aImeKol, { PadC( "% boje 1", 12 ), {|| colp_1 }, "colp_1" } )
   AAdd( aImeKol, { PadC( "Boja 2", 10 ), {|| col_2 }, "col_2" } )
   AAdd( aImeKol, { PadC( "% boje 2", 12 ), {|| colp_2 }, "colp_2" } )
   AAdd( aImeKol, { PadC( "Boja 3", 10 ), {|| col_3 }, "col_3" } )
   AAdd( aImeKol, { PadC( "% boje 3", 12 ), {|| colp_3 }, "colp_3" } )
   AAdd( aImeKol, { PadC( "Boja 4", 10 ), {|| col_4 }, "col_4" } )
   AAdd( aImeKol, { PadC( "% boje 4", 12 ), {|| colp_4 }, "colp_4" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN



FUNCTION get_ral( nTick )

   LOCAL cRet := ""
   LOCAL nRal := 0
   LOCAL nRoller := 1
   LOCAL GetList := {}
   LOCAL nTarea := Select()

   IF nTick == nil
      nTick := 0
   ENDIF

   SELECT ( F_RAL )
   IF !Used()
      O_RAL
   ENDIF

   Box(, 2, 45 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Valjak [1 - 80] / [2 - 160]:" GET nRoller PICT "9" VALID prikazi_valjak( nRoller )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "             RAL ->" GET nRal PICT "99999"

   READ

   BoxC()

   SELECT ral
   SEEK Str( nRal, 5, 0 ) + Str( nTick, 2, 0 )

   IF !Found()
      SEEK Str( nRal, 5, 0 )

      IF !Found()
         sif_ral( @nRal )
      ENDIF
   ENDIF

   nTick := field->gl_tick

   SELECT ( nTarea )

   IF LastKey() == K_ESC
      RETURN cRet
   ENDIF

   // format stringa je:
   // ------------------
   // "RAL:1000#4#80"
   //
   // 1000 - oznaka ral
   // 4 - debljina, 0 - default
   // 80 - valjak gramaza...

   cRet := "RAL:" + AllTrim( Str( nRal, 5, 0 ) ) + ;
      "#" + AllTrim( Str( nTick, 2, 0 ) ) + ;
      "#" + AllTrim( Str( dimenzije_valjaka( nRoller ) ) )

   RETURN cRet



STATIC FUNCTION prikazi_valjak( nValjak )

   LOCAL nValue := dimenzije_valjaka( nValjak )
   LOCAL cValue

   cValue := "-> " + AllTrim( Str( nValue ) ) + " gr/m2"

   @ box_x_koord() + 1, Col() + 2 SAY PadR( cValue, 12 )

   RETURN .T.



STATIC FUNCTION matrica_valjaka()

   LOCAL _arr := {}

   AAdd( _arr, { 1, 80 } )
   AAdd( _arr, { 2, 160 } )

   RETURN _arr



STATIC FUNCTION dimenzije_valjaka( nValjak )

   LOCAL nVal := 80
   LOCAL nScan
   LOCAL aArr := matrica_valjaka()

   nScan := AScan( aArr, {|xval| xval[ 1 ] == nValjak } )

   IF nScan > 0
      nVal := aArr[ nScan, 2 ]
   ENDIF

   RETURN nVal


// ----------------------------------------
// vraca informaciju o ral-u
// nRal - oznaka RAL-a (numeric)
// nTick - debljina stakla
// ----------------------------------------
FUNCTION g_ral_value( cRal )

   LOCAL xRet := ""
   LOCAL aRal
   LOCAL nRal, nTick, nRoller

   LOCAL nTArea := Select()

   aRal := TokToNiz( cRal, "#" )

   IF ValType( aRal ) != "A" .OR. Len( aRal ) < 2
      error_bar( "g_ral", "ERR format RAL:#D1#D2#D3: " +  cRal )
      RETURN "RAL:ERR"
   ENDIF

   nRal := Val( aRal[ 1 ] )
   nTick := Val( aRal[ 2 ] )
   nRoller :=  Val( aRal[ 3 ] )

   SELECT ( F_RAL )
   IF !Used()
      O_RAL
   ENDIF

   IF nTick == nil
      nTick := 0
   ENDIF

   IF nRoller == nil
      nRoller := 80
   ENDIF

   IF nTick == 0
      SEEK Str( nRal, 5, 0 )
   ELSE
      SEEK Str( nRal, 5, 0 ) + Str( nTick, 2, 0 )
   ENDIF

   IF Found()

      // opis
      xRet += " "
      xRet += AllTrim( field->en_desc )
      xRet += " "
      xRet += AllTrim( Str( nRoller ) ) + " gr/m2"

      // prva boja
      IF field->col_1 <> 0 .AND. field->colp_1 <> 0
         xRet += " "
         xRet += AllTrim( Str( field->col_1 ) )
         xRet += " ("
         xRet += AllTrim( Str( field->colp_1, 12, 2 ) ) + "%"
         xRet +=  ")"
      ENDIF

      // druga boja
      IF field->col_2 <> 0 .AND. field->colp_2 <> 0
         xRet += " "
         xRet += AllTrim( Str( field->col_2 ) )
         xRet += " ("
         xRet += AllTrim( Str( field->colp_2, 12, 2 ) ) + "%"
         xRet +=  ")"
      ENDIF

      // treca boja
      IF field->col_3 <> 0 .AND. field->colp_3 <> 0
         xRet += " "
         xRet += AllTrim( Str( field->col_3 ) )
         xRet += " ("
         xRet += AllTrim( Str( field->colp_3, 12, 2 ) ) + "%"
         xRet +=  ")"
      ENDIF

      // cetvrta boja
      IF field->col_4 <> 0 .AND. field->colp_4 <> 0
         xRet += " "
         xRet += AllTrim( Str( field->col_4 ) )
         xRet += " ("
         xRet += AllTrim( Str( field->colp_4, 12, 2 ) ) + "%"
         xRet +=  ")"
      ENDIF

   ENDIF

   IF !Empty( xRet )
      xRet := "RAL-" + AllTrim( Str( field->id, 5 ) ) + ":" + xRet
   ENDIF

   SELECT ( nTArea )

   RETURN xRet



FUNCTION rnal_prikazi_ral_kalkulaciju( aColor )

   LOCAL cTmp := ""
   LOCAL i

   // 1. 152000 (54.00%) -> 0.091 kg
   // 2. 182000 (44.00%) -> 0.072 kg

   ?U "RAL: utrošak boja (kg)"
   ? "-----------------------------------"

   FOR i := 1 TO Len( aColor )

      cTmp := Str( i, 1 ) + ". " + PadR( Str( aColor[ i, 1 ], 8 ), 8 ) + ;
         PadR( " (" + Str( aColor[ i, 2 ], 12, 2 ) + "%" + ") ", 12 ) + ;
         " -> " + PadR( Str( aColor[ i, 3 ], 15, 3 ), 12 ) + " kg"

      ? cTmp
   NEXT

   RETURN



// ----------------------------------------------
// izracunaj ukupni utrosak boja
//
// nRal - ral oznaka
// nTick - debljina stakla
// nRoller - valjak
// nUm2 - ukupna kvadratura stakla
// ----------------------------------------------
FUNCTION rnal_kalkulisi_ral( nRal, nTick, nRoller, nUm2 )

   LOCAL nTArea := Select()
   LOCAL nColor1 := 0.00000000000
   LOCAL nColor2 := 0.00000000000
   LOCAL nColor3 := 0.00000000000
   LOCAL nColor4 := 0.00000000000
   LOCAL aColor := {}

   SELECT ( F_RAL )
   IF !Used()
      O_RAL
   ENDIF

   GO TOP
   SEEK Str( nRal, 5, 0 ) + Str( nTick, 2, 0 )

   IF Found()

      nColor1 := rnal_ral_utrosak_boje( field->colp_1, nUm2, nRoller )
      nColor2 := rnal_ral_utrosak_boje( field->colp_2, nUm2, nRoller )
      nColor3 := rnal_ral_utrosak_boje( field->colp_3, nUm2, nRoller )
      nColor4 := rnal_ral_utrosak_boje( field->colp_4, nUm2, nRoller )

      IF nColor1 <> 0
         AAdd( aColor, { field->col_1, field->colp_1, nColor1 } )
      ENDIF
      IF nColor2 <> 0
         AAdd( aColor, { field->col_2, field->colp_2, nColor2 } )
      ENDIF
      IF nColor3 <> 0
         AAdd( aColor, { field->col_3, field->colp_3, nColor3 } )
      ENDIF
      IF nColor4 <> 0
         AAdd( aColor, { field->col_4, field->colp_4, nColor4 } )
      ENDIF

   ENDIF

   SELECT ( nTArea )

   RETURN aColor



// --------------------------------------------------------------
// izracunaj utrosak boje u "kg"
//
// nPercent = procenat boje
// nRoller = valjak (gr/m2)
// nUm2 = ukupna kvadratura stakla
//
// --------------------------------------------------------------
FUNCTION rnal_ral_utrosak_boje( nPercent, nUm2, nRoller )

   LOCAL nRet := 0

   IF nPercent = 0
      RETURN nRet
   ENDIF

   nRet := Round2( ( ( ( nPercent / 100 ) * nUm2 * nRoller ) / 1000 ), 12 )

   RETURN nRet
