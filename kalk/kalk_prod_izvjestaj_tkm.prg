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

STATIC __LEN_OPIS := 70


// -----------------------------------------
// izvjestaj TKM
// -----------------------------------------
FUNCTION kalk_tkm()

   LOCAL _vars
   LOCAL _calc_rec := 0

   // skeleton ::

   // uslovi izvjestaja...
   IF !get_vars( @_vars )
      RETURN
   ENDIF

   // generisanje izvjestaja
   _calc_rec := kalk_gen_fin_stanje_prodavnice( _vars )

   IF _calc_rec > 0
      // stampaj TKM izvjestaj
      stampaj_tkm( _vars )
   ENDIF

   RETURN


// -----------------------------------------
// uslovi izvjestaja
// -----------------------------------------
STATIC FUNCTION get_vars( vars )

   LOCAL _ret := .F.
   LOCAL _x := 1
   LOCAL _konta := fetch_metric( "kalk_tkm_konto", my_user(), Space( 200 ) )
   LOCAL _d_od := fetch_metric( "kalk_tkm_datum_od", my_user(), Date() -30 )
   LOCAL _d_do := fetch_metric( "kalk_tkm_datum_do", my_user(), Date() )
   LOCAL _vr_dok := fetch_metric( "kalk_tkm_vrste_dok", my_user(), Space( 200 ) )
   LOCAL _usluge := fetch_metric( "kalk_tkm_gledaj_usluge", my_user(), "N" )
   LOCAL _vise_konta := "D"

   Box(, 10, 70 )

   @ m_x + _x, m_y + 2 SAY "*** maloprodaja - izvjestaj TKM"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Datum od" GET _d_od
   @ m_x + _x, Col() + 1 SAY "do" GET _d_do

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "     Konto (prazno-svi):" GET _konta PICT "@S35"

   ++ _x

   @ m_x + _x, m_y + 2 SAY "Vrste dok. (prazno-svi):" GET _vr_dok PICT "@S35"

   ++ _x
   ++ _x

   @ m_x + _x, m_y + 2 SAY "Gledati usluge (D/N) ?" GET _usluge PICT "@!" VALID _usluge $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ret
   ENDIF

   _ret := .T.

   // snimi hash matricu...
   vars := hb_Hash()
   vars[ "datum_od" ] := _d_od
   vars[ "datum_do" ] := _d_do
   vars[ "konto" ] := _konta
   vars[ "vrste_dok" ] := _vr_dok
   vars[ "gledati_usluge" ] := _usluge
   // ako postoji tacka u kontu onda gledaj
   IF Right( AllTrim( _konta ), 1 ) == "."
      _vise_konta := "N"
   ENDIF
   vars[ "vise_konta" ] := _vise_konta

   // snimi sql/db parametre
   set_metric( "kalk_tkm_konto", my_user(), _konta )
   set_metric( "kalk_tkm_datum_od", my_user(), _d_od )
   set_metric( "kalk_tkm_datum_do", my_user(), _d_do )
   set_metric( "kalk_tkm_vrste_dok", my_user(), _vr_dok )
   set_metric( "kalk_tkm_gledati_usluge", my_user(), _usluge )

   RETURN _ret



// ------------------------------------------
// stampa izvjestaja TKM
// ------------------------------------------
STATIC FUNCTION stampaj_tkm( vars )

   LOCAL _red_br := 0
   LOCAL _line, _opis_knjizenja
   LOCAL _n_opis, _n_iznosi
   LOCAL _t_dug, _t_pot, _t_rabat
   LOCAL _a_opis := {}
   LOCAL _i

   // daj mi liniju za report...
   _line := _get_line()

   START PRINT CRET

   ?
   P_COND

   // ispisi zaglavlje izvjestaja
   tkm_zaglavlje( vars )

   // stampaj header izvjestaja
   ? _line
   tkm_header()
   ? _line

   _t_dug := 0
   _t_pot := 0
   _t_rabat := 0

   SELECT r_export
   GO TOP

   DO WHILE !Eof()

      // preskoci ako su stavke = 0
      IF ( Round( field->mp_saldo, 2 ) == 0 .AND. Round( field->nv_saldo, 2 ) == 0 )
         SKIP
         LOOP
      ENDIF

      // 1. red izvjestaja...

      // redni broj...
      ? PadL( AllTrim( Str( ++_red_br ) ), 6 ) + "."

      // datum dokumenta
      @ PRow(), PCol() + 1 SAY field->datum

      // generisi string za opis knjizenja...
      _opis_knjizenja := AllTrim( field->vr_dok )
      _opis_knjizenja += " "
      _opis_knjizenja += "broj: "
      _opis_knjizenja += AllTrim( field->idvd ) + "-" + AllTrim( field->brdok )
      _opis_knjizenja += ", "
      _opis_knjizenja += "veza: " + AllTrim( field->br_fakt )

      IF !Empty( field->opis )
         _opis_knjizenja += ", "
         _opis_knjizenja += AllTrim( field->opis )
      ENDIF

      IF !Empty( field->part_naz )
         _opis_knjizenja += ", "
         _opis_knjizenja += AllTrim( field->part_naz )
         _opis_knjizenja += ", "
         _opis_knjizenja += AllTrim( field->part_adr )
         _opis_knjizenja += ", "
         _opis_knjizenja += AllTrim( field->part_mj )
      ENDIF

      _a_opis := SjeciStr( _opis_knjizenja, __LEN_OPIS )

      // opis knjizenja
      @ PRow(), _n_opis := PCol() + 1 SAY _a_opis[ 1 ]

      // zaduzenje sa PDV
      @ PRow(), _n_iznosi := PCol() + 1 SAY Str( field->mpp_dug + ( -field->mp_rabat ), 12, 2 )

      // razduzenje sa PDV
      @ PRow(), PCol() + 1 SAY Str( ( field->mp_pot + field->mp_porez ), 12, 2 )

      _t_dug += field->mpp_dug + ( -field->mp_rabat )
      _t_pot += field->mp_pot + field->mp_porez
      _t_rabat += field->mp_rabat


      // 2, 3... red izvjestaja...
      // radi opisnog polja...

      FOR _i := 2 TO Len( _a_opis )
         ?
         @ PRow(), _n_opis SAY _a_opis[ _i ]
      NEXT

      SKIP

   ENDDO

   ? _line

   // stampaj ukupno
   ? "UKUPNO:"
   @ PRow(), _n_iznosi SAY Str( _t_dug, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( _t_pot, 12, 2 )
   // @ prow(), pcol() + 1 SAY STR( _t_rabat, 12, 2 )

   ? "SALDO TRGOVACKE KNJIGE:"
   @ PRow(), _n_iznosi SAY Str( _t_dug - _t_pot, 12, 2 )

   ? _line

   FF
   END PRINT

   RETURN



// ----------------------------------------
// vraca liniju za report
// ----------------------------------------
STATIC FUNCTION _get_line()

   LOCAL _line

   _line := ""
   _line += Replicate( "-", 7 )
   _line += Space( 1 )
   _line += Replicate( "-", 8 )
   _line += Space( 1 )
   _line += Replicate( "-", __LEN_OPIS )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )

   RETURN _line


// -----------------------------------------
// zaglavlje izvjestaja
// -----------------------------------------
STATIC FUNCTION tkm_zaglavlje( vars )

   ? gFirma, "-", AllTrim( gNFirma )
   ?
   ? Space( 10 ), "TRGOVACKA KNJIGA NA MALO (TKM) za period od:", vars[ "datum_od" ], "do:", vars[ "datum_do" ]
   ?
   ? "Uslov za prodavnice: "

   IF !Empty( AllTrim( vars[ "konto" ] ) )
      ?? AllTrim( vars[ "konto" ] )
   ELSE
      ?? " sve prodavnice"
   ENDIF

   ? "na dan", Date()

   ?

   RETURN


// -----------------------------------------
// header izvjestaja
// -----------------------------------------
STATIC FUNCTION tkm_header()

   LOCAL _row_1, _row_2

   _row_1 := ""
   _row_2 := ""

   _row_1 += PadR( "R.Br", 7 )
   _row_2 += PadR( "", 7 )

   _row_1 += Space( 1 )
   _row_2 += Space( 1 )

   _row_1 += PadC( "Datum", 8 )
   _row_2 += PadC( "dokum.", 8 )

   _row_1 += Space( 1 )
   _row_2 += Space( 1 )

   _row_1 += PadR( "", __LEN_OPIS )
   _row_2 += PadR( "Opis knjizenja", __LEN_OPIS )

   _row_1 += Space( 1 )
   _row_2 += Space( 1 )

   _row_1 += PadC( "Zaduzenje", 12 )
   _row_2 += PadC( "sa PDV", 12 )

   _row_1 += Space( 1 )
   _row_2 += Space( 1 )

   _row_1 += PadC( "Razduzenje", 12 )
   _row_2 += PadC( "sa PDV", 12 )

   ? _row_1
   ? _row_2

   RETURN
