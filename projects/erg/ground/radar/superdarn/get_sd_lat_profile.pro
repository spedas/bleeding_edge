;+
; FUNCTION get_sd_lat_profile
;
; :Description:
;   Obtain a tplot variable storing a time series of the values
;   averaged over the given latitude/longitude range, to be plotted as a RTI-type plot.
;   This procedure calls get_sd_ave() internally. 
;
; :PARAMTERS:
; vn : a tplot variable the values in which are to be averaged
;
; :KEYWORD:
; latrng: the geographical latitude range for which the given values are averaged
; dlat:   latitudial width of each latitudinal bin for which the average values are obtained.  
; lonrng: the geographical longitude range for averaging
; maglat: Set this keyword if you give the latrng in magnetic latitude, not in geographical latitude. 
; new_vn: Set a string to create a new tplot variable containing the averaged values
;
; :EXAMPLES:
;   erg_load_sdfit, site='hok',/get
;   get_sd_lat_profile, 'sd_hok_vlos_1', latrng=[60,70], lonrng=[140,170], dlat=2., /maglat
;
; :Author:
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
;   2011/07/03: Created
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-02-10 16:54:11 -0800 (Mon, 10 Feb 2014) $
; $LastChangedRevision: 14265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/get_sd_lat_profile.pro $
;-
PRO get_sd_lat_profile, vn, latrng=latrng, lonrng=lonrng, dlat=dlat, maglat=maglat, new_vn=new_vn
  
  ;Currently this procedure can take as an argument:
  ; vlos, vlshell, (vlos|vnorth|veast), _iscat
  
  ;Check the arguments and keywords
  if tnames(vn[0]) eq '' then return
  vn0 = tnames(vn[0])
  vn = vn0
  
  if ~keyword_set(latrng) or ~keyword_set(lonrng) then return
  
  if ~keyword_set(dlat) then dlat = 1.
  
  if n_elements(latrng) ne 2 or n_elements(lonrng) ne 2 then return
  
  latrng = float(latrng)
  dlat = abs(dlat)
  tlatarr = ( latrng[0] + dlat* findgen(ceil( (latrng[1]-latrng[0])/dlat )+1) ) < latrng[1]
 
  ;print, tlatarr
  
  ;Generate the time-lat array
  scan = get_scan_struc_arr(vn) 
  valarr = fltarr( n_elements(scan.x), n_elements(tlatarr)-1 )
  nlat = n_elements(tlatarr)
  latc = (tlatarr[1:(nlat-1)]+tlatarr[0:(nlat-2)])/2.
  ;print, latc
  
  for i=0L, n_elements(tlatarr)-2 do begin
    
    latmin = tlatarr[i] & latmax = tlatarr[i+1]
    latave = get_sd_ave(vn, latrng=[latmin,latmax],lonrng=lonrng,$
                          maglat=maglat )
    valarr[*,i] = latave.y
    
  endfor
  
  ;Store the time-lat arr in a tplot var
  if ~keyword_set(new_vn) then $
    new_vn = vn +'_latpro_lon'+string(lonrng[0],'(I03)')+'-'+$
      string(lonrng[1],'(I03)')
      
  store_data, new_vn, data={x: scan.x, y:valarr, v:latc}, $
    dl={spec:1}, $
    lim={zrange:[-300,300]}
    
  return
end
