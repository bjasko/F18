#include "f18.ch"

FUNCTION MainEpdv( cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oEpdv
   LOCAL cModul

   cModul := "EPDV"
   PUBLIC goModul

   oEpdv := TEpdvMod():new( NIL, cModul, f18_ver(), f18_ver_date(), cKorisn, cSifra, p3, p4, p5, p6, p7 )
   goModul := oEpdv

   oEpdv:run()

   RETURN .T.
