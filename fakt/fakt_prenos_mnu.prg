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


#include "fakt.ch"



FUNCTION fakt_razmjena_podataka()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. kalk <-> fakt                  " )
   AAdd( _opcexe, {|| KaFak() } )
   AAdd( _opc, "3. import barkod terminal" )
   AAdd( _opcexe, {|| fakt_import_bterm() } )
   AAdd( _opc, "4. export barkod terminal" )
   AAdd( _opcexe, {|| fakt_export_bterm() } )

   f18_menu( "rpod", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN
