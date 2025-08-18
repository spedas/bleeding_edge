;+
; FUNCTION get_sd_ave
;
; :Description:
; 	Obtain a tplot variable-type structure storing a time series of the values 
; 	averaged over the given latitude/longitude range.  
;
; :PARAMTERS:
; vn : a tplot variable the values in which are to be averaged
; 
; :KEYWORD:
; latrng: the geographical latitude range for which the given values are averaged
; lonrng: the geographical longitude range for averaging
; maglat: Set this keyword if you give the latrng in magnetic latitude
; maglon: Set this if you give the lonrng in magnetic longitude 
; new_vn: Set a string to create a new tplot variable containing the averaged values
;
; :EXAMPLES:
;   erg_load_sdfit, site='hok',/get
;   dat = get_sd_ave( 'sd_hok_vlos_1', latrng=[60,70], lonrng=[140,170] 
;
; :Author:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/07/03: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
; A helper function to check if the argument x (scalar or array) falls in the angular range given by 
; the argument range (a 2-element 1-D array). Both x and range should be given in degree. 
FUNCTION in_phirng, x, range, west=west

  IF dimen(range) NE 2 THEN RETURN, -1

  range= ( range + 360. ) MOD 360.
  IF range[0] LT 0. OR range[1] LT 0. THEN RETURN, -1

  IF range[0] LT range[1] THEN BEGIN

    RETURN, ( x GE range[0] AND x LT range[1])

  ENDIF ELSE BEGIN

    RETURN, ( x GE range[0] OR x LT range[1]  )

  ENDELSE


  RETURN, -1
END

FUNCTION get_sd_ave, vn, latrng=latrng, lonrng=lonrng, maglat=maglat, maglon=maglon, new_vn=new_vn
  
  
  ;Check the arguments and keywords
  npar = n_params()
  if npar ne 1 then return, !values.f_nan
  if (tnames(vn[0])) eq '' then return, !values.f_nan
  
  if n_elements(latrng) ne 2 or n_elements(lonrng) ne 2 then return, !values.f_nan
  
  is_maglat = keyword_set(maglat)
  is_maglon = keyword_set(maglon) 
  
  ;Initialize the AACGM environment
  if is_maglat then begin
    sd_init
    ;aacgmloadcoef, 2005
  endif
  
  ;Obtain parts of the variable name
  prefix = strmid(vn, 0,7)  ;e.g., 'sd_hok_'
  suf = strmid(vn,0,1,/reverse) ; e.g., '0'
  azmno_vn = prefix+'azim_no_'+suf
  ptbl_vn = prefix+ 'position_tbl_'+suf
  ctbl_vn = prefix+ 'positioncnt_tbl_'+suf
  
  ;Get variable values
  get_timespan, tr ;Time range
  get_data, vn, data=d, lim=vn_lim
  vn_v = d.v &  vn_time = d.x 
  get_data, azmno_vn, data=d
  azmno = d.y
  get_data, ctbl_vn, data= d 
  lontbl = reform(d.y[0,*,*,0])
  lattbl = reform(d.y[0,*,*,1])
  
  scan_str = get_scan_struc_arr(vn)
  scant = scan_str.x
  scan = scan_str.y
  
  ;If maglat is set, use the AACGM lat table
  if is_maglat or is_maglon then begin
    glat = lattbl & glon = lontbl
    alt = glat & alt[*] = 400. ;[km]
    aacgmconvcoord, glat,glon,alt, mlat,mlon,err, /TO_AACGM
    if is_maglat then lattbl = mlat 
    if is_maglon then lontbl = (mlon+360.) mod 360 
  endif
  
  idx = where(      lattbl ge latrng[0] and lattbl le latrng[1] $
                and in_phirng( lontbl, lonrng ) )
  ;if idx[0] eq -1 then return, !values.f_nan
  
  val = fltarr(n_elements(scant))
  for i=0L, n_elements(scant)-1 do begin
    
    tmpscan = reform(scan[i,*,*])
    if idx[0] ne -1 then val[i] = mean( tmpscan[idx], /nan ) $
    else val[i] = !values.f_nan
    
  endfor
  
  ;Save as a tplot variable
  if keyword_set(new_vn) then begin
    if (size(new_vn))[1] eq 7 then begin
      store_data, new_vn, data={x:scant, y:val}, $
        lim={ytitle:vn_lim.ytitle, yrange:vn_lim.zrange, constant:0 }
    endif
  endif
  
  ;Return the data structure containing the average values
  return, {x:scant, y:val}
  

end
