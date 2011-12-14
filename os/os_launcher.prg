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

#include "os.ch"
#include "f18_ver.ch"

EXTERNAL DESCEND
EXTERNAL RIGHT


function MainOs(cKorisn, cSifra, p3, p4, p5, p6, p7)
local oOs
local cModul

PUBLIC gKonvertPath:="D"

cModul:="OS"
PUBLIC goModul

oOs := TOsMod():new(NIL, cModul, F18_VER, F18_VER_DATE, cKorisn, cSifra, p3,p4,p5,p6,p7)
goModul:=oOs

oOs:run()

return

