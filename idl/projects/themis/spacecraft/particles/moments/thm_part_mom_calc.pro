pro thm_part_mom_calc ,types=types, probes=probes, moments=moms, comps=comps

if not keyword_set(types)   then types = ['eif','eef','sif','sef']
if not keyword_set(probes) then probes = ['a','b','c','d','e']
if not keyword_set(comps)  then comps = ['density','velocity','T3']


for p = 0,n_elements(probes)-1 do begin
    probe= probes[p]
    thx = 'th'+probe
    for t=0,n_elements(types)-1 do begin
        type = types(t)
        format = thx+'_'+type
        times= thm_part_dist(format,/times)
        ns = n_elements(times) * keyword_set(times)
        dprint,format,ns,' elements'

        if ns gt 0  then begin

          moms = replicate( moments_3d(), ns )

          for i=1L,ns-1  do begin    ; Change to start at 0L after jim fixes his code
              dat = thm_part_dist(format,index=i)
              dat.sc_pot = 24.
              moms[i] = moments_3d( dat )
              dprint,dwait=10.,format,i,'/',ns,'    ',time_string(dat.time)
          endfor

          if not keyword_set(no_tplot) then begin
              prefix = thx+'_p'+type+'_'

              for i = 0, n_elements(comps)-1 do begin

                  value = reform(transpose( struct_value(moms,comps[i]) ) )
;                  printdat,value,varname= comps[i]
                  store_data,prefix+comps[i],data= { x: moms.time,  y: value }
              endfor
          endif
        endif
    endfor
endfor


end


