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


#include "mat.ch"


// -------------------------------------------
// meni parametara modula mat
// -------------------------------------------
FUNCTION mat_parametri()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. osnovni podaci organizacione jedinice         " )
   AAdd( _opcexe, {|| org_params() } )
   AAdd( _opc, "2. parametri obrade dokumenata" )
   AAdd( _opcexe, {|| _mat_obr_params() } )

   f18_menu( "params", .F., _izbor, _opc, _opcexe )

   RETURN



STATIC FUNCTION _mat_obr_params()

   LOCAL cK1 := cK2 := cK3 := cK4 := "N"

   gNalPr := PadR( gNalPr, 30 )
   gDirPor := PadR( gDirPor, 50 )

   gPicDem := PadR( gPicDem, 15 )
   gPicDin := PadR( gPicDin, 15 )
   gPicKol := PadR( gPicKol, 15 )

   Box(, 21, 74 )
   SET CURSOR ON
   @ m_x + 3, m_y + 2 SAY "Polje K1  D/N" GET cK1 VALID cK1 $ "DN" PICT "@!"
   @ m_x + 4, m_y + 2 SAY "Polje K2  D/N" GET cK2 VALID cK2 $ "DN" PICT "@!"
   @ m_x + 5, m_y + 2 SAY "Polje K3  D/N" GET cK3 VALID cK3 $ "DN" PICT "@!"
   @ m_x + 6, m_y + 2 SAY "Polje K4  D/N" GET cK4 VALID cK4 $ "DN" PICT "@!"
   @ m_x + 8, m_y + 2 SAY "Privatni direktorij PORMP (KALK):" GET gDirPor PICT "@S25"
   @ m_x + 9, m_y + 2 SAY "Potpis na kraju naloga D/N:" GET gPotpis VALID gPotpis $ "DN"
   @ m_x + 10, m_y + 2 SAY "Nalozi realizac. prodavnice:" GET gNalPr PICT "@S25"
   @ m_x + 11, m_y + 2 SAY "Preuzimanje cijene iz sifr.(bez/nc/vpc/mpc/prosj.) ( /1/2/3/P):" GET gCijena VALID gcijena $ " 123P"
   @ m_x + 13, m_y + 2 SAY "Zadati datum naloga D/N:" GET gDatNal VALID gDatNal $ "DN" PICT "@!"
   @ m_x + 14, m_y + 2 SAY "Koristiti polja partnera, lice zaduzuje D/N" GET gKupZad VALID gKupZad $ "DN" PICT "@!"
   @ m_x + 16, m_y + 2 SAY "Prikaz dvovalutno D/N" GET g2Valute VALID g2Valute $ "DN" PICT "@!"
   @ m_x + 17, m_y + 2 SAY "Pict " + ValPomocna() + ":" GET gpicdem PICT "@S15"
   @ m_x + 18, m_y + 2 SAY "Pict " + ValDomaca() + ":"  GET gpicdin PICT "@S15"
   @ m_x + 19, m_y + 2 SAY "Pict KOL :"  GET gpickol PICT "@S15"
   @ m_x + 20, m_y + 2 SAY "Sa sifrom je vezan konto D/N" GET gKonto VALID gKonto $ "DN" PICT "@!"
   @ m_x + 21, m_y + 2 SAY "Sekretarski sistem (D/N) ?"  GET gSekS VALID gSekS $ "DN" PICT "@!"
   READ
   BoxC()

   gNalPr := Trim( gNalPr )
   gDirPor := Trim( gDirPor )

   IF LastKey() <> K_ESC

      set_metric( "mat_dir_kalk", my_user(), gDirPor  )
      set_metric( "mat_dvovalutni_rpt", NIL, g2Valute )
      set_metric( "mat_real_prod", NIL, gNalPr )
      set_metric( "mat_tip_cijene", NIL, gCijena )
      set_metric( "mat_pict_dem", NIL, gPicDem )
      set_metric( "mat_pict_din", NIL, gPicDin )
      set_metric( "mat_pict_kol", NIL, gPicKol )
      set_metric( "mat_datum_naloga", NIL, gDatNal )
      set_metric( "mat_sekretarski_sistem", NIL, gSekS )
      set_metric( "mat_polje_partner", NIL, gKupZad )
      set_metric( "mat_vezni_konto", NIL, gKonto )
      set_metric( "mat_rpt_potpis", my_user(), gPotpis )
      set_metric( "mat_rpt_k1", my_user(), cK1 )
      set_metric( "mat_rpt_k2", my_user(), cK2 )
      set_metric( "mat_rpt_k3", my_user(), cK3 )
      set_metric( "mat_rpt_k4", my_user(), cK4 )

   ENDIF

   my_close_all_dbf()

   RETURN
