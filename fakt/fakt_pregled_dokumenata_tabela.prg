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


#include "fakt.ch"
#include "f18_separator.ch"



// -------------------------------------------------------------------------
// -------------------------------------------------------------------------
FUNCTION fakt_lista_dokumenata_tabelarni_pregled( lVrsteP, lOpcine, cFilter )

   LOCAL i
   LOCAL _w1 := 30
   LOCAL _x, _y
   LOCAL _params := fakt_params()
   LOCAL _model := fiskalni_uredjaj_model()

   ImeKol := {}

   AAdd( ImeKol, { " ",            {|| g_fiscal_info( _model ) } } )
   AAdd( ImeKol, { "RJ",           {|| idfirma }  } )
   AAdd( ImeKol, { "VD",           {|| idtipdok } } )
   AAdd( ImeKol, { "Brdok",        {|| brdok + rezerv } } )
   AAdd( ImeKol, { "VP",           {|| idvrstep } } )
   AAdd( ImeKol, { "Datum",        {|| Datdok } } )
   AAdd( ImeKol, { "Partner",  {|| PadR( partner, 45 ) } } )
   AAdd( ImeKol, { "Ukupno",  {|| iznos + rabat } } )
   AAdd( ImeKol, { "Rabat",  {|| rabat } } )
   AAdd( ImeKol, { "Ukupno-Rab ",  {|| iznos } } )

   IF lVrsteP
      AAdd( ImeKol, { "Nacin placanja", {|| idvrstep } } )
   ENDIF

   // datum otpremnice datum valute
   AAdd( ImeKol, { "Datum placanja", {|| datpl } } )
   AAdd( ImeKol, { "Dat.otpr",       {|| dat_otpr } } )
   AAdd( ImeKol, { "Dat.val.",       {|| dat_val } } )

   AAdd( ImeKol, { "Fisk.rn",        {|| PadR( sh_fiscal_rn( fisc_rn, fisc_st ), 20 ) } } )
   AAdd( ImeKol, { "Fisk.vr",        {|| PadR( DToC( fisc_date ) + " " + AllTrim( fisc_time ), 20 ) } } )

   // prikaz operatera
   AAdd( ImeKol, { "Operater",       {|| GetUserName( oper_id ) } } )

   // veza sa dokumentima
   IF _params[ "fakt_dok_veze" ]
      AAdd( ImeKol, { "Vezni dokumenti", {|| PadR( get_fakt_vezni_dokumenti( idfirma, idtipdok, brdok ), 50 ) } } )
   ENDIF

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   _x := MAXROWS() - 4
   _y := MAXCOLS() - 3

   Box( , _x, _y )

   @ m_x + _x - 4, m_y + 2 SAY PadR( " <ENTER> Stampa TXT", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < P > Povrat dokumenta", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < I > Informacije", _w1 )
   @ m_x + _x - 3, m_y + 2 SAY PadR( " < a+P > Stampa ODT", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < S > Storno dokument", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < c+V > Setuj vezu fisk.", _w1 )
   @ m_x + _x - 2, m_y + 2 SAY PadR( " < R > Stampa fisk.racuna", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < F > ponuda->racun", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < F5 > Refresh ", _w1 )
   @ m_x + _x - 1, m_y + 2 SAY PadR( " < W > Dupliciraj", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < K > Ispravka podataka", _w1 ) + ;
      BROWSE_COL_SEP + PadR( " < T > Duplikat fiskalnog rn.", _w1 )

   fUPripremu := .F.

   adImeKol := {}

   PRIVATE  bGoreRed := NIL
   PRIVATE  bDoleRed := NIL
   PRIVATE  bDodajRed := NIL
   PRIVATE  fTBNoviRed := .F. // trenutno smo u novom redu ?
   PRIVATE  TBCanClose := .T. // da li se moze zavrsiti unos podataka ?
   PRIVATE  TBAppend := "N"  // mogu dodavati slogove
   PRIVATE  bZaglavlje := NIL
   // zaglavlje se edituje kada je kursor u prvoj koloni
   // prvog reda
   PRIVATE  TBSkipBlock := {| nSkip| SkipDB( nSkip, @nTBLine ) }
   PRIVATE  nTBLine := 1      // tekuca linija-kod viselinijskog browsa
   PRIVATE  nTBLastLine := 1  // broj linija kod viselinijskog browsa
   PRIVATE  TBPomjerise := "" // ako je ">2" pomjeri se lijevo dva
   // ovo se mo§e setovati u when/valid fjama

   PRIVATE  TBScatter := "N"  // uzmi samo tekuce polje

   FOR i := 1 TO Len( ImeKol )
      AAdd( adImeKol, ImeKol[ i ] )
   NEXT

   ASize( adImeKol, Len( adImeKol ) + 1 )
   AIns( adImeKol, 6 )
   adImeKol[ 6 ] := { "ID PARTNER", {|| idpartner }, "idpartner", {|| .T. }, {|| P_Firma( @widpartner ) }, "V" }

   adKol := {}
   FOR i := 1 TO Len( adImeKol )
      AAdd( adKol, i )
   NEXT

   ObjDbedit( "", _x - 3, _y, {|| fakt_tabela_komande ( lOpcine, cFilter ) }, "", "", , , , , 2 )
   BoxC()

   IF fUpripremu
      my_close_all_dbf()
      fakt_unos_dokumenta()
   ENDIF

   my_close_all_dbf()

   RETURN


STATIC FUNCTION g_fiscal_info( model )

   LOCAL cInfo := " "

   IF !postoji_fiskalni_racun( fakt_doks->idfirma, fakt_doks->idtipdok, fakt_doks->brdok, model ) 
      cInfo := " "
   ELSE
      cInfo := "F"
   ENDIF

   RETURN cInfo



STATIC FUNCTION sh_fiscal_rn( _f_rn, _s_rn )

   LOCAL _txt := ""

   _txt += AllTrim( Str( _f_rn ) )

   IF _s_rn > 0
      _txt += " / "
      _txt += AllTrim( Str( _s_rn ) )
   ENDIF

   RETURN _txt
