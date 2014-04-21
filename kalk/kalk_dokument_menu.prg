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


#include "kalk.ch"


FUNCTION kalk_pregled_dokumenata()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. štampa ažuriranog dokumenta              " )
   AAdd( _opcexe, {|| kalk_centr_stampa_dokumenta( .T. ) } )
   AAdd( _opc, "2. štampa liste dokumenata" )
   AAdd( _opcexe, {|| StDoks() } )
   AAdd( _opc, "3. pregled dokumenata po hronologiji obrade" )
   AAdd( _opcexe, {|| BrowseHron() } )
   AAdd( _opc, "4. pregled dokumenata - tabelarni pregled" )
   AAdd( _opcexe, {|| browse_kalk_dok() } )
   AAdd( _opc, "5. radni nalozi " )
   AAdd( _opcexe, {|| BrowseRn() } )
   AAdd( _opc, "7. stampa OLPP-a za azurirani dokument" )
   AAdd( _opcexe, {|| StOLPPAz() } )
   AAdd( _opc, "8. kalkulacija cijena" )
   AAdd( _opcexe, {|| kalkulacija_cijena() } )

   f18_menu( "razp", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


FUNCTION kalk_ostale_operacije_doks()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. povrat dokumenta u pripremu" )

   IF ( ImaPravoPristupa( goModul:oDataBase:cName, "DOK", "POVRATDOK" ) )
      AAdd( _opcexe, {|| Povrat_kalk_dokumenta() } )
   ELSE
      AAdd( _opcexe, {|| MsgBeep( cZabrana ) } )
   ENDIF

   AAdd( _opc, "S. pregled smeca " )
   IF ( ImaPravoPristupa( goModul:oDataBase:cName, "DOK", "SMECEPREGLED" ) )
      AAdd( _opcexe, {|| kalk_pripr9view() } )
   ELSE
      AAdd( _opcexe, {|| MsgBeep( cZabrana ) } )
   ENDIF


   f18_menu( "mazd", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN
