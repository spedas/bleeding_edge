;+
; procedure: thm_part_spec_calc
; Purpose: Calculates moments and spectra for themis particle distributions.
; Author: Davin Larson 2007
; $Id: thm_part_spec_calc.pro 17458 2015-04-30 22:28:49Z aaflores $
;-


pro thm_part_spec_calc ,instruments_types=instruments, probes=probes,  $  ;moments=moms,  $
                        moments_types=moments_types, $
                        verbose=verbose, $
                        trange=trange, $
                        tplotnames=tplotnames, $
                        tplotsuffix=tplotsuffix, $
                        set_opts=set_opts, $
                        scpot_suffix=scpot_suffix, mag_suffix=mag_suffix, $    ;inputs: suffix specifying source of magdata and scpot (name - 'th?')
                        comps=comps, get_moments=get_moments,usage=usage, $
                         units=units

defprobes = '?'
definstruments = 'p??f'
defmoments='density velocity t3 magt3'
start = systime(1)

vprobes      = ['a','b','c','d','e']
vinstruments = ['peif','peef','psif','psef','peir','peer','psir','pser','peib','peeb']
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
   dprint,'INSTRUMENTS=','"'+vinstruments+'"'
   return
endif

;probea = ssl_check_valid_name(size(/type,probes) eq 7 ? probes : '*',vprobes)

probes_a       = strfilter(vprobes,size(/type,probes) eq 7 ? probes : defprobes,/fold_case,delimiter=' ',count=nprobes)
instruments_a  = strfilter(vinstruments,size(/type,instruments)  eq 7 ? instruments  : definstruments,/fold_case,delimiter=' ',count=ninstruments)
moments_a      = strfilter(vmoments,  size(/type,moments_types)  eq 7 ? moments_types  : defmoments  ,/fold_case,delimiter=' ',count=nmoments)
tplotnames=''
if not keyword_set(tplotsuffix) then tplotsuffix=''

;if keyword_set(get_moments) then if not keyword_set(comps)  then comps = ['density','velocity','t3']
;comps = strfilter(vmoments,compmatch,/fold_case,delimiter=' ')
dprint,dlevel=2,/phelp,probes_a
dprint,dlevel=2,/phelp,instruments_a
dprint,dlevel=2,/phelp,moments_a

if size(/type,units) ne 7 then units='eflux'

;-----------------------------------------------------------------------

for p = 0,nprobes-1 do begin
    probe= probes_a[p]
    thx = 'th'+probe
    for t=0,ninstruments-1 do begin
        instrument = instruments_a(t)
        format = thx+'_'+instrument
        times= thm_part_dist(format,/times)
;        ns = n_elements(times) * keyword_set(times)
        if keyword_set(trange) then  tr = minmax(time_double(trange)) else tr=[1,1e20]
        ind = where(times ge tr[0] and times le tr[1],ns)

        dprint,format,ns,' elements'

        if ns gt 0  then begin
           if keyword_set(mag_suffix) then begin
                dprint,dlevel=3,verbose=verbose,'Interpolating mag data from: ',thx+mag_suffix
                magf = data_cut(thx+mag_suffix,times[ind])
           endif
           if keyword_set(scpot_suffix) then begin
                dprint,dlevel=3,verbose=verbose,'Interpolating sc potential from:',thx+scpot_suffix
                scpot = data_cut(thx+scpot_suffix,times[ind])
           endif
           dat = thm_part_dist(format,index=0)
           energy = average(dat.energy,2)
           if keyword_set(nmoments) then moms = replicate( moments_3d(), ns )
           time = replicate(!values.d_nan,ns)
           spec = replicate(!values.f_nan, ns, dat.nenergy )
           energy =  replicate(!values.f_nan,ns, dat.nenergy )

           last_angarray = 0
           for i=0L,ns-1  do begin
              dat = thm_part_dist(format,index=ind[i])
              angarr=[dat.theta,dat.phi,dat.dtheta,dat.dphi]
              if array_equal(last_angarray,angarr) eq 0 then begin
                 last_angarray = angarr
                 domega = 0
                 dprint,dlevel=3,verbose=verbose,'New mode at: ',time_string(dat.time)
              endif
              time[i] = dat.time
              dim = size(/dimen,dat.data)

              if keyword_set(units) then begin
                 udat = conv_units(dat,units+'')
                 bins = udat.bins
                 dim_data = size(/dimensions,udat.data)
                 nd = size(/n_dimensions,udat.data) ; +
                 dim_bins = size(/dimensions,bins)
                 if array_equal(dim_data,dim_bins) eq 0 then bins = replicate(1,udat.nenergy) # bins   ; special case for McFadden's 3D structures
                 sp = nd eq 1 ? udat.data   : total(udat.data * (bins ne 0),2) / total(bins ne 0,2)
                 en = nd eq 1 ? udat.energy : average(udat.energy,2)
                 spec[ i, 0:dim[0]-1] =  sp
                 energy[ i,0:dim[0]-1] = en
              endif
              if  nmoments ne 0 then begin
;                  dat.dead = 0
                  if keyword_set(magf) then  dat.magf=magf[i,*]
                  if keyword_set(scpot) then dat.sc_pot=scpot[i]
                  moms[i] = moments_3d( dat , domega=domega )
              endif
              dprint,dwait=10.,format,i,'/',ns;,'    ',time_string(dat.time)   ; update every 10 seconds
           endfor

           if not keyword_set(no_tplot) then begin
              prefix = thx+'_'+instrument+'_'
              suffix = '_'+strlowcase(units)+tplotsuffix
              if keyword_set(units) then begin
                 tname = prefix+'en'+suffix
                 store_data,tname, data= {x:time, y:spec ,v:energy },dlim={spec:1,zlog:1,ylog:1}
                 append_array,tplotnames,tname
              endif
              for i = 0, nmoments-1 do begin
                  momname = moments_a[i]
                  value = reform(transpose( struct_value(moms,momname) ) )
                  tname = prefix + momname
                  append_array,tplotnames,tname
;                  printdat,value,varname= comps[i]
                  store_data,tname,data= { x: moms.time,  y: value }
                  if size(/n_dimen,value) gt 1 then options,tname,colors='bgr',/def
              endfor
           endif
        endif
    endfor
endfor
dprint,dlevel=3,verbose=verbose,'Run Time: ',systime(1)-start,' seconds

end


