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



// -------------------------------
// nabavke koje su oporezive
// --------------------------------
FUNCTION t_i_opor( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.

   // standardne nabavke
   lRet := lRet .OR. ( cIdTar == PadR( "PDV17", 6 ) )
   // nabavka poljoprivreda - oporezivo
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7PO", 6 ) )
   // avansne nabavke
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7AV", 6 ) )

   // neposlovne svrhe
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7NP", 6 ) )

   RETURN lRet

// -------------------------------
// nabavke ne prizna je se ulazni porez
// --------------------------------
FUNCTION t_u_n_poup( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.

   // standardne nabavke
   // nabavka poljoprivreda - oporezivo
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7NP", 6 ) )

   RETURN lRet


// -------------------------------
// nabavke oporezive,
// priznat ulazni porez, osim pausalne naknade poljoprivrednicima
// -------------------------------
FUNCTION t_u_poup( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.

   // standardne nabavke
   lRet := lRet .OR. ( cIdTar == PadR( "PDV17", 6 ) )
   // avansne nabavke
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7AV", 6 ) )

   RETURN lRet

// -------------------------------
// nabavke oporezive,
// pausalne naknade poljoprivrednicima
// -------------------------------
FUNCTION t_u_polj( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.

   // nabavka poljoprivreda - oporezivo
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7PO", 6 ) )

   RETURN lRet

// -------------------------------
// nabavke neoporezive,
// neoporezivi dio nabavke od poljprovrednika
// -------------------------------
FUNCTION epdv_tarifa_nabavke_od_poljoprivrednika( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.

   // nabavka poljoprivreda - oporezivo
   lRet := lRet .OR. ( cIdTar == PadR( "PDV0PO", 6 ) )

   RETURN lRet




FUNCTION epdv_tarifa_nabavke_uvoz( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.
   lRet := lRet .OR. ( cIdTar == PadR( "PDV7UV", 6 ) )

   RETURN lRet



FUNCTION epdv_tarifa_nabavke_nepdv_obveznici( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.
   lRet := lRet .OR. ( cIdTar == PadR( "PDV0", 6 ) )
   lRet := lRet .OR. ( cIdTar == PadR( "PDV0UV", 6 ) )

   RETURN lRet


FUNCTION epdv_tarifa_isporuke_neoporezivo_osim_izvoza( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.
   lRet := lRet .OR. ( cIdTar == PadR( "PDV0", 6 ) )

   RETURN lRet



FUNCTION epdv_tarifa_isporuke_izvoz( cIdTar )

   LOCAL lRet

   cIdTar := PadR( cIdTar, 6 )

   lRet := .F.
   lRet := lRet .OR. ( cIdTar == PadR( "PDV0IZ", 6 ) )

   RETURN lRet
