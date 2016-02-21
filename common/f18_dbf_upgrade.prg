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

STATIC __ini_section := "DBF_version"


FUNCTION read_dbf_version_from_config()

   LOCAL _ini_params
   LOCAL _current_dbf_ver, _new_dbf_ver
   LOCAL __ini_section := "DBF_version"
   LOCAL _ret

   _ini_params := hb_Hash()
   _ini_params[ "major" ] := "0"
   _ini_params[ "minor" ] := "0"
   _ini_params[ "patch" ] := "0"

   _ret := hb_Hash()

   IF !f18_ini_config_read( __ini_section, @_ini_params, .F. )
      ?E "problem sa ini_params " + __ini_section
   ENDIF
   _current_dbf_ver := get_version_num( _ini_params[ "major" ], _ini_params[ "minor" ], _ini_params[ "patch" ] )
   _new_dbf_ver     := get_version_num( F18_DBF_VER_MAJOR, F18_DBF_VER_MINOR, F18_DBF_VER_PATCH )

   ?E "current dbf version:" + Str( _current_dbf_ver )
   ?E "    F18 dbf version:" + Str( _new_dbf_ver )

   _ret[ "current" ] := _current_dbf_ver
   _ret[ "new" ]     := _new_dbf_ver

   RETURN _ret



FUNCTION write_dbf_version_to_ini_conf()

   LOCAL _ini_params, cMsg, cDbfVer

   _ini_params := hb_Hash()
   _ini_params[ "major" ] := "0"
   _ini_params[ "minor" ] := "0"
   _ini_params[ "patch" ] := "0"


   _ini_params[ "major" ] := F18_DBF_VER_MAJOR
   _ini_params[ "minor" ] := F18_DBF_VER_MINOR
   _ini_params[ "patch" ] := F18_DBF_VER_PATCH

   cDbfVer := AllTrim( Str( F18_DBF_VER_MAJOR ) ) + "." + AllTrim( Str( F18_DBF_VER_MINOR ) ) + "." + AllTrim( Str( F18_DBF_VER_PATCH ) )

   IF !f18_ini_config_write( __ini_section, @_ini_params, .F. )
      cMsg := "ini_dbf: problem write dbf verzija: " + cDbfVer
      ?E cMsg
      error_bar( "ini_dbf:" + my_server_params()[ "database" ], cMsg )
   ELSE
      info_bar( "ini_dbf:" + my_server_params()[ "database" ], "write dbf verzija: " + cDbfVer )
   ENDIF

   RETURN .T.
