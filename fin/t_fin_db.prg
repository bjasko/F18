/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "fin.ch"

#include "hbclass.ch"
CLASS TDbFin INHERIT TDB 
	method New
    method skloniSezonu	
	method install	
	method setgaDBFs	
	method ostalef	
	method obaza	
	method kreiraj	
	method konvZn
	method scan

ENDCLASS


// --------------------------------------------
// --------------------------------------------
method New()

 ::cName:="FIN"
 ::lAdmin:=.f.

 ::kreiraj()

return self


/*! \fn *void TDBFin::skloniSez(string cSezona, bool finverse, bool fda, bool fnulirati, bool fRS)
 *  \brief formiraj sezonsku bazu podataka
 */
 
*void TDBFin::skloniSez(string cSezona, bool finverse, bool fda, bool fnulirati, bool fRS)

method skloniSezonu(cSezona, finverse, fda, fnulirati, fRS)
local cScr

save screen to cScr

if fda==nil
  fDA:=.f.
endif
if finverse==nil
  finverse:=.f.
endif
if fNulirati==nil
  fnulirati:=.f.
endif
if fRS==nil
  // mrezna radna stanica , sezona je otvorena
  fRS:=.f.
endif

if fRS // radna stanica
  if file(ToUnix(PRIVPATH+cSezona+"\PRIPR.DBF"))
      // nema se sta raditi ......., pripr.dbf u sezoni postoji !
      return
  endif
  aFilesK:={}
  aFilesS:={}
  aFilesP:={}
endif

if KLevel<>"0"
	MsgBeep("Nemate pravo na koristenje ove opcije")
endif

cls

if fRS
	// mrezna radna stanica
	? "Formiranje DBF-ova u privatnom direktoriju, RS ...."
endif
?
if finverse
 	? "Prenos iz  sezonskih direktorija u radne podatke"
else
	? "Prenos radnih podataka u sezonske direktorije"
endif
?
// privatni
fnul:=.f.

Skloni(PRIVPATH,"PARAMS.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"_KONTO.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"_PARTN.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"PNALOG.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"PSUBAN.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"PRIPR.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"PANAL.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"PSINT.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"BBKLAS.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"IOS.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"FINMAT.DBF",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"FMK.INI",cSezona,finverse,fda,fnul)
Skloni(PRIVPATH,"KOMP.TXT",cSezona,finverse,fda,fnul)

if fRS
 // mrezna radna stanica!!! , baci samo privatne direktorije
 ?
 ?
 ?
 Beep(4)
 ? "pritisni nesto za nastavak.."

 restore screen from cScr
 return
endif

if fnulirati; fnul:=.t.; else; fnul:=.f.; endif  // kumulativ datoteke
Skloni(KUMPATH,"SUBAN.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"ANAL.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"SINT.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"NALOG.DBF",cSezona,finverse,fda,fnul)

fnul:=.f.
Skloni(KUMPATH,"RJ.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"EKKAT.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"FUNK.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"FOND.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"BUDZET.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"PAREK.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"BUIZ.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"KOLIZ.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"KONIZ.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"IZVJE.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"ZAGLI.DBF",cSezona,finverse,fda,fnul)
Skloni(KUMPATH,"FMK.INI",cSezona,finverse,fda,fnul)

Skloni(SIFPATH,"PKONTO.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"KONTO.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"PARTN.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"TNAL.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"TDOK.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"VALUTE.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"TRFP2.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"TRFP3.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"SIFK.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"VRSTEP.DBF",cSezona,finverse,fda,fnul)
Skloni(SIFPATH,"FMK.INI",cSezona,finverse,fda,fnul)

if IzFMKIni("FIN","LimitiPoUgovoru_PoljeK3","N",SIFPATH)=="D"
  Skloni(SIFPATH,"ULIMIT.DBF",cSezona,finverse,fda,fnul)
endif

//sifrarnici
?
?
?
Beep(4)
? "pritisni nesto za nastavak.."

restore screen from cScr
return


/*! \fn *void TDBFin::setgaDBFs()
 *  \brief Setuje matricu gaDBFs 
 */
*void TDBFin::setgaDBFs()

method setgaDBFs()

//? "prebaceno u F18.prg"

return


/*! \fn *void TDBFin::install(string cKorisn,string cSifra,variant p3,variant p4,variant p5,variant p6,variant p7)
 *  \brief osnovni meni za instalacijske procedure
 *  \todo  prosljedjuje se goModul, ovo ce biti eliminsano eliminisanjem IFMK_START-a procedure (tj zamjenom odgovarajucim klasama)
 */

*void TDBFin::install(string cKorisn,string cSifra,variant p3,variant p4,variant p5,variant p6,variant p7)

method install()
install_start(goModul, .f.)
return


/*! *void TDBFin::kreiraj(int nArea)
 *  \brief kreirane baze podataka FIN
 */
 
*void TDBFin::kreiraj(int nArea)

method kreiraj(nArea)
local cImeDbf

if (nArea==nil)
	nArea:=-1
endif

Beep(1)

if (nArea<>-1)
	CreSystemDb(nArea)
endif

cDirRad := my_home()
cDirSif := my_home()
cDirPriv := my_home()

CreFmkSvi()
CreRoba()
CreFmkPi()


if (nArea==-1 .or. nArea==(F_FUNK))
        //FUNK.DBF
	
	aDBf:={}
   	AADD(aDBf,{ "ID"      , "C" ,   5 ,  0 })
   	AADD(aDBf,{ "NAZ"     , "C" ,  35 ,  0 })
	
	if !FILE(f18_ime_dbf("funk"))
   		DBcreate2(KUMPATH+"FUNK.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","id",KUMPATH+"FUNK")
	CREATE_INDEX("NAZ","NAZ",KUMPATH+"FUNK")
endif


if (nArea==-1 .or. nArea==(F_FOND))
	//FOND.DBF
	
   	aDBf:={}
   	AADD(aDBf,{ "ID"      , "C" ,   3 ,  0 })
   	AADD(aDBf,{ "NAZ"     , "C" ,  35 ,  0 })
	
	if !FILE(f18_ime_dbf("FOND"))
		DBcreate2(KUMPATH+"FOND.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","id",KUMPATH+"FOND")
	CREATE_INDEX("NAZ","NAZ",KUMPATH+"FOND")
endif


if (nArea==-1 .or. nArea==(F_BUDZET))
	//BUDZET.DBF	
	
   	aDBf:={}
   	AADD(aDBf,{ "IDRJ"                , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
   	AADD(aDBf,{ "IZNOS"               , "N" ,  20 ,  2 })
   	AADD(aDBf,{ "FOND"                , "C" ,   3 ,  0 })
   	AADD(aDBf,{ "FUNK"                , "C" ,   5 ,  0 })
   	AADD(aDBf,{ "REBIZNOS"            , "N" ,  20 ,  2 })
   		
	if !FILE(f18_ime_dbf("budzet"))
		DBcreate2(KUMPATH+"BUDZET.DBF",aDbf)
	endif
	
	SELECT F_BUDZET
	MY_USE (KUMPATH+"BUDZET")
	if FieldPos("IDKONTO")=0 // ne postoji polje "idkonto"
  		USE
  		save screen to cScr
  		cls
  		FERASE(KUMPATH+"BUDZET.CDX")
  		Modstru(KUMPATH+"BUDZET.DBF","C EKKATEG C 5 0  IDKONTO C 7 0",.t.)
  		restore screen from cScr
	endif
	SELECT F_BUDZET
	USE

	CREATE_INDEX("1","IdRj+Idkonto",KUMPATH+"BUDZET")
	CREATE_INDEX("2","Idkonto",KUMPATH+"BUDZET")
endif


if (nArea==-1 .or. nArea==(F_PAREK))
	//PAREK.DBF
   	
	aDBf:={}
   	AADD(aDBf,{ "IDPARTIJA"           , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "Idkonto"             , "C" ,   7 ,  0 })
   	
	if !FILE(f18_ime_dbf("parek"))
		DBcreate2(KUMPATH+"PAREK",aDbf)
	endif

	CREATE_INDEX("1","IdPartija",KUMPATH+"PAREK")
endif


if (nArea==-1 .or. nArea==(F_BUIZ))
   	//BUIZ.DBF
	
	aDBf:={}
   	AADD(aDBf,{ "ID"        , "C" ,   7 ,  0 })
   	AADD(aDBf,{ "NAZ"       , "C" ,  10 ,  0 })
   	
	if !FILE(f18_ime_dbf("buiz"))
		DBcreate2(KUMPATH+"BUIZ",aDbf)
	endif

	CREATE_INDEX( "ID"  , "ID"  , KUMPATH+"BUIZ" )
	CREATE_INDEX( "NAZ" , "NAZ" , KUMPATH+"BUIZ" )
endif



aDbf:={}
AADD(aDBf,{ "ID"                  , "C" ,   7 ,  0 })
AADD(aDBf,{ "NAZ"                 , "C" ,  57 ,  0 })
AADD(aDBf,{ "POZBILU"             , "C" ,   3 ,  0 })
AADD(aDBf,{ "POZBILS"             , "C" ,   3 ,  0 })


if (nArea==-1 .or. nArea==(F_KONTO))
	//KONTO.DBF
	
	if !FILE(f18_ime_dbf("konto"))
   		DBcreate2(SIFPATH+"KONTO.DBF",aDbf)
	endif

	CREATE_INDEX("ID","id",SIFPATH+"KONTO") // konta
	CREATE_INDEX("NAZ","naz",SIFPATH+"KONTO")
endif

if (nArea==-1 .or. nArea==(F_FIN_RJ))

	aDBf:={}
	AADD(aDBf,{ 'ID'                  , 'C' ,   6 ,  0 })
   	AADD(aDBf,{ 'NAZ'                 , 'C' ,  35 ,  0 })
		
	if !FILE(f18_ime_dbf("fin_rj"))
   		DBcreate2(KUMPATH+"FIN_RJ.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","id",KUMPATH+"FIN_RJ")
	CREATE_INDEX("NAZ","NAZ",KUMPATH+"FIN_RJ")

endif


if (nArea==-1 .or. nArea==(F__KONTO))
	//_KONTO.DBF

	if !FILE(f18_ime_dbf("_konto"))
   		DBcreate2(PRIVPATH+"_KONTO.DBF",aDbf)
	endif
endif


if (nArea==-1 .or. nArea==(F_TNAL))
	//TNAL.DBF
	
        aDbf:={}
        AADD(aDBf,{ "ID"                  , "C" ,   2 ,  0 })
        AADD(aDBf,{ "NAZ"                 , "C" ,  29 ,  0 })

	if !FILE(f18_ime_dbf("tnal"))
        	DBcreate2(SIFPATH+"TNAL.DBF",aDbf)	
	endif
	
	CREATE_INDEX("ID","id",SIFPATH+"TNAL")  // vrste naloga
	CREATE_INDEX("NAZ","naz",SIFPATH+"TNAL")
endif


if (nArea==-1 .or. nArea==(F_TDOK))
	//TDOK.DBF

	if !FILE(f18_ime_dbf("tdok"))
        aDbf:={}
        AADD(aDBf,{ "ID"                  , "C" ,   2 ,  0 })
        AADD(aDBf,{ "NAZ"                 , "C" ,  13 ,  0 })
        
		DBCREATE2(SIFPATH+"TDOK.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","id",SIFPATH+"TDOK")  // Tip dokumenta
	CREATE_INDEX("NAZ","naz",SIFPATH+"TDOK")
endif


aDbf:={}
AADD(aDBf,{ "IDFIRMA"             , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRNAL"               , "C" ,   8 ,  0 })
AADD(aDBf,{ "DATNAL"              , "D" ,   8 ,  0 })
AADD(aDBf,{ "DUGBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "POTBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "DUGDEM"              , "N" ,  15 ,  2 })
AADD(aDBf,{ "POTDEM"              , "N" ,  15 ,  2 })

if (nArea==-1 .or. nArea==(F_NALOG))
	//NALOG.DBF

	if !FILE(f18_ime_dbf("nalog"))
        	DBcreate2("NALOG",aDbf)
			reset_semaphore_version("fin_nalog")
			my_use("nalog")
			close all
	endif


	
	CREATE_INDEX("1","IdFirma+IdVn+BrNal",KUMPATH+"NALOG") 
	CREATE_INDEX("2","IdFirma+str(val(BrNal),8)+idvn",KUMPATH+"NALOG") 
	CREATE_INDEX("3","dtos(datnal)+IdFirma+idvn+brnal",KUMPATH+"NALOG") 
	CREATE_INDEX("4","datnal",KUMPATH+"NALOG") 

endif


if (nArea==-1 .or. nArea==(F_PNALOG))
	//PNALOG.DBF

	if !FILE(f18_ime_dbf("pnalog"))
        	DBcreate2(PRIVPATH+"PNALOG.DBF",aDbf)
	endif

	CREATE_INDEX("1","IdFirma+IdVn+BrNal",PRIVPATH+"PNALOG")
endif


aDbf:={}
AADD(aDBf,{ "IDFIRMA"             , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
AADD(aDBf,{ "IDPARTNER"           , "C" ,   6 ,  0 })
AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRNAL"               , "C" ,   8 ,  0 })
AADD(aDBf,{ "RBR"                 , "C" ,   4 ,  0 })
AADD(aDBf,{ "IDTIPDOK"            , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRDOK"               , "C" ,   10 ,  0 })
AADD(aDBf,{ "DATDOK"              , "D" ,   8 ,  0 })
AADD(aDBf,{ "DatVal"              , "D" ,   8 ,  0 })
AADD(aDBf,{ "OTVST"               , "C" ,   1 ,  0 })
AADD(aDBf,{ "D_P"                 , "C" ,   1 ,  0 })
AADD(aDBf,{ "IZNOSBHD"            , "N" ,  21 ,  6 })
AADD(aDBf,{ "IZNOSDEM"            , "N" ,  19 ,  6 })
AADD(aDBf,{ "OPIS"               , "C" ,  80 ,  0 })
AADD(aDBf,{ "K1"               , "C" ,   1 ,  0 })
AADD(aDBf,{ "K2"               , "C" ,   1 ,  0 })
AADD(aDBf,{ "K3"               , "C" ,   2 ,  0 })
AADD(aDBf,{ "K4"               , "C" ,   2 ,  0 })
AADD(aDBf,{ "M1"               , "C" ,   1 ,  0 })
AADD(aDBf,{ "M2"               , "C" ,   1 ,  0 })


if (nArea==-1 .or. nArea==(F_SUBAN))
	//SUBAN.DBF

	if !FILE(f18_ime_dbf("suban"))
        	DBCREATE2("SUBAN", aDbf)
            reset_semaphore_version("fin_suban")
            my_use("suban")
            close all
	endif
	
	CREATE_INDEX("1", "IdFirma+IdKonto+IdPartner+dtos(DatDok)+BrNal+RBr", "SUBAN") 
	CREATE_INDEX("2", "IdFirma+IdPartner+IdKonto", "SUBAN")
	CREATE_INDEX("3", "IdFirma+IdKonto+IdPartner+BrDok+dtos(DatDok)","SUBAN")
	CREATE_INDEX("4", "idFirma+IdVN+BrNal+Rbr", "SUBAN")
	CREATE_INDEX("5", "idFirma+IdKonto+dtos(DatDok)+idpartner", "SUBAN")

	CREATE_INDEX("6","IdKonto", "SUBAN")

	CREATE_INDEX("7","Idpartner", "SUBAN")
	CREATE_INDEX("8","Datdok", "SUBAN")
	
	CREATE_INDEX("10","idFirma+IdVN+BrNal+idkonto+DTOS(datdok)", "SUBAN")
	
	if gRJ=="D"
		CREATE_INDEX("9","idfirma+idkonto+idrj+idpartner+DTOS(datdok)+brnal+rbr", "SUBAN")
	endif
endif


if (nArea==-1 .or. nArea==(F_PSUBAN))
	//PSUBAN.DBF

	if !FILE(f18_ime_dbf("psuban"))
        	DBcreate2(PRIVPATH+"PSUBAN.DBF",aDbf)
	endif
	
	CREATE_INDEX("1","IdFirma+IdVn+BrNal",PRIVPATH+"PSUBAN")
	CREATE_INDEX("2","idFirma+IdVN+BrNal+IdKonto",PRIVPATH+"PSUBAN")
endif


if (nArea==-1 .or. nArea==(F_FIN_PRIPR))
	//PRIPR.DBF

	if !FILE(f18_ime_dbf("fin_pripr"))
        	DBcreate2(PRIVPATH+"FIN_PRIPR.DBF",aDbf)
	endif

	CREATE_INDEX("1","idFirma+IdVN+BrNal+Rbr",PRIVPATH+"FIN_PRIPR")
	CREATE_INDEX("2","idFirma+IdVN+BrNal+IdKonto",PRIVPATH+"FIN_PRIPR")
endif


aDbf:={}
AADD(aDBf,{ "IDFIRMA"             , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRNAL"               , "C" ,   8 ,  0 })
AADD(aDBf,{ "RBR"                 , "C" ,   3 ,  0 })
AADD(aDBf,{ "DATNAL"              , "D" ,   8 ,  0 })
AADD(aDBf,{ "DUGBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "POTBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "DUGDEM"              , "N" ,  15 ,  2 })
AADD(aDBf,{ "POTDEM"              , "N" ,  15 ,  2 })


if (nArea==-1 .or. nArea==(F_ANAL))
	//ANAL.DBF

	if !FILE(f18_ime_dbf("anal"))
 		DBcreate2( "ANAL", aDbf )
		reset_semaphore_version("fin_anal")
		my_use("anal")
		close all
	endif
			
	CREATE_INDEX("1","IdFirma+IdKonto+dtos(DatNal)",KUMPATH+"ANAL")  //analiti
	CREATE_INDEX("2","idFirma+IdVN+BrNal+Rbr",KUMPATH+"ANAL")  //analiti
	CREATE_INDEX("3","idFirma+dtos(DatNal)",KUMPATH+"ANAL")  //analiti
	CREATE_INDEX("4","Idkonto",KUMPATH+"ANAL")  //analiti
	CREATE_INDEX("5","DatNal",KUMPATH+"ANAL")  //analiti
	
endif


if (nArea==-1 .or. nArea==(F_PANAL))
	//PANAL.DBF

	if !FILE(f18_ime_dbf("panal"))
        	DBCREATE2(PRIVPATH+"PANAL.DBF",aDbf)
	endif

	CREATE_INDEX("1","IdFirma+IdVn+BrNal+idkonto",PRIVPATH+"PANAL")
endif


aDbf:={}
AADD(aDBf,{ "IDFIRMA"             , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDKONTO"             , "C" ,   3 ,  0 })
AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRNAL"               , "C" ,   8 ,  0 })
AADD(aDBf,{ "RBR"                 , "C" ,   3 ,  0 })
AADD(aDBf,{ "DATNAL"              , "D" ,   8 ,  0 })
AADD(aDBf,{ "DUGBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "POTBHD"              , "N" ,  17 ,  2 })
AADD(aDBf,{ "DUGDEM"              , "N" ,  15 ,  2 })
AADD(aDBf,{ "POTDEM"              , "N" ,  15 ,  2 })


if (nArea==-1 .or. nArea==(F_SINT))
	//SINT.DBF

	if !FILE(f18_ime_dbf("sint"))
        	DBcreate2( "SINT", aDbf )
			reset_semaphore_version("fin_sint")
			my_use("sint")
			close all
	endif

	
	CREATE_INDEX("1","IdFirma+IdKonto+dtos(DatNal)",KUMPATH+"SINT")  // sinteti
	CREATE_INDEX("2","idFirma+IdVN+BrNal+Rbr",KUMPATH+"SINT")
	CREATE_INDEX("3","datnal",KUMPATH+"SINT")

endif


if (nArea==-1 .or. nArea==(F_PSINT))
	//PSINT.DBF

	if !FILE(f18_ime_dbf("psint"))
        	DBCREATE2(PRIVPATH+"PSINT.DBF",aDbf)
	endif

	CREATE_INDEX("1","IdFirma+IdVn+BrNal+idkonto",PRIVPATH+"PSINT")
endif


if (nArea==-1 .or. nArea==(F_BBKLAS))
	//BBKLAS.DBF
        
        aDbf:={}
        AADD(aDBf,{ "IDKLASA"             , "C" ,   1 ,  0 })
        AADD(aDBf,{ "POCDUG"              , "N" ,  17 ,  2 })
        AADD(aDBf,{ "POCPOT"              , "N" ,  17 ,  2 })
        AADD(aDBf,{ "TEKPDUG"             , "N" ,  17 ,  2 })
        AADD(aDBf,{ "TEKPPOT"             , "N" ,  17 ,  2 })
        AADD(aDBf,{ "KUMPDUG"             , "N" ,  17 ,  2 })
        AADD(aDBf,{ "KUMPPOT"             , "N" ,  17 ,  2 })
        AADD(aDBf,{ "SALPDUG"             , "N" ,  17 ,  2 })
        AADD(aDBf,{ "SALPPOT"             , "N" ,  17 ,  2 })
	
	if !FILE(f18_ime_dbf("bbklas"))
        	DBcreate2(PRIVPATH+"BBKLAS.DBF",aDbf)
	endif
	
	CREATE_INDEX("1","IdKlasa", PRIVPATH+"BBKLAS")
endif


if (nArea==-1 .or. nArea==(F_IOS))
	//IOS.DBF

	aDbf:={}
        AADD(aDBf,{ "IDFIRMA"             , "C" ,   2 ,  0 })
        AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
        AADD(aDBf,{ "IDPARTNER"           , "C" ,   6 ,  0 })
        AADD(aDBf,{ "IZNOSBHD"            , "N" ,  17 ,  2 })
        AADD(aDBf,{ "IZNOSDEM"            , "N" ,  15 ,  2 })
	
	if !FILE(f18_ime_dbf("ios"))
        	DBcreate2(PRIVPATH+"IOS",aDbf)
	endif

	CREATE_INDEX("1","IdFirma+IdKonto+IdPartner",PRIVPATH+"IOS") // IOS
endif



if (nArea==-1 .or. nArea==(F_PKONTO))
	//PKONTO.DBF
        
        aDbf:={}
        AADD(aDBf,{ "ID"                  , "C" ,  7  ,  0 })
        AADD(aDBf,{ "TIP"                 , "C" ,  1 ,   0 })
		
	if !FILE(f18_ime_dbf("pkonto"))
        	DBcreate2(SIFPATH+"PKONTO.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","ID",SIFPATH+"PKONTO")
	CREATE_INDEX("NAZ","TIP",SIFPATH+"PKONTO")
endif

aDbf:={}
AADD(aDBf,{ "IDFIRMA"          , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDKONTO"          , "C" ,   7 ,  0 })
AADD(aDBf,{ "IDKONTO2"         , "C" ,   7 ,  0 })
AADD(aDBf,{ "IDTARIFA"         , "C" ,   6 ,  0 })
AADD(aDBf,{ "IDPARTNER"        , "C" ,   6 ,  0 })
AADD(aDBf,{ "IDVD"             , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRDOK"            , "C" ,   8 ,  0 })
AADD(aDBf,{ "DATDOK"           , "D" ,   8 ,  0 })
AADD(aDBf,{ "BRFAKTP"          , "C" ,  10 ,  0 })
AADD(aDBf,{ "DATFAKTP"         , "D" ,   8 ,  0 })
AADD(aDBf,{ "DATKURS"          , "D" ,   8 ,  0 })
AADD(aDBf,{ "FV"               , "N" ,  20 ,  8 })
AADD(aDBf,{ "GKV"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "GKV2"             , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR1"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR2"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR3"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR4"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR5"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "TR6"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "NV"               , "N" ,  20 ,  8 })
AADD(aDBf,{ "RABATV"           , "N" ,  20 ,  8 })
AADD(aDBf,{ "POREZV"           , "N" ,  20 ,  8 })
AADD(aDBf,{ "MARZA"            , "N" ,  20 ,  8 })
AADD(aDBf,{ "VPV"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "MPV"              , "N" ,  20 ,  8 })
AADD(aDBf,{ "MARZA2"           , "N" ,  20 ,  8 })
AADD(aDBf,{ "POREZ"            , "N" ,  20 ,  8 })
AADD(aDBf,{ "POREZ2"           , "N" ,  20 ,  8 })
AADD(aDBf,{ "POREZ3"           , "N" ,  20 ,  8 })
AADD(aDBf,{ "MPVSAPP"          , "N" ,  20 ,  8 })
AADD(aDBf,{ "IDROBA"           , "C" ,  10 ,  0 })
AADD(aDBf,{ "KOLICINA"         , "N" ,  19 ,  7 })
AADD(aDBf,{ "GKol"             , "N" ,  19 ,  7 })
AADD(aDBf,{ "GKol2"            , "N" ,  19 ,  7 })
AADD(aDBf,{ "PORVT"            , "N" ,  20 ,  8 })
AADD(aDBf,{ "UPOREZV"          , "N" ,  20 ,  8 })

if (nArea==-1 .or. nArea==(F_FINMAT))
	//FINMAT.DBF

	if !FILE(f18_ime_dbf("finmat"))
    		DBcreate2(PRIVPATH+"FINMAT.DBF",aDbf)
	endif
	
	CREATE_INDEX("1","idFirma+IdVD+BRDok",PRIVPATH+"FINMAT")
endif


if (nArea==-1 .or. nArea==(F_TRFP2))
	//TRFP2.DBF
        
        aDbf:={}
        AADD(aDBf,{ "ID"                  , "C" ,  60 ,  0 })
        AADD(aDBf,{ "SHEMA"               , "C" ,   1 ,  0 })
        AADD(aDBf,{ "NAZ"                 , "C" ,  20 ,  0 })
        AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
        AADD(aDBf,{ "DOKUMENT"            , "C" ,   1 ,  0 })
        AADD(aDBf,{ "PARTNER"             , "C" ,   1 ,  0 })
        AADD(aDBf,{ "D_P"                 , "C" ,   1 ,  0 })
        AADD(aDBf,{ "ZNAK"                , "C" ,   1 ,  0 })
        AADD(aDBf,{ "IDVD"                , "C" ,   2 ,  0 })
        AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
        AADD(aDBf,{ "IDTARIFA"            , "C" ,   6 ,  0 })
	
	if !FILE(f18_ime_dbf("trfp2"))
        	DBcreate2( "TRFP2", aDbf ) 
			reset_semaphore_version("trfp2")
			my_use("trfp2")
			close all
	endif

	CREATE_INDEX("ID","idvd+shema+Idkonto",SIFPATH+"TRFP2")
endif

if (nArea==-1 .or. nArea==(F_TRFP3))
	//TRFP3.DBF
        
        aDbf:={}
        AADD(aDBf,{ "ID"                  , "C" ,  60 ,  0 })
        AADD(aDBf,{ "SHEMA"               , "C" ,   1 ,  0 })
        AADD(aDBf,{ "NAZ"                 , "C" ,  20 ,  0 })
        AADD(aDBf,{ "IDKONTO"             , "C" ,   7 ,  0 })
        AADD(aDBf,{ "D_P"                 , "C" ,   1 ,  0 })
        AADD(aDBf,{ "ZNAK"                , "C" ,   1 ,  0 })
        AADD(aDBf,{ "IDVN"                , "C" ,   2 ,  0 })
	
	if !FILE(f18_ime_dbf("trfp3"))
        	DBcreate2("TRFP3",aDbf)
			reset_semaphore_version("trfp3")
			my_use("trfp3")
			close all	
	endif

	CREATE_INDEX("ID","shema+Idkonto",SIFPATH+"TRFP3")
endif


if (nArea==-1 .or. nArea==(F_KONCIJ))
	//KONCIJ.DBF

   	aDbf:={}
   	AADD(aDBf,{ "ID"                  , "C" ,   7 ,  0 })
   	AADD(aDBf,{ "SHEMA"               , "C" ,   1 ,  0 })
   	AADD(aDBf,{ "NAZ"                 , "C" ,   2 ,  0 })
   	AADD(aDBf,{ "IDPRODMJES"          , "C" ,   2 ,  0 })
   
	if !FILE(f18_ime_dbf("koncij"))
      		DBcreate2("KONCIJ",aDbf)
			reset_semaphore_version("koncij")
			my_use("koncij")
			close all	
	endif

	CREATE_INDEX("ID","id",SIFPATH+"KONCIJ") // konta
endif

if (nArea==-1 .or. nArea==(F_VKSG))
	//VKSG.DBF

	aDbf:={}
	AADD(aDBf,{ "ID"                  , "C" ,   7 ,  0 })
	AADD(aDBf,{ "GODINA"              , "C" ,   4 ,  0 })
	AADD(aDBf,{ "IDS"                 , "C" ,   7 ,  0 })

	if !FILE(f18_ime_dbf("vksg"))
   		DBcreate2(SIFPATH+"VKSG.DBF",aDbf)
	endif

	CREATE_INDEX("1","id+DESCEND(godina)",SIFPATH+"VKSG")
endif


if (nArea==-1 .or. nArea==(F_KUF))
	//KUF.DBF

   	aDbf:={}
   	AADD(aDBf,{ "ID"                  , "C" ,   8 ,  0 })
   	AADD(aDBf,{ "NAZ"                 , "C" ,  20 ,  0 })
   	AADD(aDBf,{ "IDRJ"                , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "DATPR"               , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "IDPARTN"             , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "DATFAKT"             , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "BRFAKT"              , "C" ,  20 ,  0 })
   	AADD(aDBf,{ "IZNOS"               , "N" ,  12 ,  2 })
   	AADD(aDBf,{ "IDVRSTEP"            , "C" ,   2 ,  0 })
   	AADD(aDBf,{ "DATPL"               , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "PLACENO"             , "C" ,   1 ,  0 })

	if !FILE(f18_ime_dbf("fin_kuf"))
   		DBcreate2(KUMPATH+"FIN_KUF.DBF",aDbf)
	endif
	
	CREATE_INDEX( "ID" , "id"     , KUMPATH+"FIN_KUF" )
	CREATE_INDEX( "ID2", "idrj+id", KUMPATH+"FIN_KUF" )
	CREATE_INDEX( "NAZ", "naz"    , KUMPATH+"FIN_KUF" )
endif

if (nArea==-1 .or. nArea==(F_KIF))
	//KIF.DBF

   	aDbf:={}
   	AADD(aDBf,{ "ID"                  , "C" ,   8 ,  0 })
   	AADD(aDBf,{ "NAZ"                 , "C" ,  20 ,  0 })
   	AADD(aDBf,{ "IDRJ"                , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "DATPR"               , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "IDPARTN"             , "C" ,   6 ,  0 })
   	AADD(aDBf,{ "DATFAKT"             , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "BRFAKT"              , "C" ,  20 ,  0 })
   	AADD(aDBf,{ "IZNOS"               , "N" ,  12 ,  2 })
   	AADD(aDBf,{ "IDVRSTEP"            , "C" ,   2 ,  0 })
   	AADD(aDBf,{ "DATPL"               , "D" ,   8 ,  0 })
   	AADD(aDBf,{ "PLACENO"             , "C" ,   1 ,  0 })
   	AADD(aDBf,{ "IDVPRIH"             , "C" ,   3 ,  0 })

	if !FILE(f18_ime_dbf("fin_kif"))
   		DBcreate2(KUMPATH+"FIN_KIF.DBF",aDbf)
	endif
	
	CREATE_INDEX( "ID" , "id"     , KUMPATH+"FIN_KIF" )
	CREATE_INDEX( "ID2", "idrj+id", KUMPATH+"FIN_KIF" )
	CREATE_INDEX( "NAZ", "naz"    , KUMPATH+"FIN_KIF" )
endif


if (nArea==-1 .or. nArea==(F_TNAL))
	//VRSTEP.DBF

	if !FILE(f18_ime_dbf("vrstep"))
   		aDbf:={{"ID",  "C",  2, 0}, ;
             	       {"NAZ", "C", 20, 0}}
   		DBcreate2("VRSTEP",aDbf)
		//reset_semaphore_version("vrstep")
		//my_use("vrstep")
		//close all	
	endif
	
	CREATE_INDEX("ID","Id",SIFPATH+"VRSTEP.DBF")
endif


if (nArea==-1 .or. nArea==(F_VPRIH))
	//VPRIH.DBF

	if !FILE(f18_ime_dbf("vprih"))
   		aDbf:={{"ID",  "C",  3, 0}, ;
             	       {"NAZ", "C", 20, 0}}
   		DBcreate2(SIFPATH+"VPRIH.DBF",aDbf)	
	endif
	
	CREATE_INDEX ("ID", "Id", SIFPATH+"VPRIH.DBF")
endif


if (nArea==-1 .or. nArea==(F_ULIMIT))
	//ULIMIT.DBF

	if !FILE(f18_ime_dbf("ulimit"))
   		aDbf:={{"ID"        , "C" ,  3 , 0 }, ;
        	       { "IDPARTNER" , "C" ,  6 , 0 }, ;
             	       { "LIMIT"     , "N" , 15 , 2 }}
   		DBcreate2(SIFPATH+"ULIMIT.DBF",aDbf)
	endif
	
	CREATE_INDEX("ID","Id"          , SIFPATH+"ULIMIT.DBF")
	CREATE_INDEX("2" ,"Id+idpartner", SIFPATH+"ULIMIT.DBF")
endif

// kreiraj indexe tabele FMKRULES
cre_rule_cdx()

return




/*! \fn *void TDBFin::obaza(int i)
 *  \brief otvara odgovarajucu tabelu
 *  
 *  S obzirom da se koristi prvenstveno za instalacijske funkcije
 *  otvara tabele u exclusive rezimu
 */

*void TDBFin::obaza(int i)

method obaza (i)
local lIdIDalje
local cDbfName

lIdiDalje:=.f.

if i==F_FIN_PRIPR .or. i==F_BBKLAS .or. i==F_IOS  .or.i==F_PNALOG .or. i==F_PSUBAN .or. i==F_PANAL  .or. i==F_PSINT
	lIdiDalje:=.t.
endif

if i==F_SUBAN  .or. i==F_ANAL   .or. i==F_SINT   .or. i==F_NALOG 
	lIdiDalje:=.t.
endif

if  i==F_PARTN  .or. i==F_KONTO  .or. i==F_ULIMIT .or. i==F_PKONTO  .or. i==F_TNAL   .or. i==F_TDOK   .or. i==F_VALUTE .or. i==F_VKSG   .or.  i==F_RJ   .or.  i==F__KONTO .or. i==F__PARTN .or. i==F_SIFK  .or. i==F_SIFV 
	lIdiDalje:=.t.
endif

if  i==F_FUNK  .or. i==F_FOND  .or. i==F_BUIZ 
	lIdiDalje:=.t.
endif

IF IzFMKIni("FIN","KUF","N")=="D"
  if i==F_KUF   
  	lIdiDalje:=.t.  
  endif
ENDIF

IF IzFMKIni("FIN","KIF","N")=="D"
  if i==F_KIF  .or. O_VPRIH 
  	lIdiDalje:=.t.
  endif
ENDIF

if (gSecurity=="D" .and. (i==F_EVENTS .or. i==F_EVENTLOG .or. i==F_USERS .or. i==F_GROUPS .or. i==F_RULES))
	lIdiDalje:=.t.
endif

if lIdiDalje
	cDbfName:=DBFName(i,.t.)
	if gAppSrv 
		? "OPEN: " + cDbfName + ".DBF"
		if !File(cDbfName + ".DBF")
			? "Fajl " + cDbfName + ".dbf ne postoji!!!"
			use
			return
		endif
	endif
	
	select(i)
	usex(cDbfName)
else
	use
	return
endif

return


/*! \fn *void TDBFin::ostalef()
 *  \brief Ostalef funkcije (bivsi install modul)
*/

*void TDBFin::ostalef()


method ostalef()

closeret
return


/*! \fn *void TDBFin::konvZn()
 *  \brief Koverzija znakova
 *  \note sifra: KZ
 */
 
*void TDBFin::konvZn()

method konvZn()

LOCAL cIz:="7", cU:="8", aPriv:={}, aKum:={}, aSif:={}
LOCAL GetList:={}, cSif:="D", cKum:="D", cPriv:="D"
if !gAppSrv
	IF !SigmaSif("KZ      ")
   		RETURN
 	ENDIF
	Box(,8,50)
  	@ m_x+2, m_y+2 SAY "Trenutni standard (7/8)        " GET cIz   VALID   cIz$"78"  PICT "9"
  	@ m_x+3, m_y+2 SAY "Konvertovati u standard (7/8/A)" GET cU    VALID    cU$"78A" PICT "@!"
  	@ m_x+5, m_y+2 SAY "Konvertovati sifrarnike (D/N)  " GET cSif  VALID  cSif$"DN"  PICT "@!"
  	@ m_x+6, m_y+2 SAY "Konvertovati radne baze (D/N)  " GET cKum  VALID  cKum$"DN"  PICT "@!"
  	@ m_x+7, m_y+2 SAY "Konvertovati priv.baze  (D/N)  " GET cPriv VALID cPriv$"DN"  PICT "@!"
  	READ
  	IF LASTKEY()==K_ESC
		BoxC()
		RETURN
	ENDIF
  	IF Pitanje(,"Jeste li sigurni da zelite izvrsiti konverziju (D/N)","N")=="N"
    		BoxC()
		RETURN
  	ENDIF
 	BoxC()
else
	?
	cKonvertTo:=IzFmkIni("FMK","KonvertTo","78",EXEPATH)
	
	if cKonvertTo=="78"
		cIz:="7"
		cU:="8"
		? "Trenutni standard: " + cIz
		? "Konvertovati u: " + cU 
	elseif cKonvertTo=="87"
		cIz:="8"
		cU:="7"
		? "Trenutni standard: " + cIz
		? "Konvertovati u: " + cU 
	else // pitaj
		?
		@ 10, 2 SAY "Trenutni standard (7/8)        " GET cIz VALID cIz$"78" PICT "9"
		?
		@ 11, 2 SAY "Konvertovati u standard (7/8/A)" GET cU VALID cU$"78A" PICT "@!"
		read
	endif
	cSif:="D"
	cKum:="D"
	cPriv:="D"
endif
 
aKum  := { F_SUBAN, F_ANAL, F_SINT, F_NALOG, F_BUDZET, F_PAREK, F_RJ,;
            F_FUNK, F_FOND, F_KONIZ, F_IZVJE, F_ZAGLI, F_KOLIZ, F_BUIZ }
aPriv := { F_PRIPR, F_BBKLAS, F_IOS, F_PNALOG, F_PSUBAN, F_PANAL, F_PSINT,;
            F__KONTO, F__PARTN }
aSif  := { F_KONTO, F_PARTN, F_TNAL, F_TDOK, F_PKONTO, F_VALUTE, F_TRFP2,;
            F_TRFP3, F_VRSTEP, F_ULIMIT }

 IF cSif  == "N"; aSif  := {}; ENDIF
 IF cKum  == "N"; aKum  := {}; ENDIF
 IF cPriv == "N"; aPriv := {}; ENDIF

KZNbaza(aPriv,aKum,aSif,cIz,cU)

return



/*! \fn *void TDbFin::scan()
 */
*void TDbFin::scan()

method scan
local cSlaveRadnaStanica

cSlaveRadnaStanica:=IzFmkIni("DB","Slave","N",PRIVPATH)

if (cSlaveRadnaStanica=="D")
	return
endif

ScanDb()

if (gSql=="D")
	
	nFree:=GwDiskFree()
	//odredi kolicinu u MB
	nFree:=ROUND(((nFree)/1024)/1024,1)
	for i:=1 to 2
		if (nFree<50)
			MsgBeep("Na disku C: je ostalo samo "+ALLTRIM(STR(nFree,10,1))+" MB#oslobodite prostor na disku # ... ili prijavite u servis SC-a !!") 
		endif
	next
endif
return


return


