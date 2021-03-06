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


STATIC _wo_id

// -----------------------------------------
// otvara sifrarnik artikala
// -----------------------------------------
FUNCTION s_e_groups( cId, lwo_ID, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   PRIVATE ImeKol
   PRIVATE Kol
   PRIVATE GetList := {}

   nTArea := Select()

   O_E_GROUPS

   cHeader := "Elementi - grupe /"
   cHeader += Space( 5 )
   cHeader += "'A' - pregled atributa grupe"

   IF lwo_ID == nil
      _wo_id := .F.
   ENDIF

   SELECT e_groups
   SET ORDER TO TAG "1"

   set_a_kol( @ImeKol, @Kol )

   cRet := p_sifra( F_E_GROUPS, 1, f18_max_rows() -10, f18_max_cols() -5, cHeader, @cId, dx, dy, {|| key_handler( Ch ) } )

   SELECT ( nTArea )

   RETURN cRet


// -----------------------------------------
// setovanje kolona tabele
// -----------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   IF _wo_id == .F.

      AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( e_gr_id ) }, "e_gr_id", {|| rnal_uvecaj_id( @wE_gr_id, "E_GR_ID" ), .F. }, {|| .T. } } )

   ENDIF

   AAdd( aImeKol, { PadC( "Puni naziv grupe", 30 ), {|| PadR( e_gr_full_, 30 ) }, "e_gr_full_" } )
   AAdd( aImeKol, { PadC( "Skr. opis (sifra)", 15 ), {|| PadR( e_gr_desc, 15 ) }, "e_gr_desc" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION key_handler( Ch )

   LOCAL nTRec := RecNo()
   LOCAL nE_gr_id := field->e_gr_id

   DO CASE

   CASE Upper( Chr( Ch ) ) == "A"
      // pregled atributa
      s_e_gr_att( nil, nE_gr_id )
      GO ( nTRec )
      RETURN DE_CONT

   CASE Ch == K_CTRL_N .OR. Ch == K_F4

      _wo_id := .F.
      set_a_kol( @ImeKol, @Kol )
      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT


// -------------------------------
// convert e_gr_id to string
// -------------------------------
FUNCTION e_gr_id_str( nId )
   RETURN Str( nId, 10 )



// -------------------------------
// get e_gr_desc by e_gr_id
// -------------------------------
FUNCTION g_e_gr_desc( nE_gr_id, lEmpty, lFullDesc )

   LOCAL cEGrDesc := "?????"
   LOCAL nTArea := Select()
   LOCAL cVal := ""

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cEGrDesc := ""
   ENDIF

   IF lFullDesc == nil
      lFullDesc := .T.
   ENDIF

   O_E_GROUPS
   SELECT e_groups
   SET ORDER TO TAG "1"
   GO TOP
   SEEK e_gr_id_str( nE_gr_id )

   IF Found()

      IF lFullDesc == .T.
         IF !Empty( field->e_gr_full_ )
            cEGrDesc := AllTrim( field->e_gr_full_ )
         ENDIF
      ELSE
         IF !Empty( field->e_gr_desc )
            cEGrDesc := AllTrim( field->e_gr_desc )
         ENDIF
      ENDIF

   ENDIF

   SELECT ( nTArea )

   IF !Empty( cEGrDesc )
      cEGrDesc := PadR( cEGrDesc, 6 )
   ENDIF

   RETURN cEGrDesc


// ----------------------------------------------
// vraca grupu, trazeci po e_gr_desc
// ----------------------------------------------
FUNCTION g_gr_by_type( cType )

   LOCAL nTArea := Select()
   LOCAL nGroup := 0

   O_E_GROUPS
   SELECT e_groups
   SET ORDER TO TAG "2"

   GO TOP

   SEEK PadR( cType, 20 )

   IF Found() .AND. AllTrim( field->e_gr_desc ) == cType

      nGroup := field->e_gr_id

   ENDIF

   SET ORDER TO TAG "1"
   SELECT ( nTArea )

   RETURN nGroup


// ----------------------------------------------------
// vraca group_description by element id
// ----------------------------------------------------
FUNCTION g_grd_by_elid( nEl_id )

   LOCAL nTArea := Select()
   LOCAL cGrDesc := ""

   O_ELEMENTS
   SELECT elements
   SET ORDER TO TAG "2"
   GO TOP

   SEEK elid_str( nEl_id )

   IF Found() .AND. field->el_id == nEl_id
      cGrDesc := g_e_gr_desc( field->e_gr_id, .T., .F. )
   ENDIF

   SELECT ( nTArea )

   RETURN cGrDesc
