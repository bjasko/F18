/* 
 * This file is part of the bring.out knowhow ERP, a free and open source 
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "fmk.ch"


// parametri aplikacije
function f18_app_parameters( just_set )
local _x := 1
local _pos_x
local _pos_y
local _left := 20
local _fin, _kalk, _fakt, _epdv, _virm, _ld, _os, _rnal, _mat
local _pos
local _email_server, _email_port, _email_username, _email_userpass, _email_from
local _email_to, _email_cc

// parametri modula koristenih na glavnom meniju...
_fin := fetch_metric( "main_menu_fin", my_user(), "D" )
_kalk := fetch_metric( "main_menu_kalk", my_user(), "D" )
_fakt := fetch_metric( "main_menu_fakt", my_user(), "D" )
_ld := fetch_metric( "main_menu_ld", my_user(), "D" )
_epdv := fetch_metric( "main_menu_epdv", my_user(), "D" )
_virm := fetch_metric( "main_menu_virm", my_user(), "D" )
_os := fetch_metric( "main_menu_os", my_user(), "D" )
_rnal := fetch_metric( "main_menu_rnal", my_user(), "N" )
_mat := fetch_metric( "main_menu_mat", my_user(), "N" )
_pos := fetch_metric( "main_menu_pos", my_user(), "N" )


// email parametri
_email_server := PADR( fetch_metric( "email_server", my_user(), "" ), 100 )
_email_port := fetch_metric( "email_port", my_user(), 25 )
_email_username := PADR( fetch_metric( "email_user_name", my_user(), "" ), 100 )
_email_userpass := PADR( fetch_metric( "email_user_pass", my_user(), "" ), 50 )
_email_from := PADR( fetch_metric( "email_from", my_user(), "" ), 100 )
_email_to := PADR( fetch_metric( "email_to_default", my_user(), "" ), 500 )
_email_cc := PADR( fetch_metric( "email_cc_default", my_user(), "" ), 500 )

if just_set == nil
	just_set := .f.
endif

if !just_set

	clear screen

	?

	_pos_x := 2
	_pos_y := 3

	@ _pos_x, _pos_y SAY "Odabir modula za glavni menij ***" COLOR "I"

	@ _pos_x + _x, _pos_y SAY SPACE(2) + "FIN:" GET _fin PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "KALK:" GET _kalk PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "FAKT:" GET _fakt PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "ePDV:" GET _epdv PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "LD:" GET _ld PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "VIRM:" GET _virm PICT "@!"
	
	++ _x
	@ _pos_x + _x, _pos_y SAY SPACE(2) + "OS/SII:" GET _os PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "POS:" GET _pos PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "MAT:" GET _mat PICT "@!"
	@ _pos_x + _x, col() + 1 SAY "RNAL:" GET _rnal PICT "@!"

	++ _x
	++ _x

	@ _pos_x + _x, _pos_y SAY "Email parametri ***" COLOR "I"
	++ _x
	@ _pos_x + _x, _pos_y SAY PADL( "email server:", _left ) GET _email_server PICT "@S30"
	@ _pos_x + _x, col() + 1 SAY "port:" GET _email_port PICT "9999"
 	++ _x
	@ _pos_x + _x, _pos_y SAY PADL( "username:", _left ) GET _email_username PICT "@S30"
	@ _pos_x + _x, col() + 1 SAY "password:" GET _email_userpass PICT "@S30" COLOR "BG/BG"
	++ _x
	@ _pos_x + _x, _pos_y SAY PADL( "moja email adresa:", _left ) GET _email_from PICT "@S40"
	++ _x
	@ _pos_x + _x, _pos_y SAY PADL( "slati postu na adrese:", _left ) GET _email_to PICT "@S70"
	++ _x
	@ _pos_x + _x, _pos_y SAY PADL( "cc adrese:", _left ) GET _email_cc PICT "@S70"

	read

	if LastKey() == K_ESC
    	return
	endif

endif

// parametri modula...
set_metric( "main_menu_fin", my_user(), _fin )
set_metric( "main_menu_kalk", my_user(), _kalk )
set_metric( "main_menu_fakt", my_user(), _fakt )
set_metric( "main_menu_ld", my_user(), _ld )
set_metric( "main_menu_virm", my_user(), _virm )
set_metric( "main_menu_os", my_user(), _os )
set_metric( "main_menu_epdv", my_user(), _epdv )
set_metric( "main_menu_rnal", my_user(), _rnal )
set_metric( "main_menu_mat", my_user(), _mat )
set_metric( "main_menu_pos", my_user(), _pos )

// email parametri
set_metric( "email_server", my_user(), ALLTRIM( _email_server ) )
set_metric( "email_port", my_user(), _email_port )
set_metric( "email_user_name", my_user(), ALLTRIM( _email_username ) )
set_metric( "email_user_pass", my_user(), ALLTRIM( _email_userpass ) ) 
set_metric( "email_from", my_user(), ALLTRIM( _email_from ) )
set_metric( "email_to_default", my_user(), ALLTRIM( _email_to ) )
set_metric( "email_cc_default", my_user(), ALLTRIM( _email_cc ) )

return


// ---------------------------------------------------------------------
// koristi se pojedini od modula na osnovu parametara
// ---------------------------------------------------------------------
function f18_use_module( module_name )
local _ret := .f.

if fetch_metric( "main_menu_" + module_name, my_user(), "D" ) == "D"
	_ret := .t.
endif

return _ret



