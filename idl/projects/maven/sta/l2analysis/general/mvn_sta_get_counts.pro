;+
;Get total count rate for STATIC apid, trange and mass range. Return the result as an IDL data structure consisting of
;   result = {x: timestamps, y: count rate for the specified apid and mass range}.
;
;INPUTS:
;sta_apid: string: apid: eg 'c6'. Default is 'c6' if not set.
;
;trange: [a,b]: UNIX double time range to get count rates between. Default is entire common block if not set.
;
;massrange: [a,b]: calculate count rate for this AMU mass range. If not specified, all masses are included.
;
;species: string: specify which mass ranges to use using default settings: 'h', 'he', 'o', 'o2', 'co2'.
;
;tstore: set /tstore to store the result as a tplot variable. Note, this keyword can only be set if the species keyword
;        is also set (to simplify tplot variable naming). The output tplot variable will have the form 
;        'mvn_sta_'+sta_apid+'_'+species+'_tot_counts', eg mvn_sta_c6_o_tot_counts.
;
;OUTPUTS:
;result = {x: timestamps, y: count rate for the specified apid and mass range}
;
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_get_counts.pro
;-
;

function mvn_sta_get_counts, sta_apid=sta_apid, trange=trange, massrange=massrange, success=success, species=species, tstore=tstore

proname = 'mvn_sta_get_counts'

if not keyword_set(sta_apid) then sta_apid='c6'

@'qualcolors'
if size(qualcolors,/type) eq 8 then begin  ;setup colors
    colblack = qualcolors.black
    colred = qualcolors.red
    colgreen = qualcolors.green
    colblue = qualcolors.blue
endif else begin
    cols = get_colors()
    colblack = cols.black
    colred = cols.red
    colgreen = cols.green
    colblue = cols.blue
endelse


;If keyword species set, go with this:
if size(species, /type) eq 7 then begin
  mranges = mvn_sta_get_mrange()

  species=strupcase(species)
  species2 = strlowcase(species)
  case species of
    'H' : begin
            massrange = mranges.H
            m_int=1.
          end
    'HE' : begin
            massrange = mranges.He
            m_int=2.
          end
    'O' : begin
            massrange = mranges.O
            m_int=16.
          end
    'O2' : begin
            massrange = mranges.O2
            m_int=32.
          end
    'CO2' : begin
            massrange = mranges.CO2
            m_int=44.
          end
    else : begin
            massrange=[0., 60.]
            m_int=32.
          end
  endcase
endif

if size(massrange,/type) eq 0 then massrange=[0., 60.]  ;default

;Get common block:
res1 = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)
res2 = execute("dat = all_dat_"+sta_apid)

if not keyword_set(trange) then trange=[min(dat.time,/nan), max(dat.end_time,/nan)]

iFI = where(dat.time ge trange[0] and dat.end_time le trange[1], niFI)

if niFI gt 0 then begin
    ;ARRAYS:
    cnts_arr = fltarr(niFI)+!values.f_nan
    
    if dat.units_name ne 'counts' then stop  ;I don't think this should ever happen.
    
    ;Determine number of dimensions in the data structure (eg time, energy, mass, direction):
    ndim = size(dat.data, /n_dimensions)
    
    for tt = 0l, niFI-1l do begin
        ind = iFI[tt]
            
        res3 = execute("datTMP = mvn_sta_get_"+sta_apid+"(index=ind)") ;get dat structure for this timestamp
                
        ;Find mass range (changes with energy and look direction slightly)
        iFI2 = where(datTMP.mass_arr ge massrange[0] and datTMP.mass_arr le massrange[1], niFI2)
        
        if niFI2 gt 0 then cnts_arr[tt] = total(datTMP.cnts[iFI2], /nan)  ;total counts
        
    endfor  ;tt
    
    ;Store in tplot:
    timearr = (dat.time[iFI] + ((dat.end_time[iFI] - dat.time[iFI])/2.))  ;mid points
    if keyword_set(species) and keyword_set(tstore) then begin       
        tname = 'mvn_sta_'+sta_apid+'_'+species2+'_tot_cnts'
        store_data, tname, data={x: timearr, y: cnts_arr}
          options, tname, ylog=1
          ylim, tname, 1., 1E5
          options, tname, ytitle='STA '+sta_apid+'!Ctot cnts'
        
    endif    
    
    output = create_struct("x"        ,     timearr   , $
                           "y"        ,     cnts_arr)
      
    success=1
    
    return, output
endif else begin
    print, proname, ": I couldn't find any data for the requested time range."
    success=0
    return, 0
endelse

end



