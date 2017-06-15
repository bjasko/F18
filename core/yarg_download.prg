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

STATIC s_cUtilName := "yarg"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/f18_editor/
STATIC s_cProg // windows: f18_editor.cmd, darwin: f18_editor

#ifdef __PLATFORM__WINDOWS
STATIC s_cSHA256sum := "9ec070dd7575cbba959e23a85a4eb3e5fe12b518532e08ba2ad45441af28685f"  //yarg/bin/yarg.bat
#endif

#ifdef __PLATFORM__UNIX
STATIC s_cSHA256sum := "85e0db4dcda583fb806d76041d5f1951a59f4b63ded5c33e2ac2cc9e2a60a2e4" //yarg/bin/yarg
#endif


FUNCTION check_yarg_download()

   LOCAL cPlatform
   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload := .F.
   LOCAL cDownloadRazlog := "FILE"
   LOCAL cYargCmd

   IF is_linux()
      RETURN .T.
   ENDIF

   IF s_cDirF18Util == NIL
      s_cDirF18Util := ExePath() + "F18_util" + SLASH
      s_cProg := "bin" + SLASH + s_cUtilName + iif( is_windows(), ".bat", "" )
   ENDIF


   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + ".zip"

   IF DirChange( s_cDirF18Util ) != 0  // e.g. $HOME/F18/F18_util
      IF MakeDir( s_cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   cYargCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg
   lDownload :=  !File( cYargCmd )
   IF !lDownload
      cMySum := sha256sum( cYargCmd )
      IF ( cMySum !=  s_cSHA256sum )
         MsgBeep( "yarg sha256sum " + cYargCmd + "## local:" + cMySum + "## remote:" + s_cSHA256sum )
         lDownload := .T.
         cDownloadRazlog := "SUM"
      ENDIF
   ENDIF

   IF lDownload
      IF cDownloadRazlog == "SUM" .AND. Pitanje(, "Downloadovati " + s_cProg + " novu verzija?", "D" ) == "N"
         lDownload := .F.
      ENDIF

      IF lDownload
         cZip := download_file( cUrl, NIL )
         IF !Empty( cZip )
            unzip_files( cZip, "", s_cDirF18Util, {}, .T. )
         ELSE
            MsgBeep( "Error download " + s_cProg + "##" + cUrl )
         ENDIF
      ENDIF
   ENDIF

   IF lDownload .AND. sha256sum( cYargCmd ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + cYargCmd  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
