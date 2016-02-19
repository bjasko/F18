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


STATIC lVindija := .F.
STATIC lUgovori := .F.
STATIC lRamaGlas := .F.



/*! \fn set_vars_za_specificne_slucajeve()
 *  \brief Setuje globalne varijable za specificne korisnike
 */

FUNCTION set_vars_za_specificne_slucajeve()


   IF IzFmkIni( "FMK", "Vindija", "N", KUMPATH ) == "D"
      SetVindija( .T. )
   ELSE
      SetVindija( .F. )
   ENDIF


   IF IzFmkIni( "FMK", "Ugovori", "N", KUMPATH ) == "D"
      SetUgovori( .T. )
   ELSE
      SetUgovori( .F. )
   ENDIF

   IF IzFmkIni( "FMK", "RamaGlas", "N", KUMPATH ) == "D"
      SetRamaGlas( .T. )
   ELSE
      SetRamaGlas( .F. )
   ENDIF




   RETURN .T.





FUNCTION IsVindija()


   RETURN lVindija


FUNCTION SetVindija( lValue )


   lVindija := lValue




FUNCTION IsUgovori()


   RETURN lUgovori


FUNCTION SetUgovori( lValue )


   lUgovori := lValue


FUNCTION IsRabati()

   // {

   RETURN lRabati
// }

FUNCTION SetRabati( lValue )

   // {
   lRabati := lValue
   // }

FUNCTION IsRamaGlas()


   RETURN lRamaGlas



FUNCTION SetRamaGlas( lValue )


   lRamaGlas := lValue
