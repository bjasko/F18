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

// ------------------------------
// menij pregled naloga
// ------------------------------
FUNCTION m_lst_rnal()

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL Izbor := 1

   AAdd( opc, "1. lista otvorenih naloga          " )
   AAdd( opcexe, {|| rnal_lista_dokumenata( 1 ) } )

   AAdd( opc, "2. lista zatvorenih naloga  " )
   AAdd( opcexe, {|| rnal_lista_dokumenata( 2 ) } )

   f18_menu( "lst", .F., izbor, opc, opcexe )

   RETURN
