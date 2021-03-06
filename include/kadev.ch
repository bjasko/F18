#ifndef F18_DEFINED
  #include "f18.ch"
#endif

#define I_ID         1
#define I_PREZIME    2
#define I_ID2        3
#define I_RJRMJ      4

#define AOPSTINA_ST  1
#define ASTR_SPR     2
#define AULICA_ST    3
#define AZAPOSLEN    4
#define ABRAC_ST     5
#define AMJESTO_ST   6
#define AMZ_ST       7
#define AZANIMANJE   8
#define ANAZIV_RO    9
#define ASIF_JED     10
#define AVES         11
#define ACIN         12
#define ADUZNOST     13
#define ADAT_ISTUP   14
#define ADAT_S_JED   15
#define APRISUTNOST  16
#define ABROJ_LEG    17
#define ABROJ        17

#command DEL2                                                            ;
      => (nArr)->(DbDelete())                                            ;
        ;(nTmpArr)->(DbDelete())

#xcommand O_KADEV_0     =>  select(F_KADEV_0);     my_use ("kadev_0")    ; set order to tag "1"
#xcommand O_KADEV_1     =>  select(F_KADEV_1);     my_use ("kadev_1")    ; set order to tag "1"
#xcommand O_KADEV_PROMJ   =>  select(F_KADEV_PROMJ);   my_use ("kadev_promj")  ; set order to tag "ID"
#xcommand O_KDV_RJ      =>  select(F_KDV_RJ);      my_use ("kdv_rj")     ; set order to tag "ID"
#xcommand O_KDV_RMJ     =>  select(F_KDV_RMJ);     my_use ("kdv_rmj")    ; set order to tag "ID"
#xcommand O_KDV_RJRMJ   =>  select(F_KDV_RJRMJ);   my_use ("kdv_rjrmj")  ; set order to tag "ID"
#xcommand O_KDV_MZ      =>  select(F_KDV_MZ);      my_use ("kdv_mz")     ; set order to tag "ID"
#xcommand O_KDV_NERDAN  =>  select(F_KDV_NERDAN);  my_use ("kdv_nerdan") ; set order to tag "ID"
#xcommand O_KDV_K1      =>  select(F_KDV_K1);      my_use ("kdv_k1")     ; set order to tag "ID"
#xcommand O_KDV_K2      =>  select(F_KDV_K2);      my_use ("kdv_k2")     ; set order to tag "ID"
#xcommand O_KDV_ZANIM   =>  select(F_KDV_ZANIM);   my_use ("kdv_zanim")  ; set order to tag "ID"
#xcommand O_KDV_RRASP   =>  select(F_KDV_RRASP);   my_use ("kdv_rrasp")  ; set order to tag "ID"
#xcommand O_KDV_CIN     =>  select(F_KDV_CIN);     my_use ("kdv_cin")    ; set order to tag "ID"
#xcommand O_KDV_VES     =>  select(F_KDV_VES);     my_use ("kdv_ves")    ; set order to tag "ID"
#xcommand O_KDV_NAC     =>  select(F_KDV_NAC);     my_use ("kdv_nac")    ; set order to tag "ID"
#xcommand O_KDV_RJES    =>  select(F_KDV_RJES);    my_use ("kdv_rjes")   ; set order to tag "ID"
#xcommand O_KDV_DEFRJES =>  select(F_KDV_DEFRJES); my_use ("kdv_defrjes"); set order to tag "1"
#xcommand O_KDV_GLOBUSL  => select(F_KDV_GLOBUSL);  my_use ("kdv_globusl") ; set order to tag "1"
#xcommand O_KDV_OBRAZDEF => select(F_KDV_OBRAZDEF); my_usex ("kdv_obrazdef"); set order to tag "1"
#xcommand O_KDV_USLOVI   => select(F_KDV_USLOVI);  my_use ("kdv_uslovi")  ; set order to tag "1"

