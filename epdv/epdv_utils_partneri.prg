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


#include "f18.ch"


FUNCTION s_partner( cIdPartn )

   LOCAL cPom
   LOCAL cIdBroj
   LOCAL cPdvBroj
   LOCAL cMjesto

   PushWA()

   select_o_partner( cIdPartn )

   cPom := ""

   cPom += AllTrim( field->naz )
   cMjesto := AllTrim( field->mjesto )
   IF Empty( cMjesto )
      cMjesto := "-NEP.MJ-"
   ENDIF

   IF !Empty( field->ptt )
      cMjesto := AllTrim( field->ptt ) + " " + cMjesto
   ENDIF

   cPom += ", " + cMjesto

   cPdvBroj := firma_pdv_broj( cIdPartn )

   IF !Empty( cPdvBroj )
      cPdvBroj := "PDV: " + cPdvBroj + " / "
   ELSE
      cPdvBroj := ""
   ENDIF

   cIdBroj := firma_id_broj( cIdPartn )

   IF Empty( cIdBroj )
      cIdBroj := "-NEP.ID-"
   ELSE
      cIdBroj := "ID: " + cIdBroj
   ENDIF

   cPom += ", " + cPdvBroj + cIdBroj

   PopWa()

   RETURN cPom


// -----------------------------------------------
// podaci o mojoj firmi ubaceni u partnera "10"

// lRetArray - .t. - vrati matricu
// .f. - vrati string, default
// -----------------------------------------------
FUNCTION my_firma( lRetArray )

   LOCAL lNepopunjeno := .F.
   LOCAL cNaziv
   LOCAL cMjesto
   LOCAL cIdBroj
   LOCAL cAdresa
   LOCAL cPtt
   LOCAL cPom := self_organizacija_naziv()
   LOCAL hRec

   PushWA()

   IF lRetArray == nil
      lRetArray := .F.
   ENDIF

   IF !select_o_partner( self_organizacija_id() )
      APPEND BLANK
      hRec := dbf_get_rec()
      hRec[ "id" ] := self_organizacija_id()
      update_rec_server_and_dbf( "partn", hRec, 1, "FULL" )
   ENDIF

   cNaziv := field->naz
   cMjesto := field->mjesto
   cIdBroj := firma_pdv_broj( self_organizacija_id() )
   cAdresa := field->adresa
   cPtt := field->ptt

   IF  Empty( cNaziv ) .OR. Empty( cMjesto ) .OR. Empty( cIdBroj ) .OR. Empty( cPTT ) .OR. Empty( cAdresa )
      lNepopunjeno := .T.
   ENDIF


   IF lNepopunjeno
      IF get_my_firma( @cNaziv, @cIdBroj, @cMjesto, @cAdresa, @cPtt )

         hRec           := dbf_get_rec()
         hRec[ "naz" ]    := cNaziv
         hRec[ "mjesto" ] := cMjesto
         hRec[ "adresa" ] := cAdresa
         hRec[ "ptt" ]    := cPTT

         update_rec_server_and_dbf( "partn", hRec, 1, "FULL" )
         // USifK( "PARTN", "REGB", self_organizacija_id(), Unicode():New( cIdBroj, .F. ) )
         // USifK( "PARTN", "REGB", self_organizacija_id(), cIdBroj )

      ELSE
         MsgBeep( "Nepopunjeni podaci o matičnoj firmi !" )
      ENDIF

   ENDIF

   cPom := Trim( cNaziv ) + ", Id.br: " + cIdBroj + " , " + cPtt + " " + AllTrim( cMjesto )
   cPom += " , " + AllTrim( cAdresa )

   PopWa()

   IF lRetArray
      RETURN { cNaziv, cIdBroj, cPtt, cMjesto, cAdresa }
   ENDIF

   RETURN cPom


FUNCTION get_my_firma( cNaziv, cIdBroj, cMjesto, cAdresa, cPtt )

   LOCAL GetList := {}

   BOX (, 7, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Podaci o matičnoj firmi: "
   @ box_x_koord() + 2, box_y_koord() + 2 SAY Replicate( "-", 40 )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Naziv   " GET cNaziv PICT "@S40"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Id.broj " GET cIdBroj
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Mjesto  " GET cMjesto
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Adresa  " GET cAdresa
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "PTT     " GET cPtt

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   RETURN .T.


// -----------------------------------------------
// ger rejon partnera
// - 1 ili " " federacija
// - 2 - rs
// - 3 - brcko district
// -----------------------------------------------

FUNCTION part_rejon( cIdPart )

   LOCAL cRejon

   PushWA()

   select_o_partner( self_organizacija_id() )

   // cRejon := get_partn_sifk_sifv( "REJO", Unicode():New( cIdPart, .F. ), .F. )
   cRejon := get_partn_sifk_sifv( "REJO", cIdPart, .F. )

   PopWa()

   RETURN cRejon



// ---------------------------------------------
// da li se radi o specijalnom partneru
// - upravi za indirektno oporezivanje
// ---------------------------------------------
FUNCTION IsUIO( cIdPartner )
   RETURN IsProfil( cIdPartner, "UIO" )
