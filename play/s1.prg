#include "hbclass.ch"

CREATE CLASS Class1

   VAR nArea
   VAR cArea

   METHOD New()
   METHOD m1()

ENDCLASS


METHOD Class1:New()

  RETURN Self

METHOD Class1:m1()

  ? ::nArea, SELECT( ::nArea )
  ? ::cArea, SELECT( ::cArea )

  ? my_dbSelectArea( ::cArea )
  SELECT ::cArea
  USE 
  RETURN .T.


procedure main()

  ? "start"
  oInstance := Class1():New()

  oInstance:nArea := 1
  oInstance:cArea := "X"

  oInstance:m1()

  inkey(0)
RETURN
