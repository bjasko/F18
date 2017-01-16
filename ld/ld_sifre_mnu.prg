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


FUNCTION ld_sifarnici()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   o_ld_sif_tables()

   AAdd( _opc, "1. opći šifarnici                     " )
   AAdd( _opcexe, {|| ld_opci_sifarnici() } )
   AAdd( _opc, "2. ostali šifarnici" )
   AAdd( _opcexe, {|| ld_specificni_sifarnici() } )

   f18_menu( "sif", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION ld_opci_sifarnici()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. radnici                            " )
   AAdd( _opcexe, {|| P_Radn() } )
   AAdd( _opc,  "5. radne jedinice" )
   AAdd( _opcexe, {|| P_LD_RJ() } )
   AAdd( _opc, "6. opštine" )
   AAdd( _opcexe, {|| P_Ops() } )
   AAdd( _opc, "9. vrste posla" )
   AAdd( _opcexe, {|| P_VPosla() } )
   AAdd( _opc, "B. stručne spreme" )
   AAdd( _opcexe, {|| P_StrSpr() } )
   AAdd( _opc, "C. kreditori" )
   AAdd( _opcexe, {|| P_Kred() } )
   AAdd( _opc, "F. banke" )
   AAdd( _opcexe, {|| P_Banke() } )
   AAdd( _opc, "G. sifk" )
   AAdd( _opcexe, {|| P_SifK() } )

   IF ( IsRamaGlas() )
      AAdd( _opc,  "H. objekti"  )
      AAdd( _opcexe, {|| P_fakt_objekti() } )
   ENDIF


   f18_menu( "op", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION ld_specificni_sifarnici()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. parametri obračuna                  " )
   AAdd( _opcexe, {|| P_ParObr() } )
   AAdd( _opc, "2. tipovi primanja" )
   AAdd( _opcexe, {|| P_TipPr() } )
   AAdd( _opc, "3. tipovi primanja / ostali obračuni" )
   AAdd( _opcexe, {|| P_TipPr2() } )
   AAdd( _opc, "4. porezne stope " )
   AAdd( _opcexe, {|| P_Por() } )
   AAdd( _opc, "5. doprinosi " )
   AAdd( _opcexe, {|| P_Dopr() } )
   AAdd( _opc, "6. koef.benef.rst" )
   AAdd( _opcexe, {|| P_KBenef() } )

   IF gSihtarica == "D"
      AAdd( _opc, "7. tipovi primanja u šihtarici" )
      AAdd( _opcexe, {|| P_TprSiht() } )
      AAdd( _opc, "8. norme radova u šihtarici   " )
      AAdd( _opcexe, {|| P_NorSiht() } )
   ENDIF

   IF gSihtGroup == "D"
      AAdd( _opc, "8. lista konta   " )
      AAdd( _opcexe, {|| p_konto() } )
   ENDIF

   f18_menu( "spc", .F., _izbor, _opc, _opcexe )

   RETURN .T.



STATIC FUNCTION o_ld_sif_tables()

   O_SIFK
   O_SIFV
   O_BANKE
   O_TPRSIHT
   O_NORSIHT
   O_RADN
   O_PAROBR
   o_tippr()
   O_LD_RJ
   O_POR
   O_DOPR
   O_STRSPR
   O_KBENEF
   O_VPOSLA
   O_OPS
   O_KRED
   O_TIPPR2

   IF ( IsRamaGlas() )
      O_FAKT_OBJEKTI
   ENDIF

   RETURN .T.
