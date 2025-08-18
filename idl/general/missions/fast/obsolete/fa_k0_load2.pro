;+
; Loads Fast Data
; Usage:
;    fa_k0_load,'ees'
;    fa_k0_load,'ies'
;    fa_k0_load,'dcf'
; Davin Larson
;-
pro fa_k0_load2,types,trange=trange,source=source,version=version,verbose=verbose

source = fa_file_source(verbose=verbose)
subdir = 'misc/'
subdir = ''


tr=timerange(trange)
orbits = fa_orbit_time(tr)   ; interp(odat.orbit,odat.time,tr)
orbit_range = long(orbits+[-.5,.5])
n_orbits = orbit_range[1]-orbit_range[0]+1
orbits = string(lindgen(n_orbits) + orbit_range[0],format='(i05)')

if not keyword_set(types) then types = ['ees','ies']

for i=0,n_elements(types)-1 do begin
   type = types[i]
   case type of
       'ees': vxx = 'v03'
       'ies': vxx = 'v03'
       'dcf': vxx = 'v02'
       'acf': vxx = 'v03'
       'tms': vxx = 'v04'
       else : vxx = 'v0?'
   endcase
   if keyword_set(version) then vxx = version
   orbdir = string(1000*(long(orbits)/1000), format='(i5.5)')
   relpathnames = subdir + 'fast/k0/'+type+'/'+orbdir+'/fa_k0_'+type+'_'+orbits+'_'+vxx+'.cdf'
   files = file_retrieve(relpathnames,_extra=source)
   if keyword_set(downloadonly) then continue
   cdf2tplot,file=files,/all,verbose=verbose,varformat='*' ,prefix = 'fa_'    ; load data into tplot variables
endfor

end
