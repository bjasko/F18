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


FUNCTION datotp_prazan()

   IF field->datotp < SToD( "10010101" ) // 1000-01-01
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION get_datotp()

   IF field->datotp < SToD( "10010101" )
      RETURN CToD( "" )
   ENDIF

   RETURN field->datotp