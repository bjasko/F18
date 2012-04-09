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


#include "kalk.ch"

static __import_dbf_path 
static __export_dbf_path
static __import_zip_name
static __export_zip_name


function kalk_udaljena_razmjena_podataka()
local _opc := {}
local _opcexe := {}
local _izbor := 1

__import_dbf_path := my_home() + "import_dbf" + SLASH
__export_dbf_path := my_home() + "export_dbf" + SLASH
__import_zip_name := "kalk_exp.zip"
__export_zip_name := "kalk_exp.zip"

AADD(_opc,"1. => export podataka               ")
AADD(_opcexe, {|| _kalk_export() })
AADD(_opc,"2. <= import podataka    ")
AADD(_opcexe, {|| _kalk_import() })

f18_menu( "razmjena", .f., _izbor, _opc, _opcexe )

close all
return


// ----------------------------------------
// export podataka modula KALK
// ----------------------------------------
static function _kalk_export()
local _vars := hb_hash()
local _exported_rec
local _error

// uslovi exporta
if !_vars_export( @_vars )
    return
endif

// pobrisi u folderu tmp fajlove ako postoje
delete_exp_files( __export_dbf_path )

// exportuj podatake
_exported_rec := __export( _vars )

// zatvori sve tabele prije operacije pakovanja
close all

// arhiviraj podatke
if _exported_rec > 0 
   
    // kompresuj ih u zip fajl za prenos
    _error := _compress_files( "kalk" )

    // sve u redu
    if _error == 0
        
        // pobrisi fajlove razmjene
        delete_exp_files( __export_dbf_path )

        // otvori folder sa exportovanim podacima
        open_folder( __export_dbf_path )

    endif

endif

// vrati se na glavni direktorij
DirChange( my_home() )

if ( _exported_rec > 0 )
    MsgBeep( "Exportovao " + ALLTRIM(STR( _exported_rec )) + " dokumenta." )
endif

close all
return



// ----------------------------------------
// import podataka modula KALK
// ----------------------------------------
static function _kalk_import()
local _imported_rec
local _vars := hb_hash()
local _imp_file 

// import fajl iz liste
_imp_file := get_import_file( "kalk" )

if _imp_file == NIL .or. EMPTY( _imp_file )
    MsgBeep( "Nema odabranog import fajla !????" )
    return
endif

// parametri
if !_vars_import( @_vars )
    return
endif

if !import_file_exist( _imp_file )
    // nema fajla za import ?
    MsgBeep( "import fajl ne postoji !??? prekidam operaciju" )
    return
endif

// dekompresovanje podataka
if _decompress_files( _imp_file ) <> 0
    // ako je bilo greske
    return
endif

#ifdef __PLATFORM__UNIX
    set_file_access()
#endif

// import procedura
_imported_rec := __import( _vars )

// zatvori sve
close all

// brisi fajlove importa
delete_exp_files( __import_dbf_path )

if ( _imported_rec > 0 )

    // nakon uspjesnog importa...

    // brisi zip fajl...
    delete_zip_files( _imp_file )

    MsgBeep( "Importovao " + ALLTRIM( STR( _imported_rec ) ) + " dokumenta." )

endif

// vrati se na home direktorij nakon svega
DirChange( my_home() )

return


// -------------------------------------------
// uslovi exporta dokumenta
// -------------------------------------------
static function _vars_export( vars )
local _ret := .f.
local _dat_od := fetch_metric( "kalk_export_datum_od", my_user(), DATE() - 30 )
local _dat_do := fetch_metric( "kalk_export_datum_do", my_user(), DATE() )
local _konta := fetch_metric( "kalk_export_lista_konta", my_user(), PADR( "1320;", 200 ) )
local _vrste_dok := fetch_metric( "kalk_export_vrste_dokumenata", my_user(), PADR( "10;11;", 200 ) )
local _exp_sif := fetch_metric( "kalk_export_sifrarnik", my_user(), "D" )
local _x := 1

Box(, 9, 70 )

    @ m_x + _x, m_y + 2 SAY "*** Uslovi exporta dokumenata"

    ++ _x
    ++ _x
        
    @ m_x + _x, m_y + 2 SAY "Vrste dokumenata:" GET _vrste_dok PICT "@S40"
    
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Datumski period od" GET _dat_od
    @ m_x + _x, col() + 1 SAY "do" GET _dat_do

    ++ _x
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Uzeti u obzir sljedeca konta:" GET _konta PICT "@S30"

    ++ _x
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Eksportovati sifrarnike (D/N) ?" GET _exp_sif PICT "@!" VALID _exp_sif $ "DN"

    read

BoxC()

// snimi parametre
if LastKey() <> K_ESC

    _ret := .t.

    set_metric( "kalk_export_datum_od", my_user(), _dat_od )
    set_metric( "kalk_export_datum_do", my_user(), _dat_do )
    set_metric( "kalk_export_lista_konta", my_user(), _konta )
    set_metric( "kalk_export_vrste_dokumenata", my_user(), _vrste_dok )
    set_metric( "kalk_export_sifrarnik", my_user(), _exp_sif )

    vars["datum_od"] := _dat_od
    vars["datum_do"] := _dat_do
    vars["konta"] := _konta
    vars["vrste_dok"] := _vrste_dok
    vars["export_sif"] := _exp_sif
    
endif

return _ret



// -------------------------------------------
// uslovi importa dokumenta
// -------------------------------------------
static function _vars_import( vars )
local _ret := .f.
local _dat_od := fetch_metric( "kalk_import_datum_od", my_user(), CTOD("") )
local _dat_do := fetch_metric( "kalk_import_datum_do", my_user(), CTOD("") )
local _konta := fetch_metric( "kalk_import_lista_konta", my_user(), PADR( "", 200 ) )
local _vrste_dok := fetch_metric( "kalk_import_vrste_dokumenata", my_user(), PADR( "", 200 ) )
local _zamjeniti_dok := fetch_metric( "kalk_import_zamjeniti_dokumente", my_user(), "N" )
local _zamjeniti_sif := fetch_metric( "kalk_import_zamjeniti_sifre", my_user(), "N" )
local _iz_fmk := fetch_metric( "kalk_import_iz_fmk", my_user(), "N" )
local _x := 1

Box(, 12, 70 )

    @ m_x + _x, m_y + 2 SAY "*** Uslovi importa dokumenata"

    ++ _x
    ++ _x
        
    @ m_x + _x, m_y + 2 SAY "Vrste dokumenata (prazno-sve):" GET _vrste_dok PICT "@S30"
    
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Datumski period od" GET _dat_od
    @ m_x + _x, col() + 1 SAY "do" GET _dat_do

    ++ _x
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Uzeti u obzir sljedeca konta:" GET _konta PICT "@S30"

    ++ _x
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Zamjeniti nove dokumente postojecim (D/N):" GET _zamjeniti_dok PICT "@!" VALID _zamjeniti_dok $ "DN"

    ++ _x

    @ m_x + _x, m_y + 2 SAY "Zamjeniti postojece sifre novim (D/N):" GET _zamjeniti_sif PICT "@!" VALID _zamjeniti_sif $ "DN"

    ++ _x
    ++ _x

    @ m_x + _x, m_y + 2 SAY "Import fajl dolazi iz FMK (D/N) ?" GET _iz_fmk PICT "@!" VALID _iz_fmk $ "DN"

    read

BoxC()

// snimi parametre
if LastKey() <> K_ESC

    _ret := .t.

    set_metric( "kalk_import_datum_od", my_user(), _dat_od )
    set_metric( "kalk_import_datum_do", my_user(), _dat_do )
    set_metric( "kalk_import_lista_konta", my_user(), _konta )
    set_metric( "kalk_import_vrste_dokumenata", my_user(), _vrste_dok )
    set_metric( "kalk_import_zamjeniti_dokumente", my_user(), _zamjeniti_dok )
    set_metric( "kalk_import_zamjeniti_sifre", my_user(), _zamjeniti_sif )
    set_metric( "kalk_import_iz_fmk", my_user(), _iz_fmk )

    vars["datum_od"] := _dat_od
    vars["datum_do"] := _dat_do
    vars["konta"] := _konta
    vars["vrste_dok"] := _vrste_dok
    vars["zamjeniti_dokumente"] := _zamjeniti_dok
    vars["zamjeniti_sifre"] := _zamjeniti_sif
    vars["import_iz_fmk"] := _iz_fmk
    
endif

return _ret



// -------------------------------------------
// export podataka
// -------------------------------------------
static function __export( vars )
local _ret := 0
local _id_firma, _id_vd, _br_dok
local _app_rec
local _cnt := 0
local _dat_od, _dat_do, _konta, _vrste_dok, _export_sif
local _usl_mkonto, _usl_pkonto
local _id_partn, _p_konto, _m_konto
local _id_roba

// uslovi za export ce biti...
_dat_od := vars["datum_od"]
_dat_do := vars["datum_do"]
_konta := ALLTRIM( vars["konta"] )
_vrste_dok := ALLTRIM( vars["vrste_dok"] )
_export_sif := ALLTRIM( vars["export_sif"] )
 
// kreiraj tabele exporta
_cre_exp_tbls( __export_dbf_path )

// otvori export tabele za pisanje podataka
_o_exp_tables( __export_dbf_path )

// otvori lokalne tabele za prenos
_o_tables()

Box(, 2, 65 )

@ m_x + 1, m_y + 2 SAY "... export kalk dokumenata u toku"

select kalk_doks
set order to tag "1"
go top

do while !EOF()

    _id_firma := field->idfirma
    _id_vd := field->idvd
    _br_dok := field->brdok
    _id_partn := field->idpartner
    _p_konto := field->pkonto
    _m_konto := field->mkonto

    // provjeri uslove ?!??

    // lista konta...
    if !EMPTY( _konta )

        _usl_mkonto := Parsiraj( ALLTRIM(_konta), "mkonto" )
        _usl_pkonto := Parsiraj( ALLTRIM(_konta), "pkonto" )

        if !( &_usl_mkonto )
            if !( &_usl_pkonto )
                skip
                loop
            endif
        endif

    endif

    // lista dokumenata...
    if !EMPTY( _vrste_dok )
        if !( field->idvd $ _vrste_dok )
            skip
            loop
        endif
    endif

    // datumski uslov...
    if _dat_od <> CTOD("") 
        if ( field->datdok < _dat_od )
            skip
            loop
        endif
    endif

    if _dat_do <> CTOD("")
        if ( field->datdok > _dat_do )
            skip
            loop
        endif
    endif

    // ako je sve zadovoljeno !
    // dodaj zapis u tabelu e_doks
    _app_rec := dbf_get_rec()

    select e_doks
    append blank
    dbf_update_rec( _app_rec )    

    ++ _cnt
    @ m_x + 2, m_y + 2 SAY PADR(  PADL( ALLTRIM(STR( _cnt )), 6 ) + ". " + "dokument: " + _id_firma + "-" + _id_vd + "-" + ALLTRIM( _br_dok ), 50 )

    // dodaj zapis i u tabelu e_kalk
    select kalk
    set order to tag "1"
    go top
    seek _id_firma + _id_vd + _br_dok

    do while !EOF() .and. field->idfirma == _id_firma .and. field->idvd == _id_vd .and. field->brdok == _br_dok

        // uzmi robu...
        _id_roba := field->idroba

        // upisi zapis u tabelu e_kalk
        _app_rec := dbf_get_rec()
        select e_kalk
        append blank
        dbf_update_rec( _app_rec )

        // uzmi sada robu sa ove stavke pa je ubaci u e_roba
        select roba
        hseek _id_roba
        if FOUND() .and. _export_sif == "D"
            _app_rec := dbf_get_rec()        
            select e_roba
            set order to tag "ID"
            seek _id_roba
            if !FOUND()
                append blank
                dbf_update_rec( _app_rec )
                // napuni i sifk, sifv parametre
                _fill_sifk( "ROBA", _id_roba )
            endif
        endif

        // idi dalje...
        select kalk
        skip

    enddo

    // e sada mozemo komotno ici na export partnera
    select partn
    hseek _id_partn 
    if FOUND() .and. _export_sif == "D"
        _app_rec := dbf_get_rec()
        select e_partn
        set order to tag "ID"
        seek _id_partn
        if !FOUND()
            append blank
            dbf_update_rec( _app_rec )
            // napuni i sifk, sifv parametre
            _fill_sifk( "PARTN", _id_partn )
        endif
    endif

    // i konta, naravno

    // prvo M_KONTO
    select konto
    hseek _m_konto 
    if FOUND() .and. _export_sif == "D"
        _app_rec := dbf_get_rec()
        select e_konto
        set order to tag "ID"
        seek _m_konto
        if !FOUND()
            append blank
            dbf_update_rec( _app_rec )
        endif
    endif

    // zatim P_KONTO
    select konto
    hseek _p_konto 
    if FOUND() .and. _export_sif == "D"
        _app_rec := dbf_get_rec()
        select e_konto
        set order to tag "ID"
        seek _p_konto
        if !FOUND()
            append blank
            dbf_update_rec( _app_rec )
        endif
    endif

    select kalk_doks
    skip

enddo

BoxC()

if ( _cnt > 0 )
    _ret := _cnt
endif

return _ret



// ----------------------------------------
// import podataka
// ----------------------------------------
static function __import( vars )
local _ret := 0
local _id_firma, _id_vd, _br_dok
local _app_rec
local _cnt := 0
local _dat_od, _dat_do, _konta, _vrste_dok, _zamjeniti_dok, _zamjeniti_sif, _iz_fmk
local _usl_mkonto, _usl_pkonto
local _roba_id, _partn_id, _konto_id
local _sif_exist
local _fmk_import := .f.
local _redni_broj := 0
local _total_doks := 0
local _total_kalk := 0
local _gl_brojac := 0

// ovo su nam uslovi za import...
_dat_od := vars["datum_od"]
_dat_do := vars["datum_do"]
_konta := vars["konta"]
_vrste_dok := vars["vrste_dok"]
_zamjeniti_dok := vars["zamjeniti_dokumente"]
_zamjeniti_sif := vars["zamjeniti_sifre"]
_iz_fmk := vars["import_iz_fmk"]
 
if _iz_fmk == "D"
    _fmk_import := .t.
endif

// otvaranje export tabela
_o_exp_tables( __import_dbf_path, _fmk_import )

// otvori potrebne tabele za import podataka
_o_tables()

// broj zapisa u import tabelama
select e_doks
_total_doks := RECCOUNT2()

select e_kalk
_total_kalk := RECCOUNT2()

select e_doks
set order to tag "1"
go top

Box(, 3, 70 )

@ m_x + 1, m_y + 2 SAY PADR( "... import kalk dokumenata u toku ", 69 ) COLOR "I"
@ m_x + 2, m_y + 2 SAY "broj zapisa doks/" + ALLTRIM(STR( _total_doks )) + ", kalk/" + ALLTRIM(STR( _total_kalk ))

do while !EOF()

    _id_firma := field->idfirma
    _id_vd := field->idvd
    _br_dok := field->brdok

    // uslovi, provjera...

    // datumi...
    if _dat_od <> CTOD( "" ) 
        if field->datdok < _dat_od
            skip
            loop
        endif
    endif

    if _dat_do <> CTOD( "" )
        if field->datdok > _dat_do
            skip
            loop
        endif
    endif

    // lista konta...
    if !EMPTY( _konta )

        _usl_mkonto := Parsiraj( ALLTRIM(_konta), "mkonto" )
        _usl_pkonto := Parsiraj( ALLTRIM(_konta), "pkonto" )

        if !( &_usl_mkonto )
            if !( &_usl_pkonto )
                skip
                loop
            endif
        endif

    endif

    // lista dokumenata...
    if !EMPTY( _vrste_dok )
        if !( field->idvd $ _vrste_dok )
            skip
            loop
        endif
    endif

    // da li postoji u prometu vec ?
    if _vec_postoji_u_prometu( _id_firma, _id_vd, _br_dok )

        if _zamjeniti_dok == "D"

            // dokumente iz kalk, kalk_doks brisi !
            _ok := .t.
            _ok := del_kalk( _id_firma, _id_vd, _br_dok )
            _ok := del_kalk_doks( _id_firma, _id_vd, _br_dok )

            //if !_ok
              //  MsgBeep( "Doslo je do greske sa brisanjem podataka !!!#Dokument: " + _id_firma + "-" + _id_vd + "-" + _br_dok )
              //  BoxC()
              //  return 0
            //endif
            
        else
            select e_doks
            skip
            loop
        endif

    endif

    // zikni je u nasu tabelu doks
    select e_doks
    _app_rec := dbf_get_rec()

    // cisti podbroj
    _app_rec["podbr"] := ""

    select kalk_doks
    append blank
    update_rec_server_and_dbf( "kalk_doks", _app_rec )

    ++ _cnt
    @ m_x + 3, m_y + 2 SAY PADR( PADL( ALLTRIM( STR(_cnt) ), 5 ) + ". dokument: " + _id_firma + "-" + _id_vd + "-" + _br_dok, 60 )

    // zikni je u nasu tabelu kalk
    select e_kalk
    set order to tag "1"
    go top
    seek _id_firma + _id_vd + _br_dok

    // setuj novi redni broj stavke
    _redni_broj := 0

    // prebaci mi stavke tabele KALK
    do while !EOF() .and. field->idfirma == _id_firma .and. field->idvd == _id_vd .and. field->brdok == _br_dok
        
        _app_rec := dbf_get_rec()

        // setuj redni broj automatski...
        _app_rec["rbr"] := PADL( ALLTRIM(STR( ++_redni_broj )), 3 )
        // reset podbroj
        _app_rec["podbr"] := ""

        // uvecaj i globalni brojac stavki...
        _gl_brojac += _redni_broj

        @ m_x + 3, m_y + 40 SAY "stavka: " + ALLTRIM(STR( _gl_brojac )) + " / " + _app_rec["rbr"] 

        select kalk
        append blank
        update_rec_server_and_dbf( "kalk", _app_rec )

        select e_kalk
        skip

    enddo

    select e_doks
    skip

enddo

// ako je sve ok, predji na import tabela sifrarnika
if _cnt > 0

    // ocisti mi 3 red
    @ m_x + 3, m_y + 2 SAY PADR( "", 69 )

    // update tabele roba
    update_table_roba( _zamjeniti_sif, _fmk_import )

    // update tabele partnera
    update_table_partn( _zamjeniti_sif, _fmk_import )

    // update tabele konta
    update_table_konto( _zamjeniti_sif, _fmk_import )

    // odradi update tabela sifk, sifv
    update_sifk_sifv( _fmk_import )

endif

BoxC()

if _cnt > 0
    _ret := _cnt
endif

return _ret


// ---------------------------------------------------------------------
// provjerava da li dokument vec postoji u prometu
// ---------------------------------------------------------------------
static function _vec_postoji_u_prometu( id_firma, id_vd, br_dok )
local _t_area := SELECT()
local _ret := .t.

select kalk_doks
go top
seek id_firma + id_vd + br_dok

if !FOUND()
    _ret := .f.
endif

select (_t_area)
return _ret




// ----------------------------------------------------------
// brisi dokument iz kalk-a
// ----------------------------------------------------------
static function del_kalk( id_firma, id_vd, br_dok )
local _t_area := SELECT()
local _del_rec, _t_rec 
local _ret := .f.

select kalk
set order to tag "1"
go top
seek id_firma + id_vd + br_dok

do while !EOF() .and. field->idfirma == id_firma .and. field->idvd == id_vd .and. field->brdok == br_dok

    skip 1
    _t_rec := RECNO()
    skip -1

    _del_rec := dbf_get_rec()

    delete_rec_server_and_dbf( ALIAS(), _del_rec )

    _ret := .t.

    go ( _t_rec )

enddo

select ( _t_area )
return _ret



// ----------------------------------------------------------
// brisi dokument iz doks-a
// ----------------------------------------------------------
static function del_kalk_doks( id_firma, id_vd, br_dok )
local _t_area := SELECT()
local _del_rec
local _ret := .f.

select kalk_doks
set order to tag "1"
go top
seek id_firma + id_vd + br_dok

if FOUND()

    _del_rec := dbf_get_rec()

    delete_rec_server_and_dbf( ALIAS(), _del_rec )

    _ret := .t.

endif

select ( _t_area )
return _ret



// ----------------------------------------
// kreiranje tabela razmjene
// ----------------------------------------
static function _cre_exp_tbls( use_path )
local _cre 

if use_path == NIL
    use_path := my_home()
endif

// provjeri da li postoji direktorij, pa ako ne - kreiraj
_dir_create( use_path )

// tabela kalk
O_KALK
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_kalk") from ( my_home() + "struct")

// tabela doks
O_KALK_DOKS
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_doks") from ( my_home() + "struct")

// tabela roba
O_ROBA
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_roba") from ( my_home() + "struct")

// tabela partn
O_PARTN
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_partn") from ( my_home() + "struct")

// tabela partn
O_PARTN
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_partn") from ( my_home() + "struct")

// tabela konta
O_KONTO
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_konto") from ( my_home() + "struct")

// tabela sifk
O_SIFK
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_sifk") from ( my_home() + "struct")

// tabela sifv
O_SIFV
copy structure extended to ( my_home() + "struct" )
use
create ( use_path + "e_sifv") from ( my_home() + "struct")


return


// ----------------------------------------------------
// otvaranje potrebnih tabela za prenos
// ----------------------------------------------------
static function _o_tables()

O_KALK
O_KALK_DOKS
O_SIFK
O_SIFV
O_KONTO
O_PARTN
O_ROBA

return




// ----------------------------------------------------
// otvranje export tabela
// ----------------------------------------------------
static function _o_exp_tables( use_path, from_fmk )
local _dbf_name

if ( use_path == NIL )
    use_path := my_home()
endif

if ( from_fmk == NIL )
    from_fmk := .f.
endif

log_write("otvaram tabele importa i pravim imdekse...")

// zatvori sve prije otvaranja ovih tabela
close all

_dbf_name := "e_kalk.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori kalk tabelu
select ( 360 )
use ( use_path + _dbf_name ) alias "e_kalk"
index on ( idfirma + idvd + brdok ) tag "1"

log_write("otvorio i indeksirao: " + use_path + _dbf_name )

_dbf_name := "e_doks.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori doks tabelu
select ( 361 )
use ( use_path + _dbf_name ) alias "e_doks"
index on ( idfirma + idvd + brdok ) tag "1"

log_write("otvorio i indeksirao: " + use_path + _dbf_name )

_dbf_name := "e_roba.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori roba tabelu
select ( 362 )
use ( use_path + _dbf_name ) alias "e_roba"
index on ( id ) tag "ID"

_dbf_name := "e_partn.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori partn tabelu
select ( 363 )
use ( use_path + _dbf_name ) alias "e_partn"
index on ( id ) tag "ID"

_dbf_name := "e_konto.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori konto tabelu
select ( 364 )
use ( use_path + _dbf_name ) alias "e_konto"
index on ( id ) tag "ID"

_dbf_name := "e_sifk.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori konto sifk
select ( 365 )
use ( use_path + _dbf_name ) alias "e_sifk"
index on ( id + sort + naz ) tag "ID"
index on ( id + oznaka ) tag "ID2"

_dbf_name := "e_sifv.dbf"
if from_fmk
    _dbf_name := UPPER( _dbf_name )
endif

// otvori konto tabelu
select ( 366 )
use ( use_path + _dbf_name ) alias "e_sifv"
index on ( id + oznaka + idsif + naz ) tag "ID"
index on ( id + idsif ) tag "IDIDSIF"

log_write("otvorene sve import tabele i indeksirane...")

return




// ----------------------------------------------------
// vraca listu fajlova koji se koriste kod prenosa
// ----------------------------------------------------
static function _file_list( use_path )
local _a_files := {} 

AADD( _a_files, use_path + "e_kalk.dbf" )
AADD( _a_files, use_path + "e_doks.dbf" )
AADD( _a_files, use_path + "e_roba.dbf" )
AADD( _a_files, use_path + "e_partn.dbf" )
AADD( _a_files, use_path + "e_konto.dbf" )
AADD( _a_files, use_path + "e_sifk.dbf" )
AADD( _a_files, use_path + "e_sifv.dbf" )

return _a_files


