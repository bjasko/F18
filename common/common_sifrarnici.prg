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

FUNCTION SifFmkSvi()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}

   AAdd( opc, "1. partneri                          " )

   AAdd( opcexe, {|| P_Firma() } )


   IF ( tekuci_modul() <> "FIN" )
      AAdd( opc, "2. konta" )

      AAdd( opcexe, {|| P_Konto() } )

   ELSE
      AAdd( opc, "2. ----------------- " )
      AAdd( opcexe, {|| NotImp() } )
   ENDIF

   AAdd( opc, "3. tipovi naloga" )
   AAdd( opcexe, {|| browse_tnal() } )


   AAdd( opc, "4. tipovi dokumenata" )
   AAdd( opcexe, {|| browse_tdok() } )


   AAdd( opc, "5. valute" )
   AAdd( opcexe, {|| P_Valuta() } )


   AAdd( opc, "6. radne jedinice" )
   AAdd( opcexe, {|| P_RJ() } )


   AAdd( opc, "7. opštine" )
   AAdd( opcexe, {|| P_Ops() } )


   AAdd( opc, "8. banke" )
   AAdd( opcexe, {|| P_Banke() } )


   AAdd( opc, "9. sifk - karakteristike" )
   AAdd( opcexe, {|| P_SifK() } )


   AAdd( opc, "A. vrste plaćanja" )
   AAdd( opcexe, {|| P_VrsteP() } )


   IF ( IsRamaGlas() .OR.  gModul == "FAKT" .AND. glRadNal )
      AAdd( opc, "R. objekti" )
      AAdd( opcexe, {|| P_fakt_objekti() } )
   ENDIF

   // lokalizacija
   gLokal := AllTrim( gLokal )

   IF gLokal <> "0"
      AAdd( opc, "L. lokalizacija" )
      AAdd( opcexe, {|| P_Lokal() } )
   ENDIF

   OFmkSvi()

   PRIVATE Izbor := 1
   gMeniSif := .T.
   Menu_SC( "ssvi" )
   gMeniSif := .F.

   my_close_all_dbf()

   RETURN .T.




// -------------------------------------------------------------------------
// profili
// primjer: Profil partnera = "KUP,KMS"
// KUP - kupac
// DOB - dobavljac
// KMS - komisionar
// KMT - komintent u konsignacionoj prodaji
// INO - ino partner
// UIO - radi se o specificnom partneru - uprava za indirektno
// oporezivanje
// SPE - partner koji obavlja poslove spediciji kod uvoza robe
// TRA - obavlja transport
//
// Napomena: partner moze biti i kupac i dobavljac - stavlja se KUP,DOB
// znaci moze imati vise funkcija
//
// profil partnera = SVI atributi koji odgovaraju ovom partneru
// ------------------------------------------------------------------------
FUNCTION IsProfil( cIdPartner, cProfId )

   LOCAL cProfili

   cProfili := IzSifKPartn( "PROF", cIdPartner, .F. )

   IF cProfId $ Upper( cProfili )
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF


/*
   partner je komisionar
*/

FUNCTION IsKomision( cIdPartner )

   RETURN IsProfil( cIdPartner, "KMS" )
