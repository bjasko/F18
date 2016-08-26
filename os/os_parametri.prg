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



STATIC s_dDatumObracuna


FUNCTION os_datum_obracuna( dSet )

   IF dSet != NIL
      s_dDatumObracuna := dSet
   ENDIF

   RETURN s_dDatumObracuna


// -----------------------------------
// parametar datum obrade ...
// -----------------------------------
FUNCTION os_set_datum_obrade()

   LOCAL _dat_obr := Date()
   LOCAL _os_sii := "O"

   _dat_obr := fetch_metric( "os_datum_obrade", my_user(), _dat_obr )
   _os_sii := fetch_metric( "os_sii_modul", my_user(), _os_sii )

   Box(, 4, 50 )
   SET CURSOR ON
   @ m_x + 2, m_y + 2 SAY "Obrada (O) OS / (S) SII" GET _os_sii VALID _os_sii $ "OS" PICT "@!"
   @ m_x + 3, m_y + 2 SAY "Datum obrade  " GET _dat_obr
   READ
   BoxC()

   IF LastKey() <> K_ESC

      set_metric( "os_datum_obrade", my_user(), _dat_obr )
      set_metric( "os_sii_modul", my_user(), _os_sii )

      fin_kam_datum_obracuna( _dat_obr )
      gOsSii := _os_sii

   ENDIF

   RETURN


// -----------------------------------------
// ispisuje info na glavnom ekranu...
// -----------------------------------------
FUNCTION set_os_info()

   LOCAL _mod_name := PadC( "O S N O V N A    S R E D S T V A", MAXCOLS() )

   IF gOsSii == "S"
      _mod_name := PadC( "S I T A N    I N V E N T A R", MAXCOLS() )
   ENDIF

   @ MAXROWS() - 2, 1 SAY _mod_name COLOR F18_COLOR_I

   RETURN



// -------------------------------------------
// meni parametara modula os
// -------------------------------------------
FUNCTION os_parametri()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. osnovni podaci org.jedinice         " )
   AAdd( _opcexe, {|| parametri_organizacije() } )
   AAdd( _opc, "2. parametri os/sii" )
   AAdd( _opcexe, {|| _os_sii_parametri() } )

   f18_menu( "params", .F., _izbor, _opc, _opcexe )

   RETURN




// -----------------------------------
// parametri
// -----------------------------------
FUNCTION _os_sii_parametri()

   LOCAL _dat_obr := os_datum_obracuna()
   LOCAL _pic_iznos := gPicI
   LOCAL _metoda := gMetodObr
   LOCAL _id_unikat := gIBJ
   LOCAL _druga_valuta := gDrugaVal
   LOCAL _varijanta := gVObracun
   LOCAL _obr_pocetak := gVarDio
   LOCAL _obr_pocetak_datum := gDatDio
   LOCAL _os_rj := gRJ

   _dat_obr := fetch_metric( "os_datum_obrade", my_user(), _dat_obr )
   _pic_iznos := fetch_metric( "os_prikaz_iznosa", nil, _pic_iznos )
   _metoda := fetch_metric( "os_metoda_obracuna", nil, _metoda )
   _id_unikat := fetch_metric( "os_id_broj_je_unikatan", nil, _id_unikat )
   _druga_valuta := fetch_metric( "os_prikaz_u_dvije_valute", nil, _druga_valuta )
   _varijanta := fetch_metric( "os_varijanta_obracuna", nil, _varijanta )
   _obr_pocetak := fetch_metric( "os_pocetak_obracuna", nil, _obr_pocetak )
   _obr_pocetak_datum := fetch_metric( "os_pocetak_obracuna_datum", nil, _obr_pocetak_datum )
   _os_rj := fetch_metric( "os_radna_jedinica", nil, _os_rj )

   _pic_iznos := PadR( _pic_iznos, 15 )

   Box(, 20, 70 )

   SET CURSOR ON

   @ m_x + 3, m_y + 2 SAY "Radna jedinica" GET _os_rj

   @ m_x + 4, m_y + 2 SAY "Datum obrade  " GET _dat_obr

   @ m_x + 5, m_y + 2 SAY "Prikaz iznosa " GET _pic_iznos

   @ m_x + 7, m_y + 2 SAY "Inv. broj je unikatan(jedinstven) D/N" GET _id_unikat VALID _id_unikat $ "DN" PICT "@!"

   @ m_x + 9, m_y + 2 SAY "Izvjestaji mogu i u drugoj valuti ? (D/N)" GET _druga_valuta VALID _druga_valuta $ "DN" PICT "@!"

   @ m_x + 11, m_y + 2 SAY "Obracun pocinje od (1) odmah / (2) od 1.u narednom mjesecu" GET _metoda VALID _metoda $ "12"

   @ m_x + 15, m_y + 2 SAY "Varijanta 1 - sredstvo rashodovano npr 10.05, "
   @ m_x + 16, m_y + 2 SAY "              obracun se NE vrsi za 05 mjesec"
   @ m_x + 17, m_y + 2 SAY "Varijanta 2 - obracun se vrsi za 05. mjesec  " GET _varijanta  VALID _varijanta $ "12" PICT "@!"
   @ m_x + 19, m_y + 2 SAY "Obracun pocinje od datuma razlicitog od 01.01. tekuce godine (D/N)" GET _obr_pocetak VALID _obr_pocetak $ "DN" PICT "@!"
   @ m_x + 20, m_y + 2 SAY "Obracun pocinje od datuma" GET _obr_pocetak_datum WHEN _obr_pocetak == "D"

   READ

   _pic_iznos := AllTrim( _pic_iznos )

   BoxC()

   IF LastKey() <> K_ESC

      // set sql/db parametri

      set_metric( "os_radna_jedinica", nil, _os_rj )
      gRJ := _os_rj

      set_metric( "os_datum_obrade", my_user(), _dat_obr )
      fin_kam_datum_obracuna( _dat_obr )

      set_metric( "os_prikaz_iznosa", nil, _pic_iznos )
      gPicI := _pic_iznos

      set_metric( "os_metoda_obracuna", nil, _metoda )
      gMetodObr := _metoda

      set_metric( "os_id_broj_je_unikatan", nil, _id_unikat )
      gIBJ := _id_unikat

      set_metric( "os_prikaz_u_dvije_valute", nil, _druga_valuta )
      gDrugaVal := _druga_valuta

      set_metric( "os_varijanta_obracuna", nil, _varijanta )
      gVObracun := _varijanta

      set_metric( "os_pocetak_obracuna", nil, _obr_pocetak )
      gVarDio := _obr_pocetak

      set_metric( "os_pocetak_obracuna_datum", nil, _obr_pocetak_datum )
      gDatDio := _obr_pocetak_datum

   ENDIF

   RETURN
