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

STATIC s_oBrowse
STATIC s_cRobaDuzinaSifre

MEMVAR gIdPos, gPosSamoProdaja, gIdRadnik
MEMVAR Kol, ImeKol, Ch
MEMVAR _IdPos, _IdVd, _IdRadnik, _idpartner, _BrDok, _IdRoba, _BrFaktP, _Opis, _Datum, _kolicina, _cijena, _ncijena
MEMVAR _robanaz, _idtarifa, _jmj, _barkod, _dat_od, _dat_do

FUNCTION pos_zaduzenje( cIdVd )

   LOCAL GetList := {}
   LOCAL lAzuriratiBezStampeSilent := .F.
   LOCAL hParams
   LOCAL nNovaCijena
   LOCAL nI

   IF gPosSamoProdaja == "D"
      MsgBeep( "Ne možete vršiti unos zaduženja !" )
      RETURN .F.
   ENDIF
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   ImeKol := {}
   AAdd( ImeKol, { _u( "Šifra" ),    {|| priprz->idroba },      "idroba" } )
   IF cIdVd != POS_IDVD_ZAHTJEV_SNIZENJE
      AAdd( ImeKol, { "Partner", {|| priprz->idPartner }, "idPartner" } )
   ENDIF
   AAdd( ImeKol, { "Naziv",    {|| priprz->RobaNaz  },   "robaNaz" } )
   AAdd( ImeKol,  { "JMJ",      {|| priprz->JMJ },         "jmj"       } )
   AAdd( ImeKol, { _u( "Količina" ), {|| priprz->kolicina   }, "kolicina"  } )
   AAdd( ImeKol,  { "Cijena",   {|| priprz->Cijena },      "cijena"    } )
   IF cIdVd == POS_IDVD_ZAHTJEV_SNIZENJE
      AAdd( ImeKol,  { _u( "Sniženje" ),   {|| priprz->ncijena },      "ncijena"    } )
   ENDIF
   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   s_cRobaDuzinaSifre := "13"
   o_pos_tables()

   SELECT PRIPRZ
   Scatter()
   _IdPos := gIdPos
   _IdVd := cIdVd
   _BrDok := POS_BRDOK_PRIPREMA
   _IdRadnik := gIdRadnik
   IF Empty( _datum )
      _Datum := danasnji_datum()
   ENDIF

   Box( "#" + cIdVd + "-" + pos_dokument_naziv( cIdVd ), 8, f18_max_cols() - 15 )
   SET CURSOR ON
   IF cIdVd == "81"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY " Partner:" GET _idPartner PICT "@!" VALID  !Empty( _idPartner ) .AND. p_partner( @_idPartner )
      @ box_x_koord() + 2, Col() + 2 SAY "Broj fakture:" GET _BrFaktP VALID !Empty( _brFaktP )
   ENDIF
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "    Opis:" GET _Opis PICTURE "@S50"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY " Datum dok:" GET _Datum PICT "@D" VALID _Datum <= Date()
   IF cIdVd == "89"
      @ Row(), Col() + 2 SAY "Datumski interval od:" GET _dat_od
      @ Row(), Col() + 2 SAY "do:" GET _dat_do VALID Empty( _dat_do ) .OR. _dat_do >= _dat_od
   ENDIF
   READ
   ESC_BCR
   BoxC()

   my_rlock()
   Gather()
   my_unlock()

   SELECT PRIPRZ
   SET ORDER TO
   GO  TOP
   BOX (, f18_max_rows() - 12, f18_max_cols() - 10 - 1,, { _u( "<*> - Ispravka stavke " ), _u( "Storno - negativna količina" ) } )
   @ box_x_koord(), box_y_koord() + 4 SAY8 PadC( "PRIPREMA " + pos_dokument_naziv( cIdVd ) ) COLOR f18_color_invert()

   s_oBrowse := pos_form_browse( box_x_koord() + 6, box_y_koord() + 1, box_x_koord() + f18_max_rows() - 12, box_y_koord() + f18_max_cols() - 10, ImeKol, Kol, ;
      { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), hb_UTF8ToStrBox( BROWSE_PODVUCI ), hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )
   s_oBrowse:autolite := .F.


   SET CURSOR ON
   DO WHILE .T.

      DO WHILE !s_oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

      _idroba := Space ( Len ( _idroba ) )
      _Kolicina := 0
      _cijena := 0
      _ncijena := 0
      nNovaCijena := 0

      @ box_x_koord() + 2, box_y_koord() + 25 SAY Space( 50 )
      @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT "@!S" + s_cRobaDuzinaSifre ;
         WHEN {|| pos_set_key_handler_ispravka_zaduzenja(), _idroba := PadR( _idroba, Val( s_cRobaDuzinaSifre ) ), .T. } ;
         VALID pos_valid_roba_zaduzenje( @_IdRoba, 2, 35 )
      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _Kolicina PICT "999999.999" ;
         WHEN{|| ShowGets(), .T. } VALID pos_zaduzenje_valid_kolicina( _Kolicina )

      IF cIdvd == POS_IDVD_ZAHTJEV_SNIZENJE
         @ box_x_koord() + 4, box_y_koord() + 35 SAY "MPC SA PDV:" GET _cijena  PICT "99999.999" ;
            WHEN {|| .F. } VALID {|| .T. }
         @  Row(), Col() + 2 SAY "Nova cijena:" GET nNovaCijena  PICT "99999.999" ;
            WHEN pos_when_89_ncijena( @nNovaCijena, @_cijena, @_ncijena ) VALID  pos_valid_89_ncijena( @nNovaCijena, @_cijena, @_ncijena )
      ELSE
         @ box_x_koord() + 4, box_y_koord() + 35 SAY "MPC SA PDV:" GET _cijena  PICT "99999.999" ;
            WHEN {|| .F. } VALID {|| .T. }
      ENDIF
      READ

      IF ( LastKey() == K_ESC )
         EXIT
      ENDIF

      // StUSif()
      SELECT PRIPRZ
      APPEND BLANK
      select_o_roba( _idRoba )
      _robanaz := roba->naz
      _jmj := roba->jmj
      _idtarifa := roba->idtarifa
      _cijena := iif( Empty( _cijena ), pos_get_mpc(), _cijena )
      _barkod := roba->barkod

      SELECT priprz
      my_rlock()
      Gather()
      my_unlock()
      s_oBrowse:goBottom()
      s_oBrowse:refreshAll()
      s_oBrowse:dehilite()

   ENDDO

   pos_unset_key_handler_ispravka_zaduzenja()
   BoxC()

   IF Pitanje(, "Unos završen ?", " ") == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   SELECT PRIPRZ
   IF RecCount2() > 0
      SELECT PRIPRZ
      GO TOP
      hParams := hb_Hash()
      hParams[ "idpos" ] := priprz->idpos
      hParams[ "datum" ] := priprz->datum
      hParams[ "idvd" ] := priprz->idvd
      hParams[ "brdok" ] := priprz->brdok
      hParams[ "idradnik" ] := priprz->idradnik
      hParams[ "idpartner" ] := priprz->idpartner
      hParams[ "opis" ] := hb_StrToUTF8( priprz->opis )
      hParams[ "brfaktp" ] := priprz->brfaktp
      hParams[ "priprema" ] := .T.

      Beep( 4 )
      // IF !lAzuriratiBezStampeSilent .AND. Pitanje(, "Želite li odštampati dokument (D/N) ?", "N" ) == "D"
      pos_stampa_zaduzenja( hParams )
      o_pos_tables()
      // ENDIF

      IF lAzuriratiBezStampeSilent .OR. Pitanje(, "Želite li " + hParams[ "idpos" ] + "-" + hParams[ "idvd" ] + "-" + AllTrim( hParams[ "brdok" ] ) + " ažurirati (D/N) ?", " " ) == "D"
         hParams[ "brdok" ] := pos_novi_broj_dokumenta( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ] )
         hParams[ "opis" ] := hb_UTF8ToStr( hParams[ "opis" ] )
         pos_azuriraj_zaduzenje( hParams )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_valid_roba_zaduzenje( cIdRoba, nX, nY )

   LOCAL lOk

   lOk := pos_postoji_roba( @cIdroba, nX, nY )
   cIdroba := PadR( cIdroba, Val( s_cRobaDuzinaSifre ) )

   RETURN lOk .AND. pos_zaduzenje_provjeri_duple_stavke( cIdroba )


STATIC FUNCTION pos_set_key_handler_ispravka_zaduzenja()

   SetKey( Asc( "*" ), NIL )
   SetKey( Asc( "*" ), {|| pos_ispravi_zaduzenje() } )

   RETURN .T.


FUNCTION pos_unset_key_handler_ispravka_zaduzenja()

   SetKey( Asc( "*" ), NIL )

   RETURN .F.


FUNCTION pos_zaduzenje_valid_kolicina( nKol )

   IF LastKey() = K_UP
      RETURN .T.
   ENDIF
   IF nKol = 0
      MsgBeep( "Količina mora biti različita od nule!#Ponovite unos!", 20 )
      RETURN ( .F. )
   ENDIF

   RETURN ( .T. )


FUNCTION pos_zaduzenje_provjeri_duple_stavke( cSif )

   LOCAL lFlag := .T.
   LOCAL nPrevRec

   SELECT PRIPRZ
   SET ORDER TO TAG "1"
   nPrevRec := RecNo()
   SEEK cSif
   IF Found()
      MsgBeep( "Na zaduženju se vec nalazi isti artikal!#" + "U slučaju potrebe ispravite stavku zaduženja!", 20 )
      lFlag := .F.
   ENDIF
   SET ORDER TO
   GO ( nPrevRec )

   RETURN ( lFlag )


FUNCTION pos_ispravi_zaduzenje()

   LOCAL cGetId
   LOCAL nGetKol
   LOCAL aConds
   LOCAL aProcs
   LOCAL cColor

   pos_unset_key_handler_ispravka_zaduzenja()

   cGetId := _idroba
   nGetKol := _Kolicina
   cColor := SetColor()
   prikaz_dostupnih_opcija_crno_na_zuto( { "<Enter>-Ispravi stavku", "<B>-Brisi stavku", "<Esc>-Kraj ispravke" } )
   SetColor( cColor )

   s_oBrowse:autolite := .T.
   s_oBrowse:configure()
   aConds := { {| Ch | Ch == Asc ( "b" ) .OR. Ch == Asc ( "B" ) }, {| Ch | Ch == K_ENTER } }
   aProcs := { {|| pos_brisi_stavku_zaduzenja() }, {|| pos_ispravi_stavku_zaduzenja() } }
   ShowBrowse( s_oBrowse, aConds, aProcs )
   s_oBrowse:autolite := .F.
   s_oBrowse:dehilite()
   s_oBrowse:stabilize()

   _idroba := cGetId
   _Kolicina := nGetKol

   pos_set_key_handler_ispravka_zaduzenja()

   RETURN .T.


FUNCTION pos_brisi_stavku_zaduzenja()

   SELECT PRIPRZ
   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Brisanje nije moguće!", 20 )
      RETURN ( DE_CONT )
   ENDIF
   Beep( 2 )
   my_delete_with_pack()
   s_oBrowse:refreshAll()

   RETURN ( DE_CONT )


FUNCTION pos_ispravi_stavku_zaduzenja()

   LOCAL cIdRobaPredhodna
   LOCAL GetList := {}

   IF RecCount2() == 0
      MsgBeep( "Zaduženje nema nijednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   cIdRobaPredhodna := _IdRoba := PRIPRZ->idroba
   _Kolicina := PRIPRZ->Kolicina
   Box(, 3, 80 )
   @ box_x_koord() + 1, box_y_koord() + 3 SAY8 "Artikal:" GET _idroba PICTURE "@K" VALID pos_valid_roba_zaduzenje( @_IdRoba, 1, 30 )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "Količina:" GET _Kolicina VALID pos_zaduzenje_valid_kolicina ( _Kolicina )
   READ

   IF LastKey() <> K_ESC
      my_rlock()
      IF _idroba <> cIdRobaPredhodna
         REPLACE RobaNaz WITH roba->Naz, Jmj WITH roba->Jmj, Cijena WITH roba->Cijena, IdRoba WITH _IdRoba
      ENDIF
      REPLACE Kolicina WITH _Kolicina
      my_unlock()
   ENDIF

   BoxC()
   s_oBrowse:refreshCurrent()

   RETURN ( DE_CONT )
