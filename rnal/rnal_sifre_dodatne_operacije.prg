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

STATIC _tb_direkt
STATIC __wo_id

// -----------------------------------------
// otvara sifrarnik dodatnih operacija
// -----------------------------------------
FUNCTION s_aops( cId, cDesc, lwo_ID, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   PRIVATE ImeKol
   PRIVATE Kol

   nTArea := Select()

   O_AOPS

   cHeader := "Dodatne operacije /  'A' - pregled atributa"

   IF cDesc == nil
      cDesc := ""
   ENDIF

   IF lwo_ID == nil
      lwo_ID := .F.
   ENDIF

   __wo_id := lwo_ID

   SELECT aops
   SET FILTER TO
   SET ORDER TO TAG "1"

   set_a_kol( @ImeKol, @Kol )

   IF ValType( cId ) == "C"
      // try to validate
      IF Val( cId ) <> 0

         cId := Val( cId )
         cDesc := ""

      ENDIF
   ENDIF

   set_f_kol( cDesc )


   cRet := p_sifra( F_AOPS, 1, 12, 70, cHeader, @cId, dx, dy, {| Ch| key_handler( Ch ) } )

   IF ValType( cDesc ) == "N"
      cDesc := Str( cDesc, 10 )
   ENDIF

   IF cDesc <> ""
      SET FILTER TO
   ENDIF

   IF LastKey() == K_ESC
      cId := 0
   ENDIF

   SELECT ( nTArea )

   RETURN cRet


// ---------------------------------------------------
// setuje filter na sifraniku
// ---------------------------------------------------
STATIC FUNCTION set_f_kol( cDesc )

   LOCAL cFilter := ""

   IF !Empty( cDesc )

      cFilter += 'ALLTRIM(UPPER(aop_desc)) = ' + dbf_quote( Upper( AllTrim( cDesc ) ) )
   ENDIF

   IF !Empty( cFilter )
      SET FILTER to &cFilter
      GO TOP
   ENDIF

   RETURN


// -----------------------------------------
// setovanje kolona tabele
// -----------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   IF __wo_id == .F.

      AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( aop_id ) }, "aop_id", {|| rnal_uvecaj_id( @wAop_id, "AOP_ID" ), .F. }, {|| .T. } } )

   ENDIF

   AAdd( aImeKol, { PadC( "Opis", 40 ), {|| PadR( aop_full_d, 40 ) }, "aop_full_d" } )
   AAdd( aImeKol, { PadC( "Skr.opis (sifra)", 20 ), {|| PadR( aop_desc, 20 ) }, "aop_desc" } )
   AAdd( aImeKol, { PadC( "Joker", 20 ), {|| PadR( aop_joker, 20 ) }, "aop_joker" } )
   AAdd( aImeKol, { PadC( "u art.naz ( /*)", 15 ), {|| PadR( in_art_des, 15 ) }, "in_art_des" } )

   IF aops->( FieldPos( "AOP_UNIT" ) ) <> 0
      AAdd( aImeKol, { PadC( "jed.mjere", 10 ), {|| aop_unit }, "aop_unit" } )
   ENDIF

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN



// -----------------------------------------------
// dodatna operacija u naziv artikla ???
// -----------------------------------------------
FUNCTION aop_in_desc( nAop_id )

   LOCAL lRet := .F.
   LOCAL nTArea := Select()

   SELECT aops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aopid_str( nAop_id )

   IF Found()
      IF field->in_art_des == "*"
         lRet := .T.
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN lRet



// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION key_handler( Ch )

   LOCAL nAop_id := aops->aop_id
   LOCAL nTRec := RecNo()

   DO CASE
   CASE Upper( Chr( Ch ) ) == "A"
      // pregled atributa
      s_aops_att( nil, nAop_id )
      GO ( nTRec )

      RETURN DE_CONT

   CASE Ch == K_CTRL_N .OR. Ch == K_F4
      __wo_id := .F.
      set_a_kol( @ImeKol, @Kol )
      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT


// -------------------------------
// convert aop_id to string
// -------------------------------
FUNCTION aopid_str( nId )
   RETURN Str( nId, 10 )


// -------------------------------
// get aop_desc by aop_id
// -------------------------------
FUNCTION g_aop_desc( nAop_id, lEmpty, lFullDesc )

   LOCAL cAopDesc := "?????"
   LOCAL nTArea := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cAopDesc := ""
   ENDIF

   IF lFullDesc == nil
      lFullDesc := .T.
   ENDIF

   O_AOPS
   SELECT aops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aopid_str( nAop_id )

   IF Found()
      IF lFullDesc == .T.
         IF !Empty( field->aop_full_d )
            cAopDesc := AllTrim( field->aop_full_d )
         ENDIF
      ELSE
         IF !Empty( field->aop_desc )
            cAopDesc := AllTrim( field->aop_desc )
         ENDIF
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cAopDesc


// -------------------------------
// get aop_joker by aop_id
// -------------------------------
FUNCTION g_aop_joker( nAop_id )

   LOCAL cAopJoker := ""
   LOCAL nTArea := Select()

   O_AOPS
   SELECT aops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aopid_str( nAop_id )

   IF Found()
      IF !Empty( field->aop_joker )
         cAopJoker := AllTrim( field->aop_joker )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cAopJoker


// -------------------------------
// get aop_unit by aop_id
// -------------------------------
FUNCTION g_aop_unit( nAop_id )

   LOCAL cAopUnit := ""
   LOCAL nTArea := Select()

   IF nAop_id = 0
      RETURN cAopUnit
   ENDIF

   O_AOPS
   SELECT aops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aopid_str( nAop_id )

   IF Found()
      IF aops->( FieldPos( "AOP_UNIT" ) ) <> 0 .AND. !Empty( field->aop_unit )
         cAopUnit := AllTrim( field->aop_unit )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cAopUnit
