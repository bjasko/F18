/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"
#include "hbthread.ch"

#define F_TEST_SEM_1 9001
#define F_TEST_SEM_2 9002

FUNCTION test_semaphores()

   LOCAL nI
   LOCAL _ime_f
   LOCAL _dbf_struct := {}
   LOCAL _server_params
   LOCAL cQuery
   LOCAL _table_name, _alias
   LOCAL _thread_2_id
   LOCAL _rec

   _ime_f := "test_sem_1"


   cre_t_1( "test_sem_1", .T. )

   TEST_LINE( login_as( "admin" ), .T. )

   cQuery := "drop table if exists fmk." + _ime_f + "; "
   cQuery += "create table " + _ime_f + "("
   cQuery += " id varchar(4) PRIMARY KEY, naz varchar(20)"
   cQuery += "); "
   cQuery += "GRANT ALL ON TABLE fmk." + _ime_f + " TO xtrole;"

   run_sql_query( cQuery )

   create_semaphore( _ime_f )

   TEST_LINE( login_as( "test1" ), .T. )


   TEST_LINE( sql_concat_ids( "test_sem_2" ), "to_char(godina,'9999') || to_char(mjesec,'99') || oznaka" )

   _dbf_struct := {}
   AAdd( _dbf_struct,      { 'godina',  'N',   4,  0 } )
   AAdd( _dbf_struct,      { 'mjesec',  'N',   2,  0 } )
   AAdd( _dbf_struct,      { 'oznaka',  'C',   2,  0 } )
   AAdd( _dbf_struct,      { 'NAZ', 'C',  10,  0 } )

   DBCREATE2( _ime_f, _dbf_struct )

   CREATE_INDEX( "IDN", "STR(godina, 4) + STR(mjesec, 2) + oznaka", _ime_f )
   CREATE_INDEX( "NAZ", "naz", _ime_f )

   login_as( "admin" )

   cQuery := "drop table if exists fmk." + _ime_f + "; "
   cQuery += "create table " + _ime_f + "("
   cQuery += " godina int, mjesec int, oznaka varchar(2), naz varchar(10), PRIMARY KEY(godina, mjesec, oznaka)"
   cQuery += "); "
   cQuery += "GRANT ALL ON TABLE fmk." + _ime_f + " TO xtrole;"
   run_sql_query( cQuery )

   create_semaphore( _ime_f )



   upgrade_test_tables_semaphore_v2()

   TEST_LINE( is_table_column_exists( "test_sem_1", "b_year" ), .T. )
   TEST_LINE( is_table_column_exists( "test_sem_1", "b_seasson" ), .T. )
   TEST_LINE( is_table_column_exists( "test_sem_1", "org_id" ), .T. )

   TEST_LINE( is_table_column_exists( "test_sem_2", "b_year" ), .T. )




   _alias := "test_sem_1"
   _table_name := _alias
   ? "before reset", _table_name
   reset_semaphore_version( _table_name )
   ? "after reset", _table_name

   // -------------------------------
   SELECT F_TEST_SEM_1
   USE

   login_as( "test2" )
   my_usex( _alias )
   my_server_logout()


   login_as( "test1" )
   _thread_2_id  :=  hb_threadStart(  hb_bitOr( HB_THREAD_INHERIT_PUBLIC, HB_THREAD_MEMVARS_COPY ), @_thread_2_fn() )

   // hb_threadJoin( _thread_2_id )

   my_usex( _alias )
   TEST_LINE( Alias(), Upper( _alias ) )

   _rec := dbf_get_rec()

   FOR nI := 1 TO 500
      APPEND BLANK
      _rec[ "id" ] := Str( nI, 4 )
      _rec[ "naz" ] := "naz " + Str( nI, 4 )
      update_rec_server_and_dbf( _table_name, _rec )
   NEXT

   TEST_LINE( RecCount(), 500 )


   USE

   login_as( "test3" )
   my_usex( _alias )
   TEST_LINE( Alias(), Upper( _alias ) )
   USE


   login_as( "test2" )
   my_usex( _alias )

   // user: test3, ids = "{<FULL>/}"
   USE
   login_as( "test3" )
   my_usex( _alias )


   // user: test2, ids = "{<FULL>/}"
   USE
   login_as( "test2" )
   my_usex( _alias )

   USE


/*
// -------------------------------
_alias := "test_sem_2"
_table_name := _alias

SELECT F_TEST_SEM_2
use

login_as("test3")
reset_semaphore_version(_table_name)
my_usex(_alias)
use

login_as("test2")
my_usex(_alias)
use

login_as("test1")
my_usex(_alias)
use

*/

   RETURN .T.


FUNCTION test_sem_1_from_sql_server( algoritam )

   LOCAL _result := .F.
   LOCAL nI
   LOCAL _tbl := "test_sem_1"

   lock_semaphore( _tbl )
   _result := update_dbf_from_server( _tbl, algoritam )
   unlock_semaphore( _tbl, "free" )

   RETURN _result



FUNCTION test_sem_2_from_sql_server( algoritam )

   LOCAL _result := .F.
   LOCAL nI
   LOCAL _tbl := "test_sem_2"

   _result := update_dbf_from_server( _tbl, algoritam )

   RETURN _result



STATIC FUNCTION login_as( user )

   LOCAL _server_params

   _server_params := my_server_params()

   ? "logout ", _server_params[ "user" ]
   my_server_logout()

   _server_params[ "user" ] := user
   _server_params[ "password" ] := user

   my_server_params( _server_params )

   IF my_server_login()
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF



FUNCTION create_semaphore( table_name )

   LOCAL cQuery, _ret

   cQuery := "drop table if exists sem." + table_name + "; "
   cQuery += "create table sem." + table_name + "("
   cQuery += "user_code varchar(20), b_year integer DEFAULT date_part('year', now())  CHECK (b_year > 1990 AND b_year < 2990), b_season integer DEFAULT 0, client_id integer DEFAULT 0, version bigint NOT NULL, last_trans_version bigint, last_trans_time timestamp DEFAULT now(), last_trans_user_code varchar(20), dat date, algorithm varchar(20) DEFAULT 'full', ids text[], PRIMARY KEY(user_code, b_year, b_season, client_id)"
   cQuery += "); "
   cQuery += "GRANT ALL ON TABLE sem." + table_name + " TO xtrole;"

   _ret := run_sql_query( cQuery )

   IF ValType( _ret )  == "O"
      RETURN .T.
   ENDIF

   RETURN .F.




FUNCTION upgrade_test_tables_semaphore_v2()

   LOCAL cQuery, _qry_obj, _table

   // select tablename from pg_catalog.pg_tables where schemaname = 'fmk' and NOT ( (tablename LIKE 'semaphores_%') OR (tablename LIKE 'test_%') OR (tablename LIKE 'pkg%') OR (tablename = 'metric') OR (tablename = 'client_id')) order by tablename;

   cQuery := "select tablename from pg_catalog.pg_tables where schemaname = 'fmk' and (tablename LIKE 'test_%')  order by tablename;"

   _qry_obj := run_sql_query( cQuery )

   DO WHILE ! _qry_obj:Eof()
      _table := _qry_obj:FieldGet( 1 )
      alter_table_semaphore_v2( _table )

      _qry_obj:Skip()
   ENDDO

   _qry_obj:Close()

   RETURN .T.



FUNCTION alter_table_semaphore_v2( table )

   LOCAL cQuery, _ret

   cQuery := "ALTER TABLE fmk." + table + " ADD COLUMN org_id integer DEFAULT 0,  ADD COLUMN b_year integer DEFAULT 0, ADD COLUMN b_seasson integer DEFAULT 0;"

   cQuery += "ALTER TABLE fmk." +  table + " DROP CONSTRAINT " + table + "_pkey, ADD PRIMARY KEY " + sql_primary_key( table ) + ";"

   _ret := run_sql_query( cQuery )

   IF ValType( _ret )  == "O"
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF


FUNCTION is_table_column_exists( table, column )

   LOCAL cQuery, _ret

   cQuery := "SELECT count(column_name) FROM information_schema.columns WHERE table_name =" + sql_quote( table ) + " AND table_schema='fmk' AND column_name=" + sql_quote( Lower( column ) )

   _ret := run_sql_query( cQuery )

   IF ValType( _ret )  == "O"
      RETURN ( _ret:FieldGet( 1 ) == 1 )
   ELSE
      RETURN .F.
   ENDIF


FUNCTION _thread_2_fn()

   LOCAL _table_name := "test_sem_1"

   log_handle( FCreate( StrTran( F18_LOG_FILE, ".log", "_2.log" ) ) )

   log_write( "--- thread 2: ----" )

   ? "... thread_2_fn ..."

   log_write( pp( my_server_params() ) )

   IF !login_as( "test2" )
      log_write( "login thread neuspjesan !!!!" )
      log_close()
      RETURN .F.
   ENDIF
   ? pp( my_server_params() )

   log_write( ToStr( Time() ) + ": ... thread_2_fn ... lock" )
   lock_semaphore( _table_name, "lock" )
   // ? "... thread_2_fn ... lock", my_user(), VALTYPE(sql_data_conn()), get_semaphore_version(_table_name)
   // ? "my_home", my_home(), "sempahore status:", get_semaphore_status(_table_name)

   hb_idleSleep( 10 )
   log_write( ToStr( Time() ) + ": ... thread_2_fn ... unlock" )
   lock_semaphore( _table_name, "free" )

   my_server_logout()

   RETURN
