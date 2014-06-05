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


#include "pos.ch"


STATIC __device_id := 0
STATIC __device_params
STATIC __DRV_TREMOL := "TREMOL"
STATIC __DRV_FPRINT := "FPRINT"
STATIC __DRV_FLINK := "FLINK"
STATIC __DRV_HCP := "HCP"
STATIC __DRV_TRING := "TRING"
STATIC __DRV_CURRENT


FUNCTION pos_fiskalni_racun( id_pos, datum, rn_broj, dev_params, uplaceni_iznos )

   LOCAL _err_level := 0
   LOCAL _dev_drv
   LOCAL _storno
   LOCAL _items, _head, _cont

   IF uplaceni_iznos == NIL
      uplaceni_iznos := 0
   ENDIF

   IF dev_params == NIL
      RETURN _err_level
   ENDIF

   __device_id := dev_params[ "id" ]
   __device_params := dev_params
   _dev_drv := __device_params[ "drv" ]
   __DRV_CURRENT := _dev_drv

   _o_tables()

   _storno := pos_dok_is_storno( id_pos, "42", datum, rn_broj )
   _items := pos_items_prepare( id_pos, "42", datum, rn_broj, _storno, uplaceni_iznos )

   IF _items == NIL
      RETURN 1
   ENDIF

   DO CASE

   CASE _dev_drv == "TEST"
      _err_level := 0
	
   CASE _dev_drv == __DRV_FPRINT
      _err_level := pos_to_fprint( id_pos, "42", datum, rn_broj, _items, _storno )

   CASE _dev_drv == __DRV_FLINK
      _err_level := pos_to_flink( id_pos, "42", datum, rn_broj, _items, _storno )

   CASE _dev_drv == __DRV_TRING
      _err_level := pos_to_tring( id_pos, "42", datum, rn_broj, _items, _storno )

   CASE _dev_drv == __DRV_HCP
      _err_level := pos_to_hcp( id_pos, "42", datum, rn_broj, _items, _storno, uplaceni_iznos )

   CASE _dev_drv == __DRV_TREMOL
      _cont := NIL
      _err_level := pos_to_tremol( id_pos, "42", datum, rn_broj, _items, _storno, _cont )

   ENDCASE

   IF _err_level > 0
	
      IF _dev_drv == __DRV_TREMOL
		
         _cont := "2"
         _err_level := pos_to_tremol( id_pos, "42", datum, rn_broj, _items, _storno, _cont )

         IF _err_level > 0
            msgbeep( "Problem sa štampanjem na fiskalni uređaj !" )
         ENDIF
      ELSE
         msgbeep( "Problem sa štampanjem na fiskalni uređaj !" )
      ENDIF
   ENDIF

   RETURN _err_level


// -----------------------------------------------
// otvori potrebne tabele
// -----------------------------------------------
STATIC FUNCTION _o_tables()
   RETURN



// ------------------------------------------------------------------
// da li je racun storno
// ------------------------------------------------------------------
STATIC FUNCTION pos_dok_is_storno( id_pos, tip_dok, datum, rn_broj )

   LOCAL _storno := .F.

   SELECT pos
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_pos + tip_dok + DToS( datum ) + rn_broj

   DO WHILE !Eof() .AND. field->idpos == id_pos ;
         .AND. field->idvd == tip_dok ;
         .AND. DToS( field->datum ) == DToS( datum ) ;
         .AND. field->brdok == rn_broj

      IF !Empty( AllTrim( field->c_1 ) )
         _storno := .T.
         EXIT
      ENDIF

      SKIP

   ENDDO

   RETURN _storno



// ------------------------------------------------------------------
// priprema podataka racuna za ispis na fiskalni uredjaj
// ------------------------------------------------------------------
STATIC FUNCTION pos_items_prepare( id_pos, tip_dok, datum, rn_broj, storno, uplaceni_iznos )

   LOCAL _items := {}
   LOCAL _plu
   LOCAL _reklamni_racun
   LOCAL _rabat, _cijena
   LOCAL _art_barkod, _art_id, _art_naz, _art_jmj
   LOCAL _rbr := 0
   LOCAL _rn_total := 0
   LOCAL _vr_plac
   LOCAL _level

   IF uplaceni_iznos == NIL
      uplaceni_iznos := 0
   ENDIF

   // pozicioniraj se na pos_doks
   SELECT pos_doks
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_pos + tip_dok + DToS( datum ) + rn_broj

   IF !Found()
      RETURN NIL
   ENDIF

   // vrsta placanja
   _vr_plac := pos_get_vr_plac( field->idvrstep )

   // ako je vrsta placanja <> gotovina
   IF _vr_plac <> "0"
      // vrati mi iznos racuna
      _rn_total := pos_iznos_racuna( id_pos, tip_dok, datum, rn_broj )
   ELSE
      _rn_total := 0
   ENDIF

   // ako postoji iznos uplate, onda je to total
   // koji ce biti proslijedjen txt fajlu
   IF uplaceni_iznos > 0
      _rn_total := uplaceni_iznos
   ENDIF

   // pronadji u bazi racun
   SELECT pos
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_pos + tip_dok + DToS( datum ) + rn_broj

   IF !Found()
      RETURN NIL
   ENDIF

   DO WHILE !Eof() .AND. field->idpos == id_pos ;
         .AND. field->idvd == tip_dok ;
         .AND. DToS( field->datum ) == DToS( datum ) ;
         .AND. field->brdok == rn_broj

      _reklamni_racun := ""
      _rabat := 0
      _plu := 0
      _cijena := 0
      _art_barkod := ""

      // ovo je broj racuna koji se stornira
      _reklamni_racun := field->c_1

      _art_id := field->idroba

      SELECT roba
      SEEK _art_id

      _plu := roba->fisc_plu

      IF __device_params[ "plu_type" ] == "D"
         // generisi PLU iz parametara
         _plu := auto_plu( nil, nil, __device_params )
      ENDIF

      // plu ne moze biti 0
      IF __DRV_CURRENT == "FPRINT" .AND. _plu == 0
         MsgBeep( "PLU artikla = 0, to nije moguce !" )
         RETURN NIL
      ENDIF

      _cijena := pos_get_mpc()
      _art_barkod := roba->barkod
      _art_jmj := roba->jmj

      SELECT pos

      IF field->ncijena > 0
         _rabat := ( field->ncijena / field->cijena ) * 100
      ENDIF

      // kolicina uvijek ide apsolutna vrijednost
      // storno racun fiskalni stampac tretira kao regularni unos

      _art_naz := fiscal_art_naz_fix( roba->naz, __device_params[ "drv" ] )

      AAdd( _items, { rn_broj, ;
         AllTrim( Str( ++_rbr ) ), ;
         _art_id, ;
         _art_naz, ;
         field->cijena, ;
         Abs( field->kolicina ), ;
         field->idtarifa, ;
         _reklamni_racun, ;
         _plu, ;
         field->cijena, ;
         _rabat, ;
         _art_barkod, ;
         _vr_plac, ;
         _rn_total, ;
         datum, ;
         _art_jmj } )

      SKIP

   ENDDO

   IF Len( _items ) == 0
      msgbeep( "fiskal: nema stavki za stampu !!!" )
      RETURN NIL
   ENDIF

   _level := 1
   // provjeri stavke racuna, kolicine, cijene
   IF fiscal_items_check( @_items, storno, _level, __device_params[ "drv" ] ) < 0
      RETURN NIL
   ENDIF

   RETURN _items




// -------------------------------------
// stampa fiskalnog racuna FPRINT
// -------------------------------------
STATIC FUNCTION pos_to_fprint( id_pos, tip_dok, datum, rn_broj, items, storno )

   LOCAL _err_level := 0
   LOCAL _fiscal_no := 0

   fprint_delete_answer( __device_params )

   fprint_rn( __device_params, items, NIL, storno )

   _err_level := fprint_read_error( __device_params, @_fiscal_no )

   IF _err_level = -9
      IF Pitanje(, "Da li je nestalo trake ?", "N" ) == "D"
         IF Pitanje(, "Zamjenite traku i pritisnite 'D'", "D" ) == "D"
            _err_level := fprint_read_error( __device_params, @_fiscal_no )
         ENDIF
      ENDIF
   ENDIF

   IF _fiscal_no <= 0
      _err_level := 1
   ENDIF

   IF _err_level <> 0
      
      IF pos_da_li_je_racun_fiskalizovan( @_fiscal_no )
         _err_level := 0
      ELSE
         fprint_delete_out( __device_params )
         msgbeep( "Greška kod štampanja fiskalnog računa !" )
      ENDIF

   ENDIF

   IF ( _fiscal_no > 0 .AND. _err_level == 0 )
      pos_doks_update_fisc_rn( id_pos, tip_dok, datum, rn_broj, _fiscal_no )
      msgo( "Kreiran fiskalni račun broj: " + AllTrim( Str( _fiscal_no ) ) )
      Sleep( 2 )
      msgc()
   ENDIF

   RETURN _err_level




// -------------------------------------
// stampa fiskalnog racuna FLINK
// -------------------------------------
STATIC FUNCTION pos_to_flink( id_pos, tip_dok, datum, rn_broj, items, storno )

   LOCAL _err_level := 0

   // idemo sada na upis rn u fiskalni fajl
   _err_level := fc_pos_rn( __device_params, items, storno )

   RETURN _err_level




// --------------------------------------------
// stampa fiskalnog racuna TREMOL
// --------------------------------------------
STATIC FUNCTION pos_to_tremol( id_pos, tip_dok, datum, rn_broj, items, storno, cont )

   LOCAL _err_level := 0
   LOCAL _f_name
   LOCAL _fiscal_no := 0

   IF cont == NIL
      cont := "0"
   ENDIF
	
   // idemo sada na upis rn u fiskalni fajl
   _err_level := tremol_rn( __device_params, items, NIL, storno, cont )

   IF cont <> "2"
	
      // naziv fajla
      _f_name := fiscal_out_filename( __device_params[ "out_file" ], rn_broj )

      IF tremol_read_out( __device_params, _f_name )
		
         // procitaj poruku greske
         _err_level := tremol_read_error( __device_params, _f_name, @_fiscal_no )

         IF _err_level = 0 .AND. !storno .AND. _fiscal_no > 0

            pos_doks_update_fisc_rn( id_pos, tip_dok, datum, rn_broj, _fiscal_no )

            msgbeep( "Kreiran fiskalni racun: " + AllTrim( Str( _fiscal_no ) ) )
			
         ENDIF
	
      ENDIF
	
      // obrisi fajl
      // da ne bi ostao kada server proradi ako je greska
      FErase( __device_params[ "out_dir" ] + _f_name )

   ENDIF

   RETURN _err_level




// --------------------------------------------
// stampa fiskalnog racuna HCP
// --------------------------------------------
STATIC FUNCTION pos_to_hcp( id_pos, tip_dok, datum, rn_broj, items, storno, uplaceni_iznos )

   LOCAL _err_level := 0
   LOCAL _fiscal_no := 0

   IF uplaceni_iznos == NIL
      uplaceni_iznos := 0
   ENDIF

   _err_level := hcp_rn( __device_params, items, NIL, storno, uplaceni_iznos )

   IF _err_level = 0
	
      // vrati broj racuna
      _fiscal_no := hcp_fisc_no( __device_params, storno )
	
      IF _fiscal_no > 0
         pos_doks_update_fisc_rn( id_pos, tip_dok, datum, rn_broj, _fiscal_no )
         msgbeep( "Kreiran fiskalni racun: " + AllTrim( Str( _fiscal_no ) ) )
      ENDIF

   ENDIF

   RETURN _err_level


// ------------------------------------------------
// update broj fiskalnog racuna
// ------------------------------------------------
STATIC FUNCTION pos_doks_update_fisc_rn( id_pos, tip_dok, datum, rn_broj, fisc_no )

   LOCAL _rec

   SELECT pos_doks
   SET ORDER TO TAG "1"
   GO TOP

   SEEK id_pos + tip_dok + DToS( datum ) + rn_broj

   IF !Found()
      RETURN
   ENDIF

   _rec := dbf_get_rec()
   _rec[ "fisc_rn" ] := fisc_no

   update_rec_server_and_dbf( "pos_doks", _rec, 1, "FULL" )

   RETURN



// --------------------------------------------
// vrati vrstu placanja
// --------------------------------------------
STATIC FUNCTION pos_get_vr_plac( id_vr_pl )

   LOCAL _ret := "0"
   LOCAL _t_area := Select()
   LOCAL _naz := ""

   IF Empty( id_vr_pl ) .OR. id_vr_pl == "01"
      // ovo je gotovina
      RETURN _ret
   ENDIF

   O_VRSTEP
   SELECT vrstep
   SET ORDER TO TAG "ID"
   SEEK id_vr_pl

   _naz := Upper( AllTrim( vrstep->naz ) )

   DO CASE
   CASE "KARTICA" $ _naz
      _ret := "1"
   CASE "CEK" $ _naz
      _ret := "2"
   CASE "VAUCER" $ _naz
      _ret := "3"
   CASE "VIRMAN" $ _naz
      _ret := "3"
   OTHERWISE
      _ret := "0"
   ENDCASE

   SELECT ( _t_area )

   RETURN _ret



// --------------------------------------------
// stampa fiskalnog racuna TRING (www.kase.ba)
// --------------------------------------------
STATIC FUNCTION pos_to_tring( id_pos, tip_dok, datum, rn_broj, items, storno )
   LOCAL _err_level := 0
   _err_level := tring_rn( __device_params, items, NIL, storno )
   RETURN _err_level




// -------------------------------------------
// popravlja naziv artikla
// -------------------------------------------
STATIC FUNCTION _fix_naz( cR_naz, cNaziv )

   cNaziv := PadR( cR_naz, 30 )

   DO CASE

   CASE AllTrim( gFc_type ) == "FLINK"
      cNaziv := StrKzn( cNaziv, "8", "E" )
      cNaziv := Lower( cNaziv )
      cNaziv := StrTran( cNaziv, ",", "." )
	
   ENDCASE

   RETURN



FUNCTION pos_da_li_je_racun_fiskalizovan( fisc_no )
   
   LOCAL lRet := .F.
   LOCAL nX
   LOCAL cStampano := " "

   DO WHILE .T.

      nX := 1

      Box(, 5, 70 )

      @ m_x + nX, m_y + 2 SAY8 "Program ne može da dobije odgovor od fiskalnog uređaja !"
      ++ nX
      @ m_x + nX, m_y + 2 SAY8 "Da li je račun ispravno odštampan na fiskalni uređaj (D/N) ?" GET cStampano VALID cStampano $ "DN" PICT "@!"

      READ

      IF LastKey() == K_ESC
         BoxC()
         MsgBeep( "ESC operacija nije dozvoljena. Odgovortite na postavljena pitanja." )
         LOOP
      ENDIF

      IF cStampano == "N"
         fisc_no := 0
         BoxC()
         EXIT
      ENDIF

      ++ nX
      ++ nX

      @ m_x + nX, m_y + 2 SAY8 "Molimo unesite broj računa koji je fiskalni račun ispisao:" GET fisc_no VALID fisc_no > 0 PICT "9999999999" 

      READ

      BoxC()

      IF LastKey() == K_ESC
         MsgBeep( "ESC operacija nije dozvoljena. Odgovortite na postavljena pitanja." )
         LOOP
      ENDIF

      lRet := .T.
      EXIT

   ENDDO

   RETURN lRet


