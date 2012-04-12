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

#define D_MAX_FILES     150


// -----------------------------------------------------------
// otvaranje fajlova potrebnih kod importa podataka
// -----------------------------------------------------------
static function _o_imp_tables()

select ( F_ROBA )
if !used()
	O_ROBA
endif

select ( F_TARIFA )
if !used()
	O_TARIFA
endif

select ( F_KALK_PRIPR )
if !used()
	O_KALK_PRIPR
endif

select ( F_KALK_DOKS )
if !used()
	O_KALK_DOKS
endif

select ( F_KALK )
if !used()
	O_KALK
endif

select ( F_KONCIJ )
if !used()
	O_KONCIJ
endif

return


// --------------------------------------------------------
// upit za konto
// --------------------------------------------------------
static function _box_konto()
local _konto := PADR( "1320", 7 )
local _t_area := SELECT()
	
select konto

Box(, 3, 60 )
	@ m_x+2, m_y+2 SAY "Magacinski konto:" GET _konto VALID P_Konto( @_konto )
  	read
BoxC()

select ( _t_area )
return _konto


// ----------------------------------------------------------------
// nacin zamjene barkod-ova prilikom importa
// ----------------------------------------------------------------
static function _bk_replace()
local _ret := 0
local _x := 1

Box(, 5, 60 )

	@ m_x + _x, m_y + 2 SAY "Zamjena barkod-ova"
	
	++ _x
	++ _x

	@ m_x + _x, m_y + 2 SAY "0 - bez zamjene"

	++ _x

	@ m_x + _x, m_y + 2 SAY "1 - ubaci samo nove"
	
	++ _x

	@ m_x + _x, m_y + 2 SAY "2 - zamjeni sve"

	++ _x
	++ _x

	@ m_x + _x, m_y + 2 SAY SPACE(15) + "=> odabir" GET _ret PICT "9"
	
	read
	
BoxC()

return



// ------------------------------------------------------------
// preuzimanje podataka iz POS-a
// ------------------------------------------------------------
function kalk_preuzmi_tops_dokumente()
local _auto_razduzenje := "N"
local _br_kalk, _idvd_pos
local _id_konto2 := ""
local _bk_replace
local _br_dok, _id_konto, _rbr
local _bk_tmp
local _app_rec

// opcija za automatko svodjeje prodavnice na 0
// ---------------------------------------------
// prenese se tops promet u dokument 11
// pa se prenese tops promet u dokument 42
_auto_razduzenje := fetch_metric( "kalk_tops_prenos_auto_razduzenje", my_user(), _auto_razduzenje )

// otvori tabele bitne za import podataka
_o_imp_tables()

// daj mi fajl za import
if !get_import_file( @_imp_file )
	close all
	return
endif

// otvori temp tabelu
select ( F_TMP_TOPSKA )
my_use_temp( "TOPSKA", _imp_file )

go bottom

// daj mi broj kalkulacije
_br_kalk := LEFT( STRTRAN( DTOC( field->datum ), ".", "" ), 4 ) + "/" + ALLTRIM( field->idpos )
_idvd_pos := field->idvd

// provjeri da li postoji podesenje za ovaj fajl importa
select koncij
locate for idprodmjes == topska->idpos

if !FOUND()
	MsgBeep("U sifrarniku KONTA-TIPOVI CIJENA nije postavljeno#nigdje prodajno mjesto :" + field->idprodmjes + "#Prenos nije izvrsen.")
  	close all
	return
endif

select kalk

if ( _idvd_pos == "42" .and. _auto_razduzenje == "D" )

	seek gFirma + "11" + "X"
  	skip -1
  	
	if field->idvd <> "11"
    	_br_kalk := SPACE( 8 )
  	else
    	_br_kalk := field->brdok
  	endif

  	_br_kalk := UBrojDok( VAL( LEFT ( _br_kalk, 5 ) ) + 1, 5, RIGHT( _br_kalk, 3 ) )

else
	seek gfirma + _idvd_pos + _br_kalk

  	if FOUND()
		Msg("Vec postoji dokument pod brojem " + gFirma + "-" + _idvd_pos + "-" + _br_kalk + "#Prenos nece biti izvrsen" )
		close all
		return
	endif
endif

select topska
go top

// nacin zamjene barkod-ova
// 0 - ne mjenjaj
// 1 - ubaci samo nove
// 2 - zamjeni sve

_bk_replace := _bk_replace()

// konto magacina za razduzenje
if ( _idvd_pos == "42" .and. _auto_razduzenje == "D" ) .or. ( _idvd_pos == "12" )
	_id_konto2 := _box_konto()
endif

// konacno idemo na import

_rbr := 0

do while !eof()
	
	_br_dok := _br_kalk
    _id_konto := koncij->id
	_rbr := STR( ++ _rbr, 3 )
	
	if ( _idvd_pos == "42" .and. _auto_razduzenje == "D" ) .or. ( _idvd_pos == "12" )
		// formiraj stavku 11	
		import_row_11( _br_dok, _id_konto, _id_konto2, _rbr )
	else
		// formiraj stavku 42
		import_row_42( _br_dok, _id_konto, _id_konto2, _rbr )
	endif
  	
	// zamjena barkod-a ako postoji
	if _bk_replace > 0

		select roba
	   	set order to tag "ID"
	    seek topska->idroba
	    	
		if Found()

			_bk_tmp := roba->barkod

			if _bk_replace == 2 .or. ( _bk_replace == 1 .and. !EMPTY( topska->barkod ) .and. topska->barkod <> _bk_tmp )
				
				my_use_semaphore_off()

				sql_table_update( nil, "BEGIN" )	

				_app_rec := dbf_get_rec()
				_app_rec["barkod"] := topska->barkod

				update_rec_server_and_dbf( "roba", _app_rec, 1, "CONT" )
		
				sql_table_update( nil, "END" )	
				my_use_semaphore_on()

			endif

	    endif

	endif
	
	select topska
  	skip

enddo

close all

if ( gMultiPM == "D" .and. _rbr > 0 .and. _auto_razduzenje == "N" )
	// pobrisi fajlove...
	FileDelete( _imp_file )
	FileDelete( STRTRAN( _imp_file ), ".dbf", ".txt" )
endif

return


// ---------------------------------------------------------
// formiraj stavku razduzenja magacina
// ---------------------------------------------------------
static function import_row_11( broj_dok, id_konto, id_konto2, r_br )
local _tip_dok := "11"		
local _t_area := SELECT()

if ( topska->kolicina == 0 )
	return
endif

select kalk_pripr
append blank
			
replace field->idfirma with gFirma
replace field->idvd with _tip_dok
replace field->brdok with broj_dok         
replace field->datdok with topska->datum  
replace field->datfaktp with topska->datum   
replace field->kolicina with topska->kolicina
replace field->idkonto with id_konto        
replace field->idkonto2 with id_konto2       
replace field->idroba with topska->idroba  
replace field->rbr with r_br           
replace field->tmarza2 with "%"            
replace field->idtarifa with topska->idtarifa
replace field->mpcsapp with topska->( mpc - stmpc )
replace field->prevoz with "R"

select ( _t_area )
return


// ---------------------------------------------------------
// formiraj stavku razduzenja prodavnice
// ---------------------------------------------------------
static function import_row_42( broj_dok, id_konto, id_konto2, r_br )
local _t_area := SELECT()

if ( topska->kolicina == 0 )
	return
endif

select kalk_pripr
append blank
			
replace field->idfirma with gFirma
replace field->idvd with topska->idvd
replace field->brdok with broj_dok         
replace field->datdok with topska->datum  
replace field->datfaktp with topska->datum   
replace field->kolicina with topska->kolicina
replace field->idkonto with id_konto        
replace field->idroba with topska->idroba  
replace field->rbr with r_br           
replace field->tmarza2 with "%"            
replace field->idtarifa with topska->idtarifa
replace field->mpcsapp with topska->mpc
replace field->rabatv with topska->stmpc
	
select ( _t_area )
return




// ----------------------------------------------------------
// daj mi sva prodajna mjesta iz koncija
// ----------------------------------------------------------
static function _prodajna_mjesta_iz_koncij()
local _a_pm := {}
local _scan

select koncij
go top

do while !EOF()
	// ako nije prazno
	// ako je maloprodaja
	if !EMPTY( field->idprodmjes ) .and. LEFT( field->tip, 1 ) == "M"
		_scan := ASCAN( _a_pm, {|x| ALLTRIM(x) == ALLTRIM( field->idprodmjes ) })
		if _scan == 0
			AADD( _a_pm, ALLTRIM( field->idprodmjes ) )
		endif
	endif
	skip
enddo

return _a_pm


// ----------------------------------------------------------
// selekcija fajla za import podataka
// ----------------------------------------------------------
static function get_import_file( import_file )
local _opc := {}
local _pos_kum_path
local _prod_mjesta
local _ret := .t.
local _i, _imp_files, _opt, _h, _n
local _imp_patt := "tk*.dbf"
local _prenesi, _izbor, _a_tmp1, _a_tmp2

if gMultiPM == "D"

	// daj mi sva prodajna mjesta iz tabele koncij
	_prod_mjesta := _prodajna_mjesta_iz_koncij()
	
	if LEN( _prod_mjesta ) == 0
		// imamo problem, nema prodajnih mjesta
		MsgBeep( "U tabeli koncij nisu definisana prodajna mjesta !!!" )
		_ret := .f.
		return _ret
	endif

	for _i := 1 to LEN( _prod_mjesta )

			// putanja koju cu koristiti	
			_pos_kum_path := ALLTRIM( gTopsDest ) + ALLTRIM( _prod_mjesta[ _i ] ) + SLASH
			
			// brisi sve fajlove starije od 28 dana
			BrisiSFajlove( _pos_kum_path )
			
			// daj mi fajlove u matricu po pattern-u
   			_imp_files := DIRECTORY( _pos_kum_path + _imp_patt )

			ASORT( _imp_files,,, {|x,y| DTOS(x[3]) + x[4] > DTOS(y[3]) + y[4] })
			
			// dodaj u matricu za odabir
			AEVAL( _imp_files, { |elem| PADR( ALLTRIM( _prod_mjesta[ _i ] ) + ;
										SLASH + TRIM(elem[1]), 20) + " " + ;
										UChkPostoji() + " " + DTOC(elem[3]) + " " + elem[4] ;
 								}, 1, D_MAX_FILES )  


	next

	// R/X + datum + vrijeme
 	ASORT( _opc ,,,{|x,y| RIGHT(x, 19) > RIGHT(y, 19) })  
 	
	_h := ARRAY( LEN( _opc ) )
 	
	for _n := 1 to LEN( _h )
   		_h[ _n ] := ""
 	next

	// ima li stavki za preuzimanje ? 	
	if LEN( _opc ) == 0

   		MsgBeep( "U direktoriju za prenos nema podataka" )
		_ret := .f.
		return _ret

 	endif

else
	MsgBeep( "Pripremi disketu za prenos ....#te pritisni nesto za nastavak" )
endif

if gMultiPM == "D"

	_izbor := 1
  	_prenesi := .f.

	do while .t.

   		_izbor := Menu( "izdat", _opc, _izbor, .f. )

		if _izbor == 0
     		exit
   		else
     		
			import_file := ALLTRIM( gTopsDest ) + ALLTRIM( LEFT( _opc[ _izbor ], 15 ) )
     			
			if Pitanje(, "Zelite li izvrsiti prenos ?", "D" ) == "D"
         		_prenesi := .t.
         		_izbor := 0
     		else
         		loop
     		endif
   		endif
  	enddo
	
  	if !_prenesi
		_ret := .f.
        return _ret
  	endif

else

	// CRC gledamo ako nije modemska veza
 	import_file := ALLTRIM( gTopsDest ) + "topska.dbf"

 	_a_tmp1 := IscitajCRC( ALLTRIM( gTopsDest ) + "crctk.crc" )
 	_a_tmp2 := IntegDBF( import_file )

	IF !( _a_tmp1[1] == _a_tmp2[1] .and. _a_tmp1[2] == _a_tmp2[2] ) 
   		Msg("CRCTK.CRC se ne slaze. Greska na disketi !",4)
		_ret := .f.
		return _ret
 	ENDIF

endif

return _ret




