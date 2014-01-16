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


static __line
static __txt1
static __txt2
static __txt3


// ---------------------------------
// tabele potrebne za report
// ---------------------------------
static function _o_tables()

O_SIFK
O_SIFV
O_ROBA
O_KONCIJ
O_KONTO
O_PARTN

return

 
// ----------------------------------------------------
// izvjestaj - lager lista magacina
// ----------------------------------------------------
function LLM()
parameters fPocStanje
local fimagresaka:=.f.
local aNabavke:={}
local _curr_user := "<>"
local lExpDbf := .f.
local cExpDbf := "N"
local cMoreInfo := "N"
local _vpc_iz_sif := "D"
local _print := "1"
// ulaz, izlaz parovno
local nTUlazP
local nTIzlazP
local nKolicina
local cPicDem
local cPicCDem
local cPicKol
local cLine
local cTxt1
local cTxt2
local cTxt3
local cMIPart := ""
local cMINumber := ""
local dMIDate := CTOD("")
local cMI_type := ""
local cSrKolNula := "0"
local dL_ulaz := CTOD("")
local dL_izlaz := CTOD("")

cPicDem := gPicDem
cPicCDem := gPicCDem
cPicKol := gPicKol

gPicDem := REPLICATE("9", VAL(gFPicDem)) + gPicDem
gPicCDem := REPLICATE("9", VAL(gFPicCDem)) + gPicCDem
gPicKol := REPLICATE("9", VAL(gFPicKol)) + gPicKol

cIdFirma:=gFirma
cPrikazDob:="N"
cIdKonto:=padr("1310", gDuzKonto)

private nVPVU:=0
private nVPVI:=0

private nVPVRU:=0
private nVPVRI:=0

private nNVU:=0
private nNVI:=0

if IsPlanika()
	cPlVrsta:=SPACE(1)
	private cK9:=SPACE(3)
	private cK1:=SPACE(4)
endif

if IsDomZdr()
	private cKalkTip:=SPACE(1)
	private cSzDN:="N"
endif

// signalne zalihe
private lSignZal:=.f.
private qqRGr:=SPACE(40)
private qqRGr2:=SPACE(40)

if IsVindija()
	cOpcine:=SPACE(50)
endif

_o_tables() 	
	
if fPocStanje==NIL
	fPocStanje:=.f.
else
   	fPocStanje:=.t.
   	O_KALK_PRIPR
   	cBrPSt:="00001   "
   	Box(,3,60)
     		@ m_x+1,m_y+2 SAY "Generacija poc. stanja  - broj dokumenta 16 -" GET cBrPSt
     		read
		ESC_BCR
   	BoxC()
endif

private dDatOd := DATE()
private dDatDo := DATE()

qqRoba:=space(60)
qqTarifa:=space(60)
qqidvd:=space(60)
qqIdPartner:=space(60)

private cPNab:="N"
private cDoNab:="N"
private cNula:="N"
private cErr:="N"
private cNCSif:="N"
private cMink:="N"
private cSredCij:="N"
private cPKN := "N"
private cFaBrDok := space(40)

if !Empty(cRNT1)
	private cRNalBroj:=PADR("", 40)
endif

if !fPocStanje
 
 cIdKonto := fetch_metric("kalk_lager_lista_id_konto", _curr_user, cIdKonto )
 cPNab := fetch_metric("kalk_lager_lista_po_nabavnoj", _curr_user, cPNab )
 cNula := fetch_metric("kalk_lager_lista_prikaz_nula", _curr_user, cNula )
 dDatOd := fetch_metric("kalk_lager_lista_datum_od", _curr_user, dDatOd )
 dDatDo := fetch_metric("kalk_lager_lista_datum_do", _curr_user, dDatDo )
 cDoNab := fetch_metric("kalk_lager_Lista_prikaz_do_nabavne", _curr_user, cDoNab )
 _vpc_iz_sif := fetch_metric("kalk_lager_Lista_vpc_iz_sif", _curr_user, _vpc_iz_sif )
 _print := fetch_metric("kalk_lager_print_varijanta", _curr_user, _print )
endif

cArtikalNaz:=SPACE(30)

Box(,21+IF(lPoNarudzbi,2,0),70)
	
	do while .t.
 		if gNW $ "DX"
   			@ m_x+1,m_y+2 SAY "Firma "
			?? gFirma,"-",gNFirma
 		else
  			@ m_x+1,m_y+2 SAY "Firma: " GET cIdFirma valid {|| P_Firma(@cIdFirma),cidfirma:=left(cidfirma,2),.t.}
 		endif
 		@ m_x+2,m_y+2 SAY "Konto   " GET cIdKonto valid "." $ cidkonto .or. P_Konto(@cIdKonto)
 		@ m_x+3,m_y+2 SAY "Artikli " GET qqRoba pict "@!S50"
 		@ m_x+4,m_y+2 SAY "Tarife  " GET qqTarifa pict "@!S50"
 		@ m_x+5,m_y+2 SAY "Vrste dokumenata " GET qqIDVD pict "@!S30"
 		@ m_x+6,m_y+2 SAY "Partneri " GET qqIdPartner pict "@!S20"
		@ m_x+6,col()+1 SAY "Br.fakture " GET cFaBrDok  pict "@!S15"
 		@ m_x+7,m_y+2 SAY "Prikaz Nab.vrijednosti D/N" GET cPNab  valid cpnab $ "DN" pict "@!"
 		
 		@ m_x+7,col()+1 SAY "Prikaz samo do nab.vr. D/N" GET cDoNab  valid cDoNab $ "DN" pict "@!"

		if ( IsPDV() .and. ( IsMagPNab() .or. IsMagSNab() ) )
			@ m_x+8,m_y+2 SAY "Pr.stavki kojima je NV 0 D/N" GET cNula  valid cNula $ "DN" pict "@!"
 			@ m_x+9,m_y+2 SAY "Prikaz 'ERR' ako je NV/Kolicina<>NC " GET cErr pict "@!" valid cErr $ "DN"
            @ m_x+9,col()+1 SAY "VPC iz sifrarnika robe (D/N)?" GET _vpc_iz_sif PICT "@!" VALID _vpc_iz_sif $ "DN"
		else
			@ m_x+8,m_y+2 SAY "Prikaz stavki kojima je VPV 0 D/N" GET cNula  valid cNula $ "DN" pict "@!"
 			@ m_x+9,m_y+2 SAY "Prikaz 'ERR' ako je VPV/Kolicina<>VPC " GET cErr pict "@!" valid cErr $ "DN"
 		endif

		@ m_x+10,m_y+2 SAY "Datum od " GET dDatOd
 		@ m_x+10,col()+2 SAY "do" GET dDatDo
        
        @ m_x + 11, m_y + 2 SAY "Vrsta stampe TXT/ODT (1/2)" GET _print VALID _print $ "12" PICT "@!"

 		@ m_x+12,m_y+2 SAY "Postaviti srednju NC u sifrarnik" GET cNCSif pict "@!" valid ((cpnab=="D" .and. cncsif=="D") .or. cNCSif=="N")
 		
		if fPocStanje
			@ m_x+13,m_y+2 SAY "Sredi samo stavke kol=0, nv<>0 (0/1/2)" ;
				GET cSrKolNula VALID cSrKolNula $ "012" ;
				PICT "@!"
		endif

		@ m_x+14,m_y+2 SAY "Prikaz samo kriticnih zaliha (D/N/O) ?" GET cMinK pict "@!" valid cMink$"DNO"

 		if IsVindija()
			cGr:=SPACE(10)
			cPSPDN := "N"
 			@ m_x+15,m_y+2 SAY "Grupa:" GET cGr
			@ m_x+16,m_y+2 SAY "Pregled samo prodaje (D/N)" GET cPSPDN VALID cPSPDN $ "DN" PICT "@!"
		endif
		
 		if IsPlanika()
 			@ m_x+15,m_y+2 SAY "Prikaz dobavljaca (D/N) ?" GET cPrikazDob PICT "@!" VALID cPrikazDob$"DN"
 			@ m_x+16,m_y+2 SAY "Prikaz po pl.vrsta (uslov)" GET cPlVrsta PICT "@!"
 			@ m_x+17,m_y+2 SAY "Prikaz po K9" GET cK9 PICT "@!"
 			@ m_x+17,m_y+20 SAY "Prikaz po K1" GET cK1 PICT "@!"
 		endif

 		if IsVindija()
 			@ m_x+17,m_y+2 SAY "Uslov po opcinama:" GET cOpcine PICT "@!S40"
 		endif

		// ako je roba - grupacija
 		@ m_x+17,m_y+2 SAY "Grupa artikla:" GET qqRGr PICT "@S10"
 		@ m_x+17,m_y+30 SAY "Podgrupa artikla:" GET qqRGr2 PICT "@S10"

 		@ m_x+18,m_y+2 SAY "Naziv artikla sadrzi"  GET cArtikalNaz
 		
 		if !Empty(cRNT1)
			@ m_x+19,m_y+2 SAY "Broj radnog naloga:"  GET cRNalBroj PICT "@S20"
		endif
		
		@ m_x + 20, m_y + 2 SAY "Export izvjestaja u dbf?" GET cExpDbf VALID cExpDbf $ "DN" PICT "@!"
		
		@ m_x + 20, col() + 1 SAY "Pr.dodatnih informacija ?" GET cMoreInfo VALID cMoreInfo $ "DN" PICT "@!"
		
		read
		ESC_BCR
 
 		private aUsl1:=Parsiraj(qqRoba,"IdRoba")
 		private aUsl2:=Parsiraj(qqTarifa,"IdTarifa")
 		private aUsl3:=Parsiraj(qqIDVD,"idvd")
 		private aUsl4:=Parsiraj(qqIDPartner,"idpartner")
		private aUsl5:=Parsiraj(cFaBrDok, "brfaktp" )
		
		qqRGr := ALLTRIM(qqRGr)	
 		qqRGr2 := ALLTRIM(qqRGr2)	
		
		if lPoNarudzbi
   			aUslN:=Parsiraj(qqIdNar,"idnar")
 		endif
 		
		if !EMPTY(cRnT1) .and. !EMPTY(cRNalBroj)
			private aUslRn := Parsiraj(cRNalBroj,"idzaduz2")
		endif
		
		if aUsl1<>NIL .and. aUsl2<>NIL .and. aUsl3<>NIL .and. aUsl4<>NIL .and. (!lPoNarudzbi.or.aUslN<>NIL) .and. (EMPTY(cRnT1) .or. EMPTY(cRNalBroj) .or. aUslRn<>NIL) .and. aUsl5<>nil
   			exit
 		endif
	enddo
BoxC()

if !fPocStanje

 set_metric("kalk_lager_lista_id_konto", f18_user(), cIdKonto )
 set_metric("kalk_lager_lista_po_nabavnoj", f18_user(), cPNab )
 set_metric("kalk_lager_lista_prikaz_nula", f18_user(), cNula )
 set_metric("kalk_lager_lista_datum_od", f18_user(), dDatOd )
 set_metric("kalk_lager_lista_datum_do", f18_user(), dDatDo )
 set_metric("kalk_lager_lista_prikaz_do_nabavne", f18_user(), cDoNab )
 set_metric("kalk_lager_Lista_vpc_iz_sif", _curr_user, _vpc_iz_sif )
 set_metric("kalk_lager_print_varijanta", _curr_user, _print )

endif

// export u dbf ?
if cExpDbf == "D"
	lExpDbf := .t.
endif

lSvodi:=.f.

if IsDomZdr() .and. cSzDN == "D"
	lSignZal := .t.
endif

if IzFMKIni("KALK_LLM","SvodiNaJMJ","N",KUMPATH)=="D"
	lSvodi := ( Pitanje(,"Svesti kolicine na osnovne jedinice mjere? (D/N)","N")=="D" )
endif

// sinteticki konto
fSint:=.f.
cSintK:=cIdKonto

if "." $ cIdKonto
  	cIdkonto:=StrTran(cIdKonto,".","")
  	cIdkonto:=Trim(cIdKonto)
  	cSintK:=cIdKonto
  	fSint:=.t.
	lSabKon:=(Pitanje(,"Racunati stanje robe kao zbir stanja na svim obuhvacenim kontima? (D/N)","N")=="D")
endif

if lExpDbf == .t.
	// exportuj report....
	aExpFields := g_exp_fields()
	t_exp_create( aExpFields )
	cLaunch := exp_report()
endif

_o_tables()

O_KALKREP

private cFilt:=".t."

if aUsl1<>".t."
	cFilt+=".and."+aUsl1
endif

if aUsl2<>".t."
	cFilt+=".and."+aUsl2
endif
if aUsl3<>".t."
  	cFilt+=".and."+aUsl3
endif
if aUsl4<>".t."
  	cFilt+=".and."+aUsl4
endif
if !EMPTY(cFaBrDok) .and. aUsl5<>".t."
	cFilt+=".and."+aUsl5
endif

if !empty(dDatOd) .or. !empty(dDatDo)
 	cFilt+=".and. DatDok>="+cm2str(dDatOd)+".and. DatDok<="+cm2str(dDatDo)
endif
if lPoNarudzbi .and. aUslN<>".t."
  	cFilt+=".and."+aUslN
endif
if fSint .and. lSabKon
	cFilt+=".and. MKonto="+cm2str( cSintK )
  	cSintK:=""
endif
if IsDomZdr() .and. !Empty(cKalkTip)
	cFilt+=".and. tip=" + Cm2Str(cKalkTip)
endif

if !Empty(cRNT1) .and. !EMPTY(cRNalBroj)
	cFilt+=".and." + aUslRn
endif

if cFilt==".t."
	set filter to
else
 	set filter to &cFilt
endif

select kalk

if fSint .and. lSabKon
  	if lPoNarudzbi .and. cPKN=="D"
    		set order to tag "6N"
  	else
    		set order to tag "6"
    		//"6","idFirma+IdTarifa+idroba",KUMPATH+"KALK"
  	endif
  	hseek cIdFirma
else
	if lPoNarudzbi .and. cPKN=="D"
    		set order to tag "3N"
  	else
    		set order to tag "3"
  	endif
  	hseek cIdFirma+cIdKonto
endif

select koncij
seek TRIM(cIdKonto)
select kalk

if _print == "2"
    // stampa dokumenta u odt formatu
    _params := hb_hash()
    _params["idfirma"] := gFirma
    _params["idkonto"] := cIdKonto 
    _params["roba_naz"] := cArtikalNaz
    _params["group_1"] := qqRGr
    _params["group_2"] := qqRGr2
    _params["nule"] := ( cNula == "D" )
    _params["svodi_jmj"] := lSvodi 
    _params["vpc_sif"] := ( _vpc_iz_sif == "D" )
    _params["datum_od"] := dDatOd
    _params["datum_do"] := dDatDo
    kalk_magacin_llm_odt( _params )
    return
endif

EOF CRET

nLen:=1

if IsPDV()
	
	_set_zagl(@cLine, @cTxt1, @cTxt2, @cTxt3, ;
		lPoNarudzbi, cPkn, cSredCij)

	__line := cLine
	__txt1 := cTxt1
	__txt2 := cTxt2
	__txt3 := cTxt3

else
	m:="------ ---------- -------------------- ---"+IF(lPoNarudzbi.and.cPKN=="D"," ------","")+" ---------- ---------- ---------- ---------- ---------- ----------"

	if gVarEv=="2"
		m:="----- ---------- -------------------- --- ---------- ---------- ----------"
	elseif !IsMagPNab()
 		m+=" ---------- ----------"
	else
 		m+=" ----------"
		if IsPDV()
			m+=" ----------"
			m+=" ----------"
			m+=" ----------"
		endif
	endif

	if cSredCij=="D"
		m+=" ----------"
	endif

	__line := m
	
endif

if koncij->naz $ "P1#P2"
	cPNab := "D"
endif 

if !IsMagPNab() .and. cPNab=="D"
	gaZagFix:={7+IF(lPoNarudzbi.and.!EMPTY(qqIdNar),3,0),6}
else
  	gaZagFix:={7+IF(lPoNarudzbi.and.!EMPTY(qqIdNar),3,0),5}
endif

start print cret
?

private nTStrana:=0
private bZagl:={|| ZaglLLM()}

Eval(bZagl)

nTUlaz:=0
nTIzlaz:=0
nTUlazP:=0
nTIzlazP:=0
nTVPVU:=0
nTVPVI:=0
nTVPVRU:=0
nTVPVRI:=0
nTNVU:=0
nTNVI:=0
nRazlika := 0
nTNV:=0
nNBUk := 0
nNBCij := 0
nTRabat:=0
nCol1:=50
nCol0:=50

private nRbr:=0

do while !eof() .and. IIF(fSint .and. lSabKon, idfirma, idfirma+mkonto ) = ;
		cidfirma + cSintK .and. IspitajPrekid()
	
	cIdRoba:=Idroba
	
	if lPoNarudzbi .and. cPKN=="D"
		cIdNar:=idnar
	endif

	nUlaz:=0
	nIzlaz:=0

	nVPVU:=0
	nVPVI:=0

	nVPVRU:=0
	nVPVRI:=0
	
	nNVU:=0
	nNVI:=0

	nRabat:=0

	cMIFakt := ""
	cMINumber := ""
	dMIDate := CTOD("")
	
	dL_ulaz := CTOD("")
	dL_izlaz := CTOD("")

	select roba
	hseek cIdRoba

	// pretrazi artikle po nazivu
	if (!Empty(cArtikalNaz) .and. AT(ALLTRIM(cArtikalNaz), ALLTRIM(roba->naz))==0)
		select kalk
		skip
		loop
	endif

	// uslov po planika vrsta
	if (IsPlanika() .and. !EMPTY(cPlVrsta))
	 if roba->vrsta <> cPlVrsta
		select kalk
		skip
		loop
	 endif
	endif
	// uslov po roba->k9
	if (IsPlanika() .and. !EMPTY(cK9) .and. roba->k9 <> cK9) 
	 select kalk
	 skip
	 loop
	endif

	if (IsPlanika() .and. !EMPTY(cK1) .and. roba->k1 <> cK1)
	 select kalk
	 skip
	 loop
	endif

	// uslov za roba - grupacija
	if !EMPTY( qqRGr ) .or. !EMPTY( qqRGr2 )
	    if !IsInGroup(qqRGr, qqRGr2, roba->id)
		    select kalk
		    skip
		    loop
	    endif
	endif

	// Vindija - uslov po opcinama
	if (IsVindija() .and. !EMPTY(cOpcine))
	 select partn
	 set order to tag "ID"
	 hseek kalk->idpartner
	 if AT(ALLTRIM(partn->idops), cOpcine)==0
		select kalk
		skip
		loop
	 endif
	 select roba
	endif
	// po vindija GRUPA
	if IsVindija()
	 if !Empty(cGr)
		if ALLTRIM(cGr) <> IzSifK("ROBA", "GR1", cIdRoba, .f.)
			select kalk
			skip
			loop
		else
			if Empty(IzSifK("ROBA", "GR2", cIdRoba, .f.))
				select kalk
				skip
				loop
			endif
		endif
	 endif
	 if (cPSPDN == "D")
		select kalk
		if (kalk->mu_i <> "5") .and. (kalk->mkonto <> cIdKonto)
			skip
			loop
		endif
		select roba
	 endif
	endif


	if (fieldpos("MINK"))<>0
   		nMink:=roba->mink
	else
   		nMink:=0
	endif

	select kalk
	if roba->tip $ "TUY"
		skip
		loop
	endif

	cIdkonto:=mkonto
	
	//if cMink=="O"
	//	cNula:="D"
	//endif
	
	// ako zelim oznaciti sve kriticne zalihe onda mi trebaju i artikli
	// sa stanjem 0 !!

	aNabavke:={}

	do while !eof() .and. iif(fSint.and.lSabKon,cIdFirma+IF(lPoNarudzbi.and.cPKN=="D",cIdNar,"")+cIdRoba==idFirma+IF(lPoNarudzbi.and.cPKN=="D",IdNar,"")+idroba,cIdFirma+cIdKonto+IF(lPoNarudzbi.and.cPKN=="D",cIdNar,"")+cIdRoba==idFirma+mkonto+IF(lPoNarudzbi.and.cPKN=="D",IdNar,"")+idroba) .and. IspitajPrekid()

	 if roba->tip $ "TU"
  		skip
		loop
  	 endif
  
  	 if mu_i=="1"
    		if !(idvd $ "12#22#94")
     			nKolicina:=field->kolicina-field->gkolicina-field->gkolicin2
     			nUlaz+=nKolicina
     			SumirajKolicinu(nKolicina, 0, @nTUlazP, @nTIzlazP)
     			nCol1:=pcol()+1
     			if koncij->naz == "P2"
      				nVPVU += round( roba->plc * ( kolicina-gkolicina-gkolicin2 ), gZaokr )
      				nVPVRU += round( roba->plc * ( kolicina-gkolicina-gkolicin2 ), gZaokr )
     			else
      				nVPVU += round( roba->vpc * ( kolicina - gkolicina - gkolicin2 ) , gZaokr )
      				nVPVRU += round( field->vpc * ( kolicina - gkolicina - gkolicin2 ) , gZaokr )
     			endif

     			nNVU+=round( nc*(kolicina-gkolicina-gkolicin2) , gZaokr)
   		else
     			nKolicina:=-field->kolicina
     			nIzlaz+=nKolicina
     			SumirajKolicinu(0, nKolicina, @nTUlazP, @nTIzlazP)
     			if koncij->naz=="P2"
        			nVPVI-=round( roba->plc * kolicina , gZaokr)
        			nVPVRI-=round( roba->plc * kolicina , gZaokr)
     			else
        			nVPVI-=round( roba->vpc * kolicina , gZaokr )
        			nVPVRI-=round( field->vpc * kolicina , gZaokr )
     			endif
     			nNVI-=round( nc*kolicina , gZaokr)
    		endif

		// datum zadnjeg ulaza
		dL_ulaz := field->datdok

  	elseif mu_i=="5"
    		nKolicina:=field->kolicina
    		nIzlaz+=nKolicina
    		SumirajKolicinu(0, nKolicina, @nTUlazP, @nTIzlazP)
    		if koncij->naz=="P2"
      			nVPVI+=round( roba->plc*kolicina , gZaokr)
      			nVPVRI+=round( roba->plc*kolicina , gZaokr)
    		else
			    nVPVI+=round( roba->vpc*kolicina , gZaokr)
			    nVPVRI+=round( field->vpc * kolicina , gZaokr)
    		endif
    		nRabat+=round(  rabatv/100 * vpc * kolicina , gZaokr)
    		nNVI+=ROUND(nc*kolicina, gZaokr)
  		
		// datum zadnjeg izlaza
		dL_izlaz := field->datdok

  	elseif mu_i=="8"
     		nKolicina:=-field->kolicina
     		nIzlaz+=nKolicina
     		SumirajKolicinu(0, nKolicina , @nTUlazP, @nTIzlazP)
     		if koncij->naz=="P2"
       			nVPVI+=round( roba->plc*(-kolicina) , gZaokr)
       			nVPVRI+=round( roba->plc*(-kolicina) , gZaokr)
     		else
       			nVPVI+=round( roba->vpc*(-kolicina) , gZaokr)
       			nVPVRI+=round( field->vpc * (-kolicina) , gZaokr)
     		endif
     		nRabat+=round(  rabatv/100 * vpc * (-kolicina) , gZaokr)
     		nNVI+=ROUND(nc*(-kolicina), gZaokr)
   		nKolicina:=-field->kolicina
     		nUlaz+=nKolicina
     		SumirajKolicinu(nKolicina, 0, @nTUlazP, @nTIzlazP)
     		
		if koncij->naz=="P2"
      			nVPVU+=round(-roba->plc*(kolicina-gkolicina-gkolicin2), gZaokr)
      			nVPVRU+=round(-roba->plc*(kolicina-gkolicina-gkolicin2), gZaokr)
     		else
      			nVPVU+=round(-roba->vpc*(kolicina-gkolicina-gkolicin2) , gZaokr)
      			nVPVRU+=round(-field->vpc*(kolicina-gkolicina-gkolicin2) , gZaokr)
     		endif
     		
		nNVU+=round(-nc*(kolicina-gkolicina-gkolicin2) , gZaokr)
  	endif
  
  	if fPocStanje .and. glEkonomat
    		KreDetNC(aNabavke)
  	endif

 	 // more info, set variables
	 cMIPart := field->idpartner
	 dMIDate := field->datfaktp
	 cMINumber := field->brfaktp
         cMI_type := field->mu_i

  	 skip
	enddo

    if cMinK == "D" .and. ( nUlaz - nIzlaz - nMink ) > 0
        LOOP
    endif
   
    if cNula == "D" .or. IIF( IsPDV() .and. ( IsMagPNab() .or. IsMagSNab() ), ROUND( nNVU - nNVI, 4 ) <> 0, ;
            ROUND( nVPVU - nVPVI, 4 ) <> 0 ) 

	 aNaz:=Sjecistr(roba->naz,20)
	 NovaStrana(bZagl)
	
	// rbr, idroba, naziv...
	
	? STR( ++nRbr, 5 ) + ".", cIdRoba
	nCr:=pcol()+1
	
	@ prow(),pcol()+1 SAY aNaz[1]

	cJMJ:=ROBA->JMJ
	nVPCIzSif := ROBA->VPC
	
	IF lSvodi
  		nKJMJ  := SJMJ(1 ,cIdRoba,@cJMJ)
  		cJMJ:=PADR(cJMJ,LEN(ROBA->JMJ))
	ELSE
  		nKJMJ  := 1
	ENDIF

	@ prow(),pcol()+1 SAY cJMJ

	IF lPoNarudzbi .and. cPKN=="D"
  		@ prow(),pcol()+1 SAY cIdNar
	ENDIF

	nCol0:=pcol()+1

	// ulaz, izlaz, stanje
	@ prow(),pcol()+1 SAY nKJMJ*nUlaz          pict gpickol
	@ prow(),pcol()+1 SAY nKJMJ*nIzlaz         pict gpickol
	@ prow(),pcol()+1 SAY nKJMJ*(nUlaz-nIzlaz) pict gpickol

	if fPocStanje

  		select kalk_pripr
  		if glEkonomat
    			FOR i:=LEN(aNabavke) TO 1 STEP -1
      				IF !(ROUND(aNabavke[i,1],8)<>0)
        				ADEL(aNabavke,i)
        				ASIZE(aNabavke,LEN(aNabavke)-1)
      				ENDIF
    			NEXT
    			FOR i:=1 TO LEN(aNabavke)
       				append blank
       				replace idfirma with cidfirma, idroba with cIdRoba,;
               			idkonto with cIdKonto,;
               			datdok with dDatDo+1,;
               			idtarifa with roba->idtarifa,;
               			datfaktp with dDatDo+1,;
               			idvd with "16", brdok with cBRPST ,;
               			kolicina with aNabavke[i,1],;
               			nc with aNabavke[i,2]
       				replace vpc with nc
    			NEXT
  		else
    	    if round(nUlaz-nIzlaz,4) <> 0 .and. cSrKolNula $ "01"
       				
			    append blank
       				
			    replace idfirma with cidfirma, idroba with cIdRoba,;
               			idkonto with cIdKonto,;
               			datdok with dDatDo+1,;
               			idtarifa with roba->idtarifa,;
               			datfaktp with dDatDo+1,;
               			kolicina with nUlaz-nIzlaz,;
               			idvd with "16", ;
			        	brdok with cBRPST
				
			    replace nc with (nNVU-nNVI)/(nUlaz-nIzlaz)
			    replace vpc with (nVPVU-nVPVI)/(nUlaz-nIzlaz)

			    if IsMagPNab()
                    replace vpc with nc
       		    endif
    			
		    elseif cSrKolNula $ "12" .and. round(nUlaz-nIzlaz,4) = 0
				
				// kontrolna opcija
				// kolicina 0, nabavna cijena <> 0
				if ( nNVU - nNVI ) <> 0
					
					// 1 stavka (minus)
					append blank
       				
					replace idfirma with cidfirma
					replace idroba with cIdRoba
               				replace idkonto with cIdKonto
               				replace datdok with dDatDo+1
               				replace idtarifa with roba->idtarifa
               				replace datfaktp with dDatDo+1
               				replace kolicina with -1
               				replace idvd with "16"
					replace brdok with cBRPST
                    replace brfaktp with "#KOREK"
					replace nc with 0
					replace vpc with 0

					if IsMagPNab()
               					replace vpc with nc
       					endif
    					
					// 2 stavka (plus i nv)
					append blank
       				
					replace idfirma with cidfirma
					replace idroba with cIdRoba
               				replace idkonto with cIdKonto
               				replace datdok with dDatDo+1
               				replace idtarifa with roba->idtarifa
               				replace datfaktp with dDatDo+1
               				replace kolicina with 1
               				replace idvd with "16"
					replace brdok with cBRPST
                    replace brfaktp with "#KOREK"
					replace nc with (nNVU - nNVI)
					replace vpc with 0

					if IsMagPNab()
               					replace vpc with nc
       					endif
    			
				endif

			endif
  		endif

  		select kalk

	endif

	nCol1:=pcol()+1

	// varijanta evidencije sa cijenama
	if gVarEv == "1"

		if IsMagSNab() .or. IsMagPNab()
 			
			// NV
			@ prow(),pcol()+1 SAY nNVU pict gpicdem
 			@ prow(),pcol()+1 SAY nNVI pict gpicdem
 			@ prow(),pcol()+1 SAY nNVU-nNVI pict gpicdem
 			
			if IsPDV() .and. cDoNab == "N" 

			    // PV - samo u pdv rezimu

                if _vpc_iz_sif == "D"
                    // sa vpc iz sifrarnika robe
			        @ prow(),pcol()+1 SAY nVPVU pict gpicdem
                    @ prow(),pcol()+1 SAY nRabat pict gpicdem
             	    @ prow(),pcol()+1 SAY nVPVI pict gpicdem
                    @ prow(),pcol()+1 SAY nVPVU-nVPVI pict gpicdem
                else
 			        // sa vpc iz tabele kalk
			        @ prow(),pcol()+1 SAY nVPVRU pict gpicdem
                    @ prow(),pcol()+1 SAY nRabat pict gpicdem
             	    @ prow(),pcol()+1 SAY nVPVRI pict gpicdem
                    @ prow(),pcol()+1 SAY nVPVRU-nVPVRI pict gpicdem
                endif

            endif
			
			// provjeri greske sa NC
			if !(koncij->naz = "P")
			    if ROUND( nUlaz - nIzlaz, 4 ) <> 0 
  	                 	if cErr=="D" .and. round((nNVU-nNVI)/(nUlaz-nIzlaz),4) <> Round(roba->nc,4)
    		             		?? " ERR"
					fImaGreska := .t.	
  	                 	endif
			    else
  				if (cErr=="D" .or. fPocstanje) .and. ;
					Round((nNVU-nNVI), 4) <> 0
   						fImaGresaka:=.t.
   						?? " ERR"
				endif
  			    endif
			endif
	   	else
		
             		@ prow(),pcol()+1 SAY nVPVU pict gpicdem
             		@ prow(),pcol()+1 SAY nRabat pict gpicdem
             		@ prow(),pcol()+1 SAY nVPVI pict gpicdem
             		@ prow(),pcol()+1 SAY nVPVU-nVPVI pict gpicdem
             		
			if round(nUlaz-nIzlaz,4)<>0
                		@ prow(),pcol()+1 SAY (nVPVU-nVPVI)/(nUlaz-nIzlaz) pict gpiccdem
                		if !(koncij->naz="P")
                     			if IsPDV() .and. ( IsMagPNab() .or. IsMagSNab() )
  	                 			if cErr=="D" .and. round((nNVU-nNVI)/(nUlaz-nIzlaz),4) <> Round(roba->nc,4)
    		             				?? " ERR"
  	                 			endif
                    	 		else
   	                 			if cErr=="D" .and. round((nVPVU-nVPVI)/(nUlaz-nIzlaz),4)<>round(KoncijVPC(),4)
    		             				?? " ERR"
  	                 			endif
                     			endif
               			endif
            		else
               			@ prow(),pcol()+1 SAY 0 pict gpicdem
				if IsPDV() .and. (IsMagPNab() .or. IsMagSNab())
  					if (cErr=="D" .or. fPocstanje) .and. round((nNVU-nNVI),4)<>0
   						fImaGresaka:=.t.
   						?? " ERR"
  					endif
 				else
  					if (cErr=="D" .or. fPocstanje) .and. round((nVPVU-nVPVI),4)<>0
   						fImaGresaka:=.t.
   						?? " ERR"
  					endif
 				endif 
	   		endif
     		endif
	endif

	if cSredCij=="D"
		@ prow(), pcol()+1 SAY (nNVU-nNVI+nVPVU-nVPVI)/(nUlaz-nIzlaz)/2 PICT "9999999.99"
	endif

	// novi red
	@ prow()+1,0 SAY ""
	if len(aNaz)>1
 		@ prow(),nCR  SAY aNaz[2]
	endif
	
	if gVarEv=="1"
	
		if cMink <> "N" .and. nMink > 0
 			@ prow(),ncol0    SAY padr("min.kolic:",len(gpickol))
 			@ prow(),pcol()+1 SAY nKJMJ*nMink  pict gpickol
		elseif cPNAB=="D" .and. !IsMagPNab()
			@ prow(),ncol0  SAY space(len(gpickol))
 			@ prow(),pcol()+1 SAY space(len(gpickol))
		endif
		
		if cPNAB=="D" .and. !IsMagPNab()
  			if round(nulaz-nizlaz,4)<>0
    				@ prow(),pcol()+1 SAY (nNVU-nNVI)/(nUlaz-nIzlaz) pict gpicdem
    				if cNCSif=="D"
      					select roba
      					replace nc with round((nNVU-nNVI)/(nUlaz-nIzlaz),3)
      					select kalk
    				endif
  			elseif round(nUlaz,4)<>0
    				@ prow(),pcol()+1 SAY nNVU/nUlaz pict gpicdem
  			endif
  			
			@ prow(),nCol1 SAY nNVU pict gpicdem
  			@ prow(),pcol()+1 SAY space(len(gpicdem))
  			@ prow(),pcol()+1 SAY nNVI pict gpicdem
  			@ prow(),pcol()+1 SAY nNVU-nNVI pict gpicdem
  			
			if koncij->naz=="P2"
    				//@ prow(),pcol()+1 SAY roba->plc pict gpiccdem
  			else
    				@ prow(),pcol()+1 SAY KoncijVPC() pict gpiccdem
 			endif
		endif // cbpnab
		
		if IsMagPNab()
			// ulaz - prazno	
 			@ prow(),nCol0 SAY space(len(gpickol))
			// izlaz - prazno
 			@ prow(),pcol()+1 SAY space(len(gpickol))
			// stanje - prazno
 			@ prow(),pcol()+1 SAY space(len(gpickol))
			// nv.dug - prazno
 			@ prow(),pcol()+1 SAY space(len(gpicdem))
			// nv.pot - prazno
 			@ prow(),pcol()+1 SAY space(len(gpicdem))
			// prikazi NC
			if round(nUlaz-nIzlaz,4)<>0 
				
				@ prow(),pcol()+1 SAY (nNVU-nNVI)/(nUlaz-nIzlaz) pict gpicdem
				
			endif
			if cDoNab == "N"
			 // pv.dug - prazno
 			 @ prow(),pcol()+1 SAY space(len(gpicdem))
			 // rabat - prazno
 			 @ prow(),pcol()+1 SAY space(len(gpicdem))
			 // pv.pot - prazno
 			 @ prow(),pcol()+1 SAY space(len(gpicdem))
			 // prikazi PC
        		 if round(nUlaz-nIzlaz,4)<>0
				@ prow(),pcol()+1 SAY nVPCIzSif pict gpiccdem
			 endif
			endif
		endif
		
		if cMink=="O" .and. nMink<>0 .and. (nUlaz-nIzlaz-nMink)<0
   			B_OFF
		endif
	endif

	nTULaz+=nKJMJ*nUlaz
	nTIzlaz+=nKJMJ*nIzlaz
	nTVPVU+=nVPVU
	nTVPVI+=nVPVI
	nTVPVRU+=nVPVRU
	nTVPVRI+=nVPVRI	
	nTNVU+=nNVU
	nTNVI+=nNVI
	nTNV+=(nNVU-nNVI)
	nTRabat+=nRabat

	// prikaz dodatnih informacija na lager listi
	if cMoreInfo == "D"
		? SPACE(6) + show_more_info( cMIPart, dMIDate, cMINumber, cMI_type )
	endif
	
	if lExpDbf == .t.
	   if ( cNula == "N" .and. ROUND(nUlaz-nIzlaz, 4) <> 0 ) ;
	   	.or. ( cNula == "D" )

		cTmp := ""
		
		if roba->(FIELDPOS("SIFRADOB")) <> 0
			cTmp := roba->sifradob
		endif

		if cNula == "D" .and. ROUND( nUlaz-nIzlaz,4) = 0
		     fill_exp_tbl( 0, roba->id, cTmp, ;
				roba->naz, roba->idtarifa, cJmj, ;
				nUlaz, nIzlaz, (nUlaz-nIzlaz), ;
				nNVU, nNVI, ( nNVU - nNVI ), 0, ;
				nVPVU, nVPVI, (nVPVU - nVPVI), 0, ;
                nVPVRU, nVPVRI, ;
				dL_ulaz, dL_izlaz )

		else
		     fill_exp_tbl( 0, roba->id, cTmp, ;
				roba->naz, roba->idtarifa, cJmj, ;
				nUlaz, nIzlaz, (nUlaz-nIzlaz), ;
				nNVU, nNVI, ( nNVU - nNVI ), ;
				(nNVU - nNVI)/(nUlaz - nIzlaz), ;
				nVPVU, nVPVI, ( nVPVU - nVPVI), ;
				nVPCIzSif, ;
                nVPVRU, nVPVRI, ;
                dL_ulaz, dL_izlaz )
		endif
	    endif
	endif
	
endif

if IsPlanika() .and. cPrikazDob=="D"
	? PrikaziDobavljaca(cIdRoba, 6)
endif

if lKoristitiBK
	? SPACE(6) + roba->barkod
endif

if lSignZal
	?? SPACE(6) + "p.kol: " + STR(IzSifK("ROBA", "PKOL", roba->id, .f.))
	?? ", p.cij: " + STR(IzSifK("ROBA", "PCIJ", roba->id, .f.))
endif


enddo

? __line
? "UKUPNO:"

@ prow(),nCol0 SAY ntUlaz pict pic_format( gpickol, ntUlaz )
@ prow(),pcol()+1 SAY ntIzlaz pict pic_format( gpickol, ntIzlaz )
@ prow(),pcol()+1 SAY ntUlaz-ntIzlaz pict pic_format( gpickol, (ntUlaz - ntIzlaz) )

nCol1:=pcol()+1

if gVarEv=="1"
	if IsMagSNab() .or. IsMagPNab()
	    // NV
 	    @ prow(),pcol()+1 SAY ntNVU pict pic_format( gpicdem, ntNVU )
 	    @ prow(),pcol()+1 SAY ntNVI pict pic_format( gpicdem, ntNVI )
 	    @ prow(),pcol()+1 SAY ntNV pict pic_format( gpicdem, ntNV )
 	    
	    if IsPDV() .and. cDoNab == "N" 
            if _vpc_iz_sif == "D"
	            // PV - samo u pdv rezimu 
		        @ prow(),pcol()+1 SAY ntVPVU pict pic_format( gpicdem, ntVPVU )
 		        @ prow(),pcol()+1 SAY ntRabat pict pic_format( gpicdem, ntRabat )
 		        @ prow(),pcol()+1 SAY ntVPVI pict pic_format( gpicdem, ntVPVI )
 		        @ prow(),pcol()+1 SAY ntVPVU-NtVPVI pict pic_format( gpicdem, ( ntVPVU - ntVPVI ) )
            else
 	            // PV - samo u pdv rezimu 
		        @ prow(),pcol()+1 SAY ntVPVRU pict pic_format( gpicdem, ntVPVU )
 		        @ prow(),pcol()+1 SAY ntRabat pict pic_format( gpicdem, ntRabat )
 		        @ prow(),pcol()+1 SAY ntVPVRI pict pic_format( gpicdem, ntVPVI )
 		        @ prow(),pcol()+1 SAY ntVPVRU-NtVPVRI pict pic_format( gpicdem, ( ntVPVRU - ntVPVRI ) )
            endif
	    endif
	    
	else
 		@ prow(),pcol()+1 SAY ntVPVU pict gpicdem
 		@ prow(),pcol()+1 SAY ntRabat pict gpicdem
 		@ prow(),pcol()+1 SAY ntVPVI pict gpicdem
 		@ prow(),pcol()+1 SAY ntVPVU-NtVPVI pict gpicdem
	endif
	if cPNab=="D" .and. !IsMagPNab()
		@ prow()+1,nCol1 SAY ntNVU pict gpicdem
		@ prow(),pcol()+1 SAY space(len(gpicdem))
		@ prow(),pcol()+1 SAY ntNVI pict gpicdem
		@ prow(),pcol()+1 SAY ntNVU-ntNVI pict gpicdem
	endif
endif

? __line

if (IsPlanika())
	PrintParovno(nTUlazP, nTIzlazP)
endif

FF
END PRINT

_o_tables()
O_KALK_PRIPR

if fimagresaka
    MsgBeep("Pogledajte artikle za koje je u izvjestaju stavljena oznaka ERR - GRESKA")
endif

if fPocStanje
    if fimagresaka .and. Pitanje(,"Nulirati pripremu (radi ponavljanja procedure) ?","D")=="D"
        select kalk_pripr
        zapp()
    else
        renumeracija_kalk_pripr( cBrPst, "16" )
    endif
endif

// lansiraj report....
if lExpDbf == .t.
	tbl_export( cLaunch ) 
endif

gPicDem := cPicDem
gPicCDem := cPicCDem
gPicKol := cPicKol

close all
return


// --------------------------------------------------
// sredjivanje formata ispisa
// --------------------------------------------------
static function pic_format( curr_pic, num )
local _format

if LEN( curr_pic ) < LEN( ALLTRIM( STR( num ) ) )
    // jednostavno ukini decimalno mjesto kod ispisa
    _format := STRTRAN( curr_pic, ".", "9" )
else
    _format := curr_pic
endif

return _format


// --------------------------------------
// export rpt, tbl fields
// --------------------------------------
static function g_exp_fields( )
aDbf := {}

AADD( aDbf, { "IDROBA", "C", 10, 0 })
AADD( aDbf, { "SIFRADOB", "C", 10, 0 })
AADD( aDbf, { "NAZIV", "C", 40, 0 })
AADD( aDbf, { "TARIFA", "C", 6, 0 })
AADD( aDbf, { "JMJ", "C", 3, 0 })
AADD( aDbf, { "ULAZ", "N", 15, 5 })
AADD( aDbf, { "IZLAZ", "N", 15, 5 })
AADD( aDbf, { "STANJE", "N", 15, 5 })
AADD( aDbf, { "NVDUG", "N", 20, 10 })
AADD( aDbf, { "NVPOT", "N", 20, 10 })
AADD( aDbf, { "NV", "N", 15, 5 })
AADD( aDbf, { "NC", "N", 15, 5 })
AADD( aDbf, { "PVDUG", "N", 20, 10 })
AADD( aDbf, { "PVPOT", "N", 20, 10 })
AADD( aDbf, { "PVRDUG", "N", 20, 10 })
AADD( aDbf, { "PVRPOT", "N", 20, 10 })
AADD( aDbf, { "PV", "N", 15, 5 })
AADD( aDbf, { "PC", "N", 15, 5 })
AADD( aDbf, { "D_ULAZ", "D", 8, 0 })
AADD( aDbf, { "D_IZLAZ", "D", 8, 0 })

return aDbf


// ------------------------------------------------------------
// filovanje tabele exporta
// ------------------------------------------------------------
static function fill_exp_tbl( nVar, cIdRoba, cSifDob, cNazRoba, cTarifa, ;
		cJmj, nUlaz, nIzlaz, nSaldo, nNVDug, nNVPot, nNV, nNC, ;
		nPVDug, nPVPot, nPV, nPC, nPVrdug, nPVrpot, dL_ulaz, dL_izlaz )

local nTArea := SELECT()

if nVar == nil
	nVar := 0
endif

O_R_EXP

append blank

replace field->idroba with cIdRoba
replace field->sifradob with cSifDob
replace field->naziv with cNazRoba
replace field->tarifa with cTarifa
replace field->jmj with cJmj
replace field->ulaz with nUlaz
replace field->izlaz with nIzlaz
replace field->stanje with nSaldo
replace field->nvdug with nNVDug
replace field->nvpot with nNVPot
replace field->nv with nNV
replace field->nc with nNC

if cDoNab == "D"
	// resetuj varijable
	nPVDug := 0
	nPVPot := 0
	nPV := 0
	nPC := 0
endif

replace field->pvdug with nPVDug
replace field->pvpot with nPVPot

replace field->pvrdug with nPVrDug
replace field->pvrpot with nPVrPot

replace field->pv with nPV
replace field->pc with nPC

replace field->d_ulaz with dL_ulaz
replace field->d_izlaz with dL_izlaz

if nVar == 1
	//
endif

select (nTArea)

return


// -------------------------------------------------------------
// setovanje linije i teksta
// -------------------------------------------------------------
static function _set_zagl( cLine, cTxt1, cTxt2, cTxt3,  ;
			lPoNarudzbi, cPKN, cSredCij )
local aLLM := {}
local nPom 

// r.br
nPom := 6
AADD(aLLM, {nPom, PADC("R.", nPom), PADC("br.", nPom), PADC("", nPom) })

// artikl
nPom := 10
AADD(aLLM, {nPom, PADC("Artikal", nPom), PADC("", nPom), PADC("1", nPom) })

// naziv
nPom := 20
AADD(aLLM, {nPom, PADC("Naziv", nPom), PADC("", nPom), PADC("2", nPom) })

// jmj
nPom := 3
AADD(aLLM, {nPom, PADC("jmj", nPom), PADC("", nPom), PADC("3", nPom) })

if ( lPoNarudzbi .and. cPKN == "D" )

	// narudzba
	nPom := 6
	AADD(aLLM, {nPom, PADC("Naru-", nPom), PADC("cilac", nPom), PADC("", nPom) })
	
endif

nPom := LEN( gPicKol )
// ulaz
AADD(aLLM, {nPom, PADC("ulaz", nPom), PADC("", nPom), PADC("4", nPom) })
// izlaz
AADD(aLLM, {nPom, PADC("izlaz", nPom), PADC("", nPom), PADC("5", nPom) })
// stanje
AADD(aLLM, {nPom, PADC("STANJE", nPom), PADC("", nPom), PADC("4 - 5", nPom) })

if gVarEv <> "2"
	
	// magacin nije po nabavnim cijenama
	if !IsMagPNab()
		
		if koncij->naz == "P1"
 			
			cC1Row1 := "PV Dug."
			cC2Row1 := "Rabat"
			cC3Row1 := "PV Pot."
			cC4Row1 := "PV"
			cC5Row1 := "Prod.cij."
			
		elseif koncij->naz == "P2"
		
			cC1Row1 := "Plan.vr.D"
			cC2Row1 := "Rabat"
			cC3Row1 := "Plan.vr.P"
			cC4Row1 := "Plan.vr"
			cC5Row1 := "Plan.cij."
		
		else
			
			cC1Row1 := "PV Dug."
			cC2Row1 := "Rabat"
			cC3Row1 := "PV Pot."
			cC4Row1 := "PV"
			cC5Row1 := "Prod.cij"
	
		endif
		
		nPom := LEN( gPicCDem )
		// PV Dug.
		AADD(aLLM, {nPom, PADC(cC1Row1, nPom), PADC("", nPom), PADC("6", nPom) })
		AADD(aLLM, {nPom, PADC(cC2Row1, nPom), PADC("", nPom), PADC("7", nPom) })
		AADD(aLLM, {nPom, PADC(cC3Row1, nPom), PADC("", nPom), PADC("8", nPom) })
		AADD(aLLM, {nPom, PADC(cC4Row1, nPom), PADC("", nPom), PADC("9", nPom) })
		AADD(aLLM, {nPom, PADC(cC5Row1, nPom), PADC("", nPom), PADC("10", nPom) })
		
	else
		
		// NV podaci
		// -------------------------------
		nPom := LEN( gPicCDem )
		// nv dug.
		AADD(aLLM, {nPom, PADC("NV.Dug.", nPom), PADC("", nPom), PADC("6", nPom) })
		// nv pot.
		AADD(aLLM, {nPom, PADC("NV.Pot.", nPom), PADC("", nPom), PADC("7", nPom) })
		// NV
		AADD(aLLM, {nPom, PADC("NV", nPom), PADC("NC", nPom), PADC("6 - 7", nPom) })

		if cDoNab == "N"
		  if IsPDV()
			
			nPom := LEN( gPicCDem )
			// pv.dug
			AADD(aLLM, {nPom, PADC("PV.Dug.", nPom), PADC("", nPom), PADC("8", nPom) })
			// rabat
			AADD(aLLM, {nPom, PADC("Rabat", nPom), PADC("", nPom), PADC("9", nPom) })
			// pv pot.
			AADD(aLLM, {nPom, PADC("PV.Pot.", nPom), PADC("", nPom), PADC("10", nPom) })
			// PV 
			AADD(aLLM, {nPom, PADC("PV", nPom), PADC("PC", nPom), PADC("8 - 10", nPom) })
		  else
			
			nPom := LEN( gPicCDem )
			// PV
			AADD(aLLM, {nPom, PADC("PV", nPom), PADC("", nPom), PADC("8", nPom) })
	
		  endif
		
		endif
		
	endif

endif

if cSredCij=="D"
	
	nPom := LEN( gPicCDem )
	// sredi cijene
	AADD(aLLM, {nPom, PADC("Sred.cij", nPom), PADC("", nPom), PADC("", nPom) })

endif

cLine := SetRptLineAndText(aLLM, 0)
cTxt1 := SetRptLineAndText(aLLM, 1, "*")
cTxt2 := SetRptLineAndText(aLLM, 2, "*")
cTxt3 := SetRptLineAndText(aLLM, 3, "*")

return




// --------------------------------
// zaglavlje lager liste
// --------------------------------
function ZaglLLM()
if IsPDV()
	ZaglPdv()
else
	Zagl()
endif
return



// --------------------------------
// zaglavlje ne-pdv rezima
// --------------------------------
static function Zagl()

Preduzece()
IF gVarEv=="2"
	P_12CPI
ELSE
 	P_COND2
ENDIF
select konto
hseek cIdKonto
set century on
?? "KALK: LAGER LISTA  ZA PERIOD",dDatOd,"-",dDatdo,"  na dan", date(), space(12),"Str:",str(++nTStrana,3)

IF lPoNarudzbi .and. !EMPTY(qqIdNar)
  ?
  ? "Obuhvaceni sljedeci narucioci:",TRIM(qqIdNar)
  ?
ENDIF

set century off

? "Magacin:", cIdkonto, "-", ALLTRIM(konto->naz)
if !Empty(cRNT1) .and. !EMPTY(cRNalBroj)
	?? ", uslov radni nalog: " + ALLTRIM(cRNalBroj)
endif

if cSredCij=="D"
	cSC1:="*Sred.cij.*"
	cSC2:="*         *"
else
	cSC1:=""
	cSC2:=""
endif

select kalk
if gVarEv=="2"
	? __line
 	? " R.  *  SIFRA   *                    *J. *"+IF(lPoNarudzbi.and.cPKN=="D","Naru- *","")+"   ULAZ      IZLAZ   *          "+cSC2
 	? " BR. * ARTIKLA  *   NAZIV ARTIKLA    *MJ.*"+IF(lPoNarudzbi.and.cPKN=="D","cilac *","")+"                     *  STANJE  "+cSC1
 	? "     *    1     *        2           * 3 *"+IF(lPoNarudzbi.and.cPKN=="D","      *","")+"     4          5    *  4 - 5   "+cSC2
 	? __line

elseif !IsMagSNab()

	? __line
 	if koncij->naz=="P1"
    		? " R.  * Artikal  *   Naziv            *jmj*"+IF(lPoNarudzbi.and.cPKN=="D","Naru- *","")+"  ulaz       izlaz   * STANJE   *Prod.vr D *   Rabat  *Prod.vr P*  Prod.vr *  Prod.Cj *"+cSC1
 	elseif koncij->naz=="P2"
    		? " R.  * Artikal  *   Naziv            *jmj*"+IF(lPoNarudzbi.and.cPKN=="D","Naru- *","")+"  ulaz       izlaz   * STANJE   *Plan.vr D *   Rabat  *Plan.vr P*  Plan.vr *  Plan.Cj *"+cSC1
 	else
    		? " R.  * Artikal  *   Naziv            *jmj*"+IF(lPoNarudzbi.and.cPKN=="D","Naru- *","")+"  ulaz       izlaz   * STANJE   *  VPV.Dug.*   Rabat  * VPV.Pot *   VPV    *   VPC    *"+cSC1
 	endif
 	? " br. *          *                    *   *"+IF(lPoNarudzbi.and.cPKN=="D","cilac *","")+"                     *          *          *          *         *          *          *"+cSC2
 	if cPNab=="D"
  		if koncij->naz=="P1"
    			? "     *          *                    *   *"+IF(lPoNarudzbi.and.cPKN=="D","      *","")+"                     * Cij.Kost * V.Kost. D*          * V.Kost.P* Vr.Kost. *          *"+cSC2
  		else
    			? "     *          *                    *   *"+IF(lPoNarudzbi.and.cPKN=="D","      *","")+"                     * SR.NAB.C *   NV.Dug.*          *  NV.Pot *    NV    *          *"+cSC2
 		endif
 	endif
 	? "     *    1     *        2           * 3 *"+IF(lPoNarudzbi.and.cPKN=="D","      *","")+"     4          5    *  4 - 5   *     6    *     7    *     8   *   6 - 8  *     9    *"+cSC2
 	? __line
else
 	? __line
 	? " R.  * Artikal  *   Naziv            *jmj*"+IF(lPoNarudzbi.and.cPKN=="D","Naru- *","")+"  ulaz       izlaz   * STANJE   *  NV.Dug. * NV.Pot.  *    NV    *"+cSC1
 	? " br. *          *                    *   *"+IF(lPoNarudzbi.and.cPKN=="D","cilac *","")+"                     *          *          *          *    NC    *"+cSC2
 	? "     *    1     *        2           * 3 *"+IF(lPoNarudzbi.and.cPKN=="D","      *","")+"     4          5    *  4 - 5   *     6    *     7    *   6 - 7  *"+cSC2
 	? __line
endif

return


// --------------------------------
// zaglavlje pdv rezima
// --------------------------------
static function ZaglPDV()
local nTArea := SELECT()

Preduzece()

IF gVarEv=="2"
	P_12CPI
ELSE
 	P_COND2
ENDIF

select konto
hseek cIdKonto

set century on

?? "KALK: LAGER LISTA  ZA PERIOD",dDatOd,"-",dDatdo,"  na dan", date(), space(12),"Str:",str(++nTStrana,3)

IF lPoNarudzbi .and. !EMPTY(qqIdNar)
  ?
  ? "Obuhvaceni sljedeci narucioci:",TRIM(qqIdNar)
  ?
ENDIF

set century off

? "Magacin:", cIdkonto, "-", ALLTRIM(konto->naz)
if !Empty(cRNT1) .and. !EMPTY(cRNalBroj)
	?? ", uslov radni nalog: " + ALLTRIM(cRNalBroj)
endif

? __line
? __txt1
? __txt2
? __txt3
? __line

select (nTArea)
return



/*! \fn PocStMag()
 *  \brief Generacija pocetnog stanja magacina
 */

function PocStMag()
LLM( .t. )
return


/*! \fn IsInGroup(cGr, cPodGr, cIdRoba)
 *  \brief Provjerava da li artikal pripada odredjenoj grupi i podgrupi
 *  \param cGr - grupa
 *  \param cPodGr - podgrupa
 *  \param cIdRoba - id roba
 */
function IsInGroup(cGr, cPodGr, cIdRoba)
bRet := .f.

if Empty(cGr)
	return .t.
endif

if ALLTRIM(IzSifK("ROBA", "GR1", cIdRoba, .f.)) $ ALLTRIM(cGr)
	bRet := .t.
else
	bRet := .f.
endif

if bRet
	if !Empty(cPodGr) 
		if ALLTRIM(IzSifK("ROBA", "GR2", cIdRoba, .f.)) $ ALLTRIM(cPodGr)
			bRet := .t.
		else
			bRet := .f.
		endif
	else
		bRet := .t.
	endif
endif

return bRet



// ------------------------------------------------------
// ------------------------------------------------------
static function kalk_magacin_llm_odt( params )

if !_gen_xml( params )
    MsgBeep("Problem sa generisanjem podataka ili nema podataka !")
    return
endif

if f18_odt_generate( "kalk_llm.odt", my_home() + "data.xml" )
    f18_odt_print()
endif

return


// -----------------------------------------------------
// -----------------------------------------------------
static function _gen_xml( params )
local _idfirma := params["idfirma"]
local _sintk := params["idkonto"]
local _art_naz := params["roba_naz"]
local _group_1 := params["group_1"]
local _group_2 := params["group_2"]
local _nule := params["nule"]
local _svodi_jmj := params["svodi_jmj"]
local _vpc_iz_sif := params["vpc_sif"]
local _idroba, _idkonto, _vpc_sif, _jmj
local _rbr := 0
local _t_ulaz_p := _t_izlaz_p := 0
local _ulaz, _izlaz, _vpv_u, _vpv_i, _vpv_ru, _vpv_ri, _nv_u, _nv_i
local _t_ulaz, _t_izlaz, _t_vpv_u, _t_vpv_i, _t_vpv_ru, _t_vpv_ri, _t_nv_u, _t_nv_i, _t_nv, _t_rabat
local _rabat
local _ok := .f.

_t_ulaz := _t_izlaz := _t_nv_u := _t_nv_i := _t_vpv_u := _t_vpv_i := 0
_t_rabat := _t_vpv_ru := _t_vpv_ri := _t_nv := 0

select konto
hseek params["idkonto"]

select kalk

open_xml( my_home() + "data.xml" )
xml_head()

xml_subnode( "ll", .f. )

// header
xml_node( "dat_od", DTOC( params["datum_od"] ) )
xml_node( "dat_do", DTOC( params["datum_do"] ) )
xml_node( "dat", DTOC( DATE() ) )
xml_node( "kid", to_xml_encoding( params["idkonto"] ) )
xml_node( "knaz", to_xml_encoding( ALLTRIM( konto->naz ) ) )
xml_node( "fid", to_xml_encoding( gFirma ) )
xml_node( "fnaz", to_xml_encoding( gNFirma ) )
xml_node( "tip", "MAGACIN" )

do while !EOF() .and. field->idfirma + field->mkonto = _idfirma + _sintk .and. IspitajPrekid()
	
    _idroba := field->idroba
	
	_ulaz := 0
	_izlaz := 0

	_vpv_u := 0
	_vpv_i := 0

	_vpv_ru := 0
	_vpv_ri := 0
	
	_nv_u := 0
	_nv_i := 0

	_rabat := 0

	select roba
	hseek _idroba

	if (!Empty( _art_naz ) .and. AT(ALLTRIM(_art_naz), ALLTRIM(roba->naz))==0)
		select kalk
		skip
		loop
	endif

	if !EMPTY( _group_1 ) .or. !EMPTY( _group_2 )
	    if !IsInGroup( _group_1, _group_2, roba->id)
		    select kalk
		    skip
		    loop
	    endif
	endif

	select kalk
	
    if roba->tip $ "TUY"
		skip
		loop
	endif

	_idkonto := field->mkonto
	
	do while !EOF() .and. _idfirma + _idkonto + _idroba == field->idfirma + field->mkonto + field->idroba .and. IspitajPrekid()

	    if roba->tip $ "TU"
  		    skip
		    loop
  	    endif
  
  	    if field->mu_i == "1"
    		if !(field->idvd $ "12#22#94")
     			_kolicina := field->kolicina-field->gkolicina-field->gkolicin2
     			_ulaz += _kolicina
     			SumirajKolicinu( _kolicina, 0, @_t_ulaz_p, @_t_izlaz_p )
     			if koncij->naz == "P2"
      				_vpv_u += round( roba->plc * ( kolicina-gkolicina-gkolicin2 ), gZaokr )
      				_vpv_ru += round( roba->plc * ( kolicina-gkolicina-gkolicin2 ), gZaokr )
     			else
      				_vpv_u += round( roba->vpc * ( kolicina - gkolicina - gkolicin2 ) , gZaokr )
      				_vpv_ru += round( field->vpc * ( kolicina - gkolicina - gkolicin2 ) , gZaokr )
     			endif

     			_nv_u += round( nc*(kolicina-gkolicina-gkolicin2) , gZaokr)
   		    else
     			_kolicina := -field->kolicina
     			_izlaz += _kolicina
     			SumirajKolicinu( 0, _kolicina, @_t_ulaz_p, @_t_izlaz_p )
     			if koncij->naz=="P2"
        			_vpv_i -= round( roba->plc * kolicina , gZaokr)
        			_vpv_ri -= round( roba->plc * kolicina , gZaokr)
     			else
        			_vpv_i -= round( roba->vpc * kolicina , gZaokr )
        			_vpv_ri -= round( field->vpc * kolicina , gZaokr )
     			endif
     			_nv_i -= round( nc*kolicina , gZaokr)
    		endif

  	    elseif field->mu_i == "5"
    		_kolicina := field->kolicina
    		_izlaz += _kolicina
    		SumirajKolicinu( 0, _kolicina, @_t_ulaz_p, @_t_izlaz_p )
    		if koncij->naz=="P2"
      			_vpv_i += round( roba->plc*kolicina , gZaokr)
      			_vpv_ri += round( roba->plc*kolicina , gZaokr)
    		else
			    _vpv_i += round( roba->vpc*kolicina , gZaokr)
			    _vpv_ri += round( field->vpc * kolicina , gZaokr)
    		endif
    		_rabat += round(  rabatv/100 * vpc * kolicina , gZaokr)
    		_nv_i += ROUND(nc*kolicina, gZaokr)
  		
  	    elseif field->mu_i == "8"
     		_kolicina := -field->kolicina
     		_izlaz += _kolicina
     		SumirajKolicinu( 0, _kolicina , @_t_ulaz_p, @_t_izlaz_p )
     		if koncij->naz=="P2"
       			_vpv_i += round( roba->plc*(-kolicina) , gZaokr)
       			_vpv_ri += round( roba->plc*(-kolicina) , gZaokr)
     		else
       			_vpv_i += round( roba->vpc*(-kolicina) , gZaokr)
       			_vpv_ri += round( field->vpc * (-kolicina) , gZaokr)
     		endif
     		_rabat += round(  rabatv/100 * vpc * (-kolicina) , gZaokr)
     		_nv_i += ROUND(nc*(-kolicina), gZaokr)
   		    _kolicina := -field->kolicina
     		_ulaz += _kolicina
     		SumirajKolicinu( _kolicina, 0, @_t_ulaz_p, @_t_izlaz_p )
     		
		    if koncij->naz=="P2"
      			_vpv_u += round(-roba->plc*(kolicina-gkolicina-gkolicin2), gZaokr)
      			_vpv_ru += round(-roba->plc*(kolicina-gkolicina-gkolicin2), gZaokr)
     		else
      			_vpv_u += round(-roba->vpc*(kolicina-gkolicina-gkolicin2) , gZaokr)
      			_vpv_ru += round(-field->vpc*(kolicina-gkolicina-gkolicin2) , gZaokr)
     		endif
     		
	    	_nv_u += round(-nc*(kolicina-gkolicina-gkolicin2) , gZaokr)
  	    endif
  
 	    skip

	enddo

    if _nule .or. ( ROUND( _ulaz - _izlaz, 4 ) <> 0 .or. ROUND( _nv_u - _nv_i, 4 ) <> 0 )

        xml_subnode( "items", .f. )

        xml_node( "rbr", ALLTRIM( STR( ++_rbr ) ) )
        xml_node( "id", to_xml_encoding( _idroba ) )	
        xml_node( "naz", to_xml_encoding( ALLTRIM( roba->naz ) ) )	
        xml_node( "tar", to_xml_encoding( ALLTRIM( roba->idtarifa ) ) )	
        xml_node( "barkod", to_xml_encoding( ALLTRIM( roba->barkod ) ) )	
	
	    _jmj := roba->jmj
	    _vpc_sif := roba->vpc
        _nc_sif := roba->nc
	
	    if _svodi_jmj
  		    _k_jmj := SJMJ( 1 , _idroba, @_jmj )
  		    _jmj := PADR( _jmj, LEN( roba->jmj ) )
	    else
  		    _k_jmj := 1
	    endif
        
        xml_node( "jmj", to_xml_encoding( _jmj ) )	
        xml_node( "vpc", STR( _vpc_sif, 12, 3 ) )	

        xml_node( "ulaz", STR( _k_jmj * _ulaz, 12, 3 )  )
        xml_node( "izlaz", STR( _k_jmj * _izlaz, 12, 3 )  )
        xml_node( "stanje", STR( _k_jmj * ( _ulaz - _izlaz ), 12, 3 )  )

        xml_node( "nvu", STR( _nv_u, 12, 3 )  )
        xml_node( "nvi", STR( _nv_i, 12, 3 )  )
        xml_node( "nv", STR( _nv_u - _nv_i, 12, 3 )  )
        
        _stanje := _k_jmj * ( _ulaz - _izlaz )
        __nv := ( _nv_u - _nv_i )

        if ROUND( _stanje, 4 ) == 0 .or. ROUND( __nv, 4 ) == 0
            _nc := 0 
        else
            _nc := ROUND( __nv / _stanje, 3 )
        endif

        xml_node( "nc", STR( _nc, 12, 3 ) )	
 
        if _vpc_iz_sif
            xml_node( "vpvu", STR( _vpv_u, 12, 3 )  )
            xml_node( "rabat", STR( _rabat, 12, 3 )  )
            xml_node( "vpvi", STR( _vpv_i, 12, 3 )  )
            xml_node( "vpv", STR( _vpv_u - _vpv_i, 12, 3 )  )
        else
            xml_node( "vpvu", STR( _vpv_ru, 12, 3 )  )
            xml_node( "rabat", STR( _rabat, 12, 3 )  )
            xml_node( "vpvi", STR( _vpv_ri, 12, 3 )  )
            xml_node( "vpv", STR( _vpv_ru - _vpv_ri, 12, 3 )  )
        endif

        // kontrola !
        if _nc_sif <> _nc
            xml_node( "err", "ERR" )
        else
            xml_node( "err", "" )
        endif

        xml_subnode( "items", .t. )

    endif

    _t_ulaz += _k_jmj * _ulaz
    _t_izlaz += _k_jmj * _izlaz
    _t_rabat += _rabat
    _t_nv_u += _nv_u
    _t_nv_i += _nv_i
    _t_nv += ( _nv_u - _nv_i )
    _t_vpv_u += _vpv_u
    _t_vpv_i += _vpv_i
    _t_vpv_ru += _vpv_ru
    _t_vpv_ri += _vpv_ri

enddo

xml_node( "ulaz", STR( _t_ulaz, 12, 3 ) )
xml_node( "izlaz", STR( _t_izlaz, 12, 3 ) )
xml_node( "stanje", STR( _t_ulaz - _t_izlaz, 12, 3 ) )
xml_node( "nvu", STR( _t_nv_u, 12, 3 ) )
xml_node( "nvi", STR( _t_nv_i, 12, 3 ) )
xml_node( "nv", STR( _t_nv, 12, 3 ) )

if _vpc_iz_sif
    xml_node( "vpvu", STR( _t_vpv_u, 12, 3 )  )
    xml_node( "rabat", STR( _t_rabat, 12, 3 )  )
    xml_node( "vpvi", STR( _t_vpv_i, 12, 3 )  )
    xml_node( "vpv", STR( _t_vpv_u - _t_vpv_i, 12, 3 )  )
else
    xml_node( "vpvu", STR( _t_vpv_ru, 12, 3 )  )
    xml_node( "rabat", STR( _t_rabat, 12, 3 )  )
    xml_node( "vpvi", STR( _t_vpv_ri, 12, 3 )  )
    xml_node( "vpv", STR( _t_vpv_ru - _t_vpv_ri, 12, 3 )  )
endif

xml_subnode( "ll", .t. )

close_xml()

close all

if _rbr > 0
    _ok := .t.
endif

return _ok



