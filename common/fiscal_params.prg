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


#include "fmk.ch"

STATIC __use_fiscal_opt := .F.


FUNCTION fiscal_opt_active()

   LOCAL _opt := fetch_metric( "fiscal_opt_active", my_user(), "N" )

   IF _opt == "N"
      __use_fiscal_opt := .F.
   ELSE
      __use_fiscal_opt := .T.
   ENDIF

   RETURN __use_fiscal_opt



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
   LOCAL _i
   LOCAL _tmp, _dev_param
   LOCAL _dev_id

   FOR _i := 1 TO _devices

      _dev_id := PadL( AllTrim( Str( _i ) ), 2, "0" )
      _dev_param := "fiscal_device_" + _dev_id
      _tmp := fetch_metric( _dev_param + "_id", NIL, 0  )

      IF _tmp == 0

         set_metric( _dev_param + "_id", NIL, _i )
         set_metric( _dev_param + "_active", NIL, "N" )
         set_metric( _dev_param + "_drv", NIL, "FPRINT" )
         set_metric( _dev_param + "_name", NIL, "Fiskalni uredjaj " + _dev_id )

      ENDIF

   NEXT

   RETURN .T.




// --------------------------------------------------------------
// vraca naziv fiskalnog uredjaja
// ---------------------------------:-----------------------------
STATIC FUNCTION get_fiscal_device_name( device_id )

   LOCAL _tmp := PadL( AllTrim( Str( device_id ) ), 2, "0" )

   RETURN fetch_metric( "fiscal_device_" + _tmp + "_name", NIL, "" )



FUNCTION fiskalni_parametri_za_korisnika()

   LOCAL _x := 1
   LOCAL _fiscal := fetch_metric( "fiscal_opt_active", my_user(), "N" )
   LOCAL _fiscal_devices := PadR( fetch_metric( "fiscal_opt_usr_devices", my_user(), "" ), 50 )
   LOCAL _pos_def := fetch_metric( "fiscal_opt_usr_pos_default_device", my_user(), 0 )
   LOCAL _rpt_warrning := fetch_metric( "fiscal_opt_usr_daily_warrning", my_user(), "N" )
   LOCAL _opc := {}
   LOCAL _opc_exe := {}
   LOCAL  _izbor := 1

   _fiscal := Pitanje( , "Koristiti fiskalne funkcije ?" , _fiscal )
   set_metric( "fiscal_opt_active", my_user(), _fiscal )

   IF _fiscal ==  "N" .OR. LastKey() == K_ESC
       RETURN .F.
   ENDIF


  
   AAdd( _opc, "1. fiskalni uređaji: globalne postavke        " )
   AAdd( _opc_exe, {|| globalne_postavke_fiskalni_uredjaj() } )
   AAdd( _opc, "2. fiskalni uređaji: korisničke postavke " )
   AAdd( _opc_exe, {|| korisnik_postavke_fiskalni_uredjaj() } )
   AAdd( _opc, "P. pregled parametara" )
   AAdd( _opc_exe, {|| print_fiscal_params() } )

   f18_menu( "fiscal", .F., _izbor, _opc, _opc_exe )

   Box( , 6, 75 )
   _x := 2
   @ m_x + _x, m_y + 2 SAY8 "Lista fiskanih uređaja koji se koriste:" GET _fiscal_devices VALID valid_lista_fiskalnih_uredjaja( _fiscal_devices ) PICT "@S30"

   IF f18_use_module( "pos" )
       ++ _x
       @ m_x + _x, m_y + 2 SAY8 "Primarni fiskalni uređaj kod štampe POS računa:" GET _pos_def VALID valid_pos_fiskalni_uredjaj( _pos_def ) PICT "99"
   ENDIF

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Upozorenje za dnevne izvještaje (D/N)?" GET _rpt_warrning PICT "@!" VALID _rpt_warrning $ "DN"
   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_opt_usr_devices", my_user(), AllTrim( _fiscal_devices ) )
   set_metric( "fiscal_opt_usr_pos_default_device", my_user(), _pos_def )
   set_metric( "fiscal_opt_usr_daily_warrning", my_user(), _rpt_warrning )

   fiscal_opt_active()

   RETURN  ( _fiscal == "D" )



STATIC FUNCTION valid_lista_fiskalnih_uredjaja( cLista )

   IF EMPTY( cLista )
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

   LOCAL _device_id := 1
   LOCAL _max_id := 10
   LOCAL _min_id := 1
   LOCAL _x := 1
   LOCAL _dev_tmp
   LOCAL _dev_name, _dev_act, _dev_type, _dev_drv
   LOCAL _dev_iosa, _dev_serial, _dev_plu, _dev_pdv, _dev_init_plu
   LOCAL _dev_avans, _dev_timeout, _dev_vp_sum, _dev_vp_no_customer
   LOCAL _dev_restart, _dev_unos_depozita

   IF !__use_fiscal_opt
      MsgBeep( "Fiskalne opcije moraju biti uključene !" )
      RETURN .F.
   ENDIF

   Box(, 20, 80 )

   @ m_x + _x, m_y + 2 SAY8 "Uređaj ID:" GET _device_id ;
      PICT "99" ;
      VALID ( _device_id >= _min_id .AND. _device_id <= _max_id )

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   _x += 2
   @ m_x + _x, m_y + 2 SAY8 PadR( "**** Podešenje uređaja", 60 ) COLOR "I"

   _dev_tmp := PadL( AllTrim( Str( _device_id ) ), 2, "0" )
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
   _dev_vp_no_customer := fetch_metric( "fiscal_device_" + _dev_tmp + "_vp_no_customer" , NIL, "N" )
   _dev_unos_depozita := fetch_metric( "fiscal_device_" + _dev_tmp + "_unos_depozita" , NIL, "N" )

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Naziv uređaja:" GET _dev_name   PICT "@S40"
   @ m_x + _x, Col() + 1 SAY8 "Aktivan (D/N):" GET _dev_act  PICT "@!"  VALID _dev_act $ "DN"

   _x += 2

   @ m_x + _x, m_y + 2 SAY "Drajver (FPRINT/HCP/TREMOL/TRING/...):" GET _dev_drv ;
      PICT "@S20"  VALID !Empty( _dev_drv )

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   IF AllTrim( _dev_drv ) == "FPRINT"

      ++ _x
      @ m_x + _x, m_y + 2 SAY "IOSA broj:" GET _dev_iosa ;
         PICT "@S16"  VALID !Empty( _dev_iosa )

      @ m_x + _x, Col() + 1 SAY "Serijski broj:" GET _dev_serial ;
         PICT "@S20" VALID !Empty( _dev_serial )

   ENDIF

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Uređaj je u sistemu PDV-a (D/N):" GET _dev_pdv ;
      PICT "@!" VALID _dev_pdv $ "DN"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Tip uređaja (K - kasa, P - printer):" GET _dev_type ;
      PICT "@!" VALID _dev_type $ "KP"

   _x += 2

   @ m_x + _x, m_y + 2 SAY PadR( "**** Parametri artikla", 60 ) COLOR "I"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Za artikal koristiti plu [D/P] (stat./dinam.) [I] id, [B] barkod:" GET _dev_plu ;
      PICT "@!" VALID _dev_plu $ "DPIB"

   ++ _x

   @ m_x + _x, m_y + 2 SAY8 "(dinamički) inicijalni PLU kod:" GET _dev_init_plu PICT "999999"

   _x += 2
   @ m_x + _x, m_y + 2 SAY8 PadR( "**** Parametri rada sa uređajem", 60 ) COLOR "I"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Auto depozit:" GET _dev_avans PICT "999999.99"

   @ m_x + _x, col() + 1 SAY8 "Unos depozita kod reklamiranog računa (D/N) ?" GET _dev_unos_depozita PICT "@!" VALID _dev_unos_depozita $ "DN"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Timeout fiskalnih operacija:" GET _dev_timeout PICT "999"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Zbirni račun u VP (0/1/...):" GET _dev_vp_sum PICT "999"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Bezgotovinski račun moguć bez partnera (D/N) ?" GET _dev_vp_no_customer PICT "!@" VALID _dev_vp_no_customer $ "DN"

   ++ _x
   @ m_x + _x, m_y + 2 SAY "Restart servisa nakon slanja komande (D/N) ?" GET _dev_restart ;
      PICT "@!" ;
      VALID _dev_restart $ "DN"


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
   set_metric( "fiscal_device_" + _dev_tmp + "_unos_depozita", NIL, _dev_unos_depozita )

   RETURN .T.



FUNCTION korisnik_postavke_fiskalni_uredjaj()

   LOCAL _user_name := my_user()
   LOCAL _user_id := GetUserId( _user_name )
   LOCAL _device_id := 1
   LOCAL _max_id := 10
   LOCAL _min_id := 1
   LOCAL _x := 1
   LOCAL _dev_drv, _dev_tmp
   LOCAL _out_dir, _out_file, _ans_file, _print_a4
   LOCAL _op_id, _op_pwd, _print_fiscal
   LOCAL _op_docs

   IF !__use_fiscal_opt
      MsgBeep( "Fiskalne opcije moraju biti uključene !" )
      RETURN .F.
   ENDIF

   Box(, 20, 80 )

   @ m_x + _x, m_y + 2 SAY8 PadL( "Uređaj ID:", 15 ) GET _device_id ;
      PICT "99" ;
      VALID {|| ( _device_id >= _min_id .AND. _device_id <= _max_id ), ;
      show_it( get_fiscal_device_name( _device_id, 30 ) ), .T. }

   ++ _x

   @ m_x + _x, m_y + 2 SAY8 PadL( "Korisnik:", 15 ) GET _user_id PICT "99999999" ;
      VALID {|| iif( _user_id == 0, choose_f18_user_from_list( @_user_id ), .T. ), ;
      show_it( GetFullUserName( _user_id ), 30 ), .T.  }

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   _user_name := AllTrim( GetUserName( _user_id ) )

   _x += 2
   @ m_x + _x, m_y + 2 SAY8 PadR( "*** Podešenja rada sa uređajem", 60 ) COLOR "I"

   ++ _x
   _dev_tmp := PadL( AllTrim( Str( _device_id ) ), 2, "0" )
   _dev_drv := AllTrim( fetch_metric( "fiscal_device_" + _dev_tmp + "_drv", NIL, "" ) )

   _out_dir := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _user_name, out_dir_op_sys( _dev_drv ) ), 300 )
   _out_file := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_file", _user_name, out_file_op_sys( _dev_drv ) ), 50 )
   _out_answer := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _user_name, "" ), 50 )

   _op_id := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_id", _user_name, "1" ), 10 )
   _op_pwd := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _user_name, "000000" ), 10 )
   _print_a4 := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _user_name, "N" )
   _print_fiscal := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _user_name, "D" )
   _op_docs := PadR( fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _user_name, "" ), 100 )

   @ m_x + _x, m_y + 2 SAY "Direktorij izlaznih fajlova:" GET _out_dir PICT "@S50" VALID _valid_fiscal_path( _out_dir )

   ++ _x
   @ m_x + _x, m_y + 2 SAY "       Naziv izlaznog fajla:" GET _out_file PICT "@S20" VALID !Empty( _out_file )

   ++ _x
   @ m_x + _x, m_y + 2 SAY "       Naziv fajla odgovora:" GET _out_answer PICT "@S20"

   _x += 2
   @ m_x + _x, m_y + 2 SAY "Operater, ID:" GET _op_id PICT "@S10"
   @ m_x + _x, Col() + 1 SAY "lozinka:" GET _op_pwd PICT "@S10"

   _x += 2
   @ m_x + _x, m_y + 2 SAY8 "Štampati A4 racun nakon fiskalnog (D/N/G/X):" GET _print_a4 ;
      PICT "@!" VALID _print_a4 $ "DNGX"

   _x += 2
   @ m_x + _x, m_y + 2 SAY "Uredjaj koristiti za slj.tipove dokumenata:" GET _op_docs PICT "@S20"

   _x += 2
   @ m_x + _x, m_y + 2 SAY8 "Korisnik može printati fiskalne račune (D/N/T):" GET _print_fiscal ;
      PICT "@!" VALID _print_fiscal $ "DNT"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _user_name, AllTrim( _out_dir ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_out_file", _user_name, AllTrim( _out_file ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _user_name, AllTrim( _out_answer ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_id", _user_name, AllTrim( _op_id ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _user_name, AllTrim( _op_pwd ) )
   set_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _user_name, _print_a4 )
   set_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _user_name, _print_fiscal )
   set_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _user_name, AllTrim( _op_docs ) )

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
STATIC FUNCTION _valid_fiscal_path( fiscal_path, create_dir )

   LOCAL _ok := .T.
   LOCAL _cre

   IF create_dir == NIL
      create_dir := .T.
   ENDIF

   fiscal_path := AllTrim( fiscal_path )

   IF Empty( fiscal_path )
      MsgBeep( "Izlazni direktorij za fiskalne fajlove ne smije biti prazan ?!!!" )
      _ok := .F.
      RETURN _ok
   ENDIF

   IF DirChange( fiscal_path ) != 0
      IF create_dir
         _cre := MakeDir( fiscal_path )
         IF _cre != 0
            MsgBeep( "Kreiranje " + fiscal_path + " neuspjesno ?!#Provjerite putanju direktorija izlaznih fajlova." )
            _ok := .F.
         ENDIF
      ELSE
         MsgBeep( "Izlazni direktorij: " + fiscal_path + "#ne postoji !!!" )
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

   LOCAL _device_id := 0
   LOCAL _dev_arr
   LOCAL _pos_default
   LOCAL  cUser := my_user()

   IF !__use_fiscal_opt
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
      _device_id := fiskalni_uredjaji_meni( _dev_arr )
   ELSE
      _device_id := _dev_arr[ 1, 1 ]
   ENDIF

   RETURN _device_id



// -----------------------------------------------------
// vraca listu fiskalnih uredjaja kroz matricu
// -----------------------------------------------------
FUNCTION get_fiscal_devices_list( user, tip_dok )

   LOCAL _arr := {}
   LOCAL _i
   LOCAL _dev_max := 10
   LOCAL _dev_tmp
   LOCAL _usr_dev_list := ""
   LOCAL _dev_docs_list := ""

   IF user == NIL
      user := my_user()
   ENDIF

   IF tip_dok == NIL
      tip_dok := ""
   ENDIF

   _usr_dev_list := fetch_metric( "fiscal_opt_usr_devices", user, "" )

   FOR _i := 1 TO _dev_max

      _dev_tmp := PadL( AllTrim( Str( _i ) ), 2, "0" )

      _dev_id := fetch_metric( "fiscal_device_" + _dev_tmp + "_id", NIL, 0 )

      _dev_docs_list := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", my_user(), "" )

      IF ( _dev_id <> 0 ) ;
            .AND. ( fetch_metric( "fiscal_device_" + _dev_tmp + "_active", NIL, "N" ) == "D" ) ;
            .AND. IF( !Empty( _usr_dev_list ), AllTrim( Str( _dev_id ) ) + "," $ _usr_dev_list + ",", .T. ) ;
            .AND. IF( !Empty( _dev_docs_list ) .AND. !Empty( AllTrim( tip_dok ) ), tip_dok $ _dev_docs_list, .T. )

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

   FOR n := 1 TO Len( aDevices )
      IF aDevices[ n, 3 ] <> cModel .AND. n > 1
         cModel := "MIX"
         EXIT
      ENDIF
      cModel := aDevices[ n, 3 ]
   NEXT

   RETURN cModel



STATIC FUNCTION fiskalni_uredjaji_meni( arr )

   LOCAL _ret := 0
   LOCAL _i, _n
   LOCAL _tmp
   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _m_x := m_x
   LOCAL _m_y := m_y

   FOR _i := 1 TO Len( arr )

      _tmp := ""
      _tmp += PadL( AllTrim( Str( _i ) ) + ")", 3 )
      _tmp += " uredjaj " + PadL( AllTrim( Str( arr[ _i, 1 ] ) ), 2, "0" )
      _tmp += " : " + PadR( hb_StrToUTF8( arr[ _i, 2 ] ), 40 )

      AAdd( _opc, _tmp )
      AAdd( _opcexe, {|| "" } )

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      _izbor := Menu( "choice", _opc, _izbor, .F. )
      IF _izbor == 0
         EXIT
      ELSE
         _ret := arr[ _izbor, 1 ]
         _izbor := 0
      ENDIF
   ENDDO

   m_x := _m_x
   m_y := _m_y

   RETURN _ret




// --------------------------------------------------------------
// vraca hash matricu sa postavkama fiskalnog uredjaja
// --------------------------------------------------------------
FUNCTION get_fiscal_device_params( device_id, user_name )

   LOCAL _param := hb_Hash()
   LOCAL _dev_tmp := PadL( AllTrim( Str( device_id ) ), 2, "0" )
   LOCAL _dev_param
   LOCAL _user_name := my_user()
   LOCAL _out_dir

   IF !__use_fiscal_opt
      RETURN NIL
   ENDIF

   IF user_name <> NIL
      _user_name := user_name
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
   _param[ "unos_depozita" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_unos_depozita", NIL, "N" )
   _param[ "restart_service" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_restart_service", NIL, "N" )

#ifdef TEST
   _out_dir := "/tmp/"
#else
   _out_dir := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _user_name, "" )
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
   _param[ "out_dir" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_dir", _user_name, "" )
   _param[ "out_file" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_file", _user_name, "" )
   _param[ "out_answer" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_out_answer", _user_name, "" )
   _param[ "op_id" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_id", _user_name, "" )
   _param[ "op_pwd" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_pwd", _user_name, "" )
   _param[ "print_a4" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_a4", _user_name, "N" )
   _param[ "print_fiscal" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_print_fiscal", _user_name, "D" )
   _param[ "op_docs" ] := fetch_metric( "fiscal_device_" + _dev_tmp + "_op_docs", _user_name, "" )
#endif

   IF !post_check( _param )
      RETURN NIL
   ENDIF

   RETURN _param


// ---------------------------------------------------------------
// chekiranje nakon setovanja, da li ima lokacije itd...
// ---------------------------------------------------------------
STATIC FUNCTION post_check( param )

   LOCAL _ret := .T.

   _ret := _valid_fiscal_path( PARAM[ "out_dir" ], .F. )

   IF !_ret
      MsgBeep( "Izlazni direktorij " + AllTrim( PARAM[ "out_dir" ] ) + " nije ispravan !!!#Prekidam operaciju!" )
      RETURN _ret
   ENDIF

   IF Empty( PARAM[ "out_file" ] )
      MsgBeep( "Naziv izlaznog fajla mora biti popunjen ispravno !!!" )
      _ret := .F.
      RETURN _ret
   ENDIF

   RETURN _ret




// ----------------------------------------------------------
// prikazi fiskalne parametre
// ----------------------------------------------------------
FUNCTION print_fiscal_params()

   LOCAL _dev_arr
   LOCAL _usr_count, _dev_param
   LOCAL _user := my_user()
   LOCAL _usr_cnt, _user_id, _user_name
   LOCAL _dev_cnt, _dev_id, _dev_name, _dev_act

   IF !__use_fiscal_opt
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
      _user_name := _usr_arr[ _usr_cnt, 2 ]

      _dev_arr := get_fiscal_devices_list( _user_name )

      ?
      ? "Korisnik:", AllTrim( Str( _user_id ) ), "-", GetFullUserName( _user_id )
      ? Replicate( "=", 80 )

      FOR _dev_cnt := 1 TO Len( _dev_arr )

         _dev_id := _dev_arr[ _dev_cnt, 1 ]
         _dev_name := _dev_arr[ _dev_cnt, 2 ]

         ? Space( 3 ), Replicate( "-", 70 )
         ? Space( 3 ), "Uredjaj id:", AllTrim( Str( _dev_id ) ), "-", _dev_name
         ? Space( 3 ), Replicate( "-", 70 )

         _dev_param := get_fiscal_device_params( _dev_id, _user_name )

         IF _dev_param == NIL
            ? Space( 3 ), "nema podesenih parametara !!!"
         ELSE
            _print_param( _dev_param )
         ENDIF

      NEXT

   NEXT

   FF
   ENDPRINT

   RETURN



// ------------------------------------------------------
// printanje parametra
// ------------------------------------------------------
STATIC FUNCTION _print_param( param )

   ? Space( 3 ), "Drajver:", PARAM[ "drv" ], "IOSA:", PARAM[ "iosa" ], "Serijski broj:", PARAM[ "serial" ], "Tip uredjaja:", PARAM[ "type" ]
   ? Space( 3 ), "U sistemu PDV-a:", PARAM[ "pdv" ]
   ?
   ? Space( 3 ), "Izlazni direktorij:", AllTrim( PARAM[ "out_dir" ] )
   ? Space( 3 ), "       naziv fajla:", AllTrim( PARAM[ "out_file" ] ), "naziv fajla odgovora:", AllTrim( PARAM[ "out_answer" ] )
   ? Space( 3 ), "Operater ID:", PARAM[ "op_id" ], "PWD:", PARAM[ "op_pwd" ]
   ?
   ? Space( 3 ), "Tip PLU kodova:", PARAM[ "plu_type" ], "Inicijalni PLU:", AllTrim( Str( PARAM[ "plu_init" ] ) )
   ? Space( 3 ), "Auto polog:", AllTrim( Str( PARAM[ "auto_avans" ], 12, 2 ) ), ;
      "Timeout fiskalnih operacija:", AllTrim( Str( PARAM[ "timeout" ] ) )
   ?
   ?U Space( 3 ), "A4 print:", PARAM[ "print_a4" ], " dokumenti za štampu:", PARAM[ "op_docs" ]
   ?U Space( 3 ), "Zbirni bezgotovinski račun:", AllTrim( Str( PARAM[ "vp_sum" ] ) )
   ?U Space( 3 ), "Bezgotovinski račun moguć bez partnera:", PARAM[ "vp_no_customer" ]

   RETURN
