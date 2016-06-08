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

CREATE CLASS YargReport

   VAR cName
   VAR cType INIT "xlsx"

   VAR cRunScript // ~/.f18/rg_2016/run_yarg_ld_obr_2002.sh|.bat
   VAR cReportXml
   VAR cReportProperties // ~/.f18/rg_2016/ld_obr_2002.properties

   VAR cReportOutput
   VAR aRecords // { { 'id':1, 'naz':'dva' }, { 'id':2, 'naz':'tri' } }
   VAR cBands   // primjer: "Band1", "Header#Band1"

   METHOD New( cName, cType, cBands )

   METHOD create_run_yarg_file()
   METHOD create_yarg_xml()
   METHOD create_report_properties()
   METHOD run()
   METHOD view()

ENDCLASS



METHOD YargReport:New( cName, cType, cBands )

   ::cName := cName

   IF cType != NIL
      ::cType := cType
   ENDIF

   IF cBands == NIL
      ::cBands := "Band1"
   ELSE
      ::cBands := cBands
   ENDIF

   RETURN Self


METHOD YargReport:create_run_yarg_file()

   LOCAL hFile, cTempFile

   ::cRunScript := my_home() + "run_yarg_" + ::cName + iif( is_windows(), ".bat", ".sh" )

   SET PRINTER to ( ::cRunScript )
   SET PRINTER ON
   SET CONSOLE OFF

   ::cReportOutput := my_home() + "out_" + ::cName + "." + ::cType


   IF ( hFile := hb_vfTempFile( @cTempFile, my_home(), "out_" + ::cName + "_", "." + ::cType ) ) != NIL // hb_vfTempFile( @<cFileName>, [ <cDir> ], [ <cPrefix> ], [ <cExt> ], [ <nAttr> ] )
      hb_vfClose( hFile )
      ::cReportOutput := cTempFile
   ELSE
      ::cReportOutput := my_home() + "out_" + ::cName + "." + ::cType
   ENDIF

   IF is_linux() .OR. is_mac()
      ?? "#!/bin/bash"
   ENDIF
   ? "yarg" + SLASH + "bin" + SLASH + "yarg" + iif( is_windows(), ".bat", "" )
   ?? " -rp " + ::cReportXml
   ?? " -op " + ::cReportOutput
   // -Pparam1="string a b c d" \
   // -Pparam2=11/11/11 11:00 \
   // -Pparam3=10 \
   // -Pparam4=[\{\"col1\":\"json1\ ttttttttttttttttttttt\",\"col2\":\"json2\"\},\{\"col1\":\"json3\",\"col2\":\"json4\"\}] \

   ?? " -prop " + my_home() + ::cName + ".properties"


   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   IF is_linux() .OR. is_mac()
      f18_run( "chmod +x " + ::cRunScript )
   ENDIF

   RETURN .T.


METHOD YargReport:create_report_properties()

   ::cReportProperties := my_home() + ::cName + ".properties"

   SET PRINTER to ( ::cReportProperties )
   SET PRINTER ON
   SET CONSOLE OFF

   ? "cuba.reporting.sql.driver=org.hsqldb.jdbcDriver"
   ? "cuba.reporting.sql.dbUrl=jdbc:hsqldb:hsql://localhost/reportingDb"
   ? "cuba.reporting.sql.user=sa"
   ? "cuba.reporting.sql.password="

    /*
    cuba.reporting.sql.driver=org.postgresql.Driver
    #cuba.reporting.sql.dbUrl=jdbc:postgresql://localhost/rg_2016
    #cuba.reporting.sql.user=admin
    #cuba.reporting.sql.password=pwd
    */

   IF is_mac()
      ? "cuba.reporting.openoffice.path=/Applications/LibreOffice.app/Contents/MacOS"
   ENDIF
   IF is_linux()
      ? "cuba.reporting.openoffice.path=./LO/program"
   ENDIF
   IF is_windows()
      ? "cuba.reporting.openoffice.path=." + SLASH + "LO" + SLASH + "program"
   ENDIF
   ? "cuba.reporting.openoffice.ports=8100"
   ? "cuba.reporting.openoffice.timeout=60"
   ? "cuba.reporting.openoffice.displayDeviceAvailable=false"

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   RETURN .T.



METHOD YargReport:create_yarg_xml()

   LOCAL cTemplate, hRec, cKey, lFirst, lFirst2

   ::cReportXml := my_home() + "yarg_" + ::cName + ".xml"

   create_xml( ::cReportXml )
   xml_head()
   xml_subnode_start( 'report name="report"' )

   xml_subnode_start( "templates" )

   cTemplate := "code=" + xml_quote( "DEFAULT" )
   cTemplate += " documentName=" + xml_quote(  ::cName + "." + ::cType )
   cTemplate += " documentPath=" + xml_quote(  my_home() + ::cName + "." + ::cType )
   cTemplate += " outputType=" + xml_quote( ::cType )
   cTemplate += " outputNamePattern=" + xml_quote( "outputNamePattern" )

   xml_single_node( "template", cTemplate )

   xml_subnode_end( "templates" )

   xml_subnode_start( "parameters" )
   /*
       <parameter name="param1" alias="param1" required="true" class="java.lang.String" defaultValue="defaultParam1"/>
       <parameter name="param2" alias="param2" required="true" class="java.sql.Date"/>
       <parameter name="param3" alias="param3" required="true" class="java.lang.Integer"/>
       <parameter name="param4" alias="param4" required="true" class="java.lang.String"/>
   */
   xml_subnode_end( "parameters" )

   xml_subnode_start( "formats" )
   xml_subnode_end( "formats" )

   xml_subnode_start( 'rootBand name="Root" orientation="H"' )
   xml_subnode_start( "bands" )

   IF "Header#" $ ::cBands
      xml_subnode_start( 'band name="Header" orientation="H"' )
      xml_subnode_end( "band" )
   ENDIF

   IF "Band1" $ ::cBands
      xml_subnode_start( 'band name="Band1" orientation="H"' )
      xml_subnode_start( "queries" )

      xml_subnode_start( 'query name="Data_set_1" type="groovy"' )
      xml_subnode_start( "script" )
      ?? "return ["

      lFirst := .T.
      FOR EACH hRec IN ::aRecords
         IF !lFirst
            ?? ","
         ENDIF
         lFirst := .F.
         ?? "["
         lFirst2 := .T.
         FOR EACH cKey IN hRec:Keys
            IF !lFirst2
               ?? ","
            ENDIF
            lFirst2 := .F.
            ?? sql_quote( cKey ) + ":" + sql_quote( hRec[ cKey ] )
         NEXT
         ?? "]"
      NEXT

      ?? "]"

      xml_subnode_end( "script" )

      xml_subnode_end( "query" )

      xml_subnode_end( "queries" )

      xml_subnode_end( "band" ) // band1
   ENDIF

   xml_subnode_end( "bands" )
   xml_subnode_end( "rootBand" )

   xml_subnode_end( "report" )
   close_xml()

   RETURN .T.


METHOD YargReport:view()

   RETURN f18_open_document( ::cReportOutput )


METHOD YargReport:run()

   LOCAL cScreen, nError, cStdOut, cStdErr
   LOCAL hOutput := hb_Hash()

   copy_template_to_my_home( ::cName + "." + ::cType )
   ::create_yarg_xml()
   ::create_report_properties()
   ::create_run_yarg_file()

   SAVE SCREEN TO cScreen
   CLEAR SCREEN

   FErase( ::cReportOutput )

   ? ::cRunScript
   ? "Generisanje ", ::cName, ::cType


   nError := hb_processRun( ::cRunScript, NIL, @cStdOut, @cStdErr, .F. )


   IF nError <> 0
      ? "STDOUT", _u( cStdOut )
      ? "STDERR", _u( cStdErr )
      ?
      ? "<ENTER> nastavak"
      Inkey( 0 )
      ?E "greska", ::cRunScript
      error_bar( "yarg", ::cRunScript )
      RESTORE SCREEN FROM cScreen
      RETURN .F.

   ENDIF

   RESTORE SCREEN FROM cScreen

   ::view()

   RETURN .T.