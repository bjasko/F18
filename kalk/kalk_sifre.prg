/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

FUNCTION kalk_sifrarnik()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   PRIVATE PicDem

   PicDem := kalk_pic_iznos_bilo_gpicdem()
   my_close_all_dbf()

   AAdd( _opc, "1. opći šifarnici                  " )
   AAdd( _opcexe, {|| opci_sifarnici() } )
   AAdd( _opc, "2. robno-materijalno poslovanje" )
   AAdd( _opcexe, {|| sif_roba_tarife_koncij_sast() } )
   AAdd( _opc, "3. magacinski i prodajni objekti" )
   AAdd( _opcexe, {|| P_Objekti() } )

   f18_menu( "msif", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .F.




FUNCTION kalk_roba_key_handler( Ch )

   LOCAL cSif := ROBA->id, cSif2 := ""
   LOCAL nRet

   IF Ch == K_CTRL_T .AND. gSKSif == "D"

      PushWA()
      SET ORDER TO TAG "ID"
      SEEK cSif
      SKIP 1
      cSif2 := ROBA->id
      PopWA()

   ELSEIF Ch == K_ALT_M
      RETURN MpcIzVpc()

   ELSEIF Upper( Chr( Ch ) ) == "S"

      //TB:Stabilize()
      //PushWA()
      sif_roba_kalk_stanje_magacin_key_handler_s( roba->id )
      //PopWa()
      //SELECT ROBA
      RETURN DE_CONT

   ELSEIF Upper( Chr( Ch ) ) == "D"
      roba_opis_edit( .T. )
      RETURN 6

   ENDIF

   RETURN DE_CONT

/*

-- FUNCTION OSifBaze()

   //o_konto()
   //o_koncij()
   //o_partner()
   o_tnal()
   o_tdok()
   o_trfp()
   O_TRMP
   o_valute()
   o_tarifa()
   // o_roba()
   o_sastavnice()

   RETURN .T.

*/

FUNCTION P_Objekti()

   LOCAL nTArea
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   nTArea := Select()
   kalk_o_objekti()

   AAdd( ImeKol, { "ID", {|| id }, "id" } )
   // add_mcode( @ImeKol )
   AAdd( ImeKol, { "Naziv", {|| PadR( ToStrU( naz ), 20 ) }, "naz" } )
   AAdd( ImeKol, { "IdObj", {|| idobj }, "idobj" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   SELECT ( nTArea )
   p_sifra( F_OBJEKTI, 1, f18_max_rows() - 15, f18_max_cols() - 20, "Objekti" )

   RETURN .T.




FUNCTION kalk_o_objekti()

   Select( F_OBJEKTI )
   use_sql_sif ( "objekti" )  // koristi se u KALK
   SET ORDER TO TAG "1"

   RETURN .T.
