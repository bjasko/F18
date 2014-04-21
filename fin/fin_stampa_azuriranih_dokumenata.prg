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


#include "fin.ch"



FUNCTION fin_stampa_azur_naloga_menu()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {} 

   AADD( _opc, "1. subanalitika                 ")
   AADD( _opcexe, {|| fin_stampa_analiticki_nalog() } )
   AADD( _opc, "2. sintetika  ")
   AADD( _opcexe, {|| fin_stampa_sinteticki_nalog() } )

   f18_menu( "fst", .f., _izbor, _opc, _opcexe  )

   RETURN





