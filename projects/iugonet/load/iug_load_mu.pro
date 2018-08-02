;+
;
;NAME:
;iug_load_mu
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for all the observation data taken by 
;  the Middle and Upper atmosphere (MU) radar at Shigaraki and loads data into
;  tplot format.
;
;SYNTAX:
;  iug_load_mu [ ,DATATYPE = string ]
;              [ ,LEVEL = string ]
;              [ ,PARAMETER = string ]
;              [ ,TRANGE = [min,max] ]
;              [ ,<and data keywords below> ]
;
;KEYWOARDS:
;  DATATYPE = The type of data to be loaded. In this load program,
;             DATATYPEs are 'troposphere' etc.
;  LEVEL = The level of mesospheric data to be loaded. In this load program,
;             LEVELs are 'org' and 'scr'.
;  PARAMETER = The parameter of mu observations to be loaded. For example,
;             PARAMETER is 'h1t60min00','iemdc3', and so on.
;  LENGTH = The file type of meteor data to be loaded.
;             LENGTHs are '1-day' and '1-month'. Default is 1-day.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 09/19/2010.
;
;MODIFICATIONS:
; A. Shinbori, 03/24/2011.
; A. Shinbori, 08/08/2012.
; A. Shinbori, 04/10/2012.
; A. Shinbori, 12/11/2012.
; A. Shinbori, 02/08/2013.
; A. Shinbori, 25/09/2013.
; A. Shinbori, 27/11/2013.
; A. Shinbori, 11/01/2014.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-
  
pro iug_load_mu, datatype = datatype, level = level, length=length, $
                 parameter = parameter, downloadonly=downloadonly, $
                 trange=trange, verbose=verbose

;**********************
;Verbose keyword check:
;**********************
;verbose
if (not keyword_set(verbose)) then verbose=2
 
;****************
;Datatype check:
;****************

;--- all datatypes (default)
datatype_all = strsplit('troposphere mesosphere ionosphere meteor rass fai',' ', /extract)

;--- check datatypes
if(not keyword_set(datatype)) then datatype='all'
datatypes = ssl_check_valid_name(datatype, datatype_all, /ignore_case, /include_all)

print, datatypes
                 
;===============================
;======Load data of MU=========
;===============================
for i=0, n_elements(datatypes)-1 do begin
  ;load of MU tropsphere data
   if datatypes[i] eq 'troposphere' then begin
   
      iug_load_mu_trop_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
      
   endif 
   
  ;load of MU mesosphere data
   if datatypes[i] eq 'mesosphere' then begin
   
     ;--- all levels for mesospheric observations (default)
      level_all = strsplit('org scr',' ', /extract)
      
     ;--- check level
      if (not keyword_set(level)) then level='all'
      levels = ssl_check_valid_name(level, level_all, /ignore_case, /include_all)
      
      iug_load_mu_meso_nc, level = levels, downloadonly=downloadonly, trange=trange, verbose=verbose
      iug_load_mu_meso_wind_nc, level = levels, downloadonly=downloadonly, trange=trange, verbose=verbose
   
   endif 
 
  ;load of MU ionosphere data
   if datatypes[i] eq 'ionosphere' then begin
   
      iug_load_mu_iono_drift_nc, downloadonly = downloadonly, trange = trange, verbose = verbose
      iug_load_mu_iono_pwr_nc, downloadonly = downloadonly, trange = trange, verbose = verbose
      iug_load_mu_iono_teti_nc, downloadonly = downloadonly, trange = trange, verbose = verbose
   
   endif
   
  ;load of MU meteor data  
   if datatypes[i] eq 'meteor' then begin

     ;--- all parameters for meteor observations (default)
      parameter_all_meteor = strsplit('h1t60min00 h1t60min30 h2t60min00 h2t60min30',' ', /extract)

     ;--- check parameters
      if(not keyword_set(parameter)) then parameter='all'
      parameters = ssl_check_valid_name(parameter, parameter_all_meteor, /ignore_case, /include_all)
   
      iug_load_mu_meteor_nc, parameter =parameters, length=length, trange = trange, downloadonly=downloadonly, verbose = verbose
   
   endif
   
  ;load of MU RASS data  
   if datatypes[i] eq 'rass' then begin

     ;--- all parameters for RASS observations (default)
      parameter_all_rass = strsplit('uwnd vwnd wwnd temp',' ', /extract)

     ;--- check parameters
      if(not keyword_set(parameter)) then parameter='all'
      parameters = ssl_check_valid_name(parameter, parameter_all_rass, /ignore_case, /include_all)

      iug_load_mu_rass_txt, parameter =parameters, $
                            trange = trange, downloadonly=downloadonly, verbose = verbose

   endif

  ;load of MU FAI data  
   if datatypes[i] eq 'fai' then begin

     ;--- all parameters for fai observations (default)
      parameter_all_fai = strsplit('ie2e4b ie2e4c ie2e4d ie2rea ie2mya ie2myb ie2rta ie2trb iecob3 '+$
                                   'ied101 ied103 ied108 ied110 ied201 ied202 ied203 iedb4a iedb4b '+$
                                   'iedb4c iedc4a iedc4b iedc4c iede4a iede4b iede4c iede4d iedp01 '+$
                                   'iedp02 iedp03 iedp08 iedp10 iedp11 iedp12 iedp13 iedp1s iedpaa '+$
                                   'iedpbb iedpcc iedpdd iedpee iedpff iedpgg iedphh iedpii iedpjj '+$
                                   'iedpkk iedpl2 iedpll iedpmm iedptt iedpyy iedpzz ieewb5 ieimga '+$
                                   'ieimgb ieimgm ieimgt ieis01 iefai1 iefdi2 ieggmt iemb5i iemcb3 '+$
                                   'iemdb3 iemdb5 iemdc3 iemy3a iemy3b iemy3c iemyb5 iensb5 iepbr1 '+$
                                   'iepbr2 iepbr3 iepbr4 iepbr5 iepbrt ieper1 ieper2 ieper3 ieper4 '+$
                                   'ieper5 ieper6 ieper7 ieper8 ieps3a ieps3b ieps3c ieps4a ieps4b '+$
                                   'ieps4c ieps4d ieps4e ieps5a ieps5b ieps5c ieps6a ieps6b iepsb3 '+$
                                   'iepsb4 iepsb5 iepsi1 iepsi5 iepsit iesp01 iess01 iess02 iess03 '+$
                                   'iess04 iess05 iess2l iess3l iess4l iess8c iessb5 iesst2 iesst3 '+$
                                   'iet101 iet102 ietest ietst2 ieto02 ieto03 ieto16 ietob3 ietob4 '+$
                                   'ietob5 iey4ch iey4ct ieyo4a ieyo4b ieyo4c ieyo4d ieyo4e ieyo4f '+$
                                   'ieyo4g ieyo5a ieyo5b ieyo5c ieyo5d ieyo5e ieyo5f ieyo5g ieyo5m '+$
                                   'ifco02 ifco03 ifco04 ifco16 if5bd1 if5bd2 if5bd3 if5bd4 if5bd5 '+$
                                   'if5be1 if5be2 if5be3 if5be4 if5be5 ifchk1 ifdp00 ifdp01 ifdp02 '+$
                                   'ifdp03 ifdp0a ifdp0b ifdp0c ifdp0d ifdp1u ifdp1s ifdp1t ifdpll '+$
                                   'ifdq01 ifdq02 ifim16 ifmb16 ifmc16 ifmd16 ifmf16 ifmy01 ifmy02 '+$
                                   'ifmy03 ifmy04 ifmy05 ifmy99 ifmyc1 ifmyc2 ifmyc3 ifmyc4 ifmyc5 '+$
                                   'ifmyc6 ifmyc7 ifmyca ifmycb ifmyt1 ifmyt2 ifmyt3 ifmyt4 ifmyt5 '+$
                                   'ifmyu1 ifmyu2 ifmyu3 ifmyu4 ifmyu5 ifmyv1 ifpsi1 ifpsit ifss02 '+$
                                   'iftes1 iftes2 iftes3 iftes5 iftes6 iftes7 iftes8 ifts01 ifts02 '+$
                                   'ifts03 ifts04 ifts05 ifts06 ifts07',' ', /extract)

     ;--- check parameters
      if(not keyword_set(parameter)) then parameter='all'
      parameters = ssl_check_valid_name(parameter, parameter_all_fai, /ignore_case, /include_all)

      iug_load_mu_fai_nc, parameter =parameters, $
                          trange = trange, downloadonly=downloadonly, verbose = verbose
  
   endif
endfor  

end


