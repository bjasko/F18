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


FUNCTION mat_sifrarnik()

   PRIVATE izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   O_KONTO
   O_PARTN
   O_TNAL
   O_TDOK
   O_ROBA
   O_VALUTE
   O_KARKON
   O_SIFK
   O_SIFV
   O_TARIFA

   AAdd( opc, "1. partneri                            " )
   AAdd( opcexe, {|| p_firma() } )
   AAdd( opc, "2. konto        " )
   AAdd( opcexe, {|| p_konto() } )
   AAdd( opc, "3. vrste naloga  " )
   AAdd( opcexe, {|| p_vn() } )
   AAdd( opc, "4. tipovi dokumenata  " )
   AAdd( opcexe, {|| p_tipdok() } )
   AAdd( opc, "5. roba  " )
   AAdd( opcexe, {|| p_roba() } )
   AAdd( opc, "6. tarifa  " )
   AAdd( opcexe, {|| p_tarifa() } )
   AAdd( opc, "7. osobine konta  " )
   AAdd( opcexe, {|| p_karkon() } )
   AAdd( opc, "8. valute " )
   AAdd( opcexe, {|| p_valuta() } )
   AAdd( opc, "9. sifk - karakteristike " )
   AAdd( opcexe, {|| p_sifk() } )


   f18_menu_sa_priv_vars_opc_opcexe_izbor( "m_rpt" )

   RETURN


FUNCTION P_KarKon( cid, dx, dy )

   PRIVATE ImeKol, Kol

   ImeKol := { { "ID ", {|| id }, "id", {|| .T. }, {|| vpsifra( wId ) } }, ;
      { "T.NC( /1/2/3/P)", {|| PadC( tip_nc, 17 ) }, "tip_nc", {|| .T. }, {|| wtip_nc $ " 123P" } }, ;
      { "T.PC( /1/2/3/P)", {|| PadC( tip_pc, 17 ) }, "tip_pc", {|| .T. }, {|| wtip_pc $ " 123P" } };
      }
   Kol := { 1, 2, 3 }

   RETURN PostojiSifra( F_KARKON, 1, 10, 55, "Osobine konta", @cid, dx, dy )
