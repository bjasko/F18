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


#include "fin.ch"

STATIC __import_dbf_path
STATIC __export_dbf_path
STATIC __import_zip_name
STATIC __export_zip_name


FUNCTION fin_udaljena_razmjena_podataka()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   __import_dbf_path := my_home() + "import_dbf" + SLASH
   __export_dbf_path := my_home() + "export_dbf" + SLASH
   __import_zip_name := "fin_exp.zip"
   __export_zip_name := "fin_exp.zip"

   // kreiraj ove direktorije odmah
   _dir_create( __export_dbf_path )

   AAdd( _opc, "1. => export podataka               " )
   AAdd( _opcexe, {|| _fin_export() } )
   AAdd( _opc, "2. <= import podataka    " )
   AAdd( _opcexe, {|| _fin_import() } )

   f18_menu( "razmjena", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN


// ----------------------------------------
// export podataka modula FIN
// ----------------------------------------
STATIC FUNCTION _fin_export()

   LOCAL _vars := hb_Hash()
   LOCAL _exported_rec
   LOCAL _error
   LOCAL _a_data := {}

   // uslovi exporta
   IF !_vars_export( @_vars )
      RETURN
   ENDIF

   // pobrisi u folderu tmp fajlove ako postoje
   delete_exp_files( __export_dbf_path, "fin" )

   // exportuj podatake
   _exported_rec := __export( _vars, @_a_data )

   // zatvori sve tabele prije operacije pakovanja
   my_close_all_dbf()

   // arhiviraj podatke
   IF _exported_rec > 0

      // kompresuj ih u zip fajl za prenos
      _error := _compress_files( "fin", __export_dbf_path )

      // sve u redu
      IF _error == 0

         // pobrisi fajlove razmjene
         delete_exp_files( __export_dbf_path, "fin" )

         // otvori folder sa exportovanim podacima
         open_folder( __export_dbf_path )

      ENDIF

   ENDIF

   // vrati se na glavni direktorij
   DirChange( my_home() )

   IF ( _exported_rec > 0 )

      MsgBeep( "Exportovao " + AllTrim( Str( _exported_rec ) ) + " dokumenta." )

      // printaj izvjestaj
      print_imp_exp_report( _a_data )

   ENDIF

   my_close_all_dbf()

   RETURN



// ----------------------------------------
// import podataka modula FIN
// ----------------------------------------
STATIC FUNCTION _fin_import()

   LOCAL _imported_rec
   LOCAL _vars := hb_Hash()
   LOCAL _imp_file
   LOCAL _a_data := {}
   LOCAL _imp_path := fetch_metric( "fin_import_path", my_user(), PadR( "", 300 ) )

   // zapravo, uvijek pokazi import lokaciju
   Box(, 1, 70 )
   @ m_x + 1, m_y + 2 SAY "import path:" GET _imp_path PICT "@S50"
   READ
   BoxC()
	
   IF LastKey() == K_ESC
      RETURN
   endif

   // snimi u parametre
   __import_dbf_path := AllTrim( _imp_path )
   set_metric( "fin_import_path", my_user(), _imp_path )

   // import fajl iz liste
   _imp_file := get_import_file( "fin", __import_dbf_path )

   IF _imp_file == NIL .OR. Empty( _imp_file )
      MsgBeep( "Nema odabranog import fajla !????" )
      RETURN
   ENDIF

   // parametri
   IF !_vars_import( @_vars )
      RETURN
   ENDIF

   IF !import_file_exist( _imp_file )
      // nema fajla za import ?
      MsgBeep( "import fajl ne postoji !??? prekidam operaciju" )
      RETURN
   ENDIF

   // dekompresovanje podataka
   IF _decompress_files( _imp_file, __import_dbf_path, __import_zip_name ) <> 0
      // ako je bilo greske
      RETURN
   ENDIF

#ifdef __PLATFORM__UNIX
   set_file_access( __import_dbf_path )
#endif

   // import procedura
   _imported_rec := __import( _vars, @_a_data )

   // zatvori sve
   my_close_all_dbf()

   // brisi fajlove importa
   delete_exp_files( __import_dbf_path, "fin" )

   IF ( _imported_rec > 0 )

      // nakon uspjesnog importa...
      IF Pitanje(, "Pobrisati fajl razmjne ?", "D" ) == "D"
         // brisi zip fajl...
         delete_zip_files( _imp_file )
      ENDIF


      MsgBeep( "Importovao " + AllTrim( Str( _imported_rec ) ) + " dokumenta." )

      // printaj izvjestaj
      print_imp_exp_report( _a_data )

   ENDIF

   // vrati se na home direktorij nakon svega
   DirChange( my_home() )

   RETURN



// -------------------------------------------
// uslovi exporta dokumenta
// -------------------------------------------
STATIC FUNCTION _vars_export( vars )

   LOCAL _ret := .F.
   LOCAL _dat_od := fetch_metric( "fin_export_datum_od", my_user(), Date() - 30 )
   LOCAL _dat_do := fetch_metric( "fin_export_datum_do", my_user(), Date() )
   LOCAL _konta := fetch_metric( "fin_export_lista_konta", my_user(), PadR( "1320;", 200 ) )
   LOCAL _vrste_dok := fetch_metric( "fin_export_vrste_dokumenata", my_user(), PadR( "10;11;", 200 ) )
   LOCAL _exp_sif := fetch_metric( "fin_export_sifrarnik", my_user(), "D" )
   LOCAL _exp_path := fetch_metric( "fin_export_path", my_user(), PadR( "", 300 ) )
   LOCAL _x := 1

   IF Empty( AllTrim( _exp_path ) )
      _exp_path := PadR( __export_dbf_path, 300 )
   ENDIF

   Box(, 15, 70 )

   @ m_x + _x, m_y + 2 SAY "*** Uslovi exporta dokumenata"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Vrste dokumenata:" GET _vrste_dok PICT "@S40"

   ++ _x

   @ m_x + _x, m_y + 2 SAY "Datumski period od" GET _dat_od
   @ m_x + _x, Col() + 1 SAY "do" GET _dat_do

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Uzeti u obzir sljedeca konta:" GET _konta PICT "@S30"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Eksportovati sifrarnike (D/N) ?" GET _exp_sif PICT "@!" VALID _exp_sif $ "DN"

   ++ _x

   @ m_x + _x, m_y + 2 SAY "Eksport lokacija:" GET _exp_path PICT "@S50"

   READ

   BoxC()

   // snimi parametre
   IF LastKey() <> K_ESC

      _ret := .T.

      set_metric( "fin_export_datum_od", my_user(), _dat_od )
      set_metric( "fin_export_datum_do", my_user(), _dat_do )
      set_metric( "fin_export_lista_konta", my_user(), _konta )
      set_metric( "fin_export_vrste_dokumenata", my_user(), _vrste_dok )
      set_metric( "fin_export_sifrarnik", my_user(), _exp_sif )
      set_metric( "fin_export_path", my_user(), _exp_path )

      // export path, set static var
      __export_dbf_path := AllTrim( _exp_path )

      vars[ "datum_od" ] := _dat_od
      vars[ "datum_do" ] := _dat_do
      vars[ "konta" ] := _konta
      vars[ "vrste_dok" ] := _vrste_dok
      vars[ "export_sif" ] := _exp_sif

   ENDIF

   RETURN _ret



// -------------------------------------------
// uslovi importa dokumenta
// -------------------------------------------
STATIC FUNCTION _vars_import( vars )

   LOCAL _ret := .F.
   LOCAL _dat_od := fetch_metric( "fin_import_datum_od", my_user(), CToD( "" ) )
   LOCAL _dat_do := fetch_metric( "fin_import_datum_do", my_user(), CToD( "" ) )
   LOCAL _konta := fetch_metric( "fin_import_lista_konta", my_user(), PadR( "", 200 ) )
   LOCAL _vrste_dok := fetch_metric( "fin_import_vrste_dokumenata", my_user(), PadR( "", 200 ) )
   LOCAL _zamjeniti_dok := fetch_metric( "fin_import_zamjeniti_dokumente", my_user(), "N" )
   LOCAL _zamjeniti_sif := fetch_metric( "fin_import_zamjeniti_sifre", my_user(), "N" )
   LOCAL _iz_fmk := fetch_metric( "fin_import_iz_fmk", my_user(), "N" )
   LOCAL _imp_path := fetch_metric( "fin_import_path", my_user(), PadR( "", 300 ) )
   LOCAL _x := 1

   IF Empty( AllTrim( _imp_path ) )
      _imp_path := PadR( __import_dbf_path, 300 )
   ENDIF


   Box(, 15, 70 )

   @ m_x + _x, m_y + 2 SAY "*** Uslovi importa dokumenata"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Vrste dokumenata (prazno-sve):" GET _vrste_dok PICT "@S30"

   ++ _x

   @ m_x + _x, m_y + 2 SAY "Datumski period od" GET _dat_od
   @ m_x + _x, Col() + 1 SAY "do" GET _dat_do

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Uzeti u obzir sljedeca konta:" GET _konta PICT "@S30"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Zamjeniti postojece dokumente novim (D/N):" GET _zamjeniti_dok PICT "@!" VALID _zamjeniti_dok $ "DN"

   ++ _x

   @ m_x + _x, m_y + 2 SAY "Zamjeniti postojece sifre novim (D/N):" GET _zamjeniti_sif PICT "@!" VALID _zamjeniti_sif $ "DN"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Import fajl dolazi iz FMK (D/N) ?" GET _iz_fmk PICT "@!" VALID _iz_fmk $ "DN"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Import lokacija:" GET _imp_path PICT "@S50"


   READ

   BoxC()

   // snimi parametre
   IF LastKey() <> K_ESC

      _ret := .T.

      set_metric( "fin_import_datum_od", my_user(), _dat_od )
      set_metric( "fin_import_datum_do", my_user(), _dat_do )
      set_metric( "fin_import_lista_konta", my_user(), _konta )
      set_metric( "fin_import_vrste_dokumenata", my_user(), _vrste_dok )
      set_metric( "fin_import_zamjeniti_dokumente", my_user(), _zamjeniti_dok )
      set_metric( "fin_import_zamjeniti_sifre", my_user(), _zamjeniti_sif )
      set_metric( "fin_import_iz_fmk", my_user(), _iz_fmk )
      set_metric( "fin_import_path", my_user(), _imp_path )

      // set static var
      __import_dbf_path := AllTrim( _imp_path )

      vars[ "datum_od" ] := _dat_od
      vars[ "datum_do" ] := _dat_do
      vars[ "konta" ] := _konta
      vars[ "vrste_dok" ] := _vrste_dok
      vars[ "zamjeniti_dokumente" ] := _zamjeniti_dok
      vars[ "zamjeniti_sifre" ] := _zamjeniti_sif
      vars[ "import_iz_fmk" ] := _iz_fmk

   ENDIF

   RETURN _ret



// -------------------------------------------
// export podataka
// -------------------------------------------
STATIC FUNCTION __export( vars, a_details )

   LOCAL _ret := 0
   LOCAL _id_firma, _id_vd, _br_dok
   LOCAL _app_rec
   LOCAL _cnt := 0
   LOCAL _dat_od, _dat_do, _konta, _vrste_dok, _export_sif
   LOCAL _usl_konto, _id_konto
   LOCAL _id_partn
   LOCAL _detail_rec

   // uslovi za export ce biti...
   _dat_od := vars[ "datum_od" ]
   _dat_do := vars[ "datum_do" ]
   _konta := AllTrim( vars[ "konta" ] )
   _vrste_dok := AllTrim( vars[ "vrste_dok" ] )
   _export_sif := AllTrim( vars[ "export_sif" ] )

   // kreiraj tabele exporta
   _cre_exp_tbls( __export_dbf_path )

   // otvori export tabele za pisanje podataka
   _o_exp_tables( __export_dbf_path )

   // otvori lokalne tabele za prenos
   _o_tables()

   Box(, 2, 65 )

   @ m_x + 1, m_y + 2 SAY "... export fin dokumenata u toku"

   SELECT nalog
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      _id_firma := field->idfirma
      _id_vd := field->idvn
      _br_dok := field->brnal

      // provjeri uslove ?!??

      // lista dokumenata...
      IF !Empty( _vrste_dok )
         IF !( field->idvn $ _vrste_dok )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // datumski uslov...
      IF _dat_od <> CToD( "" )
         IF ( field->datnal < _dat_od )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF _dat_do <> CToD( "" )
         IF ( field->datnal > _dat_do )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // ako je sve zadovoljeno !
      // dodaj zapis u tabelu e_nalog
      _app_rec := dbf_get_rec()

      _detail_rec := hb_Hash()
      _detail_rec[ "dokument" ] := _app_rec[ "idfirma" ] + "-" + _app_rec[ "idvn" ] + "-" + _app_rec[ "brnal" ]
      _detail_rec[ "idpartner" ] := ""
      _detail_rec[ "idkonto" ] := ""
      _detail_rec[ "partner" ] := ""
      _detail_rec[ "iznos" ] := 0
      _detail_rec[ "datum" ] := _app_rec[ "datnal" ]
      _detail_rec[ "tip" ] := "export"

      // dodaj u detalje
      add_to_details( @a_details, _detail_rec )

      SELECT e_nalog
      APPEND BLANK
      dbf_update_rec( _app_rec )

      ++ _cnt
      @ m_x + 2, m_y + 2 SAY PadR(  PadL( AllTrim( Str( _cnt ) ), 6 ) + ". " + "dokument: " + _id_firma + "-" + _id_vd + "-" + AllTrim( _br_dok ), 50 )

      // dodaj zapis i u tabelu e_suban
      SELECT suban
      SET ORDER TO TAG "4"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok

      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         // uzmi konto...
         // uzmi partner...
         _id_konto := field->idkonto
         _id_partner := field->idpartner

         // upisi zapis u tabelu e_suban
         _app_rec := dbf_get_rec()
         SELECT e_suban
         APPEND BLANK
         dbf_update_rec( _app_rec )

         // uzmi sada konto sa ove stavke pa je ubaci u e_konto
         SELECT konto
         hseek _id_konto
         IF Found() .AND. _export_sif == "D"
            _app_rec := dbf_get_rec()
            SELECT e_konto
            SET ORDER TO TAG "ID"
            SEEK _id_konto
            IF !Found()
               APPEND BLANK
               dbf_update_rec( _app_rec )
               // napuni i sifk, sifv parametre
               _fill_sifk( "KONTO", _id_konto )
            ENDIF
         ENDIF

         // uzmi sada partnera sa ove stavke pa je ubaci u e_partn
         SELECT partn
         hseek _id_partner
         IF Found() .AND. _export_sif == "D"
            _app_rec := dbf_get_rec()
            SELECT e_partn
            SET ORDER TO TAG "ID"
            SEEK _id_partner
            IF !Found()
               APPEND BLANK
               dbf_update_rec( _app_rec )
               // napuni i sifk, sifv parametre
               _fill_sifk( "PARTN", _id_partner )
            ENDIF
         ENDIF

         // idi dalje...
         SELECT suban
         SKIP

      ENDDO

      // dodaj zapis i u tabelu e_sint, e_anal
      SELECT sint
      SET ORDER TO TAG "2"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok
      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         // ubaci u e_sint
         _app_rec := dbf_get_rec()
         SELECT e_sint
         APPEND BLANK
         dbf_update_rec( _app_rec )

         SELECT sint
         SKIP

      ENDDO

      SELECT anal
      SET ORDER TO TAG "2"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok
      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         // ubaci u e_anal
         _app_rec := dbf_get_rec()

         SELECT e_anal
         APPEND BLANK
         dbf_update_rec( _app_rec )

         SELECT anal
         SKIP

      ENDDO

      SELECT nalog
      SKIP

   ENDDO

   BoxC()

   IF ( _cnt > 0 )
      _ret := _cnt
   ENDIF

   RETURN _ret



// ----------------------------------------
// import podataka
// ----------------------------------------
STATIC FUNCTION __import( vars, a_details )

   LOCAL _ret := 0
   LOCAL _id_firma, _id_vd, _br_dok
   LOCAL _app_rec
   LOCAL _cnt := 0
   LOCAL _dat_od, _dat_do, _konta, _vrste_dok, _zamjeniti_dok, _zamjeniti_sif, _iz_fmk
   LOCAL _roba_id, _partn_id, _konto_id
   LOCAL _sif_exist
   LOCAL _fmk_import := .F.
   LOCAL _redni_broj := 0
   LOCAL _total_suban := 0
   LOCAL _total_anal := 0
   LOCAL _total_sint := 0
   LOCAL _total_nalog := 0
   LOCAL _gl_brojac := 0
   LOCAL _detail_rec

   // lokuj potrebne fajlove
   IF !f18_lock_tables( { "fin_nalog", "fin_anal", "fin_sint", "fin_suban" } )
      RETURN _cnt
   ENDIF

   sql_table_update( nil, "BEGIN" )

   // ovo su nam uslovi za import...
   _dat_od := vars[ "datum_od" ]
   _dat_do := vars[ "datum_do" ]
   _konta := vars[ "konta" ]
   _vrste_dok := vars[ "vrste_dok" ]
   _zamjeniti_dok := vars[ "zamjeniti_dokumente" ]
   _zamjeniti_sif := vars[ "zamjeniti_sifre" ]
   _iz_fmk := vars[ "import_iz_fmk" ]

   IF _iz_fmk == "D"
      _fmk_import := .T.
   ENDIF

   // otvaranje export tabela
   _o_exp_tables( __import_dbf_path, _fmk_import )

   // otvori potrebne tabele za import podataka
   _o_tables()

   // broj zapisa u import tabelama
   SELECT e_nalog
   _total_nalog := RECCOUNT2()

   SELECT e_suban
   _total_suban := RECCOUNT2()

   SELECT e_nalog
   SET ORDER TO TAG "1"
   GO TOP

   Box(, 3, 70 )

   @ m_x + 1, m_y + 2 SAY PadR( "... import fin dokumenata u toku ", 69 ) COLOR "I"
   @ m_x + 2, m_y + 2 SAY "broj zapisa nalog/" + AllTrim( Str( _total_nalog ) ) + ", suban/" + AllTrim( Str( _total_suban ) )

   DO WHILE !Eof()

      _id_firma := field->idfirma
      _id_vd := field->idvn
      _br_dok := field->brnal
      _dat_dok := field->datnal

      // uslovi, provjera...

      // datumi...
      IF _dat_od <> CToD( "" )
         IF field->datnal < _dat_od
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF _dat_do <> CToD( "" )
         IF field->datnal > _dat_do
            SKIP
            LOOP
         ENDIF
      ENDIF

      // lista dokumenata...
      IF !Empty( _vrste_dok )
         IF !( field->idvn $ _vrste_dok )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // da li postoji u prometu vec ?
      IF _vec_postoji_u_prometu( _id_firma, _id_vd, _br_dok )

         _detail_rec := hb_Hash()
         _detail_rec[ "dokument" ] := _id_firma + "-" + _id_vd + "-" + _br_dok
         _detail_rec[ "datum" ] := _dat_dok
         _detail_rec[ "idpartner" ] := ""
         _detail_rec[ "partner" ] := ""
         _detail_rec[ "idkonto" ] := ""
         _detail_rec[ "iznos" ] := 0

         IF _zamjeniti_dok == "D"

            _detail_rec[ "tip" ] := "delete"
            add_to_details( @a_details, _detail_rec )

            // dokumente iz fin brisi !
            _ok := .T.
            _ok := del_fin_doc( _id_firma, _id_vd, _br_dok )

         ELSE

            _detail_rec[ "tip" ] := "x"
            add_to_details( @a_details, _detail_rec )

            SELECT e_nalog
            SKIP
            LOOP

         ENDIF

      ENDIF

      // zikni je u nasu tabelu doks
      SELECT e_nalog
      _app_rec := dbf_get_rec()

      _detail_rec := hb_Hash()
      _detail_rec[ "dokument" ] := _app_rec[ "idfirma" ] + "-" + _app_rec[ "idvn" ] + "-" + _app_rec[ "brnal" ]
      _detail_rec[ "datum" ] := _app_rec[ "datnal" ]
      _detail_rec[ "idpartner" ] := ""
      _detail_rec[ "partner" ] := ""
      _detail_rec[ "idkonto" ] := ""
      _detail_rec[ "iznos" ] := 0
      _detail_rec[ "tip" ] := "import"

      add_to_details( @a_details, _detail_rec )

      SELECT nalog
      APPEND BLANK
      update_rec_server_and_dbf( "fin_nalog", _app_rec, 1, "CONT" )

      ++ _cnt
      @ m_x + 3, m_y + 2 SAY PadR( PadL( AllTrim( Str( _cnt ) ), 5 ) + ". dokument: " + _id_firma + "-" + _id_vd + "-" + _br_dok, 60 )

      // zikni je u nasu tabelu fin
      SELECT e_suban
      SET ORDER TO TAG "1"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok

      // setuj novi redni broj stavke
      _redni_broj := 0

      // prebaci mi stavke tabele FIN
      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         _app_rec := dbf_get_rec()

         // setuj redni broj automatski...
         _app_rec[ "rbr" ] := PadL( AllTrim( Str( ++_redni_broj ) ), 4 )

         // uvecaj i globalni brojac stavki...
         _gl_brojac += _redni_broj

         @ m_x + 3, m_y + 40 SAY "stavka: " + AllTrim( Str( _gl_brojac ) ) + " / " + _app_rec[ "rbr" ]

         SELECT suban
         APPEND BLANK
         update_rec_server_and_dbf( "fin_suban", _app_rec, 1, "CONT" )

         SELECT e_suban
         SKIP

      ENDDO

      // zikni je i u tabelu anal
      SELECT e_anal
      SET ORDER TO TAG "1"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok

      // setuj novi redni broj stavke
      _redni_broj := 0

      // prebaci mi stavke tabele FIN
      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         _app_rec := dbf_get_rec()

         // setuj redni broj automatski...
         _app_rec[ "rbr" ] := PadL( AllTrim( Str( ++_redni_broj ) ), 3 )

         // uvecaj i globalni brojac stavki...
         _gl_brojac += _redni_broj

         @ m_x + 3, m_y + 40 SAY "stavka: " + AllTrim( Str( _gl_brojac ) ) + " / " + _app_rec[ "rbr" ]

         SELECT anal
         APPEND BLANK
         update_rec_server_and_dbf( "fin_anal", _app_rec, 1, "CONT" )

         SELECT e_anal
         SKIP

      ENDDO

      // zikni je i u tabelu sint
      SELECT e_sint
      SET ORDER TO TAG "1"
      GO TOP
      SEEK _id_firma + _id_vd + _br_dok

      // setuj novi redni broj stavke
      _redni_broj := 0

      // prebaci mi stavke tabele FIN
      DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvn == _id_vd .AND. field->brnal == _br_dok

         _app_rec := dbf_get_rec()

         // setuj redni broj automatski...
         _app_rec[ "rbr" ] := PadL( AllTrim( Str( ++_redni_broj ) ), 3 )

         // uvecaj i globalni brojac stavki...
         _gl_brojac += _redni_broj

         @ m_x + 3, m_y + 40 SAY "stavka: " + AllTrim( Str( _gl_brojac ) ) + " / " + _app_rec[ "rbr" ]

         SELECT sint
         APPEND BLANK
         update_rec_server_and_dbf( "fin_sint", _app_rec, 1, "CONT" )

         SELECT e_sint
         SKIP

      ENDDO

      SELECT e_nalog
      SKIP

   ENDDO

   sql_table_update( nil, "END" )
   f18_free_tables( { "fin_nalog", "fin_anal", "fin_sint", "fin_suban" } )

   IF _cnt > 0

      @ m_x + 3, m_y + 2 SAY PadR( "", 69 )

      update_table_partn( _zamjeniti_sif )
      update_table_konto( _zamjeniti_sif )
      update_sifk_sifv()

   ENDIF

   BoxC()

   IF _cnt > 0
      _ret := _cnt
   ENDIF

   RETURN _ret


// ---------------------------------------------------------------------
// provjerava da li dokument vec postoji u prometu
// ---------------------------------------------------------------------
STATIC FUNCTION _vec_postoji_u_prometu( id_firma, id_vd, br_dok )

   LOCAL _t_area := Select()
   LOCAL _ret := .T.

   SELECT nalog
   GO TOP
   SEEK id_firma + id_vd + br_dok

   IF !Found()
      _ret := .F.
   ENDIF

   SELECT ( _t_area )

   RETURN _ret




// ----------------------------------------------------------
// brisi dokument iz fin-a
// ----------------------------------------------------------
STATIC FUNCTION del_fin_doc( id_firma, id_vd, br_dok )

   LOCAL _t_area := Select()
   LOCAL _del_rec, _t_rec
   LOCAL _ret := .F.

   // suban brisi
   SELECT suban
   SET ORDER TO TAG "4"
   GO TOP
   SEEK id_firma + id_vd + br_dok
   IF Found()
      _ret := .T.
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "fin_suban", _del_rec, 2, "CONT" )
   ENDIF

   // nalog brisi
   SELECT nalog
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_firma + id_vd + br_dok
   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "fin_nalog", _del_rec, 1, "CONT" )
   ENDIF

   // anal brisi
   SELECT anal
   SET ORDER TO TAG "2"
   GO TOP
   SEEK id_firma + id_vd + br_dok
   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "fin_anal", _del_rec, 2, "CONT" )
   ENDIF

   SELECT sint
   SET ORDER TO TAG "2"
   GO TOP
   SEEK id_firma + id_vd + br_dok
   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "fin_sint", _del_rec, 2, "CONT" )
   ENDIF

   SELECT ( _t_area )

   RETURN _ret




// ----------------------------------------
// kreiranje tabela razmjene
// ----------------------------------------
STATIC FUNCTION _cre_exp_tbls( use_path )

   LOCAL _cre

   IF use_path == NIL
      use_path := my_home()
   ENDIF

   // provjeri da li postoji direktorij, pa ako ne - kreiraj
   _dir_create( use_path )

   // tabela suban
   O_SUBAN
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_suban" ) from ( my_home() + "struct" )

   // tabela nalog
   O_NALOG
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_nalog" ) from ( my_home() + "struct" )

   // tabela sint
   O_SINT
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_sint" ) from ( my_home() + "struct" )

   // tabela anal
   O_ANAL
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_anal" ) from ( my_home() + "struct" )

   // tabela partn
   O_PARTN
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_partn" ) from ( my_home() + "struct" )

   // tabela konta
   O_KONTO
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_konto" ) from ( my_home() + "struct" )

   // tabela sifk
   O_SIFK
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_sifk" ) from ( my_home() + "struct" )

   // tabela sifv
   O_SIFV
   COPY STRUCTURE EXTENDED to ( my_home() + "struct" )
   USE
   CREATE ( use_path + "e_sifv" ) from ( my_home() + "struct" )

   RETURN


// ----------------------------------------------------
// otvaranje potrebnih tabela za prenos
// ----------------------------------------------------
STATIC FUNCTION _o_tables()

   O_SUBAN
   O_NALOG
   O_ANAL
   O_SINT
   O_SIFK
   O_SIFV
   O_KONTO
   O_PARTN

   RETURN




// ----------------------------------------------------
// otvranje export tabela
// ----------------------------------------------------
STATIC FUNCTION _o_exp_tables( use_path, from_fmk )

   LOCAL _dbf_name

   IF ( use_path == NIL )
      use_path := my_home()
   ENDIF

   IF ( from_fmk == NIL )
      from_fmk := .F.
   ENDIF

   log_write( "otvaram fin tabele importa i pravim indekse...", 9 )

   // zatvori sve prije otvaranja ovih tabela
   my_close_all_dbf()

   _dbf_name := "e_suban.dbf"
   // otvori suban tabelu
   SELECT ( F_TMP_E_SUBAN )
   my_use_temp( "E_SUBAN", use_path + _dbf_name, .F., .T. )
   INDEX on ( idfirma + idvn + brnal ) TAG "1"

   log_write( "otvorio i indeksirao: " + use_path + _dbf_name, 5 )

   _dbf_name := "e_nalog.dbf"
   // otvori nalog tabelu
   SELECT ( F_TMP_E_NALOG )
   my_use_temp( "E_NALOG", use_path + _dbf_name, .F., .T. )
   INDEX on ( idfirma + idvn + brnal ) TAG "1"

   log_write( "otvorio i indeksirao: " + use_path + _dbf_name, 5 )

   _dbf_name := "e_sint.dbf"
   // otvori sint tabelu
   SELECT ( F_TMP_E_SINT )
   my_use_temp( "E_SINT", use_path + _dbf_name, .F., .T. )
   INDEX on ( idfirma + idvn + brnal ) TAG "1"

   _dbf_name := "e_anal.dbf"
   // otvori anal tabelu
   SELECT ( F_TMP_E_ANAL )
   my_use_temp( "E_ANAL", use_path + _dbf_name, .F., .T. )
   INDEX on ( idfirma + idvn + brnal ) TAG "1"

   _dbf_name := "e_partn.dbf"
   // otvori partn tabelu
   SELECT ( F_TMP_E_PARTN )
   my_use_temp( "E_PARTN", use_path + _dbf_name, .F., .T. )
   INDEX on ( id ) TAG "ID"

   _dbf_name := "e_konto.dbf"
   // otvori konto tabelu
   SELECT ( F_TMP_E_KONTO )
   my_use_temp( "E_KONTO", use_path + _dbf_name, .F., .T. )
   INDEX on ( id ) TAG "ID"

   _dbf_name := "e_sifk.dbf"
   // otvori konto sifk
   SELECT ( F_TMP_E_SIFK )
   my_use_temp( "E_SIFK", use_path + _dbf_name, .F., .T. )
   INDEX on ( id + sort + naz ) TAG "ID"
   INDEX on ( id + oznaka ) TAG "ID2"

   _dbf_name := "e_sifv.dbf"
   // otvori konto tabelu
   SELECT ( F_TMP_E_SIFV )
   my_use_temp( "E_SIFV", use_path + _dbf_name, .F., .T. )
   INDEX on ( id + oznaka + idsif + naz ) TAG "ID"
   INDEX on ( id + idsif ) TAG "IDIDSIF"

   log_write( "otvorene sve import tabele i indeksirane...", 9 )

   RETURN
