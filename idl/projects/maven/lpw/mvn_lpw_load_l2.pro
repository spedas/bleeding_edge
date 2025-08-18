;+
;mvn_lpw_load_l2
;
;Routine to load L2 LPW and EUV data into IDL tplot variables. This routine requires access to the SSL SVN library (tplot, MAVEN software, etc). You can set a time range using the SSL routine timespan outside of this routine. Or,
;you can give the routine a timespan using the trange keyword. The timespan can span multiple days, this routine grabs necessary L2 files and merges them into tplot variables.
;
;
;INPUTS:
; - vars: variable(s) that you wish to load. Entered as a string, or string array if you want multiple variables loaded. Entries can be upper or lower case.
;         The default (if not set) is to load ['lpnt', 'wspecact', 'wspecpas']. There are twelve products LPW produces:
;         wspecact       - waves active spectra
;         wspecpas       - waves passive spectra
;         we12burstlf    - electric field burst, low frequency    *** Burst mode data can take a long time to load and should be avoided if you don't want to use it.
;         we12burstmf    - electric field burst, mid frequency    *** Burst mode data can take a long time to load and should be avoided if you don't want to use it.
;         we12bursthf    - electric field burst, high frequency   *** Burst mode data can take a long time to load and should be avoided if you don't want to use it.
;         wn             - density derived from waves
;         lpiv           - IV curves from Langmuir Probe mode
;         lpnt           - Density, Temperature, Vsc dervied from lpiv
;         mrgexb         - Pointing flux (as of 2015-11-19 not yet available)
;         mrgscpot       - Vsc (spacecraft potential)
;         euv            - EUV data              *** NOTE that due to directory formats EUV must be loaded in a separate call; it cannot be loaded with other LPW variables. See examples below.
;         we12            - 1D electric field
;
;
;OUTPUTS:
;Tplot variables as listed below. The left column is the var input here, the right column is the tplot variable name produced.
;'wspecact':     tvar = 'mvn_lpw_w_spec_act_l2'
;'wspecpas':     tvar = 'mvn_lpw_w_spec_pas_l2'
;'we12burstlf':  tvar = 'mvn_lpw_w_e12_burst_lf_l2'
;'we12burstmf':  tvar = 'mvn_lpw_w_e12_burst_mf_l2'
;'we12bursthf':  tvar = 'mvn_lpw_w_e12_burst_hf_l2'
;'wn':           tvar = 'mvn_lpw_w_n_l2'
;'lpiv':         tvar = 'mvn_lpw_lp_iv_l2'
;'lpnt_n':       tvar = 'mvn_lpw_lp_ne_l2'
;'lpnt_t':       tvar = 'mvn_lpw_lp_te_l2'
;'lpnt_v':       tvar = 'mvn_lpw_lp_vsc_l2'
;'mrgexb':       tvar = 'NA2'   ;THIS IS NOT AVAILABLE YET.
;'mrgscpot':     tvar = 'mvn_lpw_mrg_sc_pot_l2'
;'euv':          tvar = 'mvn_euv_calib_bands'
;'we12':         tvar = 'mvn_lpw_w_e12_l2'
;
;
;success: a float, set this to a variable to return upon exiting. Success will be an array, the same length as the number of variables requested in vars. Each element in success
;         refers to the corresponding element in vars. For example, if vars=['wn', 'lpnt'], and success = [0., 1.], this means 'wn' failed to load, but 'lpnt' loaded successfully.
;         Note that if you request multiple dates, and data for, say, 'wn', is found for some of those dates, success will be 1., despite failing for some dates where data was available.
;         
;         +1: routine successfully loaded requested variables. Note that currenty mrgexb is not available, and euv must be called separately from other LPW variables and will not be loaded 
;             if other LPW variables are requested.
;          0: no data were found
;         -1: one or more input variables were not recognized. Check terminal output for which ones.
;         -2: no timespan has been set. Set using timespan routine, or the trange keyword here.
;         -3: trange was not entered as a string or float.
;
;tplotvars: set this to a variable to return a string array of the tplot variables loaded into tplot memory.
;
;KEYWORDS:
;trange: a double precision array of UNIX times, or string array of UTC times in the format 'yyyy-mm-dd/hr:mm:ss.ssss'. This routine will load data spanning the min and max values of trange. If trange is only one element long, this 
;        routine assumes a timespan of 1 day, ie trange : trange+1day. If this keyword is not set then the user must run timespan before hand to set the time range. If trange is set as a keyword, then timespan is used within this 
;        routine to set the time range. Be careful - this will overwrite any previous uses of timespan!
;
;set /noTPLOT to NOT tplot loaded data producets. If not set, default is to tplot loaded data.
;
;NOTES:
;I'm still working on this, so some dlimit fields will not be complete, such as time start and stop in various time frames. You will have to look at individual L2 CDF files one day at a time to get that information. For now I'm just getting the 
;correct timespan of data to load.
;
;HSBM burst data and we12 data contains a lot of points. If you load in several days of data and try to tplot it, your machine may crash!
;
;If this routine encounters a problem, it will return (hopefully), not retall. Make sure your wrapper routine does not depend on any tplot variables produced by this routine.
;
;Due to folder locations, you will need to call for EUV data in a separate call with this routine if you also want LPW data. See examples below.
;
;This routine assumes you have the folder directory mirrored at SSL, with the environment variable 'ROOT_DATA_DIR' set. It will probably crash if you don't!
;
;
;
;
;EXAMPLES:
;timespan, '2015-04-01/02:33', 2.3    ;set timespan to be 2.3 days from set date.
;mvn_lpw_load_l2, ['lpnt', 'wspecact', 'wspecpas'], success=sc1, tplotvars=tvs   ;load in Ne, Te, Vsc, and active and passive spectra. Upon return, sc1 is a float array, 3 elements long, and tvs is a string array. See above for details.
;
;
;mvn_lpw_load_l2, ['lpnt', 'wn'], trange=['2015-03-01/13:43', '2015-03-06/12:00']  ;load in data and give routine a time range, which is then fed into the timespan routine here.
;mvn_lpw_load_l2, ['lpnt', 'wn'], trange=time_double(['2015-03-01/13:43', '2015-03-06/12:00'])  ;use UNIX times instead.
;
;
;timespan, '2015-04-01/02:33', 2.3
;mvn_lpw_load_l2, ['lpnt', 'wspecact', 'wspecpas', 'euv']  ;Because you request EUV as well as LPW data, routine will only get LPW data. You must get EUV separately, as below
;mvn_lpw_load_l2, ['euv']       ;When you only request EUV data, routine will get EUV data.
;
;
;Created by: Chris Fowler (christopher.fowler@lasp.colorado.edu)
;Creation Date: 2015-11-19.
;
;EDITS:
;2015-11-30: CMF: made all produced tplot variables lower case.
;2016-06-09: CMF: bug fixed where, if multiple vars were requested, and one was not found, code would exit before trying to find the remaining requested vars. Success keyword is now a float
;                 array the same length as input vars, with a value for each requested variable.
;2016-12-20: CMF: added lines to bring through data.info field in the data structure.
;-


pro mvn_lpw_load_l2, vars, trange=trange, noTPLOT=noTPLOT, success=success, tplotvars=tplotvars


proname = 'mvn_lpw_load_l2'
if size(trange,/type) ne 0. then trange2=trange  ;copy trange, as will convert it to a dbl. Don't want to edit the input as the output will change as it's a keyword.
if size(vars,/type) eq 0. then vars=['lpnt', 'wspecact', 'wspecpas']  ;default variables if non set.
NaN = !values.f_nan ; for convenience
varsCOPY = vars  ;make a copy for later

;Acceptable vars:
varsALL=['wspecact', 'wspecpas', 'we12burstlf', 'we12burstmf', 'we12bursthf', 'wn', 'lpiv', 'lpnt', 'mrgexb', 'mrgscpot', 'we12', 'euv']

;Make a list of any input variables that are not recognized; tell user available options:
neleIn = n_elements(Vars)
success = fltarr(neleIN)  ;default

notValid = ['']
for tt = 0, neleIn-1 do begin
  if total(strmatch(varsALL, vars[tt])) ne 1 then begin
    notValid = [notValid, vars[tt]]
  endif
endfor
if n_elements(notValid) gt 1 then begin
  print, ""
  print, proname, " : ### WARNING ### : The following variables are not recognized as inputs: ", notValid
  print,""
  print, "The following are acceptable inputs: ", varsALL
  print, "Please correct and re-run. Returning."
  success = fltarr(neleIN)-1.
  return
endif

;Make sure user has not requested EUV along with LPW data. I'm not sure if this will crash later on, so make user set a separate call.
euvPRT = 0.
exbPRT = 0.  ;mrgexb

if neleIN gt 1 and total(strmatch(vars, 'euv') eq 1) then begin  ;make sure user is requesting euv and LPW. If just euv, this is ok.
    iKP = where(strmatch(vars, 'euv') eq 0, niKP)
    if niKP gt 0 then vars = vars[iKP] 
    euvPRT = 1.  ;print message at end as well.
endif
neleIN = n_elements(vars)  ;this may change by -1 above.

if total(strmatch(vars, 'mrgexb')) eq 1 then begin
  if neleIN gt 1. then begin     ;if user requested mrgexb and other variables, remove exb and carry on.
    iKP = where(strmatch(vars, 'mrgexb') eq 0.)
    vars = vars[iKP]
    exbPRT = 1.  ;print message at end.
  endif else begin    ;if user requested only mrgexb, need to bail.
    print, ""
    print, "### WARNING ### : ", proname, ": LPW variable mrgexb is not yet available. Please remove this from your call. Exiting"
    success = fltarr(neleIN)-1.
    return
  endelse
endif

;===========
;TIME RANGE:
;===========
;Work out days that need to be loaded to cover timespan:
if keyword_set(trange) then begin
    trTYPE = size(trange2,/type)  ;string or double precision?
    
    if (trTYPE ne 5) and (trTYPE ne 7) then begin  ;bail if trange2 is not a string or double precision array
        print, ""
        print, "### WARNING ### : ", proname, ": trange must be either a string array of UTC times or a double precision array of UNIX times. Exiting."
        success = fltarr(neleIN)-3.
        return
    endif
    
    neleTR = n_elements(trange2)
    
    ;UNIX TIMES:   
    if size(trange2,/type) eq 5 then begin
        if neleTR eq 1. then trange2 = [trange2[0], trange2[0] + 86400.d]  ;if only one time entered, add on 1 day.
        
        minTR = min(trange2,/nan)
        maxTR = max(trange2,/nan)
        lengthTR = (maxTR-minTR) / (24.*60.*60.)  ;the length of trange2, in days.
        
        timespan, minTR, lengthTR  ;set timerange            
    endif 
    
    
    ;UTC TIMES:
    if size(trange2,/type) eq 7 then begin
        trange2= time_double(trange2)  ;convert string to double

        if neleTR eq 1. then trange2 = [trange2[0], trange2[0] + 86400.d]  ;if only one time entered, add on 1 day.

        minTR = min(trange2,/nan)
        maxTR = max(trange2,/nan)
        lengthTR = (maxTR-minTR) / (24.*60.*60.)  ;the length of trange2, in days.

        timespan, minTR, lengthTR  ;set timerange
    endif    
endif  ;Timespan is now set, either above, or by user prior to this routine.


;This code gets timerange from timespan command:
tplot_options, get_opt=topt
tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
if ((size(trange,/type) eq 0) and tspan_exists) then trange2 = topt.trange_full

if size(trange2,/type) eq 0. then begin
    print, ""
    print, "### WARNING ### : ", proname, " Please set a timespan to look at, using either timespan, or the trange keyword. Returning."
    success = fltarr(neleIN)-2.
    return
endif

;How many days does timespan cover? The LPW software requires dates in format yyyy-mm-dd, generate these here:
;Create an array of dates to load based on trange2. Format must be 'yyyy-mm-dd' for LPW read routine:
tmin = min(trange2, max=tmax, /nan)
tmin = time_double(time_string(tmin, prec=-3))
tmax = time_double(time_string(tmax+86400D, prec=-3))
neleD = (tmax - tmin)/86400D
dates = time_string(tmin + 86400D*dindgen(neleD), prec=-3)
; dates = time_String([min(trange2,/nan):max(trange2,/nan)+86400.d:86400.d] , precision=-3) 
; neleD = n_elements(dates)  ;number of dates to load
;===========

;==========
;VARIABLES:
;==========
;lpnt contains three variables, Ne, Te, Vsc. Must unpack each separately, do part of that here. Insert them where 'lpnt' was, so that order of success is the same as user input vars.
if total(strmatch(vars, 'lpnt')) eq 1 then begin  ;did user ask for lpnt?
      varsNEW = ['']  ;new string array
      ;Go over each variable. Replace 'lpnt' with names for Ne, Te and Vsc:
      for abc = 0., neleIN-1. do if vars[abc] ne 'lpnt' then varsNEW = [varsNEW, vars[abc]] else varsNEW = [varsNEW, ['lpnt_n', 'lpnt_t', 'lpnt_v']]
      
      ;Remove first dummy element of array:
      neleTMP = n_elements(varsNEW)
      vars = varsNEW[1:neleTMP-1]  ;remove first point  
endif

neleV = n_elements(vars)  ;number of user requested variables
vars = strlowcase(vars)  ;make lowercase

;Load one variable, then loop over all dates. Combine into one tplot variable, and then move onto the next variable.
scsCNT = 0.  ;counter for indexing success or not

for vv = 0., neleV-1. do begin  ;go over each requested variable.
    varTMP = vars[vv]  ;current variable to load
    varTMP2 = varTMP   ;need a copy for later in the loop
    
    ;What is the corresponding tplot variable to look for:
    case varTMP of
        'wspecact':     tvar = 'mvn_lpw_w_spec_act_l2'  
        'wspecpas':     tvar = 'mvn_lpw_w_spec_pas_l2'
        'we12burstlf':  tvar = 'mvn_lpw_w_e12_burst_lf_l2'  
        'we12burstmf':  tvar = 'mvn_lpw_w_e12_burst_mf_l2' 
        'we12bursthf':  tvar = 'mvn_lpw_w_e12_burst_hf_l2'
        'wn':           tvar = 'mvn_lpw_w_n_l2'           
        'lpiv':         tvar = 'mvn_lpw_lp_iv_l2'          
        'lpnt_n':       tvar = 'mvn_lpw_lp_ne_l2' 
        'lpnt_t':       tvar = 'mvn_lpw_lp_te_l2'     
        'lpnt_v':       tvar = 'mvn_lpw_lp_vsc_l2'    
        'mrgexb':       tvar = 'NA2'           ;this variable should be removed above if present    
        'mrgscpot':     tvar = 'mvn_lpw_mrg_sc_pot_l2'      
        'euv':          tvar = 'mvn_euv_calib_bands'           
        'we12':         tvar = 'mvn_lpw_w_e12_l2'
        else:           tvar = 'NA'    
    endcase
    tvarSTORE = tvar  ;name to use when storing in tplot.
    
    if tvar eq 'NA' then begin
        print, ""
        print, "### WARNING ### : ", proname, ": Please check LPW variables you wish to load. I don't recognize at least one of them."
        success = fltarr(neleIN)-1.
        return
    endif

    if vv eq 0. then tplotvars = tvar else tplotvars = [tplotvars, tvar]  ;save TPLOT var names
    if (varTMP eq 'lpnt_n') or (varTMP eq 'lpnt_t') or (varTMP eq 'lpnt_v') then begin
        varTMP = 'lpnt'  ;need to reset this here to get correct CDF file.
        tvarSTORE = tvar+'_TMP'  ;need this to stop Ne,Te,Vsc being overwritten each time. At very end of code, remove the TMP tplot vars.
    endif
    
    ;=====
    ;LOOP:
    ;=====
    first = 1
    x = NaN
    y = NaN
    dy = NaN
    flag = NaN
    v = NaN
    dv = NaN
    
    ReadSuccessTot = 0.  ;the total read success for this variable. Some dates may be loaded, others not, so if this is > 0, at least one date was loaded, which we deem as success.
                         ;This is reset every variable, before looping over dates requested next.
    
    for tt = 0., neleD-1. do begin   ;go over requested dates
        dateTMP = dates[tt]  ;current date to load.
                     
        mvn_lpw_cdf_read, dateTMP, vars=varTMP, level='l2', success=ReadSuccess  ;this routine will check if varTMP is applicable. If incorrect terms are entered this routine will retall. I could probably make this ignore incorrect terms, I'll edit at a later date, maybe...
        ReadSuccessTot += ReadSuccess
        
        if ReadSuccess eq '1' then begin  ; '0' means failure                                  
              get_data, tvar, data=data1, dlimit=dl1, limit=ll1, index=i
      
              if (i gt 0) then begin
                if (first) then begin
                  ;First time around, initialize output arrays.  If any parts of the structure are
                  ;missing, then create filler values to maintain correct dimensions.  Array
                  ;concatenation works for 1D and 2D data arrays.  The second dimension must be
                  ;the same for all data files -- otherwise, concatentation does not make sense.
      
                  str_element, data1, 'x', x, success=ok
                  if (ok) then begin
                    Nx = n_elements(x)
      
                    str_element, data1, 'y', y, success=ok  ; where there's a X, there's a Y
                    ydims = size(y)
                    if (ydims[0] eq 2) then Ny = ydims[2] else Ny = 1L  ; 1D or 2D data
      
                    str_element, data1, 'dy', dy, success=ok
                    if (not ok) then dy = replicate(NaN, Nx, Ny)  ; filler values
      
                    str_element, data1, 'flag', flag, success=ok
                    if (not ok) then flag = replicate(NaN, Nx)    ; filler values
      
                    str_element, data1, 'info', info, success=ok
                    if (not ok) then info = replicate(NaN, Nx)    ; filler values
                    
                    str_element, data1, 'v', v, success=ok
                    if (not ok) then v = replicate(NaN, Nx, Ny)   ; filler values
      
                    str_element, data1, 'dv', dv, success=ok
                    if (not ok) then dv = replicate(NaN, Nx, Ny)  ; filler values
                    
                    loaded_filenames = dl1.L0_datafile  ;save cdf filename loaded, append to this below for each day loaded.
                    
                    first = 0
                  endif
                endif else begin 
                  ;Second time through and up, append data to tmp arrays. Check which fields are present
                  ;Fields that should always be present are .x, .y, .dy, .flag. Fields that may be present
                  ;are .v, .dv.  Size if y, v, dy and dv can be 1D or 2D arrays - must check. 
                  ;NOTE: here, I check data1 for each field. If it is present, I assume that that field 
                  ;already has a tmp array. This should always be true, unless a CDF file is bust and does 
                  ;not have all data in it.
                                             
                  str_element, data1, 'x', xNEW, success=ok
                  if (ok) then begin
                    Mx = n_elements(xNEW)
                    
                    x = [temporary(x), temporary(xNEW)]
      
                    str_element, data1, 'y', yNEW, success=ok  ; where there's an X, there's a Y
                    yOLD = temporary(y)
                    y = fltarr(Nx+Mx, Ny)
                    y[0L:(Nx-1L),*] = temporary(yOLD)
                    y[Nx:(Nx+Mx-1L),*] = temporary(yNEW)
      
                    str_element, data1, 'dy', dyNEW, success=ok
                    dyOLD = temporary(dy)
                    dy = fltarr(Nx+Mx, Ny)
                    dy[0L:(Nx-1L),*] = temporary(dyOLD)
                    if (ok) then dy[Nx:(Nx+Mx-1L),*] = temporary(dyNEW) $
                            else dy[Nx:(Nx+Mx-1L),*] = replicate(NaN, Mx, Ny)
      
                    str_element, data1, 'flag', flagNEW, success=ok
                    if (ok) then flag = [temporary(flag), temporary(flagNEW)] $
                            else flag = [temporary(flag), replicate(NaN, Mx)]
                    
                    str_element, data1, 'info', infoNEW, success=ok
                    if (ok) then info = [temporary(info), temporary(infoNEW)] $
                            else info = [temporary(info), replicate(NaN, Mx)]
                                      
                    str_element, data1, 'v', vNEW, success=ok
                    vOLD = temporary(v)
                    v = fltarr(Nx+Mx, Ny)
                    v[0L:(Nx-1L),*] = temporary(vOLD)
                    if (ok) then v[Nx:(Nx+Mx-1L),*] = temporary(vNEW) $
                            else v[Nx:(Nx+Mx-1L),*] = replicate(NaN, Mx, Ny)
      
                    str_element, data1, 'dv', dvNEW, success=ok
                    dvOLD = temporary(dv)
                    dv = fltarr(Nx+Mx, Ny)
                    dv[0L:(Nx-1L),*] = temporary(dvOLD)
                    if (ok) then dv[Nx:(Nx+Mx-1L),*] = temporary(dvNEW) $
                            else dv[Nx:(Nx+Mx-1L),*] = replicate(NaN, Mx, Ny)
                    
                    loaded_filenames = loaded_filenames + dl1.L0_datafile  ;append next loaded cdf file to this string.
                    
                    Nx += Mx
                  endif
      
                endelse
              endif
        endif  ;ReadSuccess = '1'
        
    endfor ;tt, dates
    
    ;Update Success value now that we have looked at all dates requested.
    if varTMP2 ne 'lpnt_t' and varTMP2 ne 'lpnt_v' then begin  ;Don't update success for Te or Vsc, as they share the same success as Ne.
          if ReadSuccessTot gt 0. then success[scsCNT] = 1.  ;if at least one date was loaded, deem it success for this variable.
          scsCNT += 1.        ;update variable counter
    endif                       
    
    ;Note that here we have looked at one variable, for (possible) multiple dates. We may have no data, or we may have data for just a few requested dates. If no data, move on to
    ;next vv.   
    data1 = 0  
    indx = where(finite(x), xcount)
    indx = where(finite(y), ycount)
    if size(x,/type) eq 0. then xcount = 0.  ;if x does not exist, xcount seems to retain the value from the last variable iteration.
    if size(y,/type) eq 0. then ycount = 0.
    
    ;Make sure data is not all NaNs (can sometimes happen):
    if size(x,/type) ne 0. then begin
        if total(finite(x,/nan)) eq n_elements(x) then xcount = 0l
        if total(finite(y,/nan)) eq n_elements(y) then ycount = 0l
    endif
    
    if ((xcount eq 0L) or (ycount eq 0L)) then begin  ; if no time or no data, then no point
      undefine, x
      undefine, y
      undefine, dy
      undefine, flag
      undefine, v
      undefine, dv
      undefine, info
      xcount = 0l  ;make sure both are zero so we jump out below
      ycount = 0l  
    endif else begin
      indx = where(finite(v), count)
      if (count eq 0L) then undefine, v
      indx = where(finite(dv), count)
      if (count eq 0L) then undefine, dv
    endelse
    
    ;If xcount = 0 above, we have no data, so skip these last steps.
    if xcount gt 0. then begin         
          ;Store tmp arrays into TPLOT variable. Variable must have same name as per L2 CDF files, ie varTMP. Need to check which tags exist in the structure before storing.
          ;Structure format code:
          ;x,y,dy,flag        1.  This should always be the minimum set of tags we have.
          ;x,y,dy,flag,dv:    2.  Sometimes dy and dv hold upper and lower limits separately
          ;x,y,dy,flag,dv,v:  3.  This is spectrogram data.
          scode = 0.  ;default code
          
          if (size(x,/type) eq 0) then begin   ;this loop might cause problems, but it shouldn't happen if we get this far...
            print,"### WARNING ### : ", proname, " - No data found!"
            tplotvars = ''
            success = 0.
            return
          endif
          
          if (size(x,/type) ne 0.) and (size(y,/type) ne 0.) and (size(dy,/type) ne 0.) and (size(flag,/type) ne 0.) and (size(v,/type) eq 0.) and (size(dv,/type) eq 0.) then scode = 1.
          if (size(x,/type) ne 0.) and (size(y,/type) ne 0.) and (size(dy,/type) ne 0.) and (size(flag,/type) ne 0.) and (size(v,/type) eq 0.) and (size(dv,/type) ne 0.) then scode = 2.
          if (size(x,/type) ne 0.) and (size(y,/type) ne 0.) and (size(dy,/type) ne 0.) and (size(flag,/type) ne 0.) and (size(v,/type) ne 0.) and (size(dv,/type) ne 0.) then scode = 3.
          
          
          ;Trim data based on timespan:
          indsKP = where(x ge trange2[0] and x le trange2[1], nindsKP)  ;indsKP are the indices to keep that lie within timespan. These are the same for each tag field. Apply below.
      
          ;Store data:
      
          if (size(x,/type) ne 0) then begin
            dataSTR = {x:x[indsKP], y:y[indsKP,*], dy:dy[indsKP,*], flag:flag[indsKP], info:info[indsKP]}
            if (size(v,/type) ne 0) then str_element, dataSTR, 'v', v[indsKP,*], /add
            if (size(dv,/type) ne 0) then str_element, dataSTR, 'dv', dv[indsKP,*], /add
          endif
          
          
          if scode eq 0. then begin  ;If data tags don't match
              print, ""
              print, "### WARNING ### : ", proname, " CDF data structures do not match for multiple dates. You will need to combine LPW L2 CDF data manually over the time range you selected for the following variable: ", varTMP
            
          endif else begin    ;create tplot variable
                
                dl1.L0_datafile = loaded_filenames  ;these are all of the CDF files loaded (which include the L0 file names as well).
                
                store_data, tvarSTORE, data=dataSTR, dlimit=dl1, limit=ll1  
                
                ;CMF : I need to clean up dlimit here, as for now it only uses information from the last loaded day.
                if tvarSTORE eq 'mvn_lpw_w_spec_act_l2' then options, 'mvn_lpw_w_spec_act_l2', ylog=1
                if tvarSTORE eq 'mvn_lpw_w_spec_pas_l2' then options, 'mvn_lpw_w_spec_pas_l2', ylog=1
            
          endelse
          
          ;Undefine variables before moving on to the next variable:
          undefine, x
          undefine, y
          undefine, dy
          undefine, flag
          undefine, v
          undefine, dv
          undefine, info
    
    endif  ;xcount gt 0
    
endfor  ;vv, variables

;If lpnt was called, copy TMP variables and then remove them. This is required to prevent variables being overwritten when a new date is called (due to how the data are stored).
;2016-09-13: CMF: bug fix, if we request ['lpnt', 'wn'], and lpnt works but there is no data for 'wn', then the dat reads in ok, but because ReadSuccessTot is 0 after failing 
;to find wn data, the following loop does not execute, and the lpnt TMP variables are left in memory, which screws up the plotting range. Timespan itself is not changed,
;but I think because these are the last variables loaded in to tplot, it affects the next plotting, unless they are removed.
if total(strmatch(varsCOPY, 'lpnt')) eq 1. then begin  ;did user ask for lpnt?
    iFIND = where(varsCOPY eq 'lpnt')  ;find which variable was lpnt
    if success[iFIND] gt 0. then begin  ;if the matching success variable is > 0, we loaded some data, so remove the tmp files below
        get_data, 'mvn_lpw_lp_ne_l2_TMP', data=dd1, dlimit=dl1, limit=ll1
        get_data, 'mvn_lpw_lp_te_l2_TMP', data=dd2, dlimit=dl2, limit=ll2
        get_data, 'mvn_lpw_lp_vsc_l2_TMP', data=dd3, dlimit=dl3, limit=ll3
  
        store_data, 'mvn_lpw_lp_ne_l2', data=dd1, dlimit=dl1, limit=ll1
        store_data, 'mvn_lpw_lp_te_l2', data=dd2, dlimit=dl2, limit=ll2
        store_data, 'mvn_lpw_lp_vsc_l2', data=dd3, dlimit=dl3, limit=ll3
  
        store_data, 'mvn_lpw_lp_ne_l2_TMP', /delete  ;remove temp variables
        store_data, 'mvn_lpw_lp_te_l2_TMP', /delete
        store_data, 'mvn_lpw_lp_vsc_l2_TMP', /delete
        store_data, 'mvn_lpw_lp_n_t_l2', /delete
  
    endif
endif

iTMP = where(success gt 0., niTMP)   ;number of variables successfully loaded
if not keyword_set(noTPLOT) and niTMP gt 0. then tplot, tplotvars  ;tplot loaded vars

if euvPRT eq 1. then begin  ;if user requested EUV and LPW, LPW has been retrieved, user must call EUV separately.
  print, ""
  print, "### WARNING ### : ", proname, " Please request EUV date separately from any LPW data. I have loaded the requested LPW data. Please run mvn_lpw_load_l2, 'euv' after this."
  print, ""
endif

if exbPRT eq 1. then begin  ;if user requested mrgexb
  print, ""
  print, "### WARNING ### : ", proname, " mrgexb is not currently available. I have loaded the other requested data."
  print, ""
endif

;success=1.   ;CMF: old version, we now have success for each variable requested.

end
