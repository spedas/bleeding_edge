;+
; PROCEDURE:
;       mvn_ngi_mspec
; PURPOSE:
;       combine mass-separated tplot variables into one spectrogram
; CALLING SEQUENCE:
;       mvn_ngi_mspec
; INPUTS:
;       None
; KEYWORDS:
;       delete_source: if set, deletes original tplot variables
; CREATED BY:
;       Yuki Harada on 2015-07-13
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-05-12 13:09:34 -0700 (Thu, 12 May 2016) $
; $LastChangedRevision: 21065 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_mspec.pro $
;-

pro mvn_ngi_mspec, delete_source=delete_source

mt = tnames('mvn_ngi_*mass???',nmt)
idx = strpos(mt,'_mass')
pref = mt
for imt=0,nmt-1 do pref[imt] = strmid(mt[imt],0,idx[imt])
uniqpref = pref[uniq(strlowcase(pref))]

if total(strlen(uniqpref)) gt 0 then begin
   for iu=0,n_elements(uniqpref)-1 do begin
      mt = tnames(uniqpref[iu]+'*mass???',nmt)
      get_data,mt[0],data=d0,dlim=dl0
      nt = n_elements(d0.x)
      times = replicate(!values.d_nan,nt,nmt)
      abund = replicate(!values.f_nan,nt,nmt)
      mass = replicate(!values.f_nan,nt,nmt)
      for imt=0,nmt-1 do begin
         get_data,mt[imt],data=d,dlim=dl
         if n_elements(d.x) ne nt then begin
            dprint,'Time steps do not match for mass:',dl.mass
            dprint,'Skipped'
            continue
         endif
         times[*,imt] = d.x[*]
         abund[*,imt] = d.y[*]
         mass[*,imt] = dl.mass
      endfor
      time = average(times,2)
      store_data,uniqpref[iu]+'_mspec',data={x:time,y:abund,v:mass}, $
                 dlim={spec:1,zlog:1,datagap:600}
      if keyword_set(delete_source) then store_data,mt,/del
   endfor
endif


end
