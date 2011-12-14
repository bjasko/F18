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

#include "kalk.ch"
#include "f18_ver.ch"

EXTERNAL DESCEND
EXTERNAL RIGHT


function MainKalk(cKorisn, cSifra, p3, p4, p5, p6, p7)
local oKalk
local cModul

PUBLIC gKonvertPath:="D"

cModul:="KALK"
PUBLIC goModul

oKalk := TKalkMod():new(NIL, cModul, F18_VER, F18_VER_DATE , cKorisn, cSifra, p3,p4,p5,p6,p7)
goModul:=oKalk

oKalk:run()

return

