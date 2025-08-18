;+
; PROCEDURE:
;       kgy_svm_pred
; PURPOSE:
;       Computes crustal B at Kaguya positions from SVM (Tsunakawa et al., 2015)
; CALLING SEQUENCE:
;       kgy_svm_pred,trange=time_double('2008-01-01/'+['02:00','04:00'])
; OPTIONAL KEYWORDS:
;       trange: time range (Def: timerange())
;       resolution: time resolution (Def: 4)
;       spice_frame: additional output B frame
;                    available frames: SELENE_M_SPACECRAFT, SSE, GSE
; CREATED BY:
;       Yuki Harada on 2018-05-08
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 23:37:33 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/lmag/kgy_svm_pred.pro $
;-

pro kgy_svm_pred, trange=trange, resolution=resolution, spice_frame=spice_frame

if ~keyword_set(resolution) then resolution = 4d
if total(strlen(spice_test('*moon*'))) eq 0 then kk = kgy_spice_kernels(/load,trange=trange)

tr = timerange(trange)

ntimes = long( (tr[1] - tr[0]) / resolution )
times = dindgen(ntimes) * resolution + tr[0]
rme = make_array(value=!values.f_nan,3,n_elements(times))

in_gaps = kgy_spk_gaps(times)
wok = where( ~in_gaps, nwok )
if nwok eq 0 then begin
   dprint,'No valid times for spk kernels'
   return
endif


rme[*,wok] = spice_body_pos( 'SELENE','Moon',utc=times[wok],frame='MOON_ME' )

bmod = kgy_svm_get(rme)

store_data,'kgy_svm_Bme',data={x:times,y:transpose(bmod)}, $
           dlim={colors:'bgr',linestyle:2}

if keyword_set(spice_frame) then begin
   bnew = spice_vector_rotate(bmod,times,'MOON_ME',spice_frame,check='SELENE')
   store_data,'kgy_svm_B'+strlowcase(spice_frame), $
              data={x:times,y:transpose(bnew)}, $
              dlim={colors:'bgr',linestyle:2}
endif


end
