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
STATIC _aop_id
STATIC __wo_id

// ------------------------------------------------
// otvara sifrarnik dodatnih operacija, atributa
// ------------------------------------------------
FUNCTION s_aops_att( cId, nAop_id, cAop_desc, lwo_ID, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   PRIVATE ImeKol
   PRIVATE Kol

   IF nAop_id == nil
      nAop_id := -1
   ENDIF

   IF cAop_desc == nil
      cAop_desc := ""
   ENDIF

   IF lwo_ID == nil
      lwo_ID := .F.
   ENDIF

   _aop_id := nAop_id
   __wo_id := lwo_ID

   nTArea := Select()

   O_AOPS_ATT

   cHeader := "Dodatne operacije, atributi /"

   SELECT aops_att
   SET ORDER TO TAG "1"

   set_a_kol( @ImeKol, @Kol )

   IF ValType( cId ) == "C"
      // try to validate
      IF Val( cId ) <> 0

         cId := Val( cId )
         nAop_id := -1
         cAop_Desc := ""

      ENDIF
   ENDIF

   aop_filter( nAop_id, cAop_desc )


   cRet := p_sifra( F_AOPS_ATT, 1, 10, 70, cHeader, @cId, dx, dy, {| Ch| key_handler( Ch ) } )

   IF ValType( cAop_desc ) == "N"
      cAop_desc := Str( cAop_desc, 10 )
   ENDIF

   IF nAop_id > 0 .OR. cAop_desc <> ""
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
STATIC FUNCTION aop_filter( nAop_id, cAop_desc )

   LOCAL cFilter := ""

   IF nAop_id > 0
      cFilter += 'aop_id == ' + aopid_str( nAop_id )
   ENDIF

   IF !Empty( cAop_desc )

      IF !Empty( cFilter )
         cFilter += ' .and. '
      ENDIF

      cFilter += 'ALLTRIM(UPPER(aop_att_d)) = ' + dbf_quote( Upper( AllTrim( cAop_desc ) ) )
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
      AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( aop_att_id ) }, "aop_att_id", {|| rnal_uvecaj_id( @wAop_att_id, "AOP_ATT_ID" ), .F. }, {|| .T. } } )
   ENDIF

   AAdd( aImeKol, { PadR( "Dod.op.ID", 15 ), {|| PadR( g_aop_desc( aop_id ), 15 ) }, "aop_id", {|| set_aop_id( @waop_id ) }, {|| s_aops( @waop_id ), show_it( g_aop_desc( waop_id ) )  } } )
   AAdd( aImeKol, { PadR( "Opis", 40 ), {|| PadR( aop_att_fu, 40 ) }, "aop_att_fu" } )
   AAdd( aImeKol, { PadR( "Skr. opis (sifra)", 20 ), {|| PadR( aop_att_de, 20 ) }, "aop_att_de" } )

   IF aops_att->( FieldPos( "AOP_ATT_JO" ) ) <> 0
      AAdd( aImeKol, { PadR( "Joker", 20 ), {|| aop_att_jo }, "aop_att_jo" } )
   ENDIF

   AAdd( aImeKol, { PadC( "u art.naz ( /*)", 15 ), {|| PadR( in_art_des, 15 ) }, "in_art_des" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN

// ---------------------------------------------------
// setuje polje aop_id pri unosu automatski
// ---------------------------------------------------
STATIC FUNCTION set_aop_id( nAop_id )

   IF _aop_id > 0
      nAop_id := _aop_id
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF

   RETURN


// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION key_handler( Ch )

   DO CASE
   CASE Ch == K_CTRL_N .OR. Ch == K_F4
      __wo_id := .F.
      set_a_kol( @ImeKol, @Kol )
      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT


// -------------------------------
// convert aop_att_id to string
// -------------------------------
FUNCTION aop_att_str( nId )
   RETURN Str( nId, 10 )


// -----------------------------------------------
// dodatna operacija atribut u naziv artikla ???
// -----------------------------------------------
FUNCTION aop_att_in_desc( nAop_att_id )

   LOCAL lRet := .F.
   LOCAL nTArea := Select()

   SELECT aops_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aop_att_str( nAop_att_id )

   IF Found()
      IF field->in_art_des == "*"
         lRet := .T.
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN lRet



// -------------------------------
// get aop_att_joker by aopatt_id
// -------------------------------
FUNCTION g_aatt_joker( nAopatt_id )

   LOCAL cAttJoker := ""
   LOCAL nTArea := Select()

   O_AOPS_ATT
   SELECT aops_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aop_att_str( nAopatt_id )

   IF Found()

      // ako ima polja ?
      IF aops_att->( FieldPos( "AOP_ATT_JO" ) ) == 0

         // uzmi iz opisa
         cAttJoker := AllTrim( g_aop_att_desc( nAopatt_id, .T., .F. ) )
         RETURN cAttJoker

      ENDIF

      IF !Empty( field->aop_att_jo )
         cAttJoker := AllTrim( field->aop_att_jo )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cAttJoker




// -------------------------------
// get aop_desc by aop_id
// -------------------------------
FUNCTION g_aop_att_desc( nAop_att_id, lEmpty, lFullDesc )

   LOCAL cAopAttDesc := "?????"
   LOCAL nTArea := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cAopAttDesc := ""
   ENDIF

   IF lFullDesc == nil
      lFullDesc := .T.
   ENDIF

   O_AOPS_ATT
   SELECT aops_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aop_att_str( nAop_att_id )

   IF Found()
      IF lFullDesc == .T.
         IF !Empty( field->aop_att_fu )
            cAopAttDesc := AllTrim( field->aop_att_fu )
         ENDIF
      ELSE
         IF !Empty( field->aop_att_de )
            cAopAttDesc := AllTrim( field->aop_att_de )
         ENDIF
      ENDIF
   ENDIF

   // izbaci konfiguratore ako postoje
   rem_jokers( @cAopAttDesc )

   SELECT ( nTArea )

   RETURN cAopAttDesc



// ---------------------------------------------
// da li se koristi konfigurator stranica
// ako se koristi setuj cVal
// ---------------------------------------------
FUNCTION is_g_config( cVal, nAop_att_id, ;
      nHeigh, nWidth, nTick )

   LOCAL nTArea := Select()
   LOCAL lGConf := .F.
   LOCAL lHConf := .F.
   LOCAL lStConf := .F.
   LOCAL lPrepConf := .F.
   LOCAL lRalConf := .F.

   LOCAL cConf := ""

   LOCAL cJoker

   // dimension from 1 to 4
   LOCAL cV1
   LOCAL cV2
   LOCAL cV3
   LOCAL cV4

   // radijusi....
   LOCAL nR1 := 0
   LOCAL nR2 := 0
   LOCAL nR3 := 0
   LOCAL nR4 := 0

   // ako vec postoji vrijednost nista....
   // preskoci...
   IF !Empty( cVal )
      RETURN .T.
   ENDIF

   O_AOPS_ATT
   SELECT aops_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK aop_att_str( nAop_att_id )

   IF Found()

      // standarni konfigurator
      IF "#G_CONFIG#" $ field->aop_att_fu
         lGConf := .T.

      // konfigurator busenja rupa
      ELSEIF "#HOLE_CONFIG#" $ field->aop_att_fu
         lHConf := .T.

      // RAL - konfigurator
      ELSEIF "#RAL_CONFIG#" $ field->aop_att_fu
         lRalConf := .T.

      // konfigurator pozicije pecata
      ELSEIF "#STAMP_CONFIG#" $ field->aop_att_fu
         lStConf := .T.

      ELSEIF "#PREP_CONFIG#" $ field->aop_att_fu
         lPrepConf := .T.

      ELSEIF "#" $ field->aop_att_fu
         lGConf := .F.

         aTmp := TokToNiz( field->aop_att_fu, "#" )
         cVal := PadR(  AllTrim( aTmp[ 2 ] ), 150 )

         RETURN .T.

      ENDIF

      IF aops_att->( FieldPos( "AOP_ATT_JO" ) ) <> 0
         cJoker := AllTrim( field->aop_att_jo )
      ELSE
         cJoker := AllTrim( field->aop_att_de )
      ENDIF

   ENDIF

   IF lGConf == .T.

      IF rnal_konfigurator_stakla( nWidth, nHeigh, @cV1, @cV2, @cV3, @cV4, ;
            @nR1, @nR2, @nR3, @nR4 ) == .T.

         // shema za G_CONFIG
         //
         // val1
         // val2               val3
         // val4
         //
         // val 1/4 - sirine stakla (gornja/donja)
         // val 2/3 - visine stakla (gornja/donja)


         // get string...
         cVal := "#"

         // prvo stranice
         IF cV1 == "D"
            cVal += "D1#"
         ENDIF

         IF cV2 == "D"
            cVal += "D2#"
         ENDIF

         IF cV3 == "D"
            cVal += "D3#"
         ENDIF

         IF cV4 == "D"
            cVal += "D4#"
         ENDIF

         // zatim radijusi

         IF nR1 <> 0
            cVal += "R1=" + AllTrim( Str( nR1 ) ) + "#"
         ENDIF

         IF nR2 <> 0
            cVal += "R2=" + AllTrim( Str( nR2 ) ) + "#"
         ENDIF

         IF nR3 <> 0
            cVal += "R3=" + AllTrim( Str( nR3 ) ) + "#"
         ENDIF

         IF nR4 <> 0
            cVal += "R4=" + AllTrim( Str( nR4 ) ) + "#"
         ENDIF


         // formira string
         //
         // npr: kod brusenja stranica gornje i donje stranice
         // i obrade 1 radijusa
         //
         // joker + ":" + string vrijednosti
         //
         // <AOP_B_STR>:#D1#D4#R1=200#

         cVal := PadR( cJoker + ":" + cVal, 150 )
      ENDIF

   ENDIF

   IF lHConf == .T.
      cVal := rnal_konfiguracija_dimenzija_rupa( cJoker )
   ENDIF

   IF lRalConf == .T.
      cVal := PadR( get_ral( nTick ), 150 )
   ENDIF

   IF lStConf == .T. .AND. Pitanje(, "Unjeti pozicije pečata (D/N) ?", "D" ) == "D"
      cVal := rnal_konfigurator_pozicije_pecata( cJoker, nWidth, nHeigh )
   ENDIF

   IF lPrepConf == .T.
      cVal := rnal_konfiguracija_prepusta( cJoker, nWidth, nHeigh, 0, 0, 0, 0 )
   ENDIF

   SELECT ( nTArea )

   RETURN .T.


// ---------------------------------------------------
// vraca formiran string za vrijednost operacije
// ---------------------------------------------------
FUNCTION g_aop_value( cVal )

   LOCAL cRet := ""
   LOCAL aTmp := {}
   LOCAL aRal := {}

   IF Empty( cVal )
      RETURN ""
   ENDIF

   cVal := AllTrim( cVal )

   // "<AOP_B_STR>:#D1#D2#"
   // "<AOP_B_STR>" + "#D1#D2#"

   aTmp := TokToNiz( cVal, ":" )

   IF aTmp == NIL .OR. Len( aTmp ) == 0 .OR. Len( aTmp ) == 1
      RETURN cVal
   ENDIF

   DO CASE

   CASE aTmp[ 1 ] == "<A_B>"
      cRet := _cre_aop_str( aTmp[ 2 ] )

   CASE aTmp[ 1 ] == "<A_Z>" // zaobljavanje
      cRet := _cre_aop_Str( aTmp[ 2 ] )

   CASE aTmp[ 1 ] == "STAMP"
      cRet := rnal_pozicija_pecata_stavke( cVal )

   CASE aTmp[ 1 ] == "<A_BU>"
      cRet := rnal_dimenzije_rupa_za_nalog( cVal )

   CASE aTmp[ 1 ] == "<A_PREP>"
      cRet := rnal_dimenzije_prepusta_za_nalog( cVal )

   CASE aTmp[ 1 ] == "RAL"
      cRet := g_ral_value( aTmp[ 2 ] )

   ENDCASE

   RETURN cRet



STATIC FUNCTION _cre_aop_str( cStr )

   LOCAL cRet := ""
   LOCAL aTmp := {}

   cStr := AllTrim( cStr )


   aTmp := TokToNiz( cStr, "#" )

   IF aTmp == NIL .OR. Len( aTmp ) == 0
      RETURN ""
   ENDIF


   IF Len( aTmp ) == 4 .AND. ;
         ( aTmp[ 1 ] + aTmp[ 2 ] + aTmp[ 3 ] + aTmp[ 4 ] == "D1D2D3D4" )
      cRet := "kompletno staklo"
   ELSEIF Len( aTmp ) < 4
      cRet := "pogledaj skicu"
   ELSE
      cRet := "-"
   ENDIF

   RETURN cRet
