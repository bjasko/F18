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

#include "rnal.ch"


static PIC_VRIJEDNOST := ""
static LEN_VRIJEDNOST := 12



// -----------------------------------------------------
// stampa naloga za proizvodnju u odt formatu...
// -----------------------------------------------------
function rnal_obracunski_list_odt()
local _params
local _doc_no, _doc_gr
local _ok := .f.
local _template := "obrlist.odt"

t_rpt_open()

// uzmi mi sve parametre za obracunski list
// header, footer itd...
_get_t_pars( @_params )

// kreiraj xml
if !_cre_xml( _params ) 
    return _ok
endif

// zatvori nepotrebne tabele
select t_docit
use
select t_docop
use
select t_pars
use

// lansiraj odt
if f18_odt_generate( _template )
    f18_odt_print()
endif

_ok := .t.

return _ok



// ------------------------------------------------------
// citanje vrijednosti iz tabele tpars u hash matricu
// ------------------------------------------------------
static function _get_t_pars( params )
local _tmp

params := hb_hash()

// ttotal
_tmp := VAL( g_t_pars_opis("N10") )
params["ttotal"] := _tmp

// rekapitulacija materijala
params["rekap_materijala"] := ( ALLTRIM( g_t_pars_opis("N20") ) == "D" )

// operater
_tmp := g_t_pars_opis("N13")
params["spec_operater"] := _tmp
// operater koji printa
_tmp := getfullusername( getUserid( f18_user() ) )
params["spec_print_operater"] := _tmp
// vrijeme printanja
_tmp := PADR( TIME(), 5 )
params["spec_print_vrijeme"] := _tmp

// podaci header-a
// ==============================================
// broj dokumenta
params["nalog_broj"] := g_t_pars_opis("N01")
// naziv naloga
params["nalog_datum"] := g_t_pars_opis("N02")
// vrijeme naloga
params["nalog_vrijeme"] := g_t_pars_opis("N12")
// dokumenti
params["nalozi_lista"] := g_t_pars_opis("N14")
// objekat id
params["nalog_objekat_id"] := g_t_pars_opis("P20")
// naziv objekta
params["nalog_objekat_naziv"] := g_t_pars_opis("P21")


// podaci kupca
// ===============================================
// firma
params["firma_naziv"] := ALLTRIM( gFNaziv )
// kupac
params["kupac_id"] := g_t_pars_opis("P01")
params["kupac_naziv"] := g_t_pars_opis("P02")
params["kupac_adresa"] := g_t_pars_opis("P03")
params["kupac_telefon"] := g_t_pars_opis("P04")
// kontakt
params["kontakt_id"] := g_t_pars_opis("P10")
params["kontakt_naziv"] := g_t_pars_opis("P11")
params["kontakt_telefon"] := g_t_pars_opis("P12")
params["kontakt_opis"] := g_t_pars_opis("P13")
params["kontakt_opis_2"] := g_t_pars_opis("N09")

return .t.






// -----------------------------------
// generisanje xml fajla
// -----------------------------------
static function _cre_xml( params )
local _xml := my_home() + "data.xml"
local _picdem := "999999999.99"
local _docs, _doc_no, _doc_xxx, _doc_no_str, _doc_it_str, _art_sh, _art_id
local _t_neto, _t_qtty, _t_total, _t_total_m, _description
local _t_u_neto, _t_u_qtty, _t_u_total, _t_u_total_m
local _ok := .t.
local _count := 0

PIC_VRIJEDNOST := PADL( ALLTRIM( RIGHT( _picdem, LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )

// otvori xml za upis...
open_xml( _xml )

xml_subnode( "specifikacija", .f. )
xml_subnode( "spec", .f. )

// upisi osvnovne podatke naloga
xml_node( "fdesc", to_xml_encoding( params["firma_naziv"] ) )
xml_node( "no", params["nalog_broj"] )
xml_node( "cdate", DTOC( DATE() ) )
xml_node( "date", params["nalog_datum"] )
xml_node( "time", params["nalog_vrijeme"] )
xml_node( "ob_id", to_xml_encoding( params["nalog_objekat_id"] ) )
xml_node( "ob_desc", to_xml_encoding( params["nalog_objekat_naziv"] ) )
xml_node( "oper", to_xml_encoding( params["spec_operater"] ) )
xml_node( "oper_print", to_xml_encoding( params["spec_print_operater"] ) )
xml_node( "pr_time", params["spec_print_vrijeme"] )

_docs := ALLTRIM( params["nalozi_lista"] )
if "," $ _docs
    xml_node( "lst", to_xml_encoding( "prema nalozima: " + ALLTRIM( _docs ) ) )
else
    xml_node( "lst", to_xml_encoding( "prema nalogu br: " + ALLTRIM( params["nalog_broj"] ) ) )
endif

// kupac/kontakt podaci...
xml_node( "cust_id", to_xml_encoding( params["kupac_id"] ) )
xml_node( "cust_desc", to_xml_encoding( params["kupac_naziv"] ) )
xml_node( "cust_adr", to_xml_encoding( params["kupac_adresa"] ) )
xml_node( "cust_tel", to_xml_encoding( params["kupac_telefon"] ) )
xml_node( "cont_id", to_xml_encoding( params["kontakt_id"] ) )
xml_node( "cont_desc", to_xml_encoding( params["kontakt_naziv"] ) )
xml_node( "cont_tel", to_xml_encoding( params["kontakt_telefon"] ) )
xml_node( "cont_desc_2", to_xml_encoding( params["kontakt_opis"] ) )
xml_node( "cont_desc_3", to_xml_encoding( params["kontakt_opis_2"] ) )

select t_docit
set order to tag "3"
go top

_doc_xxx := "XX"

_item := 0

_t_neto := 0
_t_qtty := 0
_t_total := 0
_t_total_m := 0
_t_u_neto := 0
_t_u_qtty := 0
_t_u_total := 0
_t_u_total_m := 0

// stampaj podatke 
do while !EOF()

    _doc_no := field->doc_no

    do while !EOF() .and. field->doc_no == _doc_no 

        _art_sh := field->art_sh_des
    
        // da li se stavka stampa ili ne ?
        if field->print == "N"
            skip
            loop
        endif
     
        _doc_no_str := docno_str( field->doc_no )
        _doc_it_str := docit_str( field->doc_it_no )

        // <"nalog">
        xml_subnode( "nalog", .f. )

        // broj naloga
        xml_node( "no", _doc_no_str )

        do while !EOF() .and. field->doc_no == _doc_no ;
            .and. PADR(field->art_sh_des, 150 ) == ;
                PADR( _art_sh, 150 )

            ++ _count

            // da li se stavka stampa ili ne ?
            if field->print == "N"
                skip
                loop
            endif

            _doc_no_str := docno_str( field->doc_no )
            _doc_it_str := docit_str( field->doc_it_no )

            xml_subnode( "item", .f. )

            xml_node( "no", ALLTRIM( STR( ++_item ) ) )
            
            xml_node( "art_id", ALLTRIM( STR( field->art_id ) ) )
            xml_node( "qtty", show_number( field->doc_it_qtt, PIC_VRIJEDNOST ) )
            xml_node( "h", show_number( field->doc_it_hei, PIC_VRIJEDNOST ) )
            xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) )
            xml_node( "zh", show_number( field->doc_it_zhe, PIC_VRIJEDNOST ) )
            xml_node( "zw", show_number( field->doc_it_zwi, PIC_VRIJEDNOST ) )
            xml_node( "nt", show_number( field->doc_it_net, PIC_VRIJEDNOST ) )
            xml_node( "tot", show_number( field->doc_it_tot, PIC_VRIJEDNOST ) )
            xml_node( "tm", show_number( field->doc_it_tm, PIC_VRIJEDNOST ) )

            // saberi...
            _t_qtty += field->doc_it_qtt
            _t_neto += field->doc_it_net
            _t_total += field->doc_it_tot
            _t_total_m += field->doc_it_tm

            _description := ALLTRIM( field->art_desc )
            if _count == 1 .and. EMPTY( _description )
                _description := ALLTRIM( field->full_desc )
            endif

            // opis stavke...
            if EMPTY( _description )
                _art_desc := "-//-"
            else
                _art_desc := ALLTRIM( _description )
            endif

            // redni broj u nalogu
            _art_desc := "(" + ALLTRIM( STR( field->doc_it_no )) + ") " + _art_desc
            // pozicija ako postotoji
            _art_desc += "; " + ALLTRIM( field->doc_it_des )

            xml_node( "art_desc", to_xml_encoding( _art_desc ) )
            
            // zatvori node...
            xml_subnode( "item", .t. )
    
            select t_docit
            skip

        enddo   

        // totali po dokumentu ...
        xml_node( "qtty",  show_number( _t_qtty, PIC_VRIJEDNOST ) )
        xml_node( "nt",  show_number( _t_neto, PIC_VRIJEDNOST ) )
        xml_node( "tot",  show_number( _t_total, PIC_VRIJEDNOST ) )
        xml_node( "tm",  show_number( _t_total_m, PIC_VRIJEDNOST ) )

        // dodaj na konacni zbir
        _t_u_qtty += _t_qtty
        _t_u_neto += _t_neto
        _t_u_total += _t_total
        _t_u_total_m += _t_total_m

        // resetuj varijable totale
        _t_total_m := 0
        _t_total := 0
        _t_qtty := 0
        _t_neto := 0

        _doc_xxx := _doc_no_str
   
        xml_subnode( "nalog", .t. )
 
    enddo

enddo

// ukupno total...
xml_node( "qtty",  show_number( _t_u_qtty, PIC_VRIJEDNOST ) )
xml_node( "nt",  show_number( _t_u_neto, PIC_VRIJEDNOST ) )
xml_node( "tot",  show_number( _t_u_total, PIC_VRIJEDNOST ) )
xml_node( "tm",  show_number( _t_u_total_m, PIC_VRIJEDNOST ) )

// rekapitulacija materijala treba
xml_subnode( "rekap", .f. )

select t_docit2
go top

if RECCOUNT2() <> 0 .and. params["rekap_materijala"]
	
    do while !EOF() 

	    _r_doc := field->doc_no
	    _r_doc_it_no := field->doc_it_no

	    // da li se treba stampati ?
	    select t_docit
	    seek docno_str( _r_doc ) + docit_str( _r_doc_it_no )
	
	    if field->print == "N"
		    select t_docit2
		    skip
		    loop
	    endif
	
	    // vrati se
	    select t_docit2

	    do while !EOF() .and. field->doc_no == _r_doc ;
		                .and. field->doc_it_no == _r_doc_it_no
		
            xml_subnode( "item", .f. )

            xml_node( "no", "(" + ALLTRIM( STR( field->doc_it_no ) )+ ")/" + ALLTRIM(STR( field->it_no ) ) )
            xml_node( "id", to_xml_encoding( ALLTRIM( field->art_id ) ) )
            xml_node( "desc", to_xml_encoding( ALLTRIM( field->art_desc ) ) )
            xml_node( "notes", to_xml_encoding( ALLTRIM( field->descr ) ) )
            xml_node( "qtty", ALLTRIM( STR( field->doc_it_qtt, 12, 2 ) ) )

			// ako u polju postoji informacija onda je to sigurno unesena dužina
			if field->doc_it_q2 > 0
				xml_node( "duz", "x " + ALLTRIM( STR( field->doc_it_q2, 12, 2 ) ) + " (mm)" ) 
			else
				xml_node( "duz", "" )
			endif

            xml_subnode( "item", .t. )

		    skip
	    enddo

    enddo

endif

xml_subnode( "rekap", .t. )

xml_subnode( "spec", .t. )

xml_subnode( "specifikacija", .t. )

close_xml()

return _ok





