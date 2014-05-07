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


#include "rnal.ch"


FUNCTION rnal_mnu_admin()

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL izbor := 1

   AAdd( opc, "1. administracija db-a            " )
   AAdd( opcexe, {|| m_adm() } )
   AAdd( opc, "2. regeneracija naziva artikala   " )
   AAdd( opcexe, {|| _a_gen_art() } )

   f18_menu( "administracija", .F., izbor, opc, opcexe )

   RETURN



FUNCTION _a_gen_art()

   LOCAL nCnt := 0

   IF !SigmaSif( "ARTGEN" )
      msgbeep( "!!!!! opcija nedostupna !!!!!" )
      RETURN
   ENDIF

   rnal_o_sif_tables()

   nCnt := auto_gen_art()

   MsgBeep( "Obradjeno " + AllTrim( Str( nCnt ) ) + " stavki !" )

   RETURN
