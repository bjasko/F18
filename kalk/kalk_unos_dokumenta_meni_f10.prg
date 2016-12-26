/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


STATIC s_hLastDokInfo

FUNCTION kalk_meni_f10()

   LOCAL aOpc := {}, aOpcExe := {}, nIzbor := 1

   SELECT kalk_pripr
   GO TOP

   AAdd( aOpc, "1. prenos dokumenta fakt->kalk                             " )
   AAdd( aOpcExe, {|| fakt_kalk() } )

   AAdd( aOpc, "2. povrat dokumenta u pripremu" )
   AAdd( aOpcExe, {|| kalk_povrat_dokumenta() } )

   AAdd( aOpc, "3. priprema -> smeće" )
   AAdd( aOpcExe, {|| kalk_azuriranje_tabele_pripr9() } )

   AAdd( aOpc,  "4. smeće    -> priprema" )
   AAdd( aOpcExe, {|| kalk_povrat_dokumenta_iz_pripr9() } )

   AAdd( aOpc,  "5. najstariji dokument iz smeća u pripremu" )
   AAdd( aOpcExe, {||  kalk_povrat_najstariji_dokument_iz_pripr9() } )

   AAdd( aOpc,  "6. generacija dokumenta inventure magacin " )
   AAdd( aOpcExe, {||  kalk_generacija_inventura_magacin_im() } )

   AAdd( aOpc,  "7. generacija dokumenta inventure prodavnica" )
   AAdd( aOpcExe, {|| kalk_generisi_ip() } )

   AAdd( aOpc,  "8. generacija nivelacije prod. na osnovu niv. za drugu prod" )
   AAdd( aOpcExe, {||  GenNivP() } )

   AAdd( aOpc,  "9. parametri obrade - nc / obrada sumnjivih dokumenata" )
   AAdd( aOpcExe, {|| kalk_par_metoda_nc() } )

   IF kalk_pripr->idvd == "19"
      AAdd( aOpc, "X. obrazac promjene cijena" )
      AAdd( aOpcExe, {||  Obraz19() } )
   ENDIF

   AAdd( aOpc, "B. pretvori 11 -> 41  ili  11 -> 42"        )
   AAdd( aOpcExe, {||  kalk_iz_11_u_41_42() } )

   AAdd( aOpc, "C. promijeni predznak za količine"          )
   AAdd( aOpcExe, {||  kalk_plus_minus_kol() } )


   AAdd( aOpc, "E. storno dokumenta"                        )
   AAdd( aOpcExe, {||  storno_kalk_dokument() } )

   AAdd( aOpc, "F. prenesi VPC(sifr)+POREZ -> MPCSAPP(dok)" )
   AAdd( aOpcExe, {|| kalk_set_diskont_mpc() } )

   AAdd( aOpc, "G. prenesi mpc sa por(dok)->sifarnik"  )
   AAdd( aOpcExe, {||  kalk_dokument_prenos_cijena() } )

   AAdd( aOpc, "H. prenesi vpc(sif)-> vpc(dok)"     )
   AAdd( aOpcExe, {|| VPCSifUDok() } )

   AAdd( aOpc, "I. povrat (12,11) -> u drugo skl.(96,97)" )
   AAdd( aOpcExe, {|| Iz12u97()  } )  // 11,12 -> 96,97

   AAdd( aOpc, "J. zaduženje prodavnice iz magacina (10->11)"  )
   AAdd( aOpcExe, {|| kalk_iz_10_u_11() } )

   AAdd( aOpc, "K. veleprodaja na osnovu dopreme u magacin (16->14)" )
   AAdd( aOpcExe, {|| Iz16u14() } )

   AAdd( aOpc, "L. ubacivanje troškova-uvozna kalkulacija" )
   AAdd( aOpcexe, {|| KalkTrUvoz() } )

   /*
   AAdd( opc, "2. pretvori maloprodajni popust u smanjenje MPC" )
   AAdd( opcexe, {|| PopustKaoNivelacijaMP() } )
   */

   AAdd( aOpc, "M. obračun poreza pri uvozu" )
   AAdd( aOpcExe, {|| ObracunPorezaUvoz() } )

   AAdd( aOpc, "N. pregled smeća" )
   AAdd( aOpcExe, {|| kalk_pregled_smece_pripr9() } )

   AAdd( aOpc, "O. briši sve protu-stavke" )
   AAdd( aOpcExe, {|| ProtStErase() } )

   AAdd( aOpc, "R. renumeracija kalk priprema" )
   AAdd( aOpcexe, {|| renumeracija_kalk_pripr( nil, nil, .F. ) } )

   // AAdd( aOpc, "P. duple stavke u pripremi - provjeri" )
   // AAdd( aOpcExe, {|| kalk_printaj_duple_stavke_iz_pripreme() } )

   AAdd( aOpc, "S. spoji duple stavke u pripremi" )
   AAdd( aOpcExe, {||  kalk_pripr_spoji_duple_artikle() } )


   AAdd( aOpc, "U. uskladi nc sa dokumentom 95 prema posljednjem dokumentu" )
   AAdd( aOpcExe, {|| kalk_uskladi_nc_sa_95_prema_zadnjem_ulazu() } )


   f18_menu( "kf10", .F., nIzbor, aOpc, aOpcExe )

   o_kalk_edit()

   RETURN DE_REFRESH




STATIC FUNCTION kalk_uskladi_nc_sa_95_prema_zadnjem_ulazu()

   LOCAL hParams := hb_Hash(), hDokInfo
   LOCAL cBrDok

   hDokInfo := kalk_last_dok_info()

   IF hDokInfo == NIL
      MsgBeep( "Informacija o posljednjem dokumentu ne postoji ! STOP" )
      RETURN .F.
   ENDIF

   hParams[ "idfirma" ] := hDokInfo[ "idfirma" ]
   hParams[ "idvd" ] := hDokInfo[ "idvd" ]
   hParams[ "brdok" ] := hDokInfo[ "brdok" ]
   cBrDok := hParams[ "idfirma" ] + "-" + hParams[ "idvd" ] + hParams[ "brdok" ]
   IF !( hParams[ "idvd" ] $ "10#16" )
      IF Pitanje( , "Dokument po kome želite napraviti korekciju " + cBrDok + " nije ulaz ?! Nastaviti?", "N" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   kalk_gen_uskladjenje_nc_95( hParams )

   RETURN .T.

/*
    informacije o posljednjem dokumentu
*/

FUNCTION kalk_last_dok_info(  hParams )

   IF hParams != NIL
      IF s_hLastDokInfo == NIL
         s_hLastDokInfo := hb_Hash()
      ENDIF
      s_hLastDokInfo[ "idfirma" ] := hParams[ "idfirma" ]
      s_hLastDokInfo[ "idvd" ] := hParams[ "idvd" ]
      s_hLastDokInfo[ "brdok" ] := hParams[ "brdok" ]
   ENDIF

   RETURN s_hLastDokInfo


STATIC FUNCTION kalk_dokument_prenos_cijena()

   LOCAL _opt := 2
   LOCAL _update := .F.
   LOCAL _konto := Space( 7 )
   LOCAL _t_area := Select()
   PRIVATE getList := {}

   Box(, 7, 65 )
   @ m_x + 1, m_y + 2 SAY8 "Prenos cijena dokument/šifarnik ****"
   @ m_x + 3, m_y + 2 SAY8 "1) prenos MPCSAPP (dok) => šifarnik"
   @ m_x + 4, m_y + 2 SAY8 "2) prenos šifarnik => MPCSAPP (dok)"
   @ m_x + 6, m_y + 2 SAY "    odabir > " GET _opt PICT "9"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF _opt == 1
      IF Pitanje(, "Koristiti dokument iz pripreme (D) ili ažurirani (N) ?", "N" ) == "D"
         MPCSAPPuSif()
      ELSE
         MPCSAPPiz80uSif()
      ENDIF
      RETURN
   ENDIF

   IF _opt == 2

      o_kalk_pripr()
      O_ROBA
      o_koncij()
      O_KONTO

      Box(, 1, 50 )
      @ m_x + 1, m_y + 2 SAY8 "Prodavnički konto:" GET _konto VALID p_konto( @_konto )
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      SELECT koncij
      HSEEK _konto

      SELECT kalk_pripr
      GO TOP

      DO WHILE !Eof()

         _update := .T.
         _rec := dbf_get_rec()

         SELECT roba
         HSEEK _rec[ "idroba" ]

         IF !Found()
            MsgBeep( "Nepostojeća šifra artikla " + _rec[ "idroba" ] )
            SELECT kalk_pripr
            SKIP
            LOOP
         ENDIF

         SELECT kalk_pripr
         _rec[ "mpcsapp" ] := kalk_get_mpc_by_koncij_pravilo()

         IF Round( _rec[ "mpcsapp" ], 2 ) <= 0
            MsgBeep( "Artikal " + _rec[ "idroba" ] + " cijena <= 0 !"  )
         ENDIF

         dbf_update_rec( _rec )

         SKIP

      ENDDO

      SELECT kalk_pripr
      GO TOP

   ENDIF

   IF _update
      MsgBeep( "Ubačene cijene iz šifarnika !#Odradite asistenta sa opcijom A" )
   ENDIF

   RETURN







FUNCTION ProtStErase()

   IF Pitanje(, "Pobrisati protustavke dokumenta (D/N)?", "N" ) == "N"
      RETURN
   ENDIF

   o_kalk_pripr()
   SELECT kalk_pripr
   GO TOP

   DO WHILE !Eof()
      IF "XXX" $ idkonto2
         my_delete()
      ENDIF
      SKIP
   ENDDO

   my_dbf_pack()

   GO TOP

   RETURN .T.


/*
FUNCTION ()

   IF Pitanje(, "Setovati NC na 0 (D/N)?", "N" ) == "N"
      RETURN .F.
   ENDIF

   o_kalk_pripr()
   SELECT kalk_pripr
   GO TOP
   my_flock()
   DO WHILE !Eof()
      Scatter()
      _nc := 0
      Gather()
      SKIP
   ENDDO
   my_unlock()
   GO TOP

   RETURN .T.
*/

/*
STATIC FUNCTION kalk_printaj_duple_stavke_iz_pripreme()

   LOCAL aRobaDupli := {}
   LOCAL nScan, _i

   O_ROBA
   o_kalk_pripr()

   SELECT kalk_pripr
   GO TOP

   DO WHILE !Eof()

      SELECT roba
      HSEEK kalk_pripr->idroba

      SELECT kalk_pripr

      nScan := AScan( aRobaDupli, {| var| VAR[ 1 ] == kalk_pripr->idroba } )

      IF nScan == 0
         AAdd( aRobaDupli, { kalk_pripr->idroba } )
      ELSE
         AAdd( aRobaDupli, { kalk_pripr->idroba, roba->naz, roba->barkod, kalk_pripr->rbr } )
      ENDIF

      SKIP

   ENDDO

   GO TOP

   IF Len( aRobaDupli ) > 0

      START PRINT CRET .F.

      ?U "Sljedeći artikli u pripremi su dupli:"
      ? Replicate( "-", 80 )
      ? PadR( "R.br", 5 ) + " " + PadR( "Rb.st", 5 ) + " " + PadR( "ID", 10 ) + " " + PadR( "NAZIV", 40 ) + " " + PadR( "BARKOD", 13 )
      ? Replicate( "-", 80 )

      FOR _i := 1 TO Len( aRobaDupli )
         ? PadL( AllTrim( Str( _i, 5 ) ) + ".", 5 )
         @ PRow(), PCol() + 1 SAY PadR( aRobaDupli[ _i, 4 ], 5 )
         @ PRow(), PCol() + 1 SAY aRobaDupli[ _i, 1 ]
         @ PRow(), PCol() + 1 SAY PadR( aRobaDupli[ _i, 2 ], 40 )
         @ PRow(), PCol() + 1 SAY aRobaDupli[ _i, 3 ]
      NEXT

      ENDPRINT

   ENDIF

   RETURN .T.

*/

FUNCTION kalk_pripr_spoji_duple_artikle()

   LOCAL hRec, nPozicija, cIdRoba, nKolicina, nRbr, bRobaFilter

   IF Pitanje(, "Spojiti duple artikle (D/N)?", "N" ) == "N"
      RETURN .F.
   ENDIF

   PushWa()

   bRobaFilter := {|| field->idRoba == cIdRoba .AND. ;
      Round( field->fcj, 4 ) == Round( hRec[ "fcj" ], 4 ) .AND. ;
      Round( field->nc, 4 ) == Round( hRec[ "nc" ], 4 ) .AND. ;
      Round( field->vpc, 4 ) == Round( hRec[ "vpc" ], 4 ) .AND. ;
      Round( field->rabatv, 4 ) == Round( hRec[ "rabatv" ], 4 ) .AND. ;
      Round( field->mpc, 4 ) == Round( hRec[ "mpc" ], 4 ) .AND. ;
      Round( field->mpcsapp, 4 ) == Round( hRec[ "mpcsapp" ], 4 )  }


   SELECT kalk_pripr
   GO TOP

   IF !my_flock()
      MsgBeep( "flock kalk_pripr neuspjesno ?! STOP!" )
      RETURN .F.
   ENDIF

   MsgO( "Prolaz kroz kalk_pripremu ..." )
   DO WHILE !Eof()

      hRec := dbf_get_rec()
      nPozicija := RecNo()
      cIdRoba := field->idroba
      IF field->kolicina == 0
         SKIP
         LOOP
      ENDIF

      GO TOP
      nKolicina := 0
      dbEval( {|| nKolicina += field->Kolicina }, bRobaFilter ) // saberi kolicinu
      GO TOP
      dbEval( {|| field->kolicina := 0 }, bRobaFilter ) // setuj kolicina=0 za sve cIdRoba

      GO nPozicija  // prvu stavku napuni sa kolicinom
      hRec[ "kolicina" ] := nKolicina // ukupna kolicina za cIdRoba
      dbf_update_rec( hRec, .T. ) // no-lock

      SKIP
   ENDDO
   dbEval( {|| dbDelete() }, {|| field->kolicina == 0 } ) // viska stavke

   nRbr := 1
   ordSetFocus( 0 )
   GO TOP
   dbEval( {|| field->rbr := Str( nRbr, 3 ), nRbr++ } )  // renumeracija
   MsgC()

   my_unlock()
   MsgC()


   PopWa()

   RETURN .T.