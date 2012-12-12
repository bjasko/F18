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

#include "fakt.ch"
#include "hbclass.ch"

CLASS TDbFakt INHERIT TDB 
	method New
	method install	
	method kreiraj	
ENDCLASS


// --------------------------------------------
// --------------------------------------------
method New()

 ::super:new()

 ::cName:="FAKT"
 ::lAdmin:=.f.

 ::kreiraj()

return self




method install()
	install_start(goModul, .f.)
return



method Kreiraj(nArea)
local lPoNarudzbi := .f.
local glDistrib := .f.

cDirRad := my_home()
cDirSif := my_home()
cDirPriv := my_home()

CreFMKPI()

if (nArea==nil)
	nArea:=-1
endif

Beep(1)

if (nArea<>-1)
	CreSystemDb(nArea)
endif

	

return


