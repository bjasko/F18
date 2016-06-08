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


FUNCTION fin_izvjestaji_ostali()

   PRIVATE Izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   AAdd( opc, "1. pregled promjena na računu               " )
   AAdd( opcexe, {|| PrPromRn() } )

   IF ( IsRamaGlas() )
      AAdd( opc, "P. specifikacije za pogonsko knjigovodstvo" )
      AAdd( opcexe, {|| IzvjPogonK() } )
   ENDIF

   Menu_SC( "ost" )

   RETURN .F.