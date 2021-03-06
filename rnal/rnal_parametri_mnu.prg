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

FUNCTION m_par()

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL Izbor := 1

   AAdd( opc, "1. podaci firme - zaglavlje            " )
   AAdd( opcexe, {|| ed_fi_params() } )
   AAdd( opc, "2. izgled dokumenta  " )
   AAdd( opcexe, {|| ed_doc_params() } )
   AAdd( opc, "3. zaokruženja, format prikaza  " )
   AAdd( opcexe, {|| ed_zf_params() } )
   AAdd( opc, "4. parametri exporta  " )
   AAdd( opcexe, {|| ed_ex_params() } )
   AAdd( opc, "5. parametri elemenata i atributa  " )
   AAdd( opcexe, {|| ed_elat_params() } )
   AAdd( opc, "---------------------------------" )
   AAdd( opcexe, {|| nil } )
   AAdd( opc, "O. ostalo  " )
   AAdd( opcexe, {|| ed_ost_params() } )

   f18_menu( "par", .F., izbor, opc, opcexe )

   RETURN
