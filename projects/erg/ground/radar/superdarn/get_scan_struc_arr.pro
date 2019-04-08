;+
; FUNCTION get_scan_struc_arr
;
; :Description:
; 	Obtain a structure storing SD data sorted by scan. Usually this function is
; 	used by the other routines.
;
; :EXAMPLES:
;   dat = get_scan_struc_arr( 'sd_hok_vlos_1' )
;
; :Author:
; 	Tomo Hori (E-mail: horit at isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/07/01: Initial release
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-

FUNCTION get_scan_struc_arr, vn

  ;Check the argument
  npar = n_params()
  if npar ne 1 then return, 0
  vn = vn[0] ;only 1st element is processed below
  if (tnames(vn))[0] eq '' then return,0
  get_data, vn, data=d
  vartime = d.x & var = d.y
  if (size(var))[0] ne 2 then return, 0
  
  ;Strings consisting of vn
  prefix = strmid(vn, 0,7)
  suf = strmid(vn, 0,1,/reverse)
  azmno_vn = prefix+'azim_no_'+suf
  scanno_vn = prefix+'scanno_'+suf
  get_data, azmno_vn, data=d
  azmno = d.y
  get_data, scanno_vn, data=d
  scanno = d.y
  
  scan = scanno[uniq(scanno)]
  azmno_sorted = azmno[sort(azmno)]
  azm = azmno_sorted[uniq(azmno_sorted)]
  azmmax = n_elements(azm)
  nrang = n_elements(var[0,*])
  ;;;;;;;;;;;;;;;;;;;;;;;help, azm & print, azm
  ;Create a 2-D scan array and its time array
  vararr = fltarr( n_elements(scan), nrang, azmmax )
  timearr = dblarr(n_elements(scan))
  beamtarr = dblarr(n_elements(scan), 2)
  nbeamarr = intarr(n_elements(scan))
  vararr[*] = !values.f_nan
  
  ;Store data into the 2-D scan array
  for i=0L, n_elements(scan)-1 do begin
    tscan = scan[i]
    idx = where(scanno eq tscan)
    if idx[0] ne -1 then begin
      timearr[i] = mean( vartime[idx] )
      ;Time label is the average for tplot drawing
      beamt = minmax( vartime[idx] )
      beamtarr[i,*] = transpose( [ beamt[0], beamt[1] ] ) ; Start and end time of each scan
      tazmno = azmno[idx]
      nbeamarr[i] = n_elements(tazmno)
      tvar = transpose(var[idx,*])
      for j=0, n_elements(azm)-1 do begin
        
        az = azm[j]
        if az lt 0 or az ge azmmax then continue ;beam number is invalid!, skipped
        idx2 = where( tazmno eq az, nbm )
        if nbm eq 1 then begin ; One beam for one azimuthal no., likely the normal scan
          vararr[i,*,az] = reform( tvar[*, idx2], 1,nrang,1)
        endif else if nbm gt 1 then begin
          totalvararr = total(tvar[*,idx2], 2, /nan)
          numvararr = total( finite(tvar[*,idx2]), 2 )
          idx3 = where( numvararr gt 0 )
          if idx3[0] ne -1 then totalvararr[idx3] /= numvararr[idx3]
          idx3 = where( numvararr lt 1 )
          if idx3[0] ne -1 then totalvararr[idx3] = !values.f_nan  ;To avoid division by 0
          vararr[i,*,az] = reform( totalvararr, 1, nrang, 1)
        endif else continue
        
      endfor
      
    endif
    
  endfor
  
  return, {x:timearr, y:vararr, beamt:beamtarr, nbeam:nbeamarr }
end



