/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// --------------------------------------------------------------------
// tekuci parametri ugovora
// --------------------------------------------------------------------
FUNCTION DFTParUg( lIni )

   LOCAL GetList := {}

   IF lIni == nil
      lIni := .F.
   ENDIF

   IF !lIni
      PRIVATE DFTkolicina := 1
      PRIVATE DFTidroba := PadR( "", 10 )
      PRIVATE DFTvrsta := "1"
      PRIVATE DFTidtipdok := "10"
      PRIVATE DFTdindem := "KM "
      PRIVATE DFTidtxt := "10"
      PRIVATE DFTzaokr := 2
      PRIVATE DFTiddodtxt := "  "
      //PRIVATE gGenUgV2 := "2"
      PRIVATE gFinKPath := Space( 50 )
   ENDIF

   DFTKolicina := fetch_metric( "ugovori_kolicina", nil, DFTkolicina )
   DFTidroba := fetch_metric( "ugovori_id_roba", nil, DFTidroba )
   DFTvrsta := fetch_metric( "ugovori_vrsta", nil, DFTvrsta )
   DFTidtipdok := fetch_metric( "ugovori_tip_dokumenta", nil, DFTidtipdok )
   DFTdindem := fetch_metric( "ugovori_valuta", nil, DFTdindem )
   DFTidtxt := fetch_metric( "ugovori_napomena_1", nil, DFTidtxt )
   DFTzaokr := fetch_metric( "ugovori_zaokruzenje", nil, DFTzaokr )
   DFTiddodtxt := fetch_metric( "ugovori_napomena_2", nil, DFTiddodtxt )
   //gGenUgV2 := fetch_metric( "ugovori_varijanta_2", nil, gGenUgV2 )

   IF !lIni

      Box(, 11, 75 )
      @ m_x + 0, m_y + 23 SAY8 "TEKUĆI PODACI ZA NOVE UGOVORE"
      @ m_x + 2, m_y + 2 SAY PadL( "Artikal", 20 ) GET DFTidroba VALID Empty( DFTidroba ) .OR. P_Roba( @DFTidroba, 2, 28 ) PICT "@!"
      @ m_x + 3, m_y + 2 SAY PadL( "Kolicina", 20 ) GET DFTkolicina PICT fakt_pic_kolicina()
      @ m_x + 4, m_y + 2 SAY PadL( "Tip ug.(1/2/G)", 20 ) GET DFTvrsta VALID DFTvrsta $ "12G"
      @ m_x + 5, m_y + 2 SAY PadL( "Tip dokumenta", 20 ) GET DFTidtipdok
      @ m_x + 6, m_y + 2 SAY PadL( "Valuta", 20 ) GET DFTdindem PICT "@!"
      @ m_x + 7, m_y + 2 SAY PadL( "Napomena 1", 20 ) GET DFTidtxt VALID p_fakt_ftxt( @DFTidtxt )
      @ m_x + 8, m_y + 2 SAY PadL( "Napomena 2", 20 ) GET DFTiddodtxt VALID p_fakt_ftxt( @DFTiddodtxt )
      @ m_x + 9, m_y + 2 SAY PadL( "Zaokruzenje", 20 ) GET DFTzaokr PICT "9"
      //@ m_x + 10, m_y + 2 SAY PadL( "gen.ug. ver 1/2", 20 ) GET gGenUgV2 PICT "@!" VALID gGenUgV2 $ "12"
      READ
      BoxC()

      IF LastKey() != K_ESC

         set_metric( "ugovori_kolicina", nil, DFTkolicina )
         set_metric( "ugovori_id_roba", nil, DFTidroba )
         set_metric( "ugovori_vrsta", nil, DFTvrsta )
         set_metric( "ugovori_tip_dokumenta", nil, DFTidtipdok )
         set_metric( "ugovori_valuta", nil, DFTdindem )
         set_metric( "ugovori_napomena_1", nil, DFTidtxt )
         set_metric( "ugovori_zaokruzenje", nil, DFTzaokr )
         set_metric( "ugovori_napomena_2", nil, DFTiddodtxt )
         //set_metric( "ugovori_varijanta_2", nil, gGenUgV2 )

      ENDIF

   ENDIF

   RETURN .T.
