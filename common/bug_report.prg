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


FUNCTION GlobalErrorHandler( oError, lShowErrorReport, lQuitApp )

   LOCAL cCmd
   LOCAL cOutFile
   LOCAL cMsg, cLogMsg := "BUG REPORT: "
   LOCAL lNotify := .F.
   LOCAL bErr
   LOCAL nI

   IF oError:GenCode == 45 .AND. oError:SubCode == 1302
   /*
   Verzija programa: 1.7.770 13.03.2016 8.5.0

   SubSystem/severity    : BASE          2
   GenCod/SubCode/OsCode :         45       1302          0
   Opis                  : Object destructor failure
   ImeFajla              :
   Operacija             : Reference to freed block
   Argumenti             : _?_
   canRetry/canDefault   : .f. .f.

   CALL STACK:
   --- --------------------------------------------------------------------------------
   BUG REPORT: Verzija programa: 1.7.770 13.03.2016 8.5.0 ; SubSystem/severity    : BASE          2 ; GenCod/SubCode/OsCode :         45       1302          0 ; Opis                  : Object destructor failure ; ImeFajla              :  ; Operacija             : Reference to freed block ; Argumenti             : _?_ ; canRetry/canDefault   : .f. .f. ; CALL STACK:
      1 (b)F18_ERROR_BLOCK / 66
      2 INKEY / 0
      3 MY_DB_EDIT / 157
      4 FIN_KNJIZENJE_NALOGA / 123
      5 FIN_UNOS_NALOGA / 36
      6 (b)TFINMOD_PROGRAMSKI_MODUL_OSNOVNI_MENI / 51
      7 F18_MENU / 61
      8 TFINMOD:PROGRAMSKI_MODUL_OSNOVNI_MENI / 81
      9 TFINMOD:MMENU / 38
     10 TFINMOD:RUN / 126
   */

      bErr := ErrorBlock( {| oError | Break( oError ) } )

      LOG_CALL_STACK cLogMsg
      ?E "ERR Object destructor failure/Reference to freed block 45/1302", cLogMsg

      ErrorBlock( bErr )
      RETURN .T.
   ENDIF

   bErr := ErrorBlock( {| oError | Break( oError ) } )

   hb_default( @lQuitApp, .T. )
   hb_default( @lShowErrorReport, .T. )

   IF !lShowErrorReport
      lNotify := .T.
   ELSE
      Beep( 5 )
   ENDIF

   cOutFile := my_home_root() + "error.txt"

   IF is_in_main_thread()
#ifdef F18_DEBUG
      Alert( oError:Description + " " + oError:operation )
      AltD() // oError:Description
#endif

      SET CONSOLE OFF
      SET PRINTER OFF
      SET DEVICE TO PRINTER
      SET PRINTER to ( cOutFile )
      SET PRINTER ON
      P_12CPI

   ENDIF

   OutBug()
   OutBug( "F18 bug report (v6.0) :", Date(), Time() )
   OutBug( Replicate( "=", 84 ) )

   cMsg := "Verzija programa: " + f18_ver_show( .F. )
   OutBug( cMsg )

   cLogMsg += cMsg
   OutBug()

   cMsg := "SubSystem/severity    : " + oError:SubSystem + " " + to_str( oError:severity )
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   cMsg := "GenCod/SubCode/OsCode : " + to_str( oError:GenCode ) + " " + to_str( oError:SubCode ) + " " + to_str( oError:OsCode )
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   cMsg := "Opis                  : " + oError:description
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   cMsg := "ImeFajla              : " + oError:filename
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg


   cMsg := "Operacija             : " + oError:operation
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   cMsg := "Argumenti             : " + to_str( oError:args )
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   cMsg := "canRetry/canDefault   : " + to_str( oError:canRetry ) + " " + to_str( oError:canDefault )
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   OutBug()
   cMsg := "CALL STACK:"
   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   OutBug( "---", Replicate( "-", 80 ) )
   LOG_CALL_STACK cLogMsg
   OutBug( StrTran( cLogMsg, "//", hb_eol() ) )
   OutBug( "---", Replicate( "-", 80 ) )
   OutBug()


   IF hb_HHasKey( my_server_params(), "host" ) .AND. !no_sql_mode()
      server_connection_info()
      server_db_version_info()
      server_info()
   ENDIF

   IF Used()
      current_dbf_info()
   ELSE
      cMsg := "USED() = false"
   ENDIF

   OutBug( cMsg )
   cLogMsg += " ; " + cMsg

   IF oError:cargo <> NIL

      OutBug( "== CARGO", Replicate( "=", 50 ) )
      FOR nI := 1 TO Len( oError:cargo )
         IF oError:cargo[ nI ] == "var"
            cMsg :=  "* var " + to_str( oError:cargo[ ++nI ] )  + " : " + to_str( pp( oError:cargo[ ++nI ] ) )
            ? cMsg
            cLogMsg += " ; " + cMsg
         ENDIF
      NEXT
      OutBug( Replicate( "-", 60 ) )

   ENDIF

   OutBug( "== END OF BUG REPORT ==" )

   my_close_all_dbf()

   IF is_in_main_thread()
      SET DEVICE TO SCREEN
      SET PRINTER OFF
      SET PRINTER TO
      SET CONSOLE ON
      IF lShowErrorReport
         cCmd := "f18_editor " + cOutFile
         f18_run( cCmd )
      ENDIF
      log_write( cLogMsg, 1 )
#ifndef F18_DEBUG
      send_email( oError, lNotify )
#endif
   ENDIF

   IF lQuitApp
      QUIT_1
   ENDIF

   ErrorBlock( bErr )

   RETURN .T.



FUNCTION OutBug( ... )

   IF is_in_main_thread()
      QOut( ... )
   ELSE
      OutErr( ..., hb_eol() )
   ENDIF

   RETURN .T.



STATIC FUNCTION server_info()

   LOCAL _key
   LOCAL hServerVars := { "server_version", "TimeZone" }
   LOCAL _sys_info

   OutBug()
   OutBug( "/---------- BEGIN PostgreSQL vars --------/" )
   OutBug()
   FOR EACH _key in hServerVars
      OutBug( PadR( _key, 25 ) + ":",  server_show( _key ) )
   NEXT
   OutBug()

   OutBug( "/----------  END PostgreSQL vars --------/" )
   OutBug()
   _sys_info := server_sys_info()

   IF _sys_info != NIL
      OutBug()
      OutBug( "/-------- BEGIN PostgreSQL sys info --------/" )
      FOR EACH _key in _sys_info:Keys
         OutBug( PadR( _key, 25 ) + ":",  _sys_info[ _key ] )
      NEXT
      OutBug()
      OutBug( "/-------  END PostgreSQL sys info --------/" )
      OutBug()
   ENDIF

   RETURN .T.



STATIC FUNCTION server_connection_info()

   LOCAL hParams := my_server_params()

   IF !hb_HHasKey( hParams, "host" )
      RETURN .F.
   ENDIF

   OutBug()
   OutBug( "/----- SERVER connection info: ---------- /" )
   OutBug()
   OutBug( "host/database/port/schema :", my_server_params()[ "host" ] + " / " + my_server_params()[ "database" ] + " / " +  AllTrim( Str( my_server_params()[ "port" ], 0 ) ) + " / " +  my_server_params()[ "schema" ] )
   OutBug( "                     user :", my_server_params()[ "user" ] )
   OutBug()

   RETURN .T.



STATIC FUNCTION server_db_version_info()

   LOCAL _server_db_num, _server_db_str, _f18_required_server_str, _f18_required_server_num

   _f18_required_server_num := get_version_num( server_db_ver_major(), server_db_ver_minor(), server_db_ver_patch() )

   _server_db_num := server_db_version()

   _f18_required_server_str := get_version_str( _f18_required_server_num )
   _server_db_str := get_version_str( _server_db_num )

   OutBug( "F18 client required server db >=     :", _f18_required_server_str, "/", AllTrim( Str( _f18_required_server_num, 0 ) ) )
   OutBug( "Actual knowhow ERP server db version :", _server_db_str, "/", AllTrim( Str( _server_db_num, 0 ) ) )

   RETURN .T.




STATIC FUNCTION current_dbf_info()

   LOCAL _struct, nI

   OutBug( "Trenutno radno podrucje:", Alias(), ", record:", RecNo(), "/", RecCount() )

   _struct := dbStruct()

   OutBug( Replicate( "-", 60 ) )
   OutBug( "Record content:" )
   OutBug( Replicate( "-", 60 ) )
   FOR nI := 1 TO Len( _struct )
      OutBug( Str( nI, 3 ), PadR( _struct[ nI, 1 ], 15 ), _struct[ nI, 2 ], _struct[ nI, 3 ], _struct[ nI, 4 ], Eval( FieldBlock( _struct[ nI, 1 ] ) ) )
   NEXT
   OutBug( Replicate( "-", 60 ) )

   RETURN .T.




FUNCTION RaiseError( cErrMsg )

   LOCAL oErr

   oErr := ErrorNew()
   oErr:severity    := ES_ERROR
   oErr:genCode     := EG_OPEN
   oErr:subSystem   := "F18"
   oErr:SubCode     := 1000
   oErr:Description := cErrMsg

   Eval( ErrorBlock(), oErr )

   RETURN .T.




STATIC FUNCTION send_email( oError, lNotify )

   LOCAL hParamsEmail
   LOCAL cBody, cSubject
   LOCAL cAttachment
   LOCAL _answ := fetch_metric( "bug_report_email", my_user(), "A" )
   LOCAL cDatabase
   LOCAL aAttach

   IF lNotify == NIL
      lNotify := .F.
   ENDIF

   DO CASE
   CASE _answ $ "D#N#A"
      IF _answ $ "DN"
         IF Pitanje(, "Poslati poruku greške email-om podrški bring.out-a (D/N) ?", _answ ) == "N"
            RETURN .F.
         ENDIF
      ENDIF
   OTHERWISE
      RETURN .F.
   ENDCASE

   // BUG F18 1.7.21, rg_2013/bjasko, 02.04.04, 15:00:07, variable does not exist
   IF lNotify
      cSubject := "NOTIFY F18 "
   ELSE
      cSubject := "BUG F18 "
   ENDIF

   IF hb_HHasKey( my_server_params(), "database" )
      cDatabase := my_server_params()[ "database" ]
   ELSE
      cDatabase := "DBNOTDEFINED"
   ENDIF

   cSubject += f18_ver()
   cSubject += ", " + cDatabase + "/" + AllTrim( f18_user() )
   cSubject += ", " + DToC( Date() ) + " " + PadR( Time(), 8 )

   IF oError != NIL
      cSubject += ", " + AllTrim( oError:description ) + "/" + AllTrim( oError:operation )
   ENDIF

   cBody := "U prilogu zip fajl sa sadrzajem trenutne greske i log fajlom servera"

   hParamsEmail := email_hash_za_podrska_bring_out( cSubject, cBody )

   cAttachment := send_email_attachment()

   IF ValType( cAttachment ) == "L"
      RETURN .F.
   ENDIF

   aAttach := { cAttachment }

   info_bar( "err-sync", "Slanje greške podršci bring.out ..." )

   f18_email_send( hParamsEmail, aAttach )


   FErase( cAttachment )

   RETURN .T.



STATIC FUNCTION send_email_attachment()

   LOCAL _a_files := {}
   LOCAL _path := my_home_root()
   LOCAL _server := my_server_params()
   LOCAL _filename, nErr
   LOCAL _log_file, _log_params
   LOCAL _error_file := "error.txt"

   _filename := AllTrim( _server[ "database" ] )
   _filename += "_" + AllTrim( f18_user() )
   _filename += "_" + DToS( Date() )
   _filename += "_" + StrTran( Time(), ":", "" )
   _filename += ".zip"

   _log_params := hb_Hash()
   _log_params[ "date_from" ] := Date()
   _log_params[ "date_to" ] := Date()
   _log_params[ "limit" ] := 1000
   _log_params[ "conds_true" ] := ""
   _log_params[ "conds_false" ] := ""
   _log_params[ "doc_oper" ] := "N"
   _log_file := f18_view_log( _log_params )

   AAdd( _a_files, _error_file )
   AAdd( _a_files, _log_file )

   DirChange( _path )

   nErr := zip_files( _path, _filename, _a_files )

   DirChange( my_home() )

   IF nErr <> 0
      RETURN .F.
   ENDIF

   RETURN ( _path + _filename )




FUNCTION notify_podrska( cErrorMsg )

   LOCAL oErr

   oErr := ErrorNew()
   oErr:severity := ES_ERROR
   oErr:genCode := EG_OPEN
   oErr:subSystem := "F18"
   oErr:subCode := 1000
   oErr:Description := cErrorMsg

   Eval( ErrorBlock(), oErr, .F., .F. )

   RETURN .T.
