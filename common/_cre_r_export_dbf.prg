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


STATIC s_cExportDbf := "r_export"


FUNCTION create_dbf_r_export( aFieldList, lCloseDbfs )

   LOCAL cImeDbf, cImeCdx

   hb_default( @lCloseDbfs, .F. )

   IF lCloseDbfs
      my_close_all_dbf()
   ENDIF

   cImeDBf := f18_ime_dbf( "r_export" )
   cImeCdx := ImeDbfCdx( cImeDbf )

   IF Select( "R_EXPORT" ) != 0
      SELECT r_export
      USE
   ENDIF

   FErase( cImeDbf )
   FErase( cImeCdx )
   IF File( cImeDbf )
      MsgBeep( "Ne mogu obrisati" +  cImeDbf )
      RETURN .F.
   ENDIF
   DbCreate2( cImeDbf, aFieldList )

   IF !File( cImeDbf )
      ?E "Ne mogu kreirati", cImeDbf
      RaiseError( "dbcreate2 " + cImeDbf + " " + pp( aFieldList ) )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION open_r_export_table( cExportDbf )

   LOCAL cCommand
   LOCAL cPath, cName, cExt, cDrive
   LOCAL cXlsx
   LOCAL hFile, cOutFile

   my_close_all_dbf()

   // cCommand := get_run_prefix_cmd() + file_path_quote( my_home() + my_dbf_prefix() + s_cExportDbf + ".dbf" )

   // log_write( "Export " + s_cExportDbf + " cmd: " + _cmd, 9 )

   // DirChange( my_home() )
   // IF f18_run( cCommand ) <> 0
   // MsgBeep( "Problem sa pokretanjem ?!" )
   // ENDIF


   IF cExportDbf == NIL
      cExportDbf := my_home() + my_dbf_prefix() + s_cExportDbf + ".dbf"
   ENDIF

   hb_FNameSplit( cExportDbf, @cPath, @cName, @cExt, @cDrive )

   MsgO( "LO konvert " + cName + ".dbf -> .xlsx" )
   hb_FNameSplit( cExportDbf, @cPath, @cName, @cExt, @cDrive )
   IF Right( cPath, 1 ) == SLASH // c:\temp\ => c:\temp, bez ovoga soffice --outdir zaglavi !
      cPath := Left( cPath, Len( cPath ) - 1 )
   ENDIF
   f18_run( LO_convert_xlsx_cmd() + " " + file_path_quote( cExportDbf ) + " " + file_path_quote( cPath ) ) // libreoffice --convert-to xlsx:"Calc MS Excel 2007 XML" --infilter=dBase:25 r_export.dbf
   Msgc()
   cXlsx := StrTran( cExportDbf, ".dbf", ".xlsx" )

   IF !File( cXlsx )
      MsgBeep( "Greška! XLSX nije kreiran:#" + cXlsx )
      RETURN .F.
   ENDIF

   IF ( hFile := hb_vfTempFile( @cOutFile, my_home(), "r_export_", ".xlsx" ) ) != NIL // hb_vfTempFile( @<cFileName>, [ <cDir> ], [ <cPrefix> ], [ <cExt> ], [ <nAttr> ] )
      hb_vfClose( hFile )
      COPY FILE ( cXlsx ) TO ( cOutFile )
   ELSE
      cOutFile := cXlsx
   ENDIF
   LO_open_dokument( cOutFile )

   RETURN .T.


FUNCTION o_r_export()

   SELECT ( F_R_EXP )
   my_usex ( "r_export" )

   RETURN .T.


FUNCTION select_o_r_export()

   SELECT ( F_R_EXP )
   IF !Used()
      my_usex ( "r_export" )
   ENDIF

   RETURN .T.
