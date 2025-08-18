;+
; procedure: thm_part_moments
;
; Purpose: Calculates moments and spectra for themis particle distributions.
;
;  For documentation on sun contamination correction keywords that
;  may be passed in through the _extra keyword please see:
;  thm_sst_remove_sunpulse.pro or thm_crib_sst_contamination.pro
;
;Keywords:
;  dist_array:  Provide an array of data instead of having thm_part_moments load the data directly.
;    This allows preprocessing/sanitization operations to be performed prior to moment generation.
;    See thm_part_dist_array.pro, thm_part_conv_units.pro
;  fractional_counts:  Flag to keep the ESA unit conversion routine from rounding to an even 
;                      number of counts when removing the dead time correction. 
;                      (no effect if input data already in counts, no effect on SST data)
;           
;ESA PEER/PEIR/PEIF Background Removal Keywords:
;
;/bdnd_remove:  Turn on ESA background removal.
;
;bgnd_type(Default 'anode'): Set to string naming background removal type:
;'angle','omni', or 'anode'.
;
;bgnd_npoints(Default = 3): Set to the number of lowest values points to average over when determining background.
;              
;bgnd_scale(Default=1): Set to a scaling factor that the background will be multiplied by before it is subtracted
;
;BACKGROUND REMOVAL(BGND) Description, Warnings and Caveats(from Vassilis Angelopoulos):
; This code allows for keywords that permit omni-directional or anode-dependent
; background removal from penetrating electrons in the ESA ion and electron 
; detectors. Anode-dependent subtraction is used when possible by default,
; i.e., when angle information is available; but user has full control by
; keyword specification. Default bgnd estimates use 3 lowest counts/s values.
; Scaling of the background (artificial scaling) can also allow playing with
; background estimates to account for noise statistics in the background itself.
; The parameters that have worked well for me during high bgnd levels are:
; ,/bgnd_remove, bgnd_type='anode', bgnd_npoints=3, bgnd_scale=1.5
;
; The same keywords when used in thm_part_getspec, and thm_part_moments
; are understood and passed to the data extraction routines, such that 
; they will do the removal before computing moments or spectra.
;
; This background subtraction to be used at the inner magnetosphere,
; or when SST electron fluxes indicate presence of significant electron
; fluxes at the satellite (injections). At quiet times the code tends to remove
; real fluxes, so beware.
;
;
;
; Author: Davin Larson 2007
; $Id: $
;-


pro thm_part_moments_old, instruments_types = instruments, probes = probes,  $ ;moments=moms,  $
                      data_type=data_type,$ ;same as instrument_types, added to make consistency b/t this & thm_part_getspec
                      moments_types = moments_types, $
                      verbose = verbose, $
                      trange = trange, $
                      erange = erange, $
                      tplotnames = tplotnames, $
                      tplotsuffix = tplotsuffix, $
                      suffix=suffix,$
                      set_opts = set_opts, $
                      scpot_suffix = scpot_suffix, mag_suffix = mag_suffix, $ ;inputs: suffix specifying source of magdata and scpot (name - 'th?')
                      comps = comps, get_moments = get_moments, usage = usage, $
                      get_error = get_error, $
                      units = units,sst_cal=sst_cal,$
                      dist_array=dist_array, _extra = ex

defprobes = '?'
definstruments = 'p??f'
defmoments='density velocity t3 magt3'
start = systime(1)

;syntactic sugar, makes routine consistent with the rest of TDAS
if keyword_set(suffix) then begin
  tplotsuffix=suffix
endif

vprobes      = ['a','b','c','d','e']
if n_elements(probes) eq 1 then if probes eq 'f' then vprobes=['f']
vinstruments = ['peif','peef','psif','psef','peir','peer','psir','pser','peib','peeb','pseb']
vmoments     = strlowcase(strfilter(tag_names(moments_3d()),['TIME','ERANGE','MASS','VALID'],/negate))

if keyword_set(comps) or keyword_set(get_moments)  then begin
   scp = scope_traceback(/struct)
   nscp = n_elements(scp)
   dprint,'Keyword names have changed. Please change the calling routine: ',scp[nscp-2].routine
   usage=1
endif
if keyword_set(usage) then begin
   scp = scope_traceback(/struct)
   nscp = n_elements(scp)
   dprint,'Typical usage: '  ,scp[nscp-1].routine  ,", INSTRUMENT='pe?f', PROBES='a', MOMENTS='density velocity'"
   dprint,'Valid inputs:'
   dprint,'  PROBES=',"'"+vprobes+"'"
   dprint,'  INSTRUMENTS=',"'"+vinstruments+"'"
   dprint,'  MOMENTS=',"'"+vmoments+"'"
   return
endif
If(keyword_set(erange)) Then Begin ;error checking
  If(n_elements(erange) Ne 2) Then Begin
    dprint, 'Bad Energy Range'
    Return
  Endif
  If(erange[1] Le erange[0]) Then Begin
    dprint, 'Bad Energy Range'
    Return
  Endif
  erange_set = erange
Endif Else erange_set = -1
;probea = ssl_check_valid_name(size(/type,probes) eq 7 ? probes : '*',vprobes)

if n_elements(data_type) gt 0 && n_elements(instruments) eq 0 then begin
  instruments=data_type
endif

probes_a       = strfilter(vprobes,size(/type,probes) eq 7 ? probes : defprobes,/fold_case,delimiter=' ',count=nprobes)
instruments_a  = strfilter(vinstruments,size(/type,instruments)  eq 7 ? instruments  : definstruments,/fold_case,delimiter=' ',count=ninstruments)
other_instruments = instruments_a

;for i = 0,n_elements(instruments_a)-1 do begin
;
;
;endfor

moments_a      = strfilter(vmoments,  size(/type,moments_types)  eq 7 ? moments_types  : defmoments  ,/fold_case,delimiter=' ',count=nmoments)
tplotnames=''
if not keyword_set(tplotsuffix) then tplotsuffix=''

;if keyword_set(get_moments) then if not keyword_set(comps)  then comps = ['density','velocity','t3']
;comps = strfilter(vmoments,compmatch,/fold_case,delimiter=' ')
dprint,dlevel=2,/phelp,probes_a
dprint,dlevel=2,/phelp,instruments_a
dprint,dlevel=2,/phelp,moments_a

if size(/type,units) ne 7 then units='eflux'

if keyword_set(sst_cal) then begin
  reduced_index=where(strmid(instruments_a,1,1) eq 's' and strmid(instruments_a,3,1) eq 'r',reduced_count)
  if (reduced_count gt 0) then begin
    dprint,dlevel=1,'WARNING: Beta SST calibrations should not be used with PSIR/PSER.'
  endif
endif


;-----------------------------------------------------------------------

for p = 0,nprobes-1 do begin
    probe= probes_a[p]
    thx = 'th'+probe
    for t=0,ninstruments-1 do begin
        instrument = instruments_a[t]
        format = thx+'_'+instrument
        
        if size(dist_array,/type) eq 10 then begin  ;properly formed dist_array will be an array of type pointer
          ;concatenate times into a single sequence
          for i = 0,n_elements(dist_array)-1 do begin
            times = array_concat((*dist_array[i]).time,times)
          endfor
        endif else begin
          times= thm_part_dist(format,/times,_extra=ex,sst_cal=sst_cal)
 ;        ns = n_elements(times) * keyword_set(times)
        endelse
         
        if size(times,/type) ne 5 then begin
          trx = keyword_set(trange) ? trange:timerange(/current)
          trx = time_string(trx)
          dprint, 'No ',thx,'_',instrument,' data for time range ',trx[0],' to ',trx[1],'. Continuing on to next data type.'
;           dprint,  ''
           continue
        endif

        if keyword_set(trange) then  tr = minmax(time_double(trange)) else tr=[1,1e20]
        ind = where(times ge tr[0] and times le tr[1],ns)

        dprint,format,ns,' elements'

        if ns gt 1  then begin
           if keyword_set(mag_suffix) then begin
                dprint,dlevel=2,verbose=verbose,'Interpolating mag data from: ',thx+mag_suffix
                magf = data_cut(thx+mag_suffix,times[ind])
           endif
           if keyword_set(scpot_suffix) then begin
                dprint,dlevel=2,verbose=verbose,'Interpolating sc potential from:',thx+scpot_suffix
                scpot = data_cut(thx+scpot_suffix,times[ind])
           endif
           
           ;pointer array indicates that data is provided using new vectorized system
           if size(dist_array,/type) eq 10 then begin
             dat = (*dist_array[0])[0]
             dat_seg_index=ind[0] ;find the index of the first time from the data structure, 
                                  ;since the data is organized a little bit differently, you can't quite use a single number to index
                                  ;Instead it just uses some bounds checks to fit a 2-index loop into a 1-index one so that we can maintain backwards compatibility
                
             ;find segment and subsegment index for the beginning of the requested time interval                  
             for dat_ptr_index = 0,n_elements(dist_array)-1l do begin
               if dat_seg_index lt n_elements(*dist_array[dat_ptr_index]) then break
               dat_seg_index-=n_elements(*dist_array[dat_ptr_index])
             endfor
             
             maxnrgs=0
             for max_n_energy_index = 0,n_elements(dist_array)-1l do begin
               maxnrgs = maxnrgs > (*dist_array[max_n_energy_index])[0].nenergy
             endfor
           endif else begin 
             dat = thm_part_dist(format,index=0,_extra=ex,sst_cal=sst_cal)
             maxnrgs = strmid(instrument,1,1) eq 'e' ? 32 : 16 ;hard coding is a problem....but...*shrug*...problem fixed in new particle system
           endelse
             
           if keyword_set(nmoments) then begin
             moms = replicate( moments_3d(), ns )
             If(keyword_set(get_error)) Then dmoms = moms Else dmoms = -1
           endif
           time = replicate(!values.d_nan,ns)
       
           dprint,dlevel=3,/phelp,maxnrgs
           spec = replicate(!values.f_nan, ns, maxnrgs )
           energy =  replicate(!values.f_nan,ns, maxnrgs )

           enoise_tot = thm_sst_erange_bin_val(thx,instrument,times,sst_cal=sst_cal,_extra=ex)
           mask_tot = thm_sst_find_masking(thx,instrument,ind,sst_cal=sst_cal,_extra=ex)

           last_angarray = 0
           for i=0L,ns-1  do begin
           
              if size(dist_array,/type) eq 10 then begin
                
                dat = (*dist_array[dat_ptr_index])[dat_seg_index]
                dat_seg_index++
                if dat_seg_index eq n_elements(*dist_array[dat_ptr_index]) then begin
                  dat_seg_index=0
                  dat_ptr_index++
                endif
                
              endif else begin
                dat = thm_part_dist(format,index=ind[i],mask_tot=mask_tot,enoise_tot=enoise_tot,_extra=ex,sst_cal=sst_cal)
              endelse
              
              ;mask out energy bins out of the erange, if erange is set, jmm, 2011-04-04
              If(n_elements(erange_set) Eq 2) Then Begin
                dont_keep = where(dat.energy Lt erange[0] Or dat.energy Gt erange[1])
                If(dont_keep[0] Ne -1) Then begin 
                  dat.data[dont_keep] = 0
                  dat.bins[dont_keep] = 0
                endif
              Endif
              
;quick fix to time offset problems, jmm, 28-apr-2008
              If(size(dat, /type) Eq 8) Then Begin
                mid_time = (dat.time+dat.end_time)/2.0
                trange2 = [dat.time, dat.end_time]                ; quick fix for now, I am currently working on a better solution.  DL
                dat.time = mid_time
                str_element, dat, 'end_time', /delete
                str_element, dat, 'trange', trange2, /add_replace
              Endif
              
              angarr=[dat.theta,dat.phi,dat.dtheta,dat.dphi]
              if array_equal(last_angarray,angarr) eq 0 then begin   ; Sense change in mode
                 last_angarray = angarr
                 domega = 0
;              printdat,angarr
                 dprint,dlevel=2,verbose=verbose,'Index=',i,' New mode at: ',time_string(dat.time)
              endif
              
              
              ;Check if eclipse corrections are present and apply.
              thm_part_moments_apply_eclipse, dat, domega=domega, eclipse=eclipse, previous=previous

              
              time[i] = dat.time
              dim = size(/dimen,dat.data)
              dim_spec = size(/dimensions,spec)
              if keyword_set(units) then begin
                 ;Since the unit routines check to prevent double calibration, it is safe to leave this step in, even if calibrated data was provided using the dist_array keyword
                 udat = conv_units(dat,units+'',_extra=ex)
                 bins = udat.bins
                 dim_data = size(/dimensions,udat.data)
                 nd = size(/n_dimensions,udat.data)
                 dim_bins = size(/dimensions,bins)
                 if array_equal(dim_data,dim_bins) eq 0 then bins = replicate(1,udat.nenergy) # bins   ; special case for McFadden's 3D structures
                 sp = nd eq 1 ? udat.data * (bins ne 0)  : total(udat.data * (bins ne 0),2) / total(bins ne 0,2)
                 en = nd eq 1 ? udat.energy : average(udat.energy,2)
                 spec[ i, 0:dim[0]-1] = sp
                 energy[ i,0:dim[0]-1] = en
              endif
                            
              if  nmoments ne 0 then begin
                  if keyword_set(magf) then  dat.magf=magf[i,*]
                  if keyword_set(scpot) then dat.sc_pot=scpot[i]
                  ;dat.dead = 0
                  if keyword_set(get_error) then begin
                    moms[i] = moments_3du( dat, dmomsi, domega = domega )
                    dmoms[i] = dmomsi
                  endif else moms[i] = moments_3d( dat , domega=domega )
              endif
              dprint,dwait=10.,format,i,'/',ns;,'    ',time_string(dat.time)   ; update every 10 seconds
           endfor

           if not keyword_set(no_tplot) then begin
              prefix = thx+'_'+instrument+'_'
              suffix = '_'+strlowcase(units)+tplotsuffix
              
              ;add labels to energy spectra, 
              ;labels will drawn if plotted as line plot
              if keyword_set(units) then begin
                 tname = prefix+'en'+suffix
                 energyval = float( average(energy,1))
                 kev = energyval gt 1000.
                 ylabels = strarr(n_elements(energyval))
                 for q=0, n_elements(energyval)-1 do begin
                   ylabels[q] = formatannotation(0,0,energyval[q]/(1000^kev[q]), $
                              data={timeaxis:0,formatid:4,scaling:0,exponent:0}) $
                              + ([' eV',' keV'])[kev[q]]
                 endfor
                 store_data,tname, data= {x:time, y:spec ,v:energy },dlim={spec:1,zlog:1,ylog:1 $
                   ,labels:ylabels,labflag:-1}
                 append_array,tplotnames,tname
              endif
              
              for i = 0, nmoments-1 do begin
                  momname = moments_a[i]
;                  value = reform(transpose( struct_value(moms,momname) ) )
;fix for transpose bombing when there is only  1 element, jmm, 13-feb-2008
                  value = struct_value(moms, momname)
                  if(n_elements(value) gt 1) then value = reform(transpose(temporary(value)))
                  tname = prefix + momname + tplotsuffix
                  append_array,tplotnames,tname
;                  printdat,value,varname= comps[i]
                  store_data,tname,data= { x: moms.time,  y: value }
                  if size(/n_dimen,value) gt 1 then options,tname,colors='bgr',/def
                  if(keyword_set(get_error)) then begin
                    value = struct_value(dmoms, momname)
                    if(n_elements(value) gt 1) then value = reform(transpose(temporary(value)))
                    tname = prefix + momname + '_sigma'+tplotsuffix
                    append_array, tplotnames, tname
                    store_data, tname, data = { x: moms.time,  y: value }
                    if size(/n_dimen, value) gt 1 then options, tname, colors = 'bgr', /def
                  endif
              endfor
           endif
        endif
    endfor
endfor
dprint,dlevel=3,verbose=verbose,'Run Time: ',systime(1)-start,' seconds'
tn=tplotnames
options,strfilter(tplotnames,'*_density'+tplotsuffix),/def ,yrange=[.01,200.],/ystyle,/ylog,ysubtitle='!c[1/cc]'
options,strfilter(tplotnames,'*_velocity'+tplotsuffix),/def ,yrange=[-800,800.],/ystyle,ysubtitle='!c[km/s]'
options,strfilter(tplotnames,'*_flux'+tplotsuffix),/def ,yrange=[-1e8,1e8],/ystyle,ysubtitle='!c[#/s/cm2 ??]'
options,strfilter(tplotnames,'*t3'+tplotsuffix),/def ,yrange=[1,10000.],/ystyle,/ylog,ysubtitle='!c[eV]'

;set units in moments
spd_new_units, strfilter(tplotnames, '*_density'+tplotsuffix), units_in = '1/cm^3'
spd_new_units, strfilter(tplotnames,'*_velocity'+tplotsuffix), units_in = 'km/s'
spd_new_units, strfilter(tplotnames,'*_vthermal'+tplotsuffix), units_in = 'km/s'
spd_new_units, strfilter(tplotnames,'*_flux'+tplotsuffix), units_in = '#/s/cm^2'

spd_new_units, strfilter(tplotnames,'*t3'+tplotsuffix), units_in = 'eV'
spd_new_units, strfilter(tplotnames,'*_avgtemp'+tplotsuffix), units_in = 'eV'
spd_new_units, strfilter(tplotnames,'*_sc_pot'+tplotsuffix), units_in = 'V'

spd_new_units, strfilter(tplotnames,'*_eflux'+tplotsuffix), units_in = 'eV/(cm^2-s)' ;en_efluxes will be overwritten by the next step
spd_new_units, strfilter(tplotnames,'*_en_eflux'+tplotsuffix), units_in = 'eV/(cm^2-s-sr-eV)'

spd_new_units, strfilter(tplotnames,'*tens'+tplotsuffix), units_in = 'eV/cm^3'

spd_new_units, strfilter(tplotnames,'*_symm_theta'+tplotsuffix), units_in = 'degrees'
spd_new_units, strfilter(tplotnames,'*_symm_phi'+tplotsuffix), units_in = 'degrees'
spd_new_units, strfilter(tplotnames,'*_symm_ang'+tplotsuffix), units_in = 'degrees'

spd_new_units, strfilter(tplotnames,'*_magf'+tplotsuffix), units_in = 'nT'

;set coordinates in moments
spd_new_coords, strfilter(tplotnames,'*_velocity'+tplotsuffix), coords_in = 'DSL'
spd_new_coords, strfilter(tplotnames,'*_flux'+tplotsuffix), coords_in = 'DSL'

spd_new_coords, strfilter(tplotnames,'*_t3'+tplotsuffix), coords_in = 'DSL'
spd_new_coords, strfilter(tplotnames,'*_magt3'+tplotsuffix), coords_in = 'FA'

spd_new_coords, strfilter(tplotnames,'*_eflux'+tplotsuffix), coords_in = 'DSL'

spd_new_coords, strfilter(tplotnames,'*tens'+tplotsuffix), coords_in = 'DSL'

spd_new_coords, strfilter(tplotnames,'*_magf'+tplotsuffix), coords_in = 'DSL'

If(keyword_set(get_error)) Then Begin
  store_data, '*t3_sigma*', /delete ;currently these are not filled, so delete to avoid confusion
  store_data, '*symm*_sigma*', /delete ;currently these are not filled, so delete to avoid confusion
  store_data, '*sc_pot*_sigma*', /delete ;currently these are not filled, so delete to avoid confusion
  store_data, '*magf*_sigma*', /delete ;currently these are not filled, so delete to avoid confusion
;add units to the remaining _sigma variables
  spd_new_units, strfilter(tplotnames, '*_density_sigma'+tplotsuffix), units_in = '1/cm^3'
  spd_new_units, strfilter(tplotnames,'*_velocity_sigma'+tplotsuffix), units_in = 'km/s'
  spd_new_units, strfilter(tplotnames,'*_vthermal_sigma'+tplotsuffix), units_in = 'km/s'
  spd_new_units, strfilter(tplotnames,'*_flux_sigma'+tplotsuffix), units_in = '#/s/cm^2'
  spd_new_units, strfilter(tplotnames,'*_avgtemp_sigma'+tplotsuffix), units_in = 'eV'
  spd_new_units, strfilter(tplotnames,'*_eflux_sigma'+tplotsuffix), units_in = 'eV/(cm^2-s)'
  spd_new_units, strfilter(tplotnames,'*tens_sigma'+tplotsuffix), units_in = 'eV/cm^3'
;add coordinates to the remaining _sigma variables
  spd_new_coords, strfilter(tplotnames,'*_velocity_sigma'+tplotsuffix), coords_in = 'DSL'
  spd_new_coords, strfilter(tplotnames,'*_flux_sigma'+tplotsuffix), coords_in = 'DSL'
  spd_new_coords, strfilter(tplotnames,'*_eflux_sigma'+tplotsuffix), coords_in = 'DSL'
  spd_new_coords, strfilter(tplotnames,'*tens_sigma'+tplotsuffix), coords_in = 'DSL'
Endif

end


