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


#include "fmk.ch"

function PtxtSekvence()

gpIni:=  "#%INI__#"
gpCOND:= "#%KON17#"
gpCOND2:="#%KON20#"
gp10CPI:="#%10CPI#"
gP12CPI:="#%12CPI#"
gPB_ON :="#%BON__#"
gPB_OFF:="#%BOFF_#"
gPU_ON:="#%UON__#"
gPU_OFF:="#%UOFF_#"
gPI_ON:="#%ION__#"
gPI_OFF:="#%IOFF_#"
gPFF   :="#%NSTR_#"
gPO_Port:="#%PORTR#"
gPO_Land:="#%LANDS#"
gPPort := "1"
gRPL_Normal:=""
gRPL_Gusto:=""

return

// -------------------------
// -------------------------
function Ptxt(cImeF)

local cPtxtSw := ""
local nFH

local cKom

if gPtxtSw <> nil
	cPtxtSw := gPtxtSw
else
	cPTXTSw := R_IniRead ( 'DOS', 'PTXTSW',  "/P", EXEPATH + 'FMK.INI' )
endif

#ifdef __PLATFORM__WINDOWS
	cImeF := '"' + cImeF + '"'
#endif

cKom := "ptxt " + cImeF + " "

cKom += " " + cPtxtSw

Run(cKom)
return .t.



