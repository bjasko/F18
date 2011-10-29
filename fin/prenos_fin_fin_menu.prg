/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "fin.ch"

/*! \file fmk/fin/razoff/1g/mnu_off.prg
 *  \brief Menij prenosa podataka
 */
 

/*! \fn MnuUdaljeneLokacije()
 *  \brief Menij prenosa udaljenih lokacija
 */

function MnuUdaljeneLokacije()

private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc, "1. fin <-> fin (diskete,modem)        ")
AADD(opcexe, {|| FinDisk()})

Menu_SC("rof")

return


