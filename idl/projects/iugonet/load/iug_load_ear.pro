;+
;
;NAME:
;iug_load_ear
;
;PURPOSE:
;  Queries the RISH servers for all the observation data (troposphere and FAI)
;  taken by the equatorial atmosphere radar (EAR) and loads data into tplot format.
;
;SYNTAX:
;  iug_load_ear [ ,DATATYPE = string ]
;                [ ,PARAMETERS = string]
;                [ ,TRANGE = [min,max] ]
;                [ ,FILENAMES = string scalar or array ]
;                [ ,<and data keywords below> ]
;
;KEYWOARDS:
;  DATATYPE = The type of data to be loaded. In this load program,
;             DATATYPEs are 'troposphere', 'e_region', 'v_region' etc.
;
;  PARAMETERS (I/O):
;    Set to wind parameters.  If not set, 'uwnd' is
;      assumed.  Returns cleaned input, or shows default.  
;  TRANGE (In):
;    Pass a time range a la TIME_STRING.PRO.
;    
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;
;DATA AVAILABILITY:
;  Please check the following homepage of the time schedule of field-aligned irregularity (FAI) observation 
;  before you analyze the FAI data using this software. 
;  http://www.rish.kyoto-u.ac.jp/ear/data-fai/index.html#data
;
;CODE:
;A. Shinbori, 13/05/2010.
;
;MODIFICATIONS:
;A. Shinbori, 25/11/2010.
;A. Shinbori, 08/11/2011.
;A. Shinbori, 11/05/2011.
;A. Shinbori, 27/05/2011.
;A. Shinbori, 15/06/2011.
;A. Shinbori, 25/07/2011.
;A. Shinbori, 10/01/2014.
;A. Shinbori, 14/05/2017.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-
  
pro iug_load_ear, datatype = datatype, $
   parameter = parameter, $
   trange = trange, $
   verbose = verbose, $
   downloadonly=downloadonly

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;****************
;Datatype check:
;****************

;--- all datatypes (default)
datatype_all = strsplit('troposphere e_region ef_region v_region f_region',' ', /extract)

;--- check datatypes
if (not keyword_set(datatype)) then datatype='all'
datatypes = ssl_check_valid_name(datatype, datatype_all, /ignore_case, /include_all)

print, datatypes


;===============================
;======Load data of EAR=========
;===============================
for i=0, n_elements(datatypes)-1 do begin
  ;load of ear tropsphere data
   if datatypes[i] eq 'troposphere' then begin
      iug_load_ear_trop_nc, trange = trange, downloadonly=downloadonly, verbose = verbose
   endif else begin
     ;load of ear fai data
     ;================
     ;Parameter check:
     ;================
     ;--- all parameter (default)
      parameter_all = strsplit('eb1p2a eb1p2b eb1p2c eb2p1a eb3p2a eb3p2b eb3p4a eb3p4b eb3p4c eb3p4d '+$
                               'eb3p4e eb3p4f eb3p4g eb3p4h eb4p2c eb4p2d eb4p4 eb4p4a eb4p4b eb4p4d '+$
                               'eb5p4a efb1p16 efb1p16a efb1p16b vb3p4a 150p8c8a 150p8c8b 150p8c8c '+$
                               '150p8c8d 150p8c8e 150p8c8b2a 150p8c8b2b 150p8c8b2c 150p8c8b2d 150p8c8b2e '+$
                               '150p8c8b2f fb1p16a fb1p16b fb1p16c fb1p16d fb1p16e fb1p16f fb1p16g '+$
                               'fb1p16h fb1p16i fb1p16j1 fb1p16j2 fb1p16j3 fb1p16j4 fb1p16j5 fb1p16j6 '+$
                               'fb1p16j7 fb1p16j8 fb1p16j9 fb1p16j10 fb1p16j11 fb1p16k1 fb1p16k2 fb1p16k3 '+$
                               'fb1p16k4 fb1p16k5 fb1p16m2 fb1p16m3 fb1p16m4 fb8p16 fb8p16k1 fb8p16k2 '+$
                               'fb8p16k3 fb8p16k4 fb8p16m1 fb8p16m2',+$
                               ' ', /extract)

     ;--- check parameters
      if (not keyword_set(parameter)) then parameter='all'
      parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)
      case datatypes[i] of
         'e_region':iug_load_ear_iono_er_nc, parameter = parameters, trange = trange, $
                                             downloadonly = downloadonly, verbose = verbose
         'ef_region':iug_load_ear_iono_efr_nc, parameter = parameters, trange = trange, $
                                               downloadonly = downloadonly, verbose = verbose
         'v_region':iug_load_ear_iono_vr_nc, parameter = parameters, trange = trange, $
                                             downloadonly = downloadonly, verbose = verbose
         'f_region':iug_load_ear_iono_fr_nc, parameter = parameters, trange = trange, $
                                             downloadonly = downloadonly, verbose = verbose
      endcase
   endelse
endfor 

end


