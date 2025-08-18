PRO overlay_map_precal_sdfov, site=site, geo_plot=geo_plot, nh=nh, sh=sh, $
  linethick=linethick, $
  fill=fill, $
  color=color, $
  force_nhemis=force_nhemis 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  nh_list = strsplit('bks cve cvw ekb fhe fhw gbr han hok hkw inv kap kod ksr lyr pgr pyk rkn sas sto wal ade adw', /ext )
  sh_list = strsplit('bpk dce fir hal ker mcm san sps sye sys tig unw zho', /ext )
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;Check the keywords and generate the station list to be plotted
  stns = ''
  if keyword_set(nh) then append_array, stns, nh_list
  if keyword_set(sh) then append_array, stns, sh_list
  if keyword_set(site) then append_array, stns, strsplit(site, /ext) 
  if stns[0] eq '' then return
  print, stns 
  
  if ~keyword_set(color) then color = 0 ;default color
  
  
  ;Initialize !sdarn system variable
  sd_init
  
  ;Prepare for AACGM conversion
  if ~keyword_set(geo_plot) then begin
    ts = time_struct( !map2d.time)
    yrsec = long( (ts.doy-1)*86400L + ts.sod )
    aacgmloadcoef, ts.year 
  endif
  
  ;Obtain the directory path where overlay_map_precal_sdfov.pro and save files are located.
  stack = SCOPE_TRACEBACK(/structure)
  filename = stack[SCOPE_LEVEL()-1].filename
  dir = FILE_DIRNAME(filename)
  
  for i=0, n_elements(stns)-1 do begin
    
    stn = stns[i]
    tblfn = dir +'/sdfovtbl_'+stn+'.sav
    if ~file_test(tblfn) then continue
    restore, tblfn 
    
    bm = n_elements( sdfovtbl.glat[*,0] )-1
    rg = n_elements( sdfovtbl.glat[0,*] )-1
    
    glats = [ sdfovtbl.glat[0:bm,0], reform(sdfovtbl.glat[bm,0:rg]), $
      reverse(sdfovtbl.glat[0:bm,rg]), reverse(reform(sdfovtbl.glat[0,0:rg])) ]
    glons = [ sdfovtbl.glon[0:bm,0], reform(sdfovtbl.glon[bm,0:rg]), $
      reverse(sdfovtbl.glon[0:bm,rg]), reverse(reform(sdfovtbl.glon[0,0:rg])) ]
    
    if keyword_set(geo_plot) or !map2d.coord eq 0 then begin
      lats = glats & lons = glons 
    endif else begin
      ;AACGM conversion
      alt = glats & alt[*] = 400. ;[km]
      aacgmconvcoord, glats,glons,alt, mlats,mlons, err, /TO_AACGM
      years = long( glats ) & years[*] = ts.year 
      yrsecs = long( glats) & yrsecs[*] = yrsec
      mlts = aacgmmlt( years, yrsecs,  (mlons+360.) mod 360  )
      
      ;Project the fov to the northern hemisphere if force_nhemis is set.
      if keyword_set(force_nhemis) then mlats = abs( mlats ) 
       
      lats = mlats & lons = mlts /24. * 360.
    endelse
    
    ;Draw the f-o-v with the color given by "color" keyword
    plots, lons, lats, color=color, thick=linethick
    ;Fill the f-o-v with the color given by "color" keyword
    if keyword_set(fill) then polyfill, lons, lats, color=color
    
    
  endfor
  
   
  
  return
end
