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


FUNCTION cre_all_mat( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

   // --------------------------------------------------------
   // MAT_NALOG, MAT_PNALOG
   // --------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   4,  0 } )
   AAdd( aDBf, { 'DATNAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'DUG', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT', 'N',  15,  2 } )
   AAdd( aDBf, { 'DUG2', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT2', 'N',  15,  2 } )

   _alias := "MAT_NALOG"
   _table_name := "mat_nalog"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal", _alias )
   CREATE_INDEX( "2", "datnal", _alias )
   AFTER_CREATE_INDEX

   _alias := "MAT_PNALOG"
   _table_name := "mat_pnalog"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma", _alias )



   // --------------------------------------------------------
   // MAT_SUBAN, MAT_PSUBAN
   // --------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDROBA', 'C',  10,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   4,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
   AAdd( aDBf, { 'IDTIPDOK', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C',   8,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( aDBf, { 'U_I', 'C',   1,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N',  15,  3 } )
   AAdd( aDBf, { 'D_P', 'C',   1,  0 } )
   AAdd( aDBf, { 'IZNOS', 'N',  15,  2 } )
   AAdd( aDBf, { 'IDPartner', 'C',   6,  0 } )
   AAdd( aDBf, { 'IDZaduz', 'C',   6,  0 } )
   AAdd( aDBf, { 'IZNOS2', 'N',  15,  2 } )
   AAdd( aDBf, { 'DatKurs', 'D',   8,  0 } )
   AAdd( aDBf, { 'K1', 'C',   1,  0 } )
   AAdd( aDBf, { 'K2', 'C',   1,  0 } )
   AAdd( aDBf, { 'K3', 'C',   2,  0 } )
   AAdd( aDBf, { 'K4', 'C',   2,  0 } )

   _alias := "MAT_SUBAN"
   _table_name := "mat_suban"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "1", "IdFirma+IdRoba+dtos(DatDok)", _alias )
   CREATE_INDEX( "2", "IdFirma+IdPartner+IdRoba", _alias )
   CREATE_INDEX( "3", "IdFirma+IdKonto+IdRoba+dtos(DatDok)", _alias )
   CREATE_INDEX( "4", "idFirma+IdVN+BrNal+rbr", _alias )
   CREATE_INDEX( "5", "IdFirma+IdKonto+IdPartner+IdRoba+dtos(DatDok)", _alias )
   CREATE_INDEX( "8", "datdok", _alias )
   CREATE_INDEX( "9", "DESCEND(DTOS(datdok))+idpartner", _alias )
   CREATE_INDEX( "IDROBA", "idroba", _alias )
   CREATE_INDEX( "IDPARTN", "idpartner", _alias )
   AFTER_CREATE_INDEX

   _alias := "MAT_PSUBAN"
   _table_name := "mat_psuban"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idFirma+idvn+brnal", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+Brnal+IdKonto", _alias )


   // ----------------------------------------------------------------
   // MAT_ANAL, MAT_PANAL
   // ----------------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   4,  0 } )
   AAdd( aDBf, { 'DATNAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
   AAdd( aDBf, { 'DUG', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT', 'N',  15,  2 } )
   AAdd( aDBf, { 'DUG2', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT2', 'N',  15,  2 } )

   _alias := "MAT_ANAL"
   _table_name := "mat_anal"

   IF_NOT_FILE_DBF_CREATE

   // 0.4.4
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0404
      modstru( { "*" + _table_name, "C RBR C 3 0 RBR C 4 0" } )
   ENDIF


   CREATE_INDEX( "1", "IdFirma+IdKonto+dtos(DatNal)", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+IdKonto", _alias )
   CREATE_INDEX( "3", "datnal", _alias )
   AFTER_CREATE_INDEX

   _alias := "MAT_PANAL"
   _table_name := "mat_panal"

   IF_NOT_FILE_DBF_CREATE

   IF ver[ "current" ] < 0404
      modstru( { "*mat_panal", "C RBR C 3 0 RBR C 4 0" } )
   ENDIF

   CREATE_INDEX( "1", "IdFirma+idvn+brnal+idkonto", _alias )


   // -----------------------------------------------------------
   // MAT_SINT, MAT_PSINT
   // -----------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   3,  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   4,  0 } )
   AAdd( aDBf, { 'DATNAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
   AAdd( aDBf, { 'DUG', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT', 'N',  15,  2 } )
   AAdd( aDBf, { 'DUG2', 'N',  15,  2 } )
   AAdd( aDBf, { 'POT2', 'N',  15,  2 } )

   _alias := "MAT_SINT"
   _table_name := "mat_sint"

   IF_NOT_FILE_DBF_CREATE

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0404
      modstru( { "*" + _table_name, "C RBR C 3 0 RBR C 4 0" } )
   ENDIF

   CREATE_INDEX( "1", "IdFirma+IdKonto+dtos(DatNal)", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+IdKonto", _alias )
   CREATE_INDEX( "3", "datnal", _alias )
   AFTER_CREATE_INDEX

   _alias := "MAT_PSINT"
   _table_name := "mat_psint"

   IF_NOT_FILE_DBF_CREATE

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0404
      modstru( { "*mat_psint", "C RBR C 3 0 RBR C 4 0" } )
   ENDIF

   CREATE_INDEX( "1", "IdFirma", _alias )


   // ---------------------------------------------------------
   // MAT_PRIPR
   // ---------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDROBA', 'C',  10,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'IDVN', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRNAL', 'C',   4,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
   AAdd( aDBf, { 'IDTIPDOK', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C',   8,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( aDBf, { 'U_I', 'C',   1,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N',  15,  3 } )
   AAdd( aDBf, { 'D_P', 'C',   1,  0 } )
   AAdd( aDBf, { 'IZNOS', 'N',  15,  2 } )
   AAdd( aDBf, { 'CIJENA', 'N',  15,  3 } )
   AAdd( aDBf, { 'IDPartner', 'C',   6,  0 } )
   AAdd( aDBf, { 'IDZaduz', 'C',   6,  0 } )
   AAdd( aDBf, { 'IZNOS2', 'N',  15,  2 } )
   AAdd( aDBf, { 'DATKURS', 'D',   8,  0 } )
   AAdd( aDBf, { 'K1', 'C',   1,  0 } )
   AAdd( aDBf, { 'K2', 'C',   1,  0 } )
   AAdd( aDBf, { 'K3', 'C',   2,  0 } )
   AAdd( aDBf, { 'K4', 'C',   2,  0 } )

   _alias := "MAT_PRIPR"
   _table_name := "mat_pripr"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idFirma+IdVN+BrNal+rbr", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+BrDok+Rbr", _alias )
   CREATE_INDEX( "3", "idFirma+IdVN+IdKonto", _alias )
   CREATE_INDEX( "4", "idFirma+idkonto+idpartner+idroba", _alias )


   // ------------------------------------------------------------
   // MAT_INVENT
   // ------------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'IDROBA', 'C',  10,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
   AAdd( aDBf, { 'BROJXX', 'N',   8,  2 } )
   AAdd( aDBf, { 'KOLICINA', 'N',  10,  2 } )
   AAdd( aDBf, { 'CIJENA', 'N',  12,  2 } )
   AAdd( aDBf, { 'IZNOS', 'N',  14,  2 } )
   AAdd( aDBf, { 'IZNOS2', 'N',  14,  2 } )
   AAdd( aDBf, { 'IDPARTNER', 'C',   6,  0 } )

   _alias := "MAT_INVENT"
   _table_name := "mat_invent"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdRoba", _alias )


   // -------------------------------------------------------
   // KARKON
   // -------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',  7,  0 } )
   AAdd( aDBf, { 'TIP_NC', 'C',  1,   0 } )
   AAdd( aDBf, { 'TIP_PC', 'C',  1,   0 } )

   _alias := "KARKON"
   _table_name := "mat_karkon"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID", _alias )
   AFTER_CREATE_INDEX

   RETURN .T.
