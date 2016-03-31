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



FUNCTION pos_init_dbfs()

   my_close_all_dbf()

   pos_definisi_inicijalne_podatke()
   cre_priprz()

   RETURN .T.


STATIC FUNCTION cre_priprz()

   LOCAL cFileName := PRIVPATH + "PRIPRZ"
   LOCAL lCreate := .F.

   IF !File( f18_ime_dbf( "priprz" ) )
      lCreate := .T.
   ELSE
      CLOSE ALL
      O_PRIPRZ
      IF reccount2() > 0
         RETURN .F.
      ENDIF

      IF FieldPos( "k7" ) == 0
         lCreate := .T.
      ENDIF
   ENDIF

   CLOSE ALL
   IF lCreate
      aDbf := g_pos_pripr_fields()
      DBcreate2 ( cFileName, aDbf )
      CREATE_INDEX ( "1", "IdRoba", cFileName )
   ENDIF

   RETURN .T.




FUNCTION o_pos_doks()
   RETURN o_dbf_table( F_POS_DOKS, "pos_doks", "1" )

FUNCTION o_pos_pos()
   RETURN o_dbf_table( F_POS_POS, "pos_pos", "1" )

FUNCTION o_pos_osob()
   RETURN o_dbf_table( F_OSOB, "osob", "ID" )


FUNCTION o_pos_strad()
   RETURN o_dbf_table( F_STRAD, "strad", "ID" )

FUNCTION o_pos_kase()
   RETURN o_dbf_table( F_KASE, "kase", "ID" )



STATIC FUNCTION dodaj_u_sifrarnik_prioriteta( cSifra, cPrioritet, cOpis )

   LOCAL lOk := .T.
   LOCAL _rec

   IF Select( "STRAD" ) == 0
      o_pos_strad()
   ELSE
      SELECT STRAD
   ENDIF

   APPEND BLANK

   _rec := dbf_get_rec()
   _rec[ "id" ] := PadR( cSifra, Len( _rec[ "id" ] ) )
   _rec[ "prioritet" ] := PadR( cPrioritet, Len( _rec[ "prioritet" ] ) )
   _rec[ "naz" ] := PadR( cOpis, Len( _rec[ "naz" ] ) )

   lOk := update_rec_server_and_dbf( "pos_strad", _rec, 1, "CONT" )

   RETURN lOk




STATIC FUNCTION dodaj_u_sifrarnik_radnika( cSifra, cLozinka, cOpis, cStatus )

   LOCAL lOk := .T.
   LOCAL _rec

   IF Select( "OSOB" ) == 0
      o_pos_osob()
   ELSE
      SELECT OSOB
   ENDIF

   APPEND BLANK

   _rec := dbf_get_rec()
   _rec[ "id" ] := PadR( cSifra, Len( _rec[ "id" ] ) )
   _rec[ "korsif" ] := PadR( CryptSc( PadR( cLozinka, 6 ) ), 6 )
   _rec[ "naz" ] := PadR( cOpis, Len( _rec[ "naz" ] ) )
   _rec[ "status" ] := PadR( cStatus, Len( _rec[ "status" ] ) )

   lOk := update_rec_server_and_dbf( "pos_osob", _rec, 1, "CONT" )

   RETURN lOk



STATIC FUNCTION pos_definisi_inicijalne_podatke()

   LOCAL lOk := .T.

   O_STRAD

   IF ( RECCOUNT2() == 0 )

      MsgO( "Definišem šifre prioriteta ..." )

      // sql_table_update( nil, "BEGIN" )
      IF !f18_lock_tables( { "pos_strad" }, .T. )
         // sql_table_update( nil, "END" )
         RETURN .F.
      ENDIF

      lOk := dodaj_u_sifrarnik_prioriteta( "0", "0", "Nivo adm." )

      IF lOk
         lOk := dodaj_u_sifrarnik_prioriteta( "1", "1", "Nivo upr." )
      ENDIF

      IF lOk
         lOk := dodaj_u_sifrarnik_prioriteta( "3", "3", "Nivo prod." )
      ENDIF

      MsgC()

      IF lOk
         f18_free_tables( { "pos_strad" } )
         // sql_table_update( nil, "END" )
      ELSE
         // sql_table_update( nil, "ROLLBACK" )
      ENDIF

   ENDIF

   O_OSOB

   IF ( RECCOUNT2() == 0 )

      MsgO( "Definišem šifranik radnika ..." )

      // sql_table_update( nil, "BEGIN" )
      IF !f18_lock_tables( { "pos_osob" }, .T. )
         // sql_table_update( nil, "END" )
         RETURN .F.
      ENDIF

      lOk := dodaj_u_sifrarnik_radnika( "0001", "PARSON", "Admin", "0" )

      IF lOk
         lOk := dodaj_u_sifrarnik_radnika( "0010", "P1", "Prodavac 1", "3" )
      ENDIF

      IF lOk
         lOk := dodaj_u_sifrarnik_radnika( "0011", "P2", "Prodavac 2", "3" )
      ENDIF

      MsgC()

      IF lOk
         f18_free_tables( { "pos_osob" } )
         // sql_table_update( nil, "END" )
      ELSE
         // sql_table_update( nil, "ROLLBACK" )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN .T.


FUNCTION o_pos_tables( lOtvoriKumulativ )

   my_close_all_dbf()

   IF lOtvoriKumulativ == NIL
      lOtvoriKumulativ := .T.
   ENDIF

   IF lOtvoriKumulativ
      o_pos_kumulativne_tabele()
   ENDIF

   O_ODJ
   O_OSOB
   SET ORDER TO TAG "NAZ"

   O_VRSTEP
   O_PARTN
   O_DIO
   O_K2C
   O_MJTRUR
   O_KASE
   O_SAST
   O_ROBA
   O_TARIFA
   O_SIFK
   O_SIFV
   O_PRIPRZ
   O_PRIPRG
   O__POS
   O__POS_PRIPR

   IF lOtvoriKumulativ
      SELECT pos_doks
   ELSE
      SELECT _pos_pripr
   ENDIF

   RETURN .T.


STATIC FUNCTION o_pos_kumulativne_tabele()

   O_POS
   O_POS_DOKS
   O_DOKSPF

   RETURN .T.



FUNCTION o_pos_sifre()

   O_KASE
   O_UREDJ
   O_ODJ
   O_ROBA
   O_TARIFA
   O_VRSTEP
   O_VALUTE
   O_PARTN
   O_OSOB
   O_STRAD
   O_SIFK
   O_SIFV

   RETURN .T.



FUNCTION pos_iznos_racuna( cIdPos, cIdVD, dDatum, cBrDok )

   LOCAL cSql, oData, oRow
   LOCAL nTotal := 0

   IF PCount() == 0
      cIdPos := pos_doks->IdPos
      cIdVD := pos_doks->IdVD
      dDatum := pos_doks->Datum
      cBrDok := pos_doks->BrDok
   ENDIF

   cSql := "SELECT "
   cSql += " SUM( ( kolicina * cijena ) - ( kolicina * ncijena ) ) AS total "
   cSql += "FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos "
   cSql += "WHERE "
   cSql += " idpos = " + sql_quote( cIdPos )
   cSql += " AND idvd = " + sql_quote( cIdVd )
   cSql += " AND brdok = " + sql_quote( cBrDok )
   cSql += " AND datum = " + sql_quote( dDatum )

   oData := run_sql_query( cSql )

   IF !is_var_objekat_tpqquery( oData )
      RETURN nTotal
   ENDIF

   nTotal := oData:FieldGet( 1 )

   RETURN nTotal



FUNCTION pos_stanje_artikla( id_pos, id_roba )

   LOCAL _qry, _qry_ret, _table
   LOCAL _data := {}
   LOCAL _i, oRow
   LOCAL _stanje := 0

   _qry := "SELECT SUM( CASE WHEN idvd IN ('16') THEN kolicina WHEN idvd IN ('42') THEN -kolicina WHEN idvd IN ('IN') THEN -(kolicina - kol2) ELSE 0 END ) AS stanje FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos " + ;
      " WHERE idpos = " + sql_quote( id_pos ) + ;
      " AND idroba = " + sql_quote( id_roba )

   _table := run_sql_query( _qry )
   oRow := _table:GetRow( 1 )
   _stanje := oRow:FieldGet( oRow:FieldPos( "stanje" ) )

   IF ValType( _stanje ) == "L"
      _stanje := 0
   ENDIF

   RETURN _stanje



FUNCTION pos_iznos_dokumenta( lUI )

   LOCAL cRet := Space( 13 )
   LOCAL l_u_i
   LOCAL nIznos := 0
   LOCAL cIdPos, cIdVd, cBrDok
   LOCAL dDatum

   SELECT pos_doks

   cIdPos := pos_doks->idPos
   cIdVd := pos_doks->idVd
   cBrDok := pos_doks->brDok
   dDatum := pos_doks->datum

   IF ( ( lUI == NIL ) .OR. lUI )
      // ovo su ulazi ...
      IF pos_doks->IdVd $ VD_ZAD + "#" + VD_PCS + "#" + VD_REK
         SELECT pos
         SET ORDER TO TAG "1"
         GO TOP
         SEEK cIdPos + cIdVd + DToS( dDatum ) + cBrDok
         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            nIznos += pos->kolicina * pos->cijena
            SKIP
         ENDDO
         IF pos_doks->idvd == VD_REK
            nIznos := -nIznos
         ENDIF
      ENDIF
   ENDIF

   IF ( ( lUI == NIL ) .OR. !lUI )
      // ovo su, pak, izlazi ...
      IF pos_doks->idvd $ VD_RN + "#" + VD_OTP + "#" + VD_RZS + "#" + VD_PRR + "#" + "IN" + "#" + VD_NIV
         SELECT pos
         SET ORDER TO TAG "1"
         GO TOP
         SEEK cIdPos + cIdVd + DToS( dDatum ) + cBrDok
         DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == cIdPos + cIdVd + DToS( dDatum ) + cBrDok
            DO CASE
            CASE pos_doks->idvd == "IN"
               // samo ako je razlicit iznos od 0
               // ako je 0 onda ne treba mnoziti sa cijenom
               IF pos->kol2 <> 0
                  nIznos += pos->kol2 * pos->cijena
               ENDIF
            CASE pos_doks->IdVd == VD_NIV
               nIznos += pos->kolicina * ( pos->ncijena - pos->cijena )
            OTHERWISE
               nIznos += pos->kolicina * pos->cijena
            ENDCASE
            SKIP
         ENDDO
      ENDIF
   ENDIF

   SELECT pos_doks
   cRet := Str( nIznos, 13, 2 )

   RETURN ( cRet )




// ------------------------------------------------------------------
// pos, uzimanje novog broja za tops dokument
// ------------------------------------------------------------------
FUNCTION pos_novi_broj_dokumenta( id_pos, tip_dokumenta, dat_dok )

   LOCAL _broj := 0
   LOCAL _broj_doks := 0
   LOCAL _param
   LOCAL _tmp, _rest
   LOCAL _ret := ""
   LOCAL _t_area := Select()

   IF dat_dok == NIL
      dat_dok := gDatum
   ENDIF

   _param := "pos" + "/" + id_pos + "/" + tip_dokumenta
   _broj := fetch_metric( _param, nil, _broj )

   O_POS_DOKS
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_pos + tip_dokumenta + DToS( dat_dok ) + "Ž"
   SKIP -1

   IF field->idpos == id_pos .AND. field->idvd == tip_dokumenta .AND. DToS( field->datum ) == DToS( dat_dok )
      _broj_doks := Val( field->brdok )
   ELSE
      _broj_doks := 0
   ENDIF

   _broj := Max( _broj, _broj_doks )

   ++ _broj

   _ret := PadL( AllTrim( Str( _broj ) ), 6  )

   set_metric( _param, nil, _broj )

   SELECT ( _t_area )

   RETURN _ret


FUNCTION pos_set_param_broj_dokumenta()

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _broj_old
   LOCAL _id_pos := gIdPos
   LOCAL _tip_dok := "42"

   Box(, 2, 60 )

   @ m_x + 1, m_y + 2 SAY "Dokument:" GET _id_pos
   @ m_x + 1, Col() + 1 SAY "-" GET _tip_dok

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN
   ENDIF

   _param := "pos" + "/" + _id_pos + "/" + _tip_dok
   _broj := fetch_metric( _param, nil, _broj )
   _broj_old := _broj

   @ m_x + 2, m_y + 2 SAY "Zadnji broj dokumenta:" GET _broj PICT "999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      IF _broj <> _broj_old
         set_metric( _param, nil, _broj )
      ENDIF
   ENDIF

   RETURN



FUNCTION pos_reset_broj_dokumenta( id_pos, tip_dok, broj_dok )

   LOCAL _param
   LOCAL _broj := 0

   _param := "pos" + "/" + id_pos + "/" + tip_dok
   _broj := fetch_metric( _param, nil, _broj )

   IF Val( AllTrim( broj_dok ) ) == _broj
      --_broj
      set_metric( _param, nil, _broj )
   ENDIF

   RETURN .T.



FUNCTION Del_Skip()

   LOCAL nNextRec

   nNextRec := 0
   SKIP
   nNextRec := RecNo()
   SKIP -1
   my_delete()
   GO nNextRec

   RETURN .T.



FUNCTION GoTop2()

   GO TOP
   IF Deleted()
      SKIP
   ENDIF

   RETURN .T.



/*
    Opis: da li ažurirani račun sadrži traženi artikal
 */

FUNCTION pos_racun_sadrzi_artikal( cIdPos, cIdVd, dDatum, cBroj, cIdRoba )

   LOCAL lRet := .F.
   LOCAL cWhere

   cWhere := " idpos " + sql_quote( cIdPos )
   cWhere += " AND idvd = " + sql_quote( cIdVd )
   cWhere += " AND datum = " + sql_quote( dDatum )
   cWhere += " AND brdok = " + sql_quote( cBroj )
   cWhere += " AND idroba = " + sql_quote( cIdRoba )

   IF table_count( F18_PSQL_SCHEMA_DOT + "pos_pos", cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet



FUNCTION pos_import_fmk_roba()

   LOCAL _location := fetch_metric( "pos_import_fmk_roba_path", my_user(), PadR( "", 300 ) )
   LOCAL _cnt := 0
   LOCAL _rec
   LOCAL lOk := .T.

   O_ROBA

   _location := PadR( AllTrim( _location ), 300 )

   Box(, 1, 60 )
   @ m_x + 1, m_y + 2 SAY "lokacija:" GET _location PICT "@S50"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "pos_import_fmk_roba_path", my_user(), _location )

   SELECT ( F_TMP_1 )
   IF Used()
      USE
   ENDIF

   my_use_temp( "TOPS_ROBA", AllTrim( _location ), .F., .T. )
   INDEX on ( "id" ) TAG "ID"

   SELECT tops_roba
   SET ORDER TO TAG "ID"
   GO TOP

   sql_table_update( nil, "BEGIN" )
   IF !f18_lock_tables( { "roba" }, .T. )
      sql_table_update( nil, "END" )
      RETURN .F.
   ENDIF

   Box(, 1, 60 )

   DO WHILE !Eof()

      _id_roba := field->id

      SELECT roba
      GO TOP
      SEEK _id_roba

      IF !Found()
         APPEND BLANK
      ENDIF

      _rec := dbf_get_rec()

      _rec[ "id" ] := tops_roba->id

      _rec[ "naz" ] := tops_roba->naz
      _rec[ "jmj" ] := tops_roba->jmj
      _rec[ "idtarifa" ] := tops_roba->idtarifa
      _rec[ "barkod" ] := tops_roba->barkod
      _rec[ "tip" ] := tops_roba->tip
      _rec[ "mpc" ] := tops_roba->cijena1
      _rec[ "mpc2" ] := tops_roba->cijena2

      IF tops_roba->( FieldPos( "fisc_plu" ) ) <> 0
         _rec[ "fisc_plu" ] := tops_roba->fisc_plu
      ENDIF

      ++ _cnt
      @ m_x + 1, m_y + 2 SAY "import roba: " + _rec[ "id" ] + ":" + PadR( _rec[ "naz" ], 20 ) + "..."
      lOk := update_rec_server_and_dbf( "roba", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT tops_roba
      SKIP

   ENDDO

   BoxC()

   IF lOk
      f18_free_tables( { "roba" } )
      sql_table_update( nil, "END" )
   ELSE
      sql_table_update( nil, "ROLLBACK" )
   ENDIF

   SELECT ( F_TMP_1 )
   USE

   IF lOk .AND. _cnt > 0
      MsgBeep( "Update " + AllTrim( Str( _cnt ) ) + " zapisa !" )
   ENDIF

   CLOSE ALL

   RETURN



FUNCTION pos_brisi_nepostojece_dokumente()

   LOCAL cSql, oQry
   LOCAL cIdPos, cIdVd, cBrDok, dDatum
   LOCAL nCount := 0

   IF !spec_funkcije_sifra( "ADMIN" )
      MsgBeep( "Opcija nije dostupna !" )
      RETURN .F.
   ENDIF

   cSql := "SELECT p.idpos, p.idvd, p.datum, p.brdok "
   cSql += "FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos p "
   cSql += "WHERE ( SELECT COUNT(*) FROM " + F18_PSQL_SCHEMA_DOT + "pos_doks d "
   cSql += "         WHERE d.idpos = p.idpos "
   cSql += "           AND d.idvd = p.idvd "
   cSql += "           AND d.datum = p.datum "
   cSql += "           AND d.brdok = p.brdok ) = 0 "
   cSql += "GROUP BY p.idpos, p.idvd, p.datum, p.brdok "
   cSql += "ORDER BY p.idpos, p.idvd, p.datum, p.brdok "

   MsgO( "SQL upit u toku, sačekajte trenutak ... " )
   oQry := run_sql_query( cSql )
   MsgC()

   IF !is_var_objekat_tpqquery( oQry )
      MsgBeep( "Problem sa SQL upitom !" )
      RETURN .F.
   ENDIF

   IF oQry:LastRec() > 0
      IF Pitanje(, "Izbrisati ukupno " + AllTrim( Str( oQry:LastRec() ) ) + " dokumenata (D/N) ?", "N" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   O_POS_DOKS
   O_POS

   oQry:GoTo( 1 )

   Box(, 1, 50 )

   DO WHILE !oQry:Eof()

      oRow := oQry:GetRow()

      dDatum := query_row( oRow, "datum" )
      cIdPos := query_row( oRow, "idpos" )
      cIdVd := query_row( oRow, "idvd" )
      cBrDok := query_row( oRow, "brdok" )

      @ m_x + 1, m_y + 2 SAY8 "Brišem dokument: " + cIdPos + "-" + cIdVd + "-" + cBrDok + " od datuma " + DToC( dDatum )

      IF !pos_brisi_dokument( cIdPos, cIdVd, dDatum, cBrDok )
         BoxC()
         MsgBeep( "Problem sa brisanjem dokumenta !" )
         RETURN .F.
      ENDIF

      ++ nCount

      oQry:Skip()

   ENDDO

   BoxC()

   IF nCount > 0
      MsgBeep( "Izbrisao ukupno " + AllTrim( Str( nCount ) ) + " dokumenta !"  )
   ENDIF

   RETURN .T.