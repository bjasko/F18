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

/*
   Opis: šalje izvještaj na email podrške
*/
FUNCTION txt_izvjestaj_podrska_email( file_name )

   LOCAL _attach, _body, _subject, _mail_params

   // Uzorak TXT izvještaja, F18 1.7.21, rg_2013/bjasko, 02.04.04, 15:00:07
   _subject := "Uzorak TXT izvještaja, F18 "
   _subject += f18_ver()
   _subject += ", " + my_server_params()[ "database" ] + "/" + AllTrim( f18_user() )
   _subject += ", " + DToC( Date() ) + " " + PadR( Time(), 8 )

   _body := "U prilogu primjer TXT izvještaja"

   _mail_params := email_hash_za_podrska_bring_out( _subject, _body )

   _attach := { file_name }

   MsgO( "Slanje email-a u toku ..." )

   f18_email_send( _mail_params, _attach )

   MsgC()

   RETURN .T.
