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

FUNCTION rnal_print_odabir_stavki( lPriprema )

   LOCAL nArea
   LOCAL nTArea
   LOCAL GetList := {}
   LOCAL nBoxX := 12
   LOCAL nBoxY := 77
   LOCAL cHeader := ""
   LOCAL cFooter := ""
   LOCAL cBoxOpt := ""
   PRIVATE ImeKol
   PRIVATE Kol

   nTArea := Select()

   cHeader := hb_utf8tostr( ":: Odabir stavki za štampu ::" )

   t_rpt_open()

   SELECT t_docit
   GO TOP

   Box(, nBoxX, nBoxY, .T. )

   cBoxOpt += "<SPACE> markiranje stavke"
   cBoxOpt += " "
   cBoxOpt += "<ESC> izlaz"
   cBoxOpt += " "
   cBoxOpt += "<I> unos isporuke"

   @ box_x_koord() + nBoxX, box_y_koord() + 2 SAY cBoxOpt

   set_a_kol( @ImeKol, @Kol )

   my_browse( "t_docit", nBoxX, nBoxY, {|| rnal_odabir_key_handler( lPriprema ) }, cHeader, cFooter,,,,, 1 )

   BoxC()

   SELECT ( nTArea )

   IF LastKey() == K_ESC
      RETURN 1
   ENDIF

   RETURN 1



STATIC FUNCTION rnal_odabir_key_handler( lPriprema )

   LOCAL nTrec := RecNo()
   LOCAL _ret := DE_CONT
   LOCAL _rec

   DO CASE

   CASE ( Ch == Asc( ' ' ) )

      Beep( 0.5 )

      _rec := dbf_get_rec()

      IF _rec[ "print" ] == "D"
         _rec[ "print" ] := "N"
      ELSE
         _rec[ "print" ] := "D"
      ENDIF

      dbf_update_rec( _rec )

      RETURN DE_REFRESH

   CASE ( Upper( Chr( Ch ) ) ) == "I"

      IF setuj_broj_komada_za_isporuku( lPriprema ) = 0
         RETURN DE_CONT
      ELSE
         RETURN DE_REFRESH
      ENDIF

   ENDCASE

   RETURN _ret


STATIC FUNCTION setuj_broj_komada_za_isporuku( lPriprema )

   LOCAL _ret := 1
   LOCAL GetList := {}
   LOCAL _deliver := field->doc_it_qtt
   LOCAL _rec

   Box(, 1, 25 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "isporučeno ?" GET _deliver PICT "9999999.99"
   READ
   BoxC()

   IF LastKey() == K_ESC
      _ret := 0
      RETURN _ret
   ENDIF

   _rec := dbf_get_rec()
   _rec[ "doc_it_qtt" ] := _deliver
   dbf_update_rec( _rec )

   rekalkulisi_stavke_za_stampu( lPriprema )

   RETURN _ret



STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "nalog", {|| doc_no }, "doc_no", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "rbr", {|| PadR( AllTrim( Str( doc_it_no ) ), 3 ) }, "doc_it_no", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "artikal", 20 ), {|| PadR( g_art_desc( art_id, .T., .F. ), 20 ) }, "art_id", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "ispor.", {|| Str( doc_it_qtt, 12, 2 ) }, "doc_it_qtt", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "dimenzije", 20 ), {|| PadR( prikazi_dimenzije( doc_it_qtt, doc_it_hei, doc_it_wid ), 20 ) }, "doc_it_qtt", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "marker", {|| PadR( get_print_field( print ), 3 ) }, "print", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "total", {|| "doc_it_tot" }, "doc_it_tot", {|| .T. }, {|| .T. } } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


STATIC FUNCTION get_print_field( value )

   LOCAL _ret := ""

   _ret := ">"
   _ret += value
   _ret += "<"

   RETURN _ret


STATIC FUNCTION prikazi_dimenzije( qtty, height, width )

   LOCAL _ret := ""

   _ret += AllTrim( Str( qtty, 12, 0 ) )
   _ret += "x"
   _ret += AllTrim( Str( height, 12, 2 ) )
   _ret += "x"
   _ret += AllTrim( Str( width, 12, 2 ) )

   RETURN _ret
