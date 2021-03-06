/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1995-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


/*

  Opis: kreira se pomoćna tabela sa filterisanim zapisima tabele SUBAN po IDRJ = tražena radna jedinica
        te otvara kao ANAL ili SINT

  Usage: otvori_sint_anal_kroz_temp( .T., "IDRJ = '01'")

   Parameters:
      lSint - .T. sintetika, .F. analitika
      cFilter - filter za suban tabelu

  Return:
    otvorena pomoćna tabela ali kao alias SINT ili ANAL

*/

FUNCTION otvori_sint_anal_kroz_temp( lSint, cFilter )

   LOCAL nArr

   IF lSint == NIL
      lSint := .F.
   ENDIF

   napravi_pomocnu_tabelu( lSint )

   SET ORDER TO TAG "0"
   GO TOP

   o_suban()

   Box(, 2, 30 )

   nSlog := 0
   nUkupno := RECCOUNT2()
   cFilt := cFilter
   cSort1 := "idFirma+IdVN+BrNal+IdKonto"

   INDEX ON &cSort1 TO "SUBTMP" FOR &cFilt
   GO TOP

   nArr := Select()

   BoxC()

   DO WHILE !Eof()

      nD1 := nD2 := nP1 := nP2 := 0
      cIdFirma := IdFirma
      cIDVn = IdVN
      cBrNal := BrNal

      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal

         cIdkonto := idkonto

         nDugBHD := nDugDEM := 0
         nPotBHD := nPotDEM := 0

         IF D_P = "1"
            nDugBHD := IznosBHD
            nDugDEM := IznosDEM
         ELSE
            nPotBHD := IznosBHD
            nPotDEM := IznosDEM
         ENDIF

         IF !lSint
            SELECT ANAL
            SEEK cidfirma + cidvn + cbrnal + cidkonto
            fNasao := .F.
            DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal .AND. IdKonto == cIdKonto
               IF Month( ( nArr )->datdok ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
               SKIP 1
            ENDDO
            IF !fNasao
               APPEND BLANK
            ENDIF

            RREPLACE IdFirma WITH cIdFirma, IdKonto WITH cIdKonto, IdVN WITH cIdVN, ;
               BrNal WITH cBrNal, ;
               DatNal WITH Max( ( nArr )->datdok, datnal ), ;
               DugBHD WITH DugBHD + nDugBHD, PotBHD WITH PotBHD + nPotBHD, ;
               DugDEM WITH DugDEM + nDugDEM, PotDEM WITH PotDEM + nPotDEM

         ELSE             // sintetika

            SELECT SINT
            SEEK cidfirma + cidvn + cbrnal + Left( cidkonto, 3 )
            fNasao := .F.
            DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal .AND. Left( cIdKonto, 3 ) == idkonto
               IF  Month( ( nArr )->datdok ) == Month( datnal )
                  fNasao := .T.
                  EXIT
               ENDIF
               SKIP 1
            ENDDO
            IF !fNasao
               APPEND BLANK
            ENDIF

            RREPLACE IdFirma WITH cIdFirma, IdKonto WITH Left( cIdKonto, 3 ), IdVN WITH cIdVN, ;
               BrNal WITH cBrNal, ;
               DatNal WITH Max( ( nArr )->datdok, datnal ), ;
               DugBHD WITH DugBHD + nDugBHD, PotBHD WITH PotBHD + nPotBHD, ;
               DugDEM WITH DugDEM + nDugDEM, PotDEM WITH PotDEM + nPotDEM

         ENDIF

         SELECT ( nArr )
         SKIP 1

      ENDDO

      SELECT ( nArr )

   ENDDO

   SELECT ( nArr )
   USE

   IF !lSint
      SELECT ANAL
   ELSE
      SELECT SINT
   ENDIF

   GO TOP

   my_flock()

   DO WHILE !Eof()
      nRbr := 0
      cIdFirma := IdFirma
      cIDVn = IdVN
      cBrNal := BrNal
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal
         REPLACE rbr WITH Str( ++nRbr, 3 )
         SKIP 1
      ENDDO
   ENDDO

   my_unlock()

   SET ORDER TO TAG "1"
   GO TOP

   RETURN




STATIC FUNCTION close_sint_anal( lSint )

   IF lSint
      SELECT ( F_SINT )
   ELSE
      SELECT ( F_ANAL )
   ENDIF

   IF Used()
      USE
   ENDIF

   RETURN .T.




STATIC FUNCTION napravi_pomocnu_tabelu( lSint )

   LOCAL aDbf := {}
   LOCAL cTable := my_home() + my_dbf_prefix() + "pom"

   close_sint_anal( lSint )

   AAdd( aDBf, { 'IDFIRMA', 'C',   5,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C', IF( lSint, 3, 7 ),  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   8,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   3,  0 } )
   AAdd( aDBf, { 'DATNAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'DUGBHD', 'N',  17,  2 } )
   AAdd( aDBf, { 'POTBHD', 'N',  17,  2 } )
   AAdd( aDBf, { 'DUGDEM', 'N',  15,  2 } )
   AAdd( aDBf, { 'POTDEM', 'N',  15,  2 } )

   DBCREATE( cTable, aDbf )

   SELECT ( F_TMP_1 )
   USE

   IF !lSint
      my_use_temp( "ANAL", cTable, .F., .T. )
   ELSE
      my_use_temp( "SINT", cTable, .F., .T. )
   ENDIF

   INDEX ON idFirma + IdVN + BrNal + IdKonto TAG "0"

   IF lSint
      INDEX ON IdFirma + IdKonto + DToS( DatNal ) TAG "1"
      INDEX ON idFirma + IdVN + BrNal + Rbr       TAG "2"
   ELSE
      INDEX ON IdFirma + IdKonto + DToS( DatNal ) TAG "1"
      INDEX ON idFirma + IdVN + BrNal + Rbr       TAG "2"
      INDEX ON idFirma + DToS( DatNal )         TAG "3"
      INDEX ON Idkonto                      TAG "4"
      INDEX ON DatNal                       TAG "5"
   ENDIF

   RETURN
