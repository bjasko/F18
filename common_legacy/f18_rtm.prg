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

STATIC _f18_delphi_exe := "f18_delphirb.exe" // pod ovim imenom u my_home se pokrece
STATIC _f18_label_exe := "f18_labeliranje.exe"

// ------------------------------------------------------------
// stampa rtm reporta kroz delphirb
//
// - rtm_file - naziv rtm fajla
// - table_name - naziv tabele koju otvara
// - table_index - naziv indeksa koji otvara tabelu
// - test_mode .t. ili .f., default .f. - testni rezim komande
// ------------------------------------------------------------
FUNCTION f18_rtm_print( rtm_file, table_name, table_index, test_mode, rtm_mode )

   LOCAL cCmd
   LOCAL lOk := .F.
   LOCAL _util_path
   LOCAL nError

#ifdef __PLATFORM__UNIX

   _f18_delphi_exe := "delphirb"
   _f18_label_exe := "labeliranje"
#endif

#ifdef __PLATFORM__LINUX
   my_close_all_dbf()
#endif

   // provjera uslova

   IF ( rtm_file == NIL )
      MsgBeep( "Nije zadat rtm fajl !?" )
      RETURN lOk
   ENDIF

   IF ( table_name == NIL )
      table_name := ""
   ENDIF

   IF ( table_index == NIL )
      table_index := ""
   ENDIF

   IF ( test_mode == NIL )
      test_mode := .F.
   ENDIF

   IF ( rtm_mode == NIL )
      rtm_mode := "drb"
   ENDIF

   // provjeri treba li kopirati delphirb.exe ?
   IF !delphirb_exe_copy_to_my_home( rtm_mode )
      RETURN lOk
   ENDIF

   // provjeri treba li kopirati template fajl
   IF !copy_rtm_template( rtm_file )
      // sigurno postoji opet neka greska...
      RETURN lOk
   ENDIF

   // ovdje treba kod za filovanje datoteke IZLAZ.DBF
   IF Pitanje(, "Štampati delphirb report ?", "D" ) == "N"
      RETURN lOk
   ENDIF

   // idemo na slaganje komande za report

   cCmd := ""

#ifdef __PLATFORM__UNIX
   cCmd += SLASH + "opt" + SLASH + "knowhowERP" + SLASH + "util" + SLASH
#endif

   IF rtm_mode == "drb"
      cCmd += _f18_delphi_exe
   ELSE
      cCmd += _f18_label_exe
   ENDIF

   cCmd += " "
   cCmd += rtm_file
   cCmd += " "

#ifdef __PLATFORM__WINDOWS
   cCmd += "." + SLASH
#else
   cCmd += my_home()
#endif

   IF !Empty( table_name )

      // dodaj i naziv tabele i index na komandu
      cCmd += " "
      cCmd += table_name
      cCmd += " "
      cCmd += table_index

   ENDIF

#ifdef __PLATFORM__UNIX
   cCmd += " "
   cCmd += "&"
#endif

#ifdef __PLATFORM__WINDOWS
   IF test_mode
      cCmd += " & pause"
   ENDIF
#endif


?E "delphirb/label print, cmd: " + cCmd, " start in dir", my_home()


   DirChange( my_home() ) // pozicionirati se na home direktorij tokom izvrsenja
   nError := hb_run( cCmd ) // f18_run pravi probleme, izgleda da mijenja direktorij, zato se koristi obicni hb_run

   IF nError <> 0
      MsgBeep( "Postoji problem sa stampom#Greska: " + AllTrim( Str( nError ) ) )
      RETURN lOk
   ENDIF

   lOk := .T.

   RETURN lOk



STATIC FUNCTION delphirb_exe_copy_to_my_home( mode )

   LOCAL lOk := .T.
   LOCAL _util_path
   LOCAL _drb := "delphirb.exe"
   LOCAL _lab := "labeliranje.exe"
   LOCAL _exe, _tmp

   IF mode == NIL
      mode := "drb"
   ENDIF

   IF mode == "drb"
      _exe := _f18_delphi_exe
      _tmp := _drb
   ELSE
      _exe := _f18_label_exe
      _tmp := _lab
   ENDIF


#ifdef __PLATFORM__WINDOWS
   _util_path := "c:" + SLASH + "knowhowERP" + SLASH + "util" + SLASH
#else
   _util_path := SLASH + "opt" + SLASH + "knowhowERP" + SLASH + "util" + SLASH

   RETURN lOk
#endif

// kopiraj delphirb u home path
IF !File( my_home() + _exe )
IF !File( _util_path + _tmp )
MsgBeep( "Fajl " + _util_path + _tmp + " ne postoji !?" )
lOk := .F.
RETURN lOk
ELSE
FileCopy( _util_path + _tmp, my_home() + _exe )
ENDIF
ENDIF

   RETURN lOk


// ---------------------------------------------------------
// kopiranje template fajla u home direktorij
//
// napomena: template = "nalplac", bez ekstenzije
// ---------------------------------------------------------
STATIC FUNCTION copy_rtm_template( template )

   LOCAL _ret := .F.
   LOCAL _rtm_ext := ".rtm"
   LOCAL _a_source, _a_template
   LOCAL _src_size, _src_date, _src_time
   LOCAL _temp_size, _temp_date, _temp_time
   LOCAL _copy := .F.

   IF !File( my_home() + template + _rtm_ext )
      _copy := .T.
   ELSE

      // fajl postoji na lokaciji, ispitaj velicinu, datum vrijeme
      _a_source := Directory( my_home() + template + _rtm_ext )
      _a_template := Directory( f18_template_location( template + _rtm_ext ) )

      // datum, vrijeme, velicina
      _src_size := AllTrim( Str( _a_source[ 1, 2 ] ) )
      _src_date := DToS( _a_source[ 1, 3 ] )
      _src_time := _a_source[ 1, 4 ]

      _temp_size := AllTrim( Str( _a_template[ 1, 2 ] ) )
      _temp_date := DToS( _a_template[ 1, 3 ] )
      _temp_time := _a_template[ 1, 4 ]

      // treba ga kopirati
      IF _temp_date + _temp_time > _src_date + _src_time
         _copy := .T.
      ENDIF

   ENDIF

   // treba ga kopirati
   IF _copy

      IF !File( f18_template_location( template + _rtm_ext ) )
         MsgBeep( "Fajl " + f18_template_location( template + _rtm_ext ) + " ne postoji !" )
         RETURN _ret
      ELSE
         FileCopy( f18_template_location( template + _rtm_ext ), my_home() + template + _rtm_ext )
      ENDIF

   ENDIF

   _ret := .T.

   RETURN _ret
