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

#include "fmk.ch"


function f18_ime_dbf( xTableRec )

   LOCAL _pos
   LOCAL _a_dbf_rec
   LOCAL _ret
 

   SWITCH VALTYPE( xTableRec ) 

   CASE "H"
      _a_dbf_rec := xTableRec
      EXIT
   CASE "C"
      _a_dbf_rec := get_a_dbf_rec( FILEBASE( xTableRec, .t. ) )
     EXIT
   OTHERWISE
      Alert( "f1_ime_dbf arg ?! " + hb_valToStr( xTableRec ) )
   ENDSWITCH
  
    if _a_dbf_rec[ "table" ] == "x"
        Alert( "f18_ime_dbf alias :" + ToStr( xTableRec ) )
    endif

    _ret := my_home() + _a_dbf_rec["table"] + "." + DBFEXT

return _ret



/*
   uzima sva polja iz tekuceg dbf zapisa
*/
FUNCTION dbf_get_rec()

   LOCAL _ime_polja, _i, _struct
   LOCAL _ret := hb_Hash()

   _struct := dbStruct()
   FOR _i := 1 TO Len( _struct )

      _ime_polja := _struct[ _i, 1 ]

      IF !( "#" + _ime_polja + "#" $ "#BRISANO#_OID_#_COMMIT_#" )
         _ret[ Lower( _ime_polja ) ] := Eval( FieldBlock( _ime_polja ) )
      ENDIF

   NEXT

   RETURN _ret


/*
     is_dbf_struktura_polja_identicna( "racun", "BRDOK", 8, 0)

    => .T. ako je racun, brdok C(8, 0)

    => .F.  ako je racun.brdok npr. C(6,0)
    => .F.  ako je racun.brdok polje ne postoji
*/
FUNCTION is_dbf_struktura_polja_identicna( cTable, cPolje, nLen, nWidth )

   my_use( cTable )

   IF FieldPos( cPolje ) == 0
      USE
      RETURN .F.
   ENDIF

   SWITCH ValType( cPolje )

   CASE "C"
      IF Len( Eval( FieldBlock( cPolje ) ) ) != nLen
         USE
         RETURN .F.
      ENDIF
      EXIT
   OTHERWISE
      USE
      RaiseError( "implementirano samo za C polja" )

   ENDSWITCH

   USE

   RETURN .T.


FUNCTION my_reccount()
   RETURN RecCount()

FUNCTION my_delete()
   RETURN delete_with_rlock()

FUNCTION my_delete_with_pack()

   my_delete()

   RETURN my_dbf_pack()

FUNCTION delete_with_rlock()

   IF my_rlock()
      DELETE
      my_unlock()
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF

/*
   ferase_dbf( "konto", .T. ) => izbriši tabelu "konto.dbf"
                                 (kao i pripadajuće indekse)

   - lSilent (default .T.)
     .F. => pitaj korisnika da li želi izbrisati tabelu
     .T. => briši bez pitanja
*/

FUNCTION ferase_dbf( tbl_name, lSilent )

   LOCAL _tmp, _odg

   IF lSilent == NIL
      lSilent := .T.
   ENDIF

   IF !lSilent

      _odg := Pitanje(, "Izbrisati dbf tabelu " + tbl_name + " (L-quit) ?!", "N" )

      IF _odg == "L"
         log_write( "ferase_dbf quit: " + tbl_name, 3 )
         QUIT_1
      ENDIF

      IF _odg == "N"
         RETURN .F.
      ENDIF

   ENDIF

   log_write( "ferase_dbf : " + tbl_name, 3 )
   tbl_name := f18_ime_dbf( tbl_name )

   IF File( tbl_name )
      IF FErase( tbl_name ) != 0
         log_write( "ferase_dbf : " + tbl_name + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   _tmp := StrTran( tbl_name, DBFEXT, INDEXEXT )
   IF File( _tmp )
      log_write( "ferase_dbf, brisem: " + _tmp, 3 )
      IF FErase( _tmp ) != 0
         log_write( "ferase_dbf : " + _tmp + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   _tmp := StrTran( tbl_name, DBFEXT, MEMOEXT )
   IF File( _tmp )
      log_write( "ferase, brisem: " + _tmp, 3 )
      IF FErase( _tmp ) != 0
         log_write( "ferase_dbf : " + _tmp + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.


// ------------------------------------------
// kreira sve potrbne indekse
// ------------------------------------------
FUNCTION repair_dbfs()

   LOCAL _ver

   _ver := read_dbf_version_from_config()

   cre_all_dbfs( _ver )

   RETURN




// ------------------------------------------------------
// open exclusive, open_index - otvoriti index
// ------------------------------------------------------
FUNCTION reopen_shared( dbf_table, open_index )
   RETURN reopen_dbf( .F., dbf_table, open_index )



FUNCTION reopen_exclusive( dbf_table, open_index )
   RETURN reopen_dbf( .T., dbf_table, open_index )


FUNCTION reopen_dbf( excl, dbf_table, open_index )

   LOCAL _a_dbf_rec
   LOCAL _dbf
   LOCAL lRet
   LOCAL cMsg

   IF open_index == NIL
      open_index := .T.
   ENDIF

   _a_dbf_rec  := get_a_dbf_rec( dbf_table, .T. )

   IF _a_dbf_rec[ "sql" ]
        RETURN .F.
   ENDIF

   SELECT ( _a_dbf_rec[ "wa" ] )
   USE

   _dbf := my_home() + _a_dbf_rec[ "table" ]

   BEGIN SEQUENCE WITH {| err| Break( err ) }

      dbUseArea( .F., DBFENGINE, _dbf, _a_dbf_rec[ "alias" ], iif( excl, .F., .T. ), .F. )

      IF open_index
         IF File( ImeDbfCdx( _dbf ) )
            dbSetIndex( ImeDbfCDX( _dbf ) )
         ENDIF
         lRet := .T.
      ENDIF

   RECOVER USING _err

         cMsg := "ERROR reopen_dbf: " + _err:description + ": tbl:" + _dbf + " excl:" + ToStr( excl )
         log_write( cMsg, 2 )
         lRet := .F.

   END SEQUENCE

   RETURN lRet


// ------------------------------------------------------
// zap, then open shared, open_index - otvori index
// ------------------------------------------------------
FUNCTION reopen_exclusive_and_zap( dbf_table, open_index )

   LOCAL _a_dbf_rec
   LOCAL _dbf
   LOCAL _idx

   IF open_index == NIL
      open_index := .T.
   ENDIF



   BEGIN SEQUENCE WITH {| err | Break( err ) }

      reopen_dbf( .T., dbf_table, open_index )
      ZAP
      reopen_dbf( .F., dbf_table, open_index )

   RECOVER USING _err

      reopen_dbf( .F., dbf_table, open_index )
      zapp()

   END SEQUENCE

   RETURN .T.


FUNCTION my_dbf_zap( cTabelaOrAlias )
   
   LOCAL cAlias
   LOCAL lRet

   IF cTabelaOrAlias  != NIL
      cAlias := get_a_dbf_rec( cTabelaOrAlias )[ "alias" ]
   ELSE
      cAlias := Alias()
   ENDIF

   PushWa()
   lRet := reopen_exclusive_and_zap( cAlias, .T. )
   PopWa()

   RETURN lRet   
 
FUNCTION my_dbf_pack( lOpenUSharedRezimu )

   LOCAL lRet

   IF lOpenUSharedRezimu == NIL
      lOpenUSharedRezimu := .T.
   ENDIF

   PushWa()
   lRet :=  reopen_dbf( .T., Alias(), .T. )

   IF lRet
      __dbPack()
   ENDIF

   IF lRet .AND. lOpenUSharedRezimu
     lRet := reopen_dbf( .F., Alias(), .T. )
   ENDIF

   PopWa()
   RETURN lRet



FUNCTION pakuj_dbf( a_dbf_rec, lSilent )

   log_write( "PACK table " + a_dbf_rec[ "alias" ], 2 )

   BEGIN SEQUENCE WITH {| err| Break( err ) }

      SELECT ( a_dbf_rec[ "wa" ] )
      my_use_temp( a_dbf_rec[ "alias" ], my_home() + a_dbf_rec[ "table" ], .F., .T. )


      IF ! lSilent
         Box( "#Molimo sačekajte...", 7, 60 )
         @ m_x + 7, m_y + 2 SAY8 "Pakujem tabelu radi brzine, molim sačekajte ..."
      ENDIF

      PACK

      DO WHILE .T.
         USE
         IF Used()
            hb_idleSleep( 2 )
         ELSE
            EXIT
         ENDIF
      ENDDO

      IF ! lSilent
         BoxC()
      ENDIF

   RECOVER using _err
      log_write( "NOTIFY: PACK neuspjesan dbf: " + a_dbf_rec[ "table" ] + "  " + _err:Description, 3 )

   END SEQUENCE

   RETURN






FUNCTION full_table_synchro()

   LOCAL _sifra := Space( 6 ), _full_table_name, _alias := PadR( "PAROBR", 30 )

   Box( , 3, 60 )
   @ m_x + 1, m_y + 2 SAY " Admin sifra :" GET  _sifra PICT "@!"
   @ m_x + 2, m_y + 2 SAY "Table alias  :"  GET _alias PICTURE "@S20"
   READ
   BoxC()

   IF ( LastKey() == K_ESC ) .OR. ( Upper( AllTrim( _sifra ) ) != "F18AD" )
      MsgBeep( "nista od ovog posla !" )
      RETURN .F.
   ENDIF

   _alias := AllTrim( Upper( _alias ) )

   CLOSE ALL
   _full_table_name := f18_ime_dbf( _alias )

   IF File( _full_table_name )
      ferase_dbf( _alias )
   ELSE
      MsgBeep( "ove dbf tabele nema: " + _full_table_name )
   ENDIF

   post_login()

   RETURN .T.


STATIC FUNCTION zatvori_dbf( value )

   SELECT( value[ 'wa' ] )

   IF Used()
      // ostalo je još otvorenih DBF-ova
      USE
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF



FUNCTION dbf_open_and_count( a_dbf_rec, cnt, del )

   SELECT ( a_dbf_rec[ "wa" ] )
   my_use_temp( a_dbf_rec[ "alias" ], my_home() + a_dbf_rec[ "table" ], .F., .F. ) // new_area = .F. , eksluzivno = .F.

   SET DELETED OFF

   SET ORDER TO TAG "DEL"
   COUNT TO del
   cnt := RecCount()

   USE
   SET DELETED ON

   RETURN .T.
