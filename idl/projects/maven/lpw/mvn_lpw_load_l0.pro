;+
;Routine to load multiple days of data using timespan and mvn_lpw_load (which is the L1 loader, not L2).
;
;mvn_lpw_load_append_l1:
;
;Sub routine to append tplot variables together on each iteration of mvn_lpw_load. 
;
;INPUTS:
;ext: string: temporary extension added to end of tplot names when combining.
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/LPW_loader/mvn_lpw_load_l0.pro
;-

pro mvn_lpw_load_append_l0, ext

;Find mvn_lpw tplot variables:
tpnames0 = tnames()

;Find mvn_lpw* tplot variables 
inds1 = where(strmatch(tpnames0, 'mvn_lpw*') eq 1 and (tpnames0 ne 'mvn_lpw_load_kernel_files') and (tpnames0 ne 'mvn_lpw_load_file'), $
                ninds1)

if ninds1 gt 0 then begin
    tpnames1 = tpnames0[inds1]  ;mvn_lpw* tplot variables
    
    ;Find the variables that are not _l2 and not _ext (ie, remove L2 variables - we won't touch those, and remove temp variables):
    inds2 = where(strmatch(tpnames1, 'mvn_lpw*_l2') eq 0 and strmatch(tpnames1, 'mvn_lpw*'+ext) eq 0, ninds2)
    
    if ninds2 gt 0 then begin
    
        tpnames2 = tpnames1[inds2]  ;these are the mvn_lpw variables we want to combine  
        
        ;Go over each variable and add to a temporary tplot name, which will be renamed at the end of the loop.
        for vv = 0l, ninds2-1l do begin
            nameTMP = tpnames2[vv] ;tplot variable to look at
            get_data, nameTMP, data=ddvar, dlimit=dlvar, limit=llvar
            
            if size(ddvar,/type) eq 8 then begin
    
                ;Check if tmp variable already exists; if so, combine, if not, create:
                tFI = where(strmatch(tpnames1, nameTMP+ext) eq 1, niFI)
                if niFI eq 0 then begin
                    ;Create the temp var:
                    store_data, nameTMP+ext, data=ddvar, dlimit=dlvar, limit=llvar
                
                endif else begin
                    ;Add to existing temp var:
                    get_data, nameTMP+ext, data=ddtmp, dlimit=dltmp, limit=lltmp  ;get the existing temp var
                    
                    tagnames = tag_names(ddtmp)  ;find tags
                    
                    ;x and y tags are always present; find any others:
                    iKP = where(strmatch(tagnames, 'X') eq 0 and strmatch(tagnames, 'Y') eq 0, niKP)
                    
                    timeTMP = [ddtmp.x, ddvar.x]  ;combine time (always present)
                    yTMP = [ddtmp.y, ddvar.y]  ;combine y data
                    
                    ;Make structure that other tags will be added to:
                    str_tmp = create_struct('X'   ,     timeTMP   , $
                                            'Y'   ,     yTMP      )

                    ;Loop over any other tags:
                    for tt = 0l, niKP-1l do begin
                      
                        tn = tagnames[iKP[tt]]  ;tag name in this iteration
                        res1 = execute("tagTMP = [ddtmp."+tn+", ddvar."+tn+"]")  ;combine the tag into a new array
                        
                        res2 = execute("str_element, str_tmp, '"+tn+"', tagTMP, /add")  ;add this tag to the structure
                
                    endfor
                    
                    ;Store latest iteration of this variable:
                    store_data, nameTMP+ext, data=str_tmp, dlimit=dltmp, limit=lltmp 
                  
                    ;str_element,my_str,'my_tag_name','value',/add
               
                endelse
             
            endif  ;ddvar exists
        
        endfor  ;vv
                
    endif  ;ninds2>0
    
endif  ;ninds1 > 0

end

;=============
;=============

;+
;Routine to load multiple days of data using timespan and mvn_lpw_load (which is the L1 loader, not L2).
;
;INPUTS:
;
;
;KEYWORDS:
;trange: [a,b], string start and stop times for the time range to load. These should be in the format 'yyyy-mm-dd' (no hr:mn:ss
;        resolution). These follow the same format as timespan, days are loaded from 'a' up to but not including 'b' eg:
;        trange = ['2018-01-01', '2018-01-03'] will load data for two dates, 01 and 02.
;        trange = ['2018-01-01', '2018-01-04'] will load data for three dates, 01, 02 and 03. 
;                
;        This routine will use date ranges set by timespan. If trange is set, this will overwrite the timespan settings.
;
;packet: select which packets to load. See mvn_lpw_load for all options. Suggested setting: packet='nohsbm'. This will load all data
;        except burst data, which takes a long time to load.
;
;clearspice: The mvn_lpw_load routine automatically loads SPICE kernels (used for clock times). The default is to leave
;            these kernels in memory in exit. Use this keyword to alter that behavior:
;            string: '0': leave SPICE kernels in IDL on exit.
;                    '1': remove SPICE kernels from IDL on exit (the default if not set).
;
;notatlasp: Set this keyword if you are not connected to the LASP SPG server, otherwise your IDL session will not be able to find
;           L0 files. 
;
;-
;

pro mvn_lpw_load_l0, trange=trange, packet=packet, clearspice=clearspice, notatlasp=notatlasp, noserver=noserver

if size(clearspice,/type) eq 0 then clearspice='1'
if size(clearspice,/type) ne 7 then begin
    print, ""
    print, "mvn_lpw_load_l0: if set, the keyword leavespice must be set as a string, '0' or '1'."
    retall
endif

;Get trange from timespan if not specified by user:
if not keyword_set(trange) then get_timespan, trange  

if size(trange,/type) eq 7 then trange = time_double(trange)  ;convert to UNIX double

t1d = trange[0]  ;start UNIX time
ndays = round((trange[1]-trange[0])/86400d)  ;number of days to load

ext1 = '_lp_ext'  ;temporary file name added to end of LPW variables that are being combined in time.
len_ext1 = strlen(ext1)  ;length of this string (for later)

for dd = 0l, ndays-1 do begin
    dateSTR = time_string(t1d + (86400d*dd), precision=-3)  ;date to load
    
    ;Delete any mvn_lpw* files from a previous load of mvn_lpw_load. This is because some variables (eg waves) are not always
    ;present, and so cannot be assumed to have been loaded on each call to mvn_lpw_load next.
    tpnames0 = tnames()
    ;Find lpw variables, but ignore L2 variables:
    inds1 = where(strmatch(tpnames0, 'mvn_lpw*') eq 1 and strmatch(tpnames0, 'mvn_lpw*_l2') eq 0 and $
                  strmatch(tpnames0, 'mvn_lpw*'+ext1) eq 0, ninds1)
    if ninds1 gt 0 then store_data, tpnames0[inds1], /delete ;remove these variables
    
    mvn_lpw_load, dateSTR, packet=packet, success=success, notatlasp=notatlasp, noserver=noserver
  
    if success eq 1 then begin
        if ndays gt 1 then mvn_lpw_load_append_l0, ext1   ;only create temp vars if needed (saves time)
        if clearspice eq '1' then mvn_spc_clear_spice_kernels     
    endif 
    
endfor   ;dd

;Rename tmp variables here (if present), and remove variables from last day loaded:
if ndays gt 1 then begin
    tpnames1 = tnames()
    
    ;Find mvn_lpw*+ext1 tplot variables
    inds1 = where(strmatch(tpnames1, 'mvn_lpw*'+ext1) eq 1, ninds1)
    
    for vv = 0l, ninds1-1l do begin
        extname = tpnames1[inds1[vv]]  ;temp var name with +ext1 added
        slen = strlen(extname)
        varname = strmid(extname, 0, slen-len_ext1)  ;extract base tplot name
        
        get_data, extname, data=dd1, dlimit=dl1, limit=ll1  ;get full variable
        store_data, varname, data=dd1, dlimit=dl1, limit=ll1  ;resave full variable, but with original base name only
        store_data, extname, /delete   ;remove temp variable
    endfor
endif

end




