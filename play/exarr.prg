REQUEST ARRAYRDD

#define USE_DBCREATE_EXTENSIONS

PROCEDURE exarr()

   LOCAL aStruct := { ;
      { "NAME"     , "C", 40, 0 }, ;
      { "ADDRESS"  , "C", 40, 0 }, ;
      { "BIRTHDAY" , "D",  8, 0 }, ;
      { "AGE"      , "N",  3, 0 } }

   Set( _SET_DATEFORMAT, "yyyy-mm-dd" )
   CLS

   ? "Create a new dbf in memory using dbCreate() command"

#ifndef USE_DBCREATE_EXTENSIONS
   ? "Create it"
   dbCreate( "arrtest.dbf", aStruct, "ARRAYRDD" )
   WAIT
   ? "Open it"
   USE arrtest.dbf VIA "ARRAYRDD"
   WAIT
#else
   ? "Create it and leave opened"
   dbCreate( "arrtest.dbf", aStruct, "ARRAYRDD", .T., "arrtest" )
   WAIT
#endif

   ? "Show structure"
   ? hb_ValToExp( dbStruct() )
   WAIT

   ? "ALIAS", Alias(), "RECNO", RecNo(), ;
      "BOF", Bof(), "EOF", Eof(), "LASTREC", LastRec()
   ? RecNo(), '"' + FIELD->NAME + '"'
   dbGoBottom()
   ? RecNo(), '"' + FIELD->NAME + '"'
   dbGoTop()
   ? RecNo(), '"' + FIELD->NAME + '"'
   WAIT

   ? "Adding some data"
   dbAppend()
   field->name     := "Giudice Francesco Saverio"
   field->address  := "Main Street 10"
   field->birthday := hb_SToD( "19670103" )
   field->age      := 39

   ? RecNo(), '"' + FIELD->NAME + '"'

   dbAppend()
   field->name     := "Mouse Mickey"
   field->address  := "Main Street 20"
   field->birthday := hb_SToD( "19400101" )
   field->age      := 66

   DO WHILE ! Eof()
      ? RecNo(), '"' + FIELD->NAME + '"'
      IF RecNo() == 20
         Inkey( 0 )
      ENDIF
      dbSkip()
   ENDDO
   ? "ALIAS", Alias(), "RECNO", RecNo(), ;
      "BOF", Bof(), "EOF", Eof(), "LASTREC", LastRec()
   WAIT
   dbGoBottom()
   ? "ALIAS", Alias(), "RECNO", RecNo(), ;
      "BOF", Bof(), "EOF", Eof(), "LASTREC", LastRec()
   WAIT
   DO WHILE ! Bof()
      ? RecNo(), '[' + FIELD->NAME + ']'
      IF RecNo() == LastRec() - 20
         Inkey( 0 )
      ENDIF
      dbSkip( -1 )
   ENDDO
   ? "ALIAS", Alias(), "RECNO", RecNo(), ;
      "BOF", Bof(), "EOF", Eof(), "LASTREC", LastRec()
   WAIT

   ? "Show it - Please don't press any key except movement keys and ESC"
   ? "          to exit from Browse(), otherwise you will get an error"
   ? "          due to missing index support"
   WAIT
   Browse()

   RETURN
