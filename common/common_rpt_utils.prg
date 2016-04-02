#include "f18.ch"


/* FormDat1(dUlazni)
 *     formatira datum sa stoljecem (dUlazni)=> cDat
 *   param: dUlazni - ulazni datum
 */

FUNCTION FormDat1( dUlazni )

   LOCAL cVrati

   SET CENTURY ON
   cVrati := DToC( dUlazni ) + "."
   SET CENTURY OFF

   RETURN cVrati
