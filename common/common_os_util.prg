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

#include "fmk.ch"

#define D_STAROST_DANA   25

PROCEDURE OutMsg( hFile, cMsg )

   IF hFile == 1
      OutStd( cMsg )
   ELSEIF hFile == 2
      OutErr( cMsg )
   ELSE
      FWrite( hFile, cMsg )
   ENDIF

   RETURN



// ------------------------------------
// vraca putanju exe fajlova
// ------------------------------------
FUNCTION GetExePath( cPath )

   LOCAL cRet := ""
   LOCAL i
   LOCAL n := 0
   LOCAL cTmp

   FOR i := 1 TO Len( cPath )

      cTmp := SubStr( cPath, i, 1 )
	
      IF cTmp == "\"
         n += 1
      ENDIF

      cRet += cTmp

      IF n = 2
         EXIT
      ENDIF

   NEXT

   RETURN cRet


/*! \fn FilePath(cFile)
 *  \brief  Extract the full path name from a filename
 *  \return cFilePath
 */

FUNCTION My_FilePath( cFile )

   LOCAL nPos, cFilePath

   nPos := RAt( SLASH, cFile )
   IF ( nPos != 0 )
      cFilePath := SubStr( cFile, 1, nPos )
   ELSE
      cFilePath := ""
   ENDIF

   RETURN cFilePath

FUNCTION ExFileName( cFile )

   LOCAL nPos, cFileName

   IF ( nPos := RAt( SLASH, cFile ) ) != 0
      cFileName := SubStr( cFile, nPos + 1 )
   ELSE
      cFileName := cFile
   ENDIF

   RETURN cFileName

FUNCTION AddBS( cPath )

   IF Right( cPath, 1 ) <> SLASH
      cPath := cPath + SLASH
   ENDIF

FUNCTION DiskPrazan( cDisk )

   IF DiskSpace( Asc( cDisk ) -64 ) < 15000
      Beep( 4 )
      Msg( "Nema dovoljno prostora na ovom disku, stavite drugu disketu", 6 )
      RETURN .F.
   ENDIF

   RETURN .T.


// string FmkIni_ExePath_POS_PitanjeUgasiti;

/*! \ingroup ini
 *  \var *string FmkIni_ExePath_POS_PitanjeUgasiti
 *  \param "0" - ne pitaj (dobro za racunar koji se ne koristi SAMO kao PC Kasa
 *  \param "-" - pitaj
 */

FUNCTION UgasitiR()

   LOCAL cPitanje

   IF ( gSQL == "D" )
      cPitanje := IzFmkIni( "POS", "PitanjeUgasiti", "-" )
      IF cPitanje == "-"
         cPitanje := " "
      ENDIF

      IF ( cPitanje == "0" )
         goModul:quit()
      ELSEIF Pitanje(, "Želite li ugasiti racunar D/N ?", cPitanje ) == "D"
         IF Gw( "OMSG SHUTDOWN" ) == "OK"
            goModul:quit()
         ENDIF
      ENDIF
   ENDIF

   IF gModul <> "TOPS"
      goModul:quit()
   ENDIF

   RETURN



/*! \file ChangeEXT(cImeF,cExt, cExtNew, fBezAdd)
 * \brief Promjeni ekstenziju
 *
 * \params cImeF   ime fajla
 * \params cExt    polazna extenzija (obavezno 3 slova)
 * \params cExtNew nova extenzija
 * \params fBezAdd ako je .t. onda ce fajlu koji nema cExt dodati cExtNew
 *
 * \code
 *
 * ChangeEXT("SUBAN", "DBF", "CDX", .t.)
 * suban     -> suban.CDX
 *
 * ChangeEXT("SUBAN", "DBF", "CDX", .f.)
 * SUBAN     -> SUBAN
 *
 *
 * ChangeEXT("SUBAN.DBF", "DBF", "CDX", .t.)
 * SUBAN.DBF  -> SUBAN.CDX
 *
 * \endcode
 *
 */

FUNCTION ChangeEXT( cImeF, cExt, cExtNew, fBezAdd )

   LOCAL cTacka

   IF fBezAdd == NIL
      fBezAdd := .T.
   ENDIF

   IF Empty( cExtNew )
      cTacka := ""
   ELSE
      cTacka := "."
   ENDIF
   cImeF := ToUnix( cImeF )

   cImeF := Trim( StrTran( cImeF, "." + cEXT, cTacka + cExtNew ) )
   IF !Empty( cTacka ) .AND.  Right( cImeF, 4 ) <> cTacka + cExtNew
      cImeF := cImeF + cTacka + cExtNew
   ENDIF

   RETURN  cImeF


// ------------------------------------------
// ------------------------------------------
FUNCTION IsDirectory( cDir1 )

   LOCAL cDirTek
   LOCAL lExists

   cDir1 := ToUnix( cDir1 )

   cDirTek := DirName()

   IF DirChange( cDir1 ) <> 0
      lExists := .F.
   ELSE
      lExists := .T.
   ENDIF

   DirChange( cDirTek )

   RETURN lExists


/*! \fn BrisiSFajlove(cDir)
  * \brief Brisi fajlove starije od 45 dana
  *
  * \code
  *
  * npr:  cDir ->  c:\tops\prenos\
  *
  * brisi sve fajlove u direktoriju
  * starije od 45 dana
  *
  * \endcode
  */

FUNCTION BrisiSFajlove( cDir, nDana )

   LOCAL cFile

   IF nDana == nil
      nDana := D_STAROST_DANA
   ENDIF

   cDir := ToUnix( Trim( cdir ) )
   cFile := FileSeek( Trim( cDir ) + "*.*" )
   DO WHILE !Empty( cFile )
      IF Date() - FileDate() > nDana
         FileDelete( cdir + cfile )
      ENDIF
      cfile := FileSeek()
   ENDDO

   RETURN NIL



// ----------------------------------------------
// ----------------------------------------------
FUNCTION ToUnix( cFileName )
   RETURN cFileName


#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapifs.h"

HB_FUNC( FILEBASE )
{
   const char * szPath = hb_parc( 1 );
   if( szPath )
   {
      PHB_FNAME pFileName = hb_fsFNameSplit( szPath );
      hb_retc( pFileName->szName );
      hb_xfree( pFileName );
   }
   else
      hb_retc_null();
}

/* FileExt( <cFile> ) --> cFileExt
*/
HB_FUNC( FILEEXT )
{
   const char * szPath = hb_parc( 1 );
   if( szPath )
   {
      PHB_FNAME pFileName = hb_fsFNameSplit( szPath );
      if( pFileName->szExtension != NULL )
         hb_retc( pFileName->szExtension + 1 ); /* Skip the dot */
      else
         hb_retc_null();
      hb_xfree( pFileName );
   }
   else
      hb_retc_null();
}

#pragma ENDDUMP


#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapierr.h"
#include "hbapigt.h"
#include "hbapiitm.h"
#include "hbapifs.h"

/* TOFIX: The screen buffer handling is not right for all platforms (Windows)
          The output of the launched (MS-DOS?) app is not visible. */

HB_FUNC( __RUN_SYSTEM )
{
   const char * pszCommand = hb_parc( 1 );
   int iResult;

   if( pszCommand && hb_gtSuspend() == HB_SUCCESS )
   {
      char * pszFree = NULL;

      iResult = system( hb_osEncodeCP( pszCommand, &pszFree, NULL ) );

      hb_retni(iResult);

      if( pszFree )
         hb_xfree( pszFree );

      if( hb_gtResume() != HB_SUCCESS )
      {
         /* an error should be generated here !! Something like */
         /* hb_errRT_BASE_Ext1( EG_GTRESUME, 6002, NULL, HB_ERR_FUNCNAME, 0, EF_CANDEFAULT ); */
      }


   }
}

#pragma ENDDUMP



FUNCTION f18_run( cmd, output, always_ok, async )

   LOCAL _ret, _stdout, _stderr, _prefix
   LOCAL _msg

   IF always_ok == NIL
      always_ok := .F.
   ENDIF

   IF async == NIL
      // najcesce mi zelimo da okinemo exkternu komandu i nastavimo rad
      async := .F.
   ENDIF


#ifdef __PLATFORM__LINUX
   _ret := __run_system( cmd + iif( async, "&", "" ) )
#else
   _ret := hb_processRun( cmd, NIL, NIL, NIL, async )
#endif

   IF _ret <> 0

#ifdef __PLATFORM__WINDOWS
      _prefix := "c:\knowhowERP\util\start.exe /m "
#else
#ifdef __PLATFORM__DARWIN
      _prefix := "open "
#else
      _prefix := "xdg-open "
#endif
#endif

      IF Left( cmd, 4 ) == "java"
         _prefix := ""
      ENDIF

#ifdef __PLATFORM__LINUX
      IF async
         _ret := __run_system( _prefix + cmd + "&" )
      ELSE
         _ret := hb_processRun( _prefix + cmd, NIL, NIL, NIL, async )
      ENDIF
#else
      _ret := hb_processRun( _prefix + cmd, NIL, NIL, NIL, async )
#endif


#ifdef __PLATFORM__WINDOWS
      // copy komanda trazi system run a ne hbprocess run
      IF _ret <> 0
         _ret := __run_system( cmd )
      ENDIF
#endif
      IF _ret <> 0 .AND. !always_ok
         _msg := "ERR run cmd:"  + cmd
         log_write( _msg, 2 )
         MsgBeep( _msg )
      ENDIF

   ENDIF

   IF ValType( output ) == "H"
      // hash matrica
      output[ "stdout" ] := _stdout
      output[ "stderr" ] := _stderr
   ENDIF

   RETURN _ret

// -------------------------------------------
// -------------------------------------------
FUNCTION f18_open_document( document )

   LOCAL _ret, _prefix
   LOCAL _msg


#ifdef __PLATFORM__WINDOWS

   // _prefix := "start "
   _prefix := "c:\knowhowERP\util\start.exe "

#else
#ifdef __PLATFORM__DARWIN
   _prefix := "open "
#else
   _prefix := "xdg-open "
#endif
#endif

#ifdef __PLATFORM__LINUX
   _ret := __run_system( _prefix + document + "&" )
#else
   _ret := hb_processRun( _prefix + document, NIL, NIL, NIL, .T. )
#endif

   RETURN _ret


// ----------------------------
// ----------------------------
FUNCTION open_folder( folder )

   LOCAL _cmd
#ifdef __PLATFORM__WINDOWS

   folder := _path_quote( folder )
#endif

   RETURN f18_open_document( folder )
