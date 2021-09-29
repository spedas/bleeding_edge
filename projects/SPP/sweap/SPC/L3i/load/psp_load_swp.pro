;+
;NAME: PSP_LOAD_SWP
;
;DESCRIPTION:
; Given a time range (passed to routine or set via the TIMESPAN routine), 
; this loader will load the fitting PSP l3i SWEAP data file from the user's 
; local directory or from the remote server depending on the preferences set in 
; the !psp_sweap variable or passed as keyword options to this routine.
; 
; The Faraday Cup data products include proton density and their uncertainties, 
; proton bulk velocity vector, Carrington longitude/latitude data, and 
; corresponding data uncertainties and delta values
;
;
;KEYWORDS (Optional):
; DOWNLOADONLY: Set this to download files but *not* store data in TPLOT.
; NO_DOWNLOAD:  Set this to use only locally available files. Default is 
;                 whatever is in the !psp_sweap config.
; NO_UPDATE:    Set this to only download new filenames. Default is whatever 
;                 is in the !psp_sweap config.
; PATHFORMAT:   (String) Special path format to use if !psp_sweap.remote_data_dir is 
;                 changed from its default (SPDF@NASA/GSFC)
; TRANGE:       Time range of interest stored as a 2 element array of doubles 
;                 (as output by timerange()) or strings (as accepted by 
;                 timerange()). Defaults to the range set in tplot or prompts 
;                 for date if not yet set.
; TYPE:         (String) Data type to load.
;                 Valid options:
;                 'spc_l3i': SPC Level 3 data (default)
; VARFORMAT:    Specify a subset of variables to load from the CDF file.
; VERBOSE:      Integer indicating the desired verbosity level. 
;               Defaults to value in !psp_sweap.verbose
; 
;KEYWORD OUTPUTS:
; TPLOTNAMES:   Named variable to hold array of TPLOT variable names loaded
;
;EXAMPLE:
; ; Load all variables for the 3 day period Sep 10-13, 2019
; timespan,'2019-09-10',3
; psp_load_swp
;
; ; Load and plot just proton density variables for 3 hours on Nov 11, 2018
; trg = ['2018-11-11/12:00:00','2018-11-11/15:00:00'] 
; psp_load_swp, trange=trg, varformat="*np*"
; tplot,['psp_spc_np_fit','psp_spc_np_moment'],trange=trg
;
;CREATED BY: Jonathan Tsang, Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/load/psp_load_swp.pro $
;-

PRO psp_load_swp, TYPE=type, TRANGE=trange, VARFORMAT=varformat, $
  PATHFORMAT=pathformat, TPLOTNAMES=tn, VERBOSE=verbose, $
  DOWNLOADONLY=downloadonly,NO_DOWNLOAD=no_download,NO_UPDATE=no_update

psp_swp_init
rname = (scope_traceback(/structure))[1].routine

if not isa(verbose,/int) then verbose=!psp_sweap.verbose
if not isa(no_download,/int) then no_download = !psp_sweap.no_download
if not isa(no_update,/int) then no_update = !psp_sweap.no_update

if (isa(type,'undefined') and ~isa(type,/null)) then type = 'spc_l3i' $
else if not isa(type,/string,/scalar) then begin
  info = rname+": Data type keyword must be a scalar string."
  dprint, dlevel=1, verbose=verbose, info
  return
endif

if ~keyword_set(pathformat) then begin
  case type of
    'spc_l3i': begin
      pathformat =  'psp/sweap/spc/l3/l3i/YYYY/psp_swp_spc_l3i_YYYYMMDD_v??.cdf'  
    end
    else: begin
      info = rname+": Data type '"+type.toString()+"' is not supported."
      dprint, dlevel=1, verbose=verbose, info
      return
    end
  endcase    
endif

if not keyword_set(varformat) then varformat = '*' $
else begin
  varformat = varformat+' *DQF*'
endelse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

relpathnames = file_dailynames(file_format=pathformat,trange=trange)

files = spd_download( $
  remote_file=relpathnames, remote_path=!psp_sweap.remote_data_dir, $
  local_path = !psp_sweap.local_data_dir, no_download = no_download, $
  no_update = no_update, /last_version, /valid_only, $
  file_mode = '666'o, dir_mode = '777'o)
  
if keyword_set(downloadonly) then return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

prefix = 'psp_spc_' ;To avoid conflicts with other loaded tplot variables
cdf2tplot, file=files, varformat=varformat, verbose=verbose, prefix=prefix, $
  tplotnames=tn,/load_labels  ; load data into tplot variables
dprint,dlevel=4,verbose=verbose,tn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

; Add uncertainty fields to tvars as available.
; Some use one, symmetric delta .. called "uncertainty"
; others use "deltahigh" and "deltalow"
tn_new = []
for i=0,n_elements(tn)-1 do begin
  get_data,tn[i],data=d
  if tnames(tn[i]+'_uncertainty') then begin
    dvar = tn[i]+'_uncertainty'
    get_data,dvar,data=dy
    str_element,d,'dy',dy.y,/add_rep
    store_data,tn[i],data=d
    options,/def,tn[i],psp_dy=1,noerrorbars=1
    
    ;Split and store vector components with uncertainty
    if tn[i].Matches('(_SC)|(_RTN)$') then begin
      suffix = tn[i].Matches('(_RTN)$') ? ['_r','_t','_n'] : ['_x','_y','_z']
      split_vec,tn[i],suffix=suffix,names_out=tnvec
      for j=0,n_elements(tnvec)-1 do begin
        get_data, tnvec[j], data=d
        str_element,d,'dy',dy.y[*,j],/add_rep
        store_data,tnvec[j],data=d
      endfor
      options,/def,tnvec,psp_dy=1,noerrorbars=1
      tn_new = [tn_new, tnvec]
    endif
    
  endif else if tnames(tn[i]+'_deltalow') then begin
    dvarLow = tn[i]+'_deltalow'
    dvarHigh = tn[i]+'_deltahigh'
    get_data,dvarLow,data=dyL
    get_data,dvarHigh,data=dyH
    str_element,d,'dyL',dyL.y,/add_rep
    str_element,d,'dyH',dyH.y,/add_rep
    store_data,tn[i],data=d
    options,/def,tn[i],psp_dy=1,noerrorbars=1
    
    ;Split and store vector components with deltahigh and deltalow
    if tn[i].Matches('(_SC)|(_RTN)$') then begin
      suffix = tn[i].Matches('(_RTN)$') ? ['_r','_t','_n'] : ['_x','_y','_z']
      split_vec,tn[i],suffix=suffix,names_out=tnvec
      for j=0,n_elements(tnvec)-1 do begin
        get_data, tnvec[j], data=d
        str_element,d,'dyL',dyL.y[*,j],/add_rep
        str_element,d,'dyH',dyH.y[*,j],/add_rep
        store_data,tnvec[j],data=d
      endfor
      options,/def,tnvec,psp_dy=1,noerrorbars=1
      tn_new = [tn_new, tnvec]
    endif
  endif
endfor
tn = [tn, tn_new]

; Set default options
options,/def,tn,ynozero=1
options,/def,['*_RTN','*_SC','*_HCI'],colors='bgr'
end
