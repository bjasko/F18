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

#include "f18.ch"

FUNCTION MainEpdv( cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oEpdv
   LOCAL cModul

   cModul := "EPDV"
   PUBLIC goModul

   oEpdv := TEpdvMod():new( NIL, cModul, f18_ver(), f18_ver()_DATE, cKorisn, cSifra, p3, p4, p5, p6, p7 )
   goModul := oEpdv

   oEpdv:run()

   RETURN .T.
