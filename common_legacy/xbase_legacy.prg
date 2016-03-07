/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


STATIC aBoxStack := {}
STATIC nPos := 0
STATIC cPokPonovo := "Pokušati ponovo (D/N) ?"
STATIC nPreuseLevel := 0



FUNCTION Gather( cZn )

   LOCAL i, aStruct
   LOCAL _field_b
   LOCAL _ime_p
   LOCAL cVar

   IF cZn == nil
      cZn := "_"
   ENDIF
   aStruct := dbStruct()

   FOR i := 1 TO Len( aStruct )
      _field_b := FieldBlock( _ime_p := aStruct[ i, 1 ] )

      // cImeP - privatna var
      cVar := cZn + _ime_p

      // rlock()
      // IF "U" $ TYPE(cVar)
      // MsgBeep2("Neuskladj.strukt.baza! F-ja: GATHER(), Alias: " + ALIAS() + ", Polje: " + _ime_p)
      // ELSE
      Eval( _field_b, Eval( MemVarBlock( cVar ) ) )
      // ENDIF

      // dbunlock()
   NEXT

   RETURN NIL


/*! \fn Scatter(cZn)
  * \brief vrijednosti field varijabli tekuceg sloga prebacuje u public varijable
  *
  * \param cZn - Default = "_"; odredjuje prefixs varijabli koje ce generisati
  *
  * \code
  *
  *  use ROBA
  *  Scatter("_")
  *  ? _id, _naz, _jmj
  *
  * \endcode
  *
  */

FUNCTION Scatter( cZn )
   RETURN set_global_vars_from_dbf( cZn )


FUNCTION GatherR( cZn )

   LOCAL i, j, aStruct

   IF cZn == nil
      cZn := "_"
   ENDIF
   aStruct := dbStruct()
   SkratiAZaD( @aStruct )
   WHILE .T.

      FOR j := 1 TO Len( aRel )
         IF aRel[ j, 1 ] == Alias()  // {"K_0","ID","K_1","ID",1}
            // matrica relacija
            cVar := cZn + aRel[ j, 2 ]
            xField := &( aRel[ j, 2 ] )
            if &cVar == xField // ako nije promjenjen broj
               LOOP
            ENDIF
            SELECT ( aRel[ j, 3 ] ); SET ORDER TO aRel[ j, 5 ]
            DO WHILE .T.
               IF FLock()
                  SEEK xField
                  DO while &( aRel[ j, 4 ] ) == xField .AND. !Eof()
                     SKIP
                     nRec := RecNo()
                     SKIP -1
                     field->&( aRel[ j, 4 ] ) := &cVar
                     GO nRec
                  ENDDO

               ELSE
                  Inkey( 0.4 )
                  LOOP
               ENDIF
               EXIT
            ENDDO // .t.
            SELECT ( aRel[ j, 1 ] )
         ENDIF
      NEXT    // j


      FOR i := 1 TO Len( aStruct )
         cImeP := aStruct[ i, 1 ]
         cVar := cZn + cImeP
         field->&cImeP := &cVar
      NEXT
      EXIT
   END

   RETURN NIL


/*! \fn Gather2(cZn)
*   \brief Gather ne versi rlock-unlock
*   \note Gather2 pretpostavlja zakljucan zapis !!
*/

FUNCTION Gather2( zn )

   LOCAL _i, _struct
   LOCAL _field_b, _var

   IF zn == nil
      zn := "_"
   ENDIF

   _struct := dbStruct()

   FOR _i := 1 TO Len( _struct )
      _ime_p := _struct[ _i, 1 ]
      _field_b := FieldBlock( _ime_p )
      _var :=  zn + _ime_p

      IF  !( "#" + _ime_p + "#"  $ "#BRISANO#_SITE_#_OID_#_USER_#_COMMIT_#_DATAZ_#_TIMEAZ_#" )
         Eval( _field_b, Eval( MemVarBlock( _var ) ) )
      ENDIF
   NEXT

   RETURN


FUNCTION delete2()

   LOCAL nRec

   DO WHILE .T.

      IF my_rlock()
         dbdelete2()
         my_unlock()
         EXIT
      ELSE
         Inkey( 0.4 )
         LOOP
      ENDIF

   ENDDO

   RETURN NIL


FUNCTION dbdelete2()

   IF !Eof() .OR. !Bof()
      dbDelete()
   ENDIF

   RETURN NIL


/*
*
* fcisti =  .t. - pocisti polja
*           .f. - ostavi stare vrijednosti polja
* funl    = .t. - otkljucaj zapis, pa zakljucaj zapis
*           .f. - ne diraj (pretpostavlja se da je zapis vec zakljucan)
*/

FUNCTION appblank2( fcisti, funl )

   LOCAL aStruct, i, nPrevOrd
   LOCAL cImeP

   IF fcisti == nil
      fcisti := .T.
   ENDIF

   nPrevOrd := IndexOrd()

   dbAppend( .T. )

   IF fcisti // ako zelis pocistiti stare vrijednosti
      aStruct := dbStruct()
      FOR i := 1 TO Len( aStruct )
         cImeP := aStruct[ i, 1 ]
         IF !( "#" + cImeP + "#"  $ "#BRISANO#_OID_#_COMMIT_#" )
            DO CASE
            CASE aStruct[ i, 2 ] == 'C'
               field->&cImeP := ""
            CASE aStruct[ i, 2 ] == 'N'
               field->&cImeP := 0
            CASE aStruct[ i, 2 ] == 'D'
               field->&cImeP := CToD( "" )
            CASE aStruct[ i, 2 ] == 'L'
               field->&cImeP := .F.
            ENDCASE
         ENDIF
      NEXT
   ENDIF  // fcisti

   ordSetFocus( nPrevOrd )

   RETURN NIL


/*! \fn AppFrom(cFDbf, fOtvori)
*  \brief apenduje iz cFDbf-a u tekucu tabelu
*  \param cFDBF - ime dbf-a
*  \param fOtvori - .t. - otvori DBF, .f. - vec je otvorena
*/

FUNCTION AppFrom( cFDbf, fOtvori )

   LOCAL nArr

   nArr := Select()

   cFDBF := ToUnix( cFDBF )

   DO WHILE .T.
      IF !FLock()
         Inkey( 0.4 )
         LOOP
      ENDIF
      EXIT
   ENDDO

   IF fotvori
      USE ( cFDbf ) new
   ELSE
      SELECT ( cFDbF )
   ENDIF

   GO TOP

   DO WHILE !Eof()
      SELECT ( nArr )
      Scatter( "f" )

      SELECT ( cFDBF )
      Scatter( "f" )

      SELECT ( nArr )   // prebaci se u tekuci fajl-u koji zelis staviti zapise
      appblank2( .F., .F. )
      Gather2( "f" ) // pretpostavlja zakljucan zapis

      SELECT ( cFDBF )
      SKIP
   ENDDO
   IF fOtvori
      USE // zatvori from DBF
   ENDIF

   dbUnlock()
   SELECT ( nArr )

   RETURN .T.



FUNCTION PrazanDbf()
   RETURN .F.





FUNCTION seek2( cArg )

   dbSeek( cArg )

   RETURN NIL

// -------------------------------------------------------------------
// brise sve zapise - ako jmarkira za brisanje sve zapise u bazi
// ako je exclusivno otvorena - __dbZap, ako je shared,
// markiraj za deleted sve zapise
//
// - pack - prepakuj zapise
// -------------------------------------------------------------------

FUNCTION zapp( pack )

   LOCAL bErr
   LOCAL cLogMsg := "", cMsg, nI

   IF !Used()
      RETURN .F.
   ENDIF

   IF pack == NIL
      pack := .F.
   ENDIF


   BEGIN SEQUENCE WITH {| err | Break( err ) }

      __dbZap()
      LOG_CALL_STACK cLogMsg
      log_write( "ZAP exclusive: " + Alias(), 5 )
      ?E "zap exclusive ", Alias(), cLogMsg
      IF PACK
         __dbPack()
      ENDIF

   RECOVER

      log_write( "ZAP shared: " + Alias(), 5 )
      LOG_CALL_STACK cLogMsg
      ?E "zap shared: ", Alias(), cLogMsg
      PushWA()
      DO WHILE .T.
         SET ORDER TO 0
         GO TOP
         DO WHILE !Eof()
            delete_with_rlock()
            SKIP
         ENDDO
         EXIT
      ENDDO
      PopWa()

   END SEQUENCE

   RETURN NIL


FUNCTION nErr( oe )

   break oe

/*  EofFndRet(ef, close)
 *  Daje poruku da ne postoje podaci
 *  param ef = .t.   gledaj eof();  ef == .f. gledaj found()
 *  return  .t. ako ne postoje podaci
 */

FUNCTION EofFndRet( ef, close )

   LOCAL fRet := .F., cStr := "Ne postoje traženi podaci.."

   IF ef // eof()
      IF Eof()
         Beep( 1 )
         Msg( cStr, 6 )
         fRet := .T.
      ENDIF
   ELSE
      IF !Found()
         Beep( 1 )
         Msg( cStr, 6 )
         fRet := .T.
      ENDIF
   ENDIF

   IF CLOSE .AND. fRet
      my_close_all_dbf()
   ENDIF

   RETURN fRet


/*! \fn spec_funkcije_sifra(cSif)
 *  \brief zasticene funkcije sistema
 *
 * za programske funkcije koje samo serviser
 * treba da zna, tj koje obicni korisniku
 * nece biti dokumentovane
 *
 * \note Default cSif=SIGMAXXX
 *
 * \return .t. kada je lozinka ispravna
*/

FUNCTION spec_funkcije_sifra( cSif )

   LOCAL lGw_Status

   lGw_Status := IF( "U" $ Type( "GW_STATUS" ), "-", gw_status )

   GW_STATUS := "-"

   IF cSif == NIL
      cSif := "SIGMAXXX"
   ELSE
      cSif := PadR( cSif, 8 )
   ENDIF

   Box(, 2, 70 )
   cSifra := Space( 8 )
   @ m_x + 1, m_y + 2 SAY "Sifra za koristenje specijalnih funkcija:"
   cSifra := Upper( GetSecret( cSifra ) )
   BoxC()

   GW_STATUS := lGW_Status

   IF AllTrim( cSifra ) == AllTrim( cSif )
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF



/*! \fn O_POMDB(nArea,cImeDBF)
 *  \brief otvori pomocnu tabelu, koja ako se nalazi na CDU npr se kopira u lokalni
 *   direktorij pa zapuje
 */

FUNCTION O_POMDB( nArea, cImeDBF )

   SELECT ( nArea )

   IF Right( Upper( cImeDBF ), 4 ) <> "." + DBFEXT
      cImeDBF := cImeDBf + "." + DBFEXT
   ENDIF
   cImeCDX := StrTran( Upper( cImeDBF ), "." + DBFEXT, "." + INDEXEXT )
   cImeCDX := ToUnix( cImeCDX )

   usex ( PRIVPATH + cImeDBF )

   RETURN




FUNCTION DbfArea( tbl, var )

   LOCAL _rec
   LOCAL _only_basic_params := .T.

   IF ( var == NIL )
      var := 0
   ENDIF

   _rec := get_a_dbf_rec( Lower( tbl ), _only_basic_params )

   RETURN _rec[ "wa" ]




FUNCTION NDBF( tbl )
   RETURN DbfArea( tbl )



FUNCTION NDBFPos( tbl )
   RETURN DbfArea( tbl, 1 )



FUNCTION F_Baze( tbl )

   LOCAL _dbf_tbl
   LOCAL _area := 0
   LOCAL _rec
   LOCAL _only_basic_params := .T.

   _rec := get_a_dbf_rec( Lower( tbl ), _only_basic_params )

   // ovo je work area
   IF _rec <> NIL
      _area := _rec[ "wa" ]
   ENDIF

   IF _area <= 0
      my_close_all_dbf()
      QUIT
   ENDIF

   RETURN _area



FUNCTION Sel_Bazu( tbl )

   LOCAL _area

   _area := F_baze( tbl )

   IF _area > 0
      SELECT ( _area )
   ELSE
      my_close_all_dbf()
      QUIT
   ENDIF

   RETURN


FUNCTION gaDBFDir( nPos )
   RETURN my_home()



FUNCTION O_Bazu( tbl )

   my_use( Lower( tbl ) )

   RETURN



FUNCTION ExportBaze( cBaza )

   LOCAL nArr := Select()

   FErase( cBaza + "." + INDEXEXT )
   FErase( cBaza + "." + DBFEXT )
   cBaza += "." + DBFEXT
   COPY STRUCTURE EXTENDED TO ( PRIVPATH + "struct" )
   CREATE ( cBaza ) FROM ( PRIVPATH + "struct" ) NEW
   MsgO( "apendujem..." )
   APPEND FROM ( Alias( nArr ) )
   MsgC()
   USE
   SELECT ( nArr )

   RETURN


/*
  ImdDBFCDX(cIme)
    suban     -> suban.CDX
    suban.DBF -> suban.CDX
*/
FUNCTION ImeDBFCDX( cIme, ext )

   IF ext == NIL
      ext := INDEXEXT
   ENDIF

   cIme := Trim( StrTran( ToUnix( cIme ), "." + DBFEXT, "." + ext ) )

   IF Right ( cIme, 4 ) <> "." + ext
      cIme := cIme + "." + ext
   ENDIF

   RETURN  cIme