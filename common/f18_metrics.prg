#include "fmk.ch"



// funkcije za setovanje i iscitavanje parametara iz knowhow database-a
// koriste se pqsql funkcije fetchmetrictext() i setmetrictext()

// primjer koristenja:
//
// (citanje)
// local gFc_use := "N"
// f18_get_metric("KoristitiFiskalneFunkcije", @gFc_use )
//
// (upisivanje)
// f18_set_metric("KoristitiFiskalneFunkcije", gFc_use )
//
// ako zelimo da nas parametar bude globalan dodajemo .t. kao treci 
// parametar funkcijama, npr:
//
// f18_get_metric("Koristiti...", @gFc_use, .t.) 
//
// -------------------------------------------------------------
// vrati parametar iz metric tabele
// -------------------------------------------------------------
function f18_get_metric( param, value, global )
local _temp_qry
local _table
local _server := pg_server()
local _temp_res := ""

if global == nil
	global := .f.
endif

_temp_qry := "SELECT fetchmetrictext(" + _sql_quote( __param_name(param, global) ) + ")"
_table := _sql_query( _server, _temp_qry )
if _table == NIL
	MsgBeep( "problem sa: " + _temp_qry )
    return .f.
endif

_temp_res := _table:Fieldget( _table:Fieldpos("fetchmetrictext") )

if EMPTY( _temp_res )
	f18_set_metric( param, value, global )
else
	value := __get_param_value( value, _temp_res )
endif

return .t.



// --------------------------------------------------------------
// setuj parametre u metric tabelu
// --------------------------------------------------------------
function f18_set_metric( param, value, global )
local _temp_qry
local _table
local _server := pg_server()

if global == nil
	global := .f.
endif

_temp_qry := "SELECT setmetric(" + _sql_quote( __param_name(param, global) ) + "," + _sql_quote( __set_param_value( value ) ) +  ")"
_table := _sql_query( _server, _temp_qry )
if _table == NIL
	MsgBeep( "problem sa:" + _temp_qry )
    return .f.
endif

return _table:Fieldget( _table:Fieldpos("setmetric") )




// -------------------------------------------------------------
// vraca naziv parametra
// 
// struktura parametra ce biti 
//    za global_param = .t.    F18/global/naziv_parametra
//    za global_param = .f.    F18/FIN/naziv_parametra
// -------------------------------------------------------------
static function __param_name( param, global_param )
local __ret := ""

__ret += "F18/"

if global_param = .t.
	__ret += "global/" 
else
	__ret += goModul:oDataBase:cName + "/"
endif

__ret += param

return __ret


// vraca vrijednost varijable iz baze na osnovu originalne 
// vrijednosti
// iz baze će nam sve izaći kao "string" pa moramo napraviti konverziju
static function __get_param_value( _orig_value, _string )
local __val_type := valtype( _orig_value )

do case
	case __val_type == "C"
		// ovo je string
		return _string
	case __val_type == "N"
		// ovo je numeric
		return val( _string )
	case __val_type == "D"
		// ovo je date
		return ctod( _string )
	case __val_type == "L"
		// ovo je bool
		if _string = ".t."
			return .t.
		else
			return .f.
		endif
endcase

return



// setuje varijable i pri tome konvertuje kao string
static function __set_param_value( value )
local __val_type := valtype( value )

do case
	case __val_type == "C"
		// ovo je string
		return value
	case __val_type == "N"
		// ovo je numeric
		return str( value )
	case __val_type == "D"
		// ovo je date
		return dtoc( value )
	case __val_type == "L"
		// ovo je bool
		if value = .t.
			return "TRUE"
		else
			return "FALSE"
		endif
endcase

return


