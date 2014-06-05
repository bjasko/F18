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


#include "epdv.ch"

FUNCTION ed_kuf()

   o_kuf( .T. )
   tbl_priprema()

   RETURN




STATIC FUNCTION tbl_priprema()

   LOCAL _row := maxrows() - 4
   LOCAL _col := maxcols() - 3

   Box(, _row, _col )

   @ m_x + _row - 2, m_y + 2 SAY "<c-N>  Nove Stavke    | <ENT> Ispravi stavku   | <c-T> Brisi Stavku         "
   @ m_x + _row - 1, m_y + 2 SAY "<c-A>  Ispravka Naloga| <c-P> Stampa dokumenta | <a-A> Azuriranje           "
   @ m_x + _row, m_y + 2 SAY "<a-P>  Povrat dok.    | <a-X> Renumeracija"

   PRIVATE ImeKol
   PRIVATE Kol

   SELECT ( F_P_KUF )
   SET ORDER TO TAG "br_dok"
   GO TOP

   set_a_kol( @Kol, @ImeKol )
   ObjDbedit( "ekuf", _row, _col, {|| k_handler() }, "", "KUF Priprema...", , , , , 3 )
   BoxC()
   closeret


STATIC FUNCTION set_a_kol( aKol, aImeKol )

   aImeKol := {}

   AAdd( aImeKol, { "Br.dok", {|| Transform( br_dok, "99999" ) }, "br_dok", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "R.br", {|| Transform( r_br, "99999" ) }, "r_br", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { "Datum", {|| datum }, "datum", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Tarifa", 6 ), {|| id_tar }, "id_tar", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Dobavljac", 15 ), {|| PadR( s_partner( id_part ), 13 ) + ".." }, "opis", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { PadR( "Br.dob - Opis", 17 ), {|| PadR( AllTrim( src_br_2 ) + "-" + opis, 15 ) + ".." }, "", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.b.pdv", {|| Transform( i_b_pdv, PIC_IZN() ) }, "i_b_pdv", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.pdv", {|| Transform( i_pdv, PIC_IZN() ) }, "i_pdv", {|| .T. }, {|| .T. } } )
   AAdd( aImeKol, { "Izn.s.pdv", {|| Transform( i_b_pdv + i_pdv, PIC_IZN() ) }, "", {|| .T. }, {|| .T. } } )

   aKol := {}
   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


STATIC FUNCTION ed_item( lNova )

   LOCAL cIspravno := "D"
   LOCAL nI_s_pdv := 0
   LOCAL nX := 2
   LOCAL nXPart := 0
   LOCAL nYPart := 22

   Box(, 16, 70 )
   IF lNova
      _br_dok := 0
      _r_br := next_r_br( "P_KUF" )
      _id_part := Space( Len( id_part ) )
      _id_tar := PadR( "PDV17", Len( id_tar ) )
      _datum := Date()
      _opis := Space( Len( opis ) )
      _i_b_pdv := 0
      _i_pdv := 0
      _src_br_2 := Space( Len( src_br_2 ) )
   ENDIF

   @ m_x + nX, m_y + 2 SAY "R.br: " GET _r_br ;
      PICT "999999"

   @ m_x + nX, Col() + 2 SAY "datum: " GET _datum
   nX += 2

   nXPart := nX
   @ m_x + nX, m_y + 2 SAY "Dobavljac: " GET _id_part ;
      VALID v_part( @_id_part, @_id_tar, "KUF", .T. ) ;
      PICT "@!"

   nX += 2


   @ m_x + nX, m_y + 2 SAY "Broj fakture " GET _src_br_2
   nX ++

   @ m_x + nX, m_y + 2 SAY "Opis stavke: " GET _opis ;
      WHEN {|| SetPos( m_x + nXPart, m_y + nYPart ), QQOut( s_partner( _id_part ) ), .T. } ;
      PICT "@S50"

   nX += 2

   @ m_x + nX, m_y + 2 SAY "Iznos bez PDV (osnovica): " GET _i_b_pdv ;
      PICT PIC_IZN()
   ++nX

   @ m_x + nX, m_y + 2 SAY "tarifa: " GET _id_tar ;
      VALID v_id_tar( @_id_tar, @_i_b_pdv, @_i_pdv,  Col(), lNova )  ;
      PICT "@!"

   ++nX

   @ m_x + nX, m_y + 2 SAY "   Iznos PDV: " GET _i_pdv ;
      WHEN {||  .T. } ;
      VALID {|| nI_s_pdv := _i_b_pdv + _i_pdv, .T. } ;
      PICT PIC_IZN()
   ++nX

   @ m_x + nX, m_y + 2 SAY "Iznos sa PDV: " GET nI_s_pdv ;
      when {|| .F. } ;
      PICT PIC_IZN()
   nX += 2

   @ m_x + nX, m_y + 2 SAY "Ispravno ?" GET cIspravno ;
      PICT "@!"
   ++nX

   READ

   SELECT F_P_KUF
   BoxC()

   ESC_RETURN .F.

   IF cIspravno == "D"
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF



STATIC FUNCTION k_handler()

   LOCAL nTekRec
   LOCAL nBrDokP

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0
      RETURN DE_CONT
   ENDIF

   DO CASE

   CASE ( Ch == K_CTRL_T )

      SELECT P_KUF
      RETURN browse_brisi_stavku( .T. )

   CASE ( Ch == K_ENTER )

      SELECT P_KUF
      nTekRec := RecNo()
      my_flock()
      Scatter()
      IF ed_item( .F. )
         SELECT P_KUF
         GO nTekRec
         Gather()
         RETURN DE_REFRESH
      ENDIF
      my_unlock()
      RETURN DE_CONT

   CASE ( Ch == K_CTRL_N )

      SELECT P_KUF
      my_flock()

      DO WHILE .T.

         SELECT P_KUF
         APPEND BLANK
         nTekRec := RecNo()
         Scatter()

         IF ed_item( .T. )
            GO nTekRec
            Gather()
         ELSE
            // brisi necemo ovu stavku
            SELECT P_KUF
            GO nTekRec
            DELETE
            EXIT
         ENDIF
      ENDDO

      my_unlock()

      SET ORDER TO TAG "BR_DOK"
      GO BOTTOM

      RETURN DE_REFRESH

   CASE ( Ch  == K_CTRL_F9 )

      IF Pitanje( , "Želite li izbrisati pripremu !!????", "N" ) == "D"
         my_dbf_zap()
         RETURN DE_REFRESH
      ENDIF
      RETURN DE_CONT

   CASE Ch == K_CTRL_P

      nBrDokP := 0
      Box( , 2, 60 )
      @ m_x + 1, m_y + 2 SAY8 "Dokument (0-štampaj pripremu) " GET nBrDokP PICT "999999"
      READ
      BoxC()
      IF LastKey() <> K_ESC
         rpt_kuf( nBrDokP )
      ENDIF

      my_close_all_dbf()

      o_kuf( .T. )

      SELECT P_KUF
      SET ORDER TO TAG "br_dok"

      RETURN DE_REFRESH

   CASE Ch == K_ALT_A

      IF Pitanje( , "Ažurirati KUF dokument (D/N) ?", "N" ) == "D"
         azur_kuf()
         RETURN DE_REFRESH
      ELSE
         RETURN DE_CONT
      ENDIF

   CASE Ch == K_ALT_P

      IF Pitanje( , "Povrat KUF dokumenta u pripremu (D/N) ?", "N" ) == "D"
         nBrDokP := 0
         Box(, 1, 40 )
         @ m_x + 1, m_y + 2 SAY "KUF dokument br:" GET nBrDokP  PICT "999999"

         READ
         BoxC()

         IF LastKey() <> K_ESC
            pov_kuf( nBrDokP )
            RETURN DE_REFRESH
         ENDIF
      ENDIF

      SELECT P_KUF
      RETURN DE_REFRESH

   CASE Ch == K_ALT_X

      IF Pitanje (, "Izvršiti renumeraciju KUF pripreme (D/N) ?", "N" ) == "D"
         renm_rbr( "P_KUF", .F. )
      ENDIF

      SELECT P_KUF
      SET ORDER TO TAG "BR_DOK"
      GO TOP

      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT

