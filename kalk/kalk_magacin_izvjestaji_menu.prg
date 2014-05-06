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


FUNCTION kalk_izvjestaji_magacina()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. kartica - magacin                        " )
   AAdd( _opcexe, {|| Kartica_magacin() } )
   AAdd( _Opc, "2. lager lista - magacin" )
   AAdd( _opcexe, {|| LLM() } )
   AAdd( _Opc, "3. lager lista - proizvoljni sort" )
   AAdd( _opcexe, {|| KaLagM() } )

   AAdd( _Opc, "4. finansijsko stanje magacina" )
   AAdd( _opcexe, {|| FLLM() } )
   AAdd( _Opc, "5. realizacija po partnerima" )
   AAdd( _opcexe, {||  kalk_real_partnera() } )
   AAdd( _Opc, "6. promet grupe partnera" )
   AAdd( _opcexe, {|| PrometGP() } )
   AAdd( _opc, "7. pregled robe za dobavljača" )
   AAdd( _opcexe, {|| ProbDob() } )
   AAdd( _Opc, "8. TKV" )
   AAdd( _opcexe, {|| kalk_tkv() } )
   AAdd( _Opc, "----------------------------------" )
   AAdd( _opcexe, nil )
   AAdd( _Opc, "P. porezi" )
   AAdd( _opcexe, {|| MPoreziMag() } )
   AAdd( _Opc, "----------------------------------" )
   AAdd( _opcexe, nil )
   AAdd( _Opc, "K. kontrolni izvjestaji" )
   AAdd( _opcexe, {|| m_ctrl_rpt() } )
   AAdd( _Opc, "S. pregledi za vise objekata" )
   AAdd( _opcexe, {|| MRekMag() } )
   AAdd( _Opc, "T. lista trebovanja po sastavnicama" )
   AAdd( _opcexe, {|| g_sast_list() } )
   AAdd( _Opc, "U. specifikacija izlaza po sastavnicama" )
   AAdd( _opcexe, {|| rpt_prspec() } )

   f18_menu( "imag", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


// ----------------------------------------------------
// kontrolni izvjestaji
// ----------------------------------------------------
FUNCTION m_ctrl_rpt()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _Opc, "1. kontrola sastavnica               " )
   AAdd( _opcexe, {|| r_ct_sast() } )

   f18_menu( "ctrl", .F., _izbor, _opc, _opcexe )

   RETURN


FUNCTION MPoreziMag()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _Opc, "1. realizacija - veleprodaja po tarifama" )
   AAdd( _opcexe, {|| RekPorMag() } )
   AAdd( _Opc, "2. porez na promet " )
   AAdd( _opcexe, {|| RekPorNap() } )
   AAdd( _Opc, "3. rekapitulacija po tarifama" )
   AAdd( _opcexe, {|| RekmagTar() } )

   f18_menu( "porm", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


FUNCTION MRekMag()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. rekapitulacija finansijskog stanja" )
   AAdd( _opcexe, {|| RFLLM() } )

   f18_menu( "rmag", .F., _izbor, _opc, _opcexe )
   my_close_all_dbf()

   RETURN
