;+
; NAME: mms_load_bss
;
; PURPOSE: To display horizontal color bars indicating burst data availability
;
; NOTES: 
;   "bss" stands for Burst Segment Status (a term used in the MMS-SDC2SITL-ICD document). 
;   By default, it produces the following tplot-variables.
;   
;   1. mms_bss_fast  (red bar) 
;      the time periods of fast-survey mode (more precisely, the time periods of ROIs)
;      
;   2. mms_bss_burst (green bar) 
;      the time periods (segments) selected by SITLs for burst data
;      
;   3. mms_bss_status (usually black or yellow bars) 
;      Representing segment statuses. 
;      Black if transmission was successful. 
;      Yellow if pending (i.e., the SDC is still trying to downlink the data). 
;      Red if transmission failed (i.e., overwritten). 
;      Blue if partially downlinked (and not pending anymore).
;
;   4. mms_bss_fom (histogram) 
;      The height represents the FOM values (i.e., priority level defined by SITLs)
;
;   See also "mms_load_bss_crib" for examples.
;
;   5. To labels bss bars set the include_labels flag, /include_labels
;   
; CREATED BY: Mitsuo Oka   Oct 2015
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2015-10-20 07:31:50 -0700 (Tue, 20 Oct 2015) $
; $LastChangedRevision: 19113 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_load_bss.pro $
PRO mms_load_bss, trange=trange, datatype=datatype, include_labels=include_labels
  compile_opt idl2

  if undefined(trange) then trange = timerange() else trange = timerange(trange)
  if undefined(datatype) then datatype = ['fast','burst','status','fom']
  datatype = strlowcase(datatype)
  
  nmax = n_elements(datatype)
  for n=0,nmax-1 do begin
    case datatype[n] of
      'fast':   mms_load_bss_fast, trange=trange, include_labels=include_labels
      'burst':  mms_load_bss_burst, trange=trange, include_labels=include_labels
      'status': mms_load_bss_status, trange=trange, include_labels=include_labels
      'fom':    mms_load_bss_fom, trange=trange
      else: message,'datatype: '+datatype[n]+' is not allowed.'
    endcase
  endfor

END
