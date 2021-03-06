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

STATIC s_lUseFiskalneFunkcije := .F.
STATIC s_cFiskalniUredjajModel

FUNCTION fiscal_opt_active()

   LOCAL _opt := fetch_metric( "fiscal_opt_active", my_user(), "N" )

   IF _opt == "N"
      s_lUseFiskalneFunkcije := .F.
   ELSE
      s_lUseFiskalneFunkcije := .T.
   ENDIF

   RETURN s_lUseFiskalneFunkcije



// ---------------------------------------------
// init fiscal params
//
// setuju se init vrijednosti u parametrima:
//
// fiscal_device_01_id, active, name...
// fiscal_device_02_id, active, name...
//
// ---------------------------------------------
FUNCTION set_init_fiscal_params()

   LOCAL _devices := 10
   LOCAL nI
   LOCAL _tmp, _dev_param
   LOCAL _dev_id

   info_bar( "init", "fiscal params" )
   FOR nI := 1 TO _devices

      _dev_id := PadL( AllTrim( Str( nI ) ), 2, "0" )
      _dev_param := "fiscal_device_" + _dev_id
      _tmp := fetch_metric( _dev_param + "_id", NIL, 0  )

      IF _tmp == 0

         set_metric( _dev_param + "_id", NIL, nI )
         set_metric( _dev_param + "_active", NIL, "N" )
         set_metric( _dev_param + "_drv", NIL, "FPRINT" )
         set_metric( _dev_param + "_name", NIL, "Fiskalni uredjaj " + _dev_id )

      ENDIF

   NEXT
   info_bar( "init", "" )

   RETURN .T.




// --------------------------------------------------------------
// vraca naziv fiskalnog uredjaja
// ---------------------------------:-----------------------------
STATIC FUNCTION get_fiscal_device_name( nDeviceId )

   LOCAL _tmp := PadL( AllTrim( Str( nDeviceId ) ), 2, "0" )

   RETURN fetch_metric( "fiscal_device_" + _tmp + "_name", NIL, "" )



FUNCTION fiskalni_parametri_za_korisnika()

   LOCAL nX := 1
   LOCAL _fiscal := fetch_metric( "fiscal_opt_active", my_user(), "N" )
   LOCAL _fiscal_tek := _fiscal
   LOCAL _fiscal_devices := PadR( fetch_metric( "fiscal_opt_usr_devices", my_user(), "" ), 50 )
   LOCAL _pos_def := fetch_metric( "fiscal_opt_usr_pos_default_device", my_user(), 0 )
   LOCAL _rpt_warrning := fetch_metric( "fiscal_opt_usr_daily_warrning", my_user(), "N" )
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL  _izbor := 1
   LOCAL GetList := {}

   _fiscal := Pitanje( , "Koristiti fiskalne funkcije (D/N) ?", _fiscal )
   set_metric( "fiscal_opt_active", my_user(), _fiscal )

   IF _fiscal_tek <> _fiscal
      log_write( "fiskalne funkcije za korisnika " + my_user() + " : " + iif( _fiscal == "D", "aktivirane", "deaktivirane" ), 2 )
   ENDIF

   IF _fiscal ==  "N" .OR. LastKey() == K_ESC
      RETURN .F.
   ENDIF

   fiscal_opt_active()

   AAdd( aOpc, "1. fiskalni uređaji: globalne postavke        " )
   AAdd( aOpcExe, {|| globalne_postavke_fiskalni_uredjaj() } )
   AAdd( aOpc, "2. fiskalni uređaji: korisničke postavke " )
   AAdd( aOpcExe, {|| korisnik_postavke_fiskalni_uredjaj() } )
   AAdd( aOpc, "P. pregled parametara" )
   AAdd( aOpcExe, {|| print_fiscal_params() } )

   f18_menu( "fiscal", .F., _izbor, aOpc, aOpcExe )

   Box( , 6, 75 )
   nX := 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Lista fiskanih uređaja koji se koriste:" GET _fiscal_devices VALID valid_lista_fiskalnih_uredjaja( _fiscal_devices ) PICT "@S30"

   IF f18_use_module( "pos" )
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Primarni fiskalni uređaj kod štampe POS računa:" GET _pos_def VALID valid_pos_fiskalni_uredjaj( _pos_def ) PICT "99"
   ENDIF
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Upozorenje za dnevne izvještaje (D/N)?" GET _rpt_warrning PICT "@!" VALID _rpt_warrning $ "DN"
   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_opt_usr_devices", my_user(), AllTrim( _fiscal_devices ) )
   set_metric( "fiscal_opt_usr_pos_default_device", my_user(), _pos_def )
   set_metric( "fiscal_opt_usr_daily_warrning", my_user(), _rpt_warrning )

   RETURN  ( _fiscal == "D" )



STATIC FUNCTION valid_lista_fiskalnih_uredjaja( cLista )

   IF Empty( cLista )
      MsgBeep( "Ako želite koristiti fiskalne uređaje 1 i 3,#navesti: 1;3" )
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION valid_pos_fiskalni_uredjaj( nUredjaj )

   IF nUredjaj > 0
      RETURN .T.
   ENDIF

   MsgBeep( "Odaberi fiskalni uređaj koji se koristi za POS račune,#npr: 1" )

   RETURN .F.



FUNCTION globalne_postavke_fiskalni_uredjaj()

   LOCAL nDeviceId := 1
   LOCAL _max_id := 10
   LOCAL _min_id := 1
   LOCAL nX := 1
   LOCAL _dev_tmp
   LOCAL _dev_name, _dev_act, _dev_type, _dev_drv
   LOCAL _dev_iosa, _dev_serial, _dev_plu, _dev_pdv, _dev_init_plu
   LOCAL _dev_avans, _dev_timeout, _dev_vp_sum, _dev_vp_no_customer
   LOCAL _dev_restart
   LOCAL GetList := {}

   IF !s_lUseFiskalneFunkcije
      MsgBeep( "Fiskalne opcije moraju biti uključene !" )
      RETURN .F.
   ENDIF

   Box(, 20, 80 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Uređaj ID:" GET nDeviceId PICT "99" ;
      VALID ( nDeviceId >= _min_id .AND. nDeviceId <= _max_id )

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadR( "**** Podešenje uređaja", 60 ) COLOR f18_color_i()

   _dev_tmp := PadL( AllTrim( Str( nDeviceId ) ), 2, "0" )
   _dev_name := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_name", NIL, "" ), 100 )
   _dev_act := fetch_metric( "fiscal_device_" + _dev_tmp + "_active", NIL, "N" )
   _dev_drv := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, "" ), 20 )
   _dev_type := fetch_metric( "fiscal_device_" + _dev_tmp + "_type", NIL, "P" )
   _dev_pdv := fetch_metric( "fiscal_device_" + _dev_tmp + "_pdv", NIL, "D" )
   _dev_iosa := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_iosa", NIL, "1234567890123456" ), 16 )
   _dev_serial := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_serial", NIL, "000000" ), 20 )
   _dev_plu := fetch_metric( "fiscal_device_" + _dev_tmp + "_plu_type", NIL, "D" )
   _dev_init_plu := fetch_metric( "fiscal_device_" + _dev_tmp + "_plu_init", NIL, 10 )
   _dev_avans := fetch_metric( "fiscal_device_" + _dev_tmp + "_auto_avans", NIL, 0 )
   _dev_timeout := fetch_metric( "fiscal_device_" + _dev_tmp + "_time_out", NIL, 300 )
   _dev_vp_sum := fetch_metric( "fiscal_device_" + _dev_tmp + "_vp_sum", NIL, 1 )
   _dev_restart := fetch_metric( "fiscal_device_" + _dev_tmp + "_restart_service", NIL, "N" )
   _dev_vp_no_customer := fetch_metric( "fiscal_device_" + _dev_tmp + "_vp_no_customer", NIL, "N" )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Naziv uređaja:" GET _dev_name   PICT "@S40"
   @ box_x_koord() + nX, Col() + 1 SAY8 "Aktivan (D/N):" GET _dev_act  PICT "@!"  VALID _dev_act $ "DN"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Drajver (FPRINT/HCP/TREMOL/TRING/...):" GET _dev_drv ;
      PICT "@S20"  VALID !Empty( _dev_drv )

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   IF AllTrim( _dev_drv ) == "FPRINT"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "IOSA broj:" GET _dev_iosa ;
         PICT "@S16"  VALID !Empty( _dev_iosa )

      @ box_x_koord() + nX, Col() + 1 SAY "Serijski broj:" GET _dev_serial ;
         PICT "@S20" VALID !Empty( _dev_serial )

   ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Uređaj je u sistemu PDV-a (D/N):" GET _dev_pdv ;
      PICT "@!" VALID _dev_pdv $ "DN"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Tip uređaja (K - kasa, P - printer):" GET _dev_type ;
      PICT "@!" VALID _dev_type $ "KP"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "**** Parametri artikla", 60 ) COLOR f18_color_i()

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Za artikal koristiti plu [D/P] (stat./dinam.) [I] id, [B] barkod:" GET _dev_plu ;
      PICT "@!" VALID _dev_plu $ "DPIB"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "(dinamički) inicijalni PLU kod:" GET _dev_init_plu PICT "999999"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadR( "**** Parametri rada sa uređajem", 60 ) COLOR f18_color_i()

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Auto depozit:" GET _dev_avans PICT "999999.99"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Timeout fiskalnih operacija:" GET _dev_timeout PICT "999"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Zbirni račun u VP (0/1/...):" GET _dev_vp_sum PICT "999"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Bezgotovinski račun moguć bez partnera (D/N) ?" GET _dev_vp_no_customer PICT "!@" VALID _dev_vp_no_customer $ "DN"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Restart servisa nakon slanja komande (D/N) ?" GET _dev_restart ;
      PICT "@!" VALID _dev_restart $ "DN"


   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_device_" + _dev_tmp + "_name", NIL, AllTrim( _dev_name ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_active", NIL, _dev_act )
   set_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, AllTrim( _dev_drv ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_type", NIL, _dev_type )
   set_metric( "fiscal_device_" + _dev_tmp + "_pdv", NIL, _dev_pdv )
   set_metric( "fiscal_device_" + _dev_tmp + "_iosa", NIL, AllTrim( _dev_iosa ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_serial", NIL, AllTrim( _dev_serial ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_plu_type", NIL, _dev_plu )
   set_metric( "fiscal_device_" + _dev_tmp + "_plu_init", NIL, _dev_init_plu )
   set_metric( "fiscal_device_" + _dev_tmp + "_auto_avans", NIL, _dev_avans )
   set_metric( "fiscal_device_" + _dev_tmp + "_time_out", NIL, _dev_timeout )
   set_metric( "fiscal_device_" + _dev_tmp + "_vp_sum", NIL, _dev_vp_sum )
   set_metric( "fiscal_device_" + _dev_tmp + "_restart_service", NIL, _dev_restart )
   set_metric( "fiscal_device_" + _dev_tmp + "_vp_no_customer", NIL, _dev_vp_no_customer )

   RETURN .T.



FUNCTION korisnik_postavke_fiskalni_uredjaj()

   LOCAL _cUserName := my_user()
   LOCAL _user_id := f18_get_user_id( _cUserName )
   LOCAL nDeviceId := 1
   LOCAL _max_id := 10
   LOCAL _min_id := 1
   LOCAL nX := 1
   LOCAL _dev_drv, _dev_tmp
   LOCAL _out_dir, _out_file, _ans_file, _print_a4
   LOCAL _op_id, _op_pwd, _print_fiscal
   LOCAL _op_docs
   LOCAL GetList := {}

   IF !s_lUseFiskalneFunkcije
      MsgBeep( "Fiskalne opcije moraju biti uključene !" )
      RETURN .F.
   ENDIF

   Box(, 20, 80 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Uređaj ID:", 15 ) GET nDeviceId ;
      PICT "99" VALID {|| ( nDeviceId >= _min_id .AND. nDeviceId <= _max_id ), ;
      show_it( get_fiscal_device_name( nDeviceId, 30 ) ), .T. }

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Korisnik:", 15 ) GET _user_id PICT "99999999" ;
      VALID {|| iif( _user_id == 0, choose_f18_user_from_list( @_user_id ), .T. ), ;
      show_it( GetFullUserName( _user_id ), 30 ), .T.  }

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   _cUserName := AllTrim( GetUserName( _user_id ) )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadR( "*** Podešenja rada sa uređajem", 60 ) COLOR f18_color_i()

   ++nX
   _dev_tmp := PadL( AllTrim( Str( nDeviceId ) ), 2, "0" )
   _dev_drv := AllTrim( fetch_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, "" ) )

   _out_dir := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _cUserName, out_dir_op_sys( _dev_drv ) ), 300 )
   _out_file := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_file", _cUserName, out_file_op_sys( _dev_drv ) ), 50 )
   _out_answer := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _cUserName, "" ), 50 )

   _op_id := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_id", _cUserName, "1" ), 10 )
   _op_pwd := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _cUserName, "000000" ), 10 )
   _print_a4 := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _cUserName, "N" )
   _print_fiscal := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _cUserName, "D" )
   _op_docs := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _cUserName, "" ), 100 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Direktorij izlaznih fajlova:" GET _out_dir PICT "@S50" VALID _valid_fiscal_path( _out_dir )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "       Naziv izlaznog fajla:" GET _out_file PICT "@S20" VALID !Empty( _out_file )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "       Naziv fajla odgovora:" GET _out_answer PICT "@S20"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Operater, ID:" GET _op_id PICT "@S10"
   @ box_x_koord() + nX, Col() + 1 SAY "lozinka:" GET _op_pwd PICT "@S10"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Štampati A4 racun nakon fiskalnog (D/N/G/X):" GET _print_a4 PICT "@!" VALID _print_a4 $ "DNGX"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Uredjaj koristiti za slj.tipove dokumenata:" GET _op_docs PICT "@S20"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Korisnik može printati fiskalne račune (D/N/T):" GET _print_fiscal PICT "@!" VALID _print_fiscal $ "DNT"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _cUserName, AllTrim( _out_dir ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_out_file", _cUserName, AllTrim( _out_file ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _cUserName, AllTrim( _out_answer ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_id", _cUserName, AllTrim( _op_id ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _cUserName, AllTrim( _op_pwd ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _cUserName, _print_a4 )
   set_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _cUserName, _print_fiscal )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _cUserName, AllTrim( _op_docs ) )

   RETURN .T.




// ---------------------------------------------------------------------
// izlazni direktorij za fiskalne funkcije
// ---------------------------------------------------------------------
STATIC FUNCTION out_dir_op_sys( dev_type )

   LOCAL _path := ""

   DO CASE

   CASE dev_type == "FPRINT" .OR. dev_type == "TREMOL"

#ifdef __PLATFORM__WINDOWS
      _path := "C:" + SLASH + "fiscal" + SLASH
#else
      _path := SLASH + "home" + SLASH + "bringout" + SLASH + "fiscal" + SLASH
#endif

   CASE dev_type == "HCP"

#ifdef __PLATFORM__WINDOWS
      _path := "C:" + SLASH + "HCP" + SLASH
#else
      _path := SLASH + "home" + SLASH + "bringout" + SLASH + "HCP" + SLASH
#endif

   ENDCASE

   RETURN _path


// ---------------------------------------------------------------------
// izlazni fajl za fiskalne opcije
// ---------------------------------------------------------------------
STATIC FUNCTION out_file_op_sys( dev_type )

   LOCAL _file := ""

   DO CASE
   CASE dev_type == "FPRINT"
      _file := "out.txt"
   CASE dev_type == "HCP"
      _file := "TR$_01.XML"
   CASE dev_type == "TREMOL"
      _file := "01.xml"
   ENDCASE

   RETURN _file




// -------------------------------------------------------
// validacija path-a izlaznih fajlova
// -------------------------------------------------------
STATIC FUNCTION _valid_fiscal_path( cFiscalPath, lCreateDir )

   LOCAL _ok := .T.
   LOCAL nMakeDir

   IF lCreateDir == NIL
      lCreateDir := .T.
   ENDIF

   cFiscalPath := AllTrim( cFiscalPath )

   IF Empty( cFiscalPath )
      MsgBeep( "Izlazni direktorij za fiskalne fajlove ne smije biti prazan ?!!!" )
      _ok := .F.
      RETURN _ok
   ENDIF

   IF DirChange( cFiscalPath ) != 0
      IF lCreateDir
         nMakeDir := MakeDir( cFiscalPath )
         IF nMakeDir != 0
            MsgBeep( "Kreiranje " + cFiscalPath + " neuspjesno ?!#Provjerite putanju direktorija izlaznih fajlova." )
            _ok := .F.
         ENDIF
      ELSE
         MsgBeep( "Izlazni direktorij: " + cFiscalPath + "#ne postoji !!!" )
         _ok := .F.
      ENDIF
   ENDIF

   RETURN _ok




/*
    Odabir fiskalnog uređaja

    - Ako ih ima više od 1 - korisniku se prikazuje meni
    - Ako je za korisnika definisan jedan uređaj bez menija

    Korištenje:

    odaberi_fiskalni_uredjaj( "10" ) // FAKT, uređaji koje korisnik upotrebljava za VP račune
    odaberi_fiskalni_uredjaj( "11" ) // FAKT, MP računi

    odaberi_fiskalni_uredjaj( NIL, .T. ) // POS modul

    Parametri:

       lSilent - .T. default, ne prikazuj poruke o grešci

    Return (nDevice):

       0 - nema fiskalnog uređaja
       3 - fiskalni uređaj 3
*/

FUNCTION odaberi_fiskalni_uredjaj( cIdTipDok, lFromPos, lSilent )

   LOCAL nDeviceId := 0
   LOCAL _dev_arr
   LOCAL _pos_default
   LOCAL  cUser := my_user()

   IF !s_lUseFiskalneFunkcije
      RETURN NIL
   ENDIF

   IF lFromPos == NIL
      lFromPos := .F.
   ENDIF

   IF lSilent == NIL
      lSilent := .T.
   ENDIF

   IF cIdTipDok == NIL
      cIdTipDok := ""
   ENDIF

   _dev_arr := get_fiscal_devices_list( cUser, cIdTipDok )

   IF Len( _dev_arr ) == 0 .AND. !lSilent
      MsgBeep( "Nema podešenih fiskanih uređaja,#Fiskalne funkcije onemogućene." )
      RETURN 0
   ENDIF

   IF lFromPos
      _pos_default := fetch_metric( "fiscal_opt_usr_pos_default_device", cUser, 0 )
      IF _pos_default > 0
         RETURN _pos_default
      ENDIF
   ENDIF

   IF Len( _dev_arr ) > 1
      nDeviceId := fiskalni_uredjaji_meni( _dev_arr )
   ELSE
      nDeviceId := _dev_arr[ 1, 1 ]
   ENDIF

   RETURN nDeviceId



// -----------------------------------------------------
// vraca listu fiskalnih uredjaja kroz matricu
// -----------------------------------------------------
FUNCTION get_fiscal_devices_list( cUser, cTipDok )

   LOCAL _arr := {}
   LOCAL nI
   LOCAL _dev_max := 10
   LOCAL _dev_tmp
   LOCAL _usr_dev_list := ""
   LOCAL _dev_docs_list := ""

   IF cUser == NIL
      cUser := my_user()
   ENDIF

   IF cTipDok == NIL
      cTipDok := ""
   ENDIF

   _usr_dev_list := fetch_metric( "fiscal_opt_usr_devices", cUser, "" )

   FOR nI := 1 TO _dev_max

      _dev_tmp := PadL( AllTrim( Str( nI ) ), 2, "0" )

      _dev_id := fetch_metric( "fiscal_device_" + _dev_tmp + "_id", NIL, 0 )

      _dev_docs_list := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", my_user(), "" )

      IF ( _dev_id <> 0 ) ;
            .AND. ( fetch_metric( "fiscal_device_" + _dev_tmp + "_active", NIL, "N" ) == "D" ) ;
            .AND. IF( !Empty( _usr_dev_list ), AllTrim( Str( _dev_id ) ) + "," $ _usr_dev_list + ",", .T. ) ;
            .AND. IF( !Empty( _dev_docs_list ) .AND. !Empty( AllTrim( cTipDok ) ), cTipDok $ _dev_docs_list, .T. )

         AAdd( _arr, { _dev_id, fetch_metric( "fiscal_device_" + _dev_tmp + "_name", NIL, "" ), ;
            fetch_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, "" ) } )

      ENDIF

   NEXT

   RETURN _arr

/*
   opis: vraća model definisanih uređaja

   usage: fiskalni_uredjaj_model() => "FPRINT"

     return:

       - model uređaja, npr FPRINT, TREMOL itd...
       - ukoliko se koristi više vrsta uređaja vraća "MIX"
*/

FUNCTION fiskalni_uredjaj_model()

   LOCAL cModel := ""
   LOCAL aDevices := get_fiscal_devices_list()
   LOCAL nI

   IF s_cFiskalniUredjajModel != NIL
      RETURN s_cFiskalniUredjajModel
   ENDIF

   FOR nI := 1 TO Len( aDevices )
      IF aDevices[ nI, 3 ] <> cModel .AND. nI > 1
         cModel := "MIX"
         EXIT
      ENDIF
      cModel := aDevices[ nI, 3 ]
   NEXT

   s_cFiskalniUredjajModel := cModel

   RETURN cModel



STATIC FUNCTION fiskalni_uredjaji_meni( aOpcije )

   LOCAL nRet := 0
   LOCAL nI, _n
   LOCAL _tmp
   LOCAL _izbor := 1
   LOCAL aOpc := {}
   LOCAL _opcexe := {}
   LOCAL _m_x := box_x_koord()
   LOCAL _m_y := box_y_koord()

   FOR nI := 1 TO Len( aOpcije )

      _tmp := ""
      _tmp += PadL( AllTrim( Str( nI ) ) + ")", 3 )
      _tmp += " uredjaj " + PadL( AllTrim( Str( aOpcije[ nI, 1 ] ) ), 2, "0" )
      _tmp += " : " + PadR( hb_StrToUTF8( aOpcije[ nI, 2 ] ), 40 )

      AAdd( aOpc, _tmp )
      AAdd( _opcexe, {|| "" } )

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      _izbor := meni_0( "choice", aOpc, _izbor, .F. )
      IF _izbor == 0
         EXIT
      ELSE
         nRet := aOpcije[ _izbor, 1 ]
         _izbor := 0
      ENDIF
   ENDDO

   box_x_koord( _m_x )
   box_y_koord(  _m_y )

   RETURN nRet




// --------------------------------------------------------------
// vraca hash matricu sa postavkama fiskalnog uredjaja
// --------------------------------------------------------------
FUNCTION get_fiscal_device_params( nDeviceId, cUserName )

   LOCAL _param := hb_Hash()
   LOCAL _dev_tmp
   LOCAL _dev_param
   LOCAL _cUserName := my_user()
   LOCAL _out_dir

   IF !s_lUseFiskalneFunkcije
      RETURN NIL
   ENDIF

   _dev_tmp := PadL( AllTrim( Str( nDeviceId ) ), 2, "0" )

   IF cUserName <> NIL
      _cUserName := cUserName
   ENDIF

   _dev_param := "fiscal_device_" + _dev_tmp

   _dev_id := fetch_metric( _dev_param + "_id", NIL, 0 )

   IF _dev_id == 0
      RETURN NIL
   ENDIF

   _param[ "id" ] := _dev_id
   _param[ "name" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_name", NIL, "" )
   _param[ "active" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_active", NIL, "" )
   _param[ "drv" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, "" )
   _param[ "type" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_type", NIL, "P" )
   _param[ "pdv" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_pdv", NIL, "D" )
   _param[ "iosa" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_iosa", NIL, "" )
   _param[ "serial" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_serial", NIL, "" )
   _param[ "plu_type" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_plu_type", NIL, "D" )
   _param[ "plu_init" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_plu_init", NIL, 10 )
   _param[ "auto_avans" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_auto_avans", NIL, 0 )
   _param[ "timeout" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_time_out", NIL, 300 )
   _param[ "vp_sum" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_vp_sum", NIL, 1 )
   _param[ "vp_no_customer" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_vp_no_customer", NIL, "N" )
   _param[ "restart_service" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_restart_service", NIL, "N" )

#ifdef TEST
   _out_dir := "/tmp/"
#else
   _out_dir := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _cUserName, "" )
#endif

   IF Empty( _out_dir )
      RETURN NIL
   ENDIF

#ifdef TEST
   _param[ "out_dir" ]  := "/tmp/"
   _param[ "out_file" ] := "fiscal.txt"
   _param[ "out_answer" ] := "answer.txt"
   _param[ "op_id" ] := "01"
   _param[ "op_pwd" ] := "00"
   _param[ "print_a4" ] := "N"
   _param[ "print_fiscal" ] := "T"
   _param[ "op_docs" ] := ""
#else
   _param[ "out_dir" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _cUserName, "" )
   _param[ "out_file" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_file", _cUserName, "" )
   _param[ "out_answer" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _cUserName, "" )
   _param[ "op_id" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_id", _cUserName, "" )
   _param[ "op_pwd" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _cUserName, "" )
   _param[ "print_a4" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _cUserName, "N" )
   _param[ "print_fiscal" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _cUserName, "D" )
   _param[ "op_docs" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _cUserName, "" )
#endif

   IF !post_check( _param )
      RETURN NIL
   ENDIF

   RETURN _param


// ---------------------------------------------------------------
// chekiranje nakon setovanja, da li ima lokacije itd...
// ---------------------------------------------------------------
STATIC FUNCTION post_check( hParams )

   LOCAL lRet := .T.

   lRet := _valid_fiscal_path( hParams[ "out_dir" ], .F. )

   IF !lRet
      MsgBeep( "Izlazni direktorij " + AllTrim( hParams[ "out_dir" ] ) + " nije ispravan !!!#Prekidam operaciju!" )
      RETURN lRet
   ENDIF

   IF Empty( hParams[ "out_file" ] )
      MsgBeep( "Naziv izlaznog fajla mora biti popunjen ispravno !!!" )
      lRet := .F.
      RETURN lRet
   ENDIF

   RETURN lRet




// ----------------------------------------------------------
// prikazi fiskalne parametre
// ----------------------------------------------------------
FUNCTION print_fiscal_params()

   LOCAL _dev_arr
   LOCAL _usr_count, _dev_param
   LOCAL _user := my_user()
   LOCAL _usr_cnt, _user_id, _cUserName
   LOCAL _dev_cnt, _dev_id, _dev_name, _dev_act

   IF !s_lUseFiskalneFunkcije
      MsgBeep( "Fiskalne opcije moraju biti ukljucene !!!" )
      RETURN .F.
   ENDIF

   _usr_arr := get_list_f18_users()

   START PRINT CRET
   ?
   ? "Prikaz fiskalnih parametara:"
   ?

   FOR _usr_cnt := 1 TO Len( _usr_arr )

      _user_id := _usr_arr[ _usr_cnt, 1 ]
      _cUserName := _usr_arr[ _usr_cnt, 2 ]

      _dev_arr := get_fiscal_devices_list( _cUserName )

      ?
      ? "Korisnik:", AllTrim( Str( _user_id ) ), "-", GetFullUserName( _user_id )
      ? Replicate( "=", 80 )

      FOR _dev_cnt := 1 TO Len( _dev_arr )

         _dev_id := _dev_arr[ _dev_cnt, 1 ]
         _dev_name := _dev_arr[ _dev_cnt, 2 ]

         ? Space( 3 ), Replicate( "-", 70 )
         ? Space( 3 ), "Uredjaj id:", AllTrim( Str( _dev_id ) ), "-", _dev_name
         ? Space( 3 ), Replicate( "-", 70 )

         _dev_param := get_fiscal_device_params( _dev_id, _cUserName )

         IF _dev_param == NIL
            ? Space( 3 ), "nema podesenih parametara !!!"
         ELSE
            _print_param( _dev_param )
         ENDIF

      NEXT

   NEXT

   FF
   ENDPRINT

   RETURN .T.



// ------------------------------------------------------
// printanje parametra
// ------------------------------------------------------
STATIC FUNCTION _print_param( hParams )

   ? Space( 3 ), "Drajver:", hParams[ "drv" ], "IOSA:", hParams[ "iosa" ], "Serijski broj:", hParams[ "serial" ], "Tip uredjaja:", hParams[ "type" ]
   ? Space( 3 ), "U sistemu PDV-a:", hParams[ "pdv" ]
   ?
   ? Space( 3 ), "Izlazni direktorij:", AllTrim( hParams[ "out_dir" ] )
   ? Space( 3 ), "       naziv fajla:", AllTrim( hParams[ "out_file" ] ), "naziv fajla odgovora:", AllTrim( hParams[ "out_answer" ] )
   ? Space( 3 ), "Operater ID:", hParams[ "op_id" ], "PWD:", hParams[ "op_pwd" ]
   ?
   ? Space( 3 ), "Tip PLU kodova:", hParams[ "plu_type" ], "Inicijalni PLU:", AllTrim( Str( hParams[ "plu_init" ] ) )
   ? Space( 3 ), "Auto polog:", AllTrim( Str( hParams[ "auto_avans" ], 12, 2 ) ), ;
      "Timeout fiskalnih operacija:", AllTrim( Str( hParams[ "timeout" ] ) )
   ?
   ?U Space( 3 ), "A4 print:", hParams[ "print_a4" ], " dokumenti za štampu:", hParams[ "op_docs" ]
   ?U Space( 3 ), "Zbirni bezgotovinski račun:", AllTrim( Str( hParams[ "vp_sum" ] ) )
   ?U Space( 3 ), "Bezgotovinski račun moguć bez partnera:", hParams[ "vp_no_customer" ]

   RETURN
