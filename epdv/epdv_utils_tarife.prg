#include "f18.ch"

FUNCTION s_tarifa( cIdTar )

   LOCAL cPom

   PushWA()

   SELECT ( F_TARIFA )

   IF !select_o_tarifa( cIdTar )
      cPom := "-NEP.TAR- ?!"
   ELSE
      cPom := AllTrim( field->naz )
   ENDIF

   PopWa()

   RETURN cPom



FUNCTION get_stopa_pdv_za_tarifu( cIdTar )

   LOCAL nStopa

   PushWA()

   IF !select_o_tarifa( PadR( cIdTar, 6 ) )
      nStopa := -999
   ELSE
      nStopa := tarifa->pdv
   ENDIF

   PopWa()

   RETURN nStopa
