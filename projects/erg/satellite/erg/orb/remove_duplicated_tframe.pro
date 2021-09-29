;+
; PRO  remove_duplicated_tframe
;
; :Description:
;    This was a duplicated procedure in  erg_load_orb.pro, erg_load_orb_l3.pro, erg_load_orb_predict.pro
;
; :Author:
;
;   Tzu-Fang Chang, ISEE, Nagoya University (jocelyn at isee.nagoya-u.ac.jp)
;   Mariko Teramoto, ISEE, Naogya Univ. (teramoto at isee.nagoya-u.ac.jp)
;   Kuni Keika, Department of Earth and Planetary Science,
;     Graduate School of Science,The University of Tokyo (keika at eps.u-tokyo.ac.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2020-05-18 10:34:14 -0700 (Mon, 18 May 2020) $
; $LastChangedRevision: 28705 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/orb/remove_duplicated_tframe.pro $
;-
pro remove_duplicated_tframe, tvars

  if n_params() ne 1 then return
  tvars = tnames(tvars)
  if strlen(tvars[0]) lt 1 then return

  for i=0L, n_elements(tvars)-1 do begin
    tvar = tvars[i]

    get_data, tvar, time, data, dl=dl, lim=lim
    if(time[0] eq 0) then continue
    n = n_elements(time)
    dt = [ time[1:(n-1)], time[n-1]+1 ] - time[0:(n-1)]
    idx = where( abs(dt) gt 0d, n1 )

    if n ne n1 then begin
      newtime = time[idx]
      if size(data,/n_dim) eq 1 then begin
        newdata = data[idx]
      endif else newdata = data[ idx, *]
      store_data, tvar, data={x:newtime, y:newdata},dl=dl, lim=lim
    endif
  endfor

  return
end

