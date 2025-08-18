;+
;PROCEDURE:   emm_emus_image_bar
;PURPOSE:
;  Creates tplot variables representing relevant attributes of the
;EMMEMUS disk images
;
;USAGE:
;  emm_emus_image_bar, trange = trange, disk = disk
;
;INPUTS:
;
;REQUIRED KEYWORDS:
;      trange:   time range for which image bars are requested
;        disk:   structure created by emm_emus_examine_disk. This
;saves time by not having to restore raw files

; OPTIONAL KEYWORDS:
;  ZRANGE: 2xN-element array of brightness ranges where N is the
;  number of wavelength bands in the disk structure
;  DAYSIDE: if brightness_range is not defined, then the brightness
;  ranges are set to examine dayside features. Otherwise aurora is
;  assumed to be the science target and brightness ranges are set appropriately.

pro emm_emus_image_bar, trange = trange, disk = disk, $
                        brightness_range = brightness_range, $
                        dayside = dayside

; first define the time interval for the tplot variables
  dt = 12                     ; 6 seconds is approximately the integration spacing for EMUS
  time_range = time_double (trange)
  t_total = time_double (time_range [1]) - time_double (time_range [0])
  nt = round (T_total/dt)
  time_range [1] = time_range [0] + dt*nt
  Times = array (time_range [0], time_range [1],nt)

  nb = n_elements (disk[0].bands)
  If not keyword_set (brightness_range) then brightness_range = fltarr(2, nb)
  zlog = bytarr(nb)
  ytitle = strarr (nb)
  ztitle = replicate ('Brightness, R', nb)
  brightness_color_table = bytarr(nb)
  tvar = strarr (nb); tplot variables
 
  nint = n_elements (disk [0].time)

  
; assign ytitles, tplot variable names, and color tables
  for j = 0, nb-1 do begin
     if disk [0].bands [j] eq 'O I 130.4 triplet' then begin
        ytitle[j] = 'O 130.4 nm'
        tvar[j] = 'emus_O_1304'
        brightness_color_table [j] =8
     endif else if disk[0].bands [j] eq 'O I 135.6 doublet' then begin
        ytitle[j] = 'O 135.6 nm'
        tvar [j] = 'emus_O_1356'
        brightness_color_table [j] = 3
     endif 
  endfor
  
; assign brightness ranges and logs
  if not keyword_set (dayside) then begin
     for j = 0, nb-1 do begin
        if disk [0].bands [j] eq 'O I 130.4 triplet' then begin
           if Brightness_range[0] eq 0.0 then brightness_range [*, j] = [2, 50]
           zlog [j] = 1
        endif else if disk[0].bands [j] eq 'O I 135.6 doublet' then begin
           if brightness_range [0] eq 0.0 then brightness_range [*, j] = [0, 10]
           zlog [j] = 0
        endif 
     endfor
  endif else  begin
     for j = 0, nb-1 do begin
        if disk [0].bands [j] eq 'O I 130.4 triplet' then begin
           if brightness_range [0] eq 0.0 then brightness_range [*, j] = [0, 400]
           zlog [j] = 0
        endif else if disk[0].bands [j] eq 'O I 135.6 doublet' then begin
           if brightness_range [0] eq 0.0 then brightness_range [*, j] = [0, 100]
           zlog [j] = 0
        endif 
     endfor
  endelse

  
  npix = n_elements (disk[0, 0].local_time[0,*, 0])
  

; fillable the arrays with nans
  LT_pixel = fltarr (nt, npix)*sqrt(-7.3)
  elon_pixel = LT_pixel
  lat_pixel = LT_pixel
  sza_pixel = LT_pixel
  br_pixel = LT_pixel
; the number of geometric tplot variables
  ng = 5

  nf = n_elements (disk)
  
  rad = fltarr (nt, npix, nb)

  for k = 0, nf-1 do begin
; find tplot times closest to EMUS integration times
     indices = value_locate (times, disk [k].time)
; To make sure no times are skipped (vertical gaps in tplot)
     ni = n_elements (indices)
; if there is no overlap between the times
     if total (indices) eq -1*ni then continue

     indices_full = min (indices) + lindgen (ni)
; assign values
     LT_pixel [indices,*] = disk [k].local_time[*,*, 0]
     Elon_pixel [indices,*] = disk [k].elon [*,*, 0]
     lat_pixel [indices,*] = disk [k].lat [*,*, 0]
     sza_pixel [indices,*] = disk [k].SZA [*,*, 0]
     br_pixel [indices,*] = disk [k].BR

     for j = 0, nb-1 do rad [indices,*, j] = disk [k].rad [*,*, j]     
; replace off disk pixels with nans
    
     for i = 0, nint-1 do begin 
        nodisk = where (reform (disk [k].mrh [i,*, 0]) gt 135.0)
        if nodisk[0] eq -1 then continue
        LT_pixel [Indices[i], nodisk] = sqrt (-7.2)
        elon_pixel [Indices[i], nodisk] = sqrt (-7.2)
        lat_pixel [Indices[i], nodisk] = sqrt (-7.2)
        sza_pixel [Indices[i], nodisk] = sqrt (-7.2)
        br_pixel [Indices[i], nodisk] = sqrt (-7.2)
       ; for j = 0, nb-1 do begin
       ;    tmp = rad [indices [i],*, j]
       ;    tmp[nodisk] =sqrt (-7.2)
       ;    rad [i,*, j] = tmp
        ;endfor
     endfor
    
  endfor

; append the array of tplot variable names
  tvar = ['emus_lt', 'emus_elon', 'emus_lat', 'emus_sza', 'emus_br',tvar]

; Vertical size of the panels
  Panel_size = [replicate (0.4, ng),replicate (0.7,nb)]

; append the array of ztitles and ytitles
  ytitle = 'EMUS!c' +['Local!cTime', 'Long!citude', 'Latitude', 'SZA', 'Br(400km)',ytitle]
  ztitle = ['hours', replicate ('degrees', 3), 'nT',ztitle]

; create the tplot variables for geometry
  store_data, 'emus_lt', data = {x: times, v:indgen (npix), $
                                 y: LT_pixel}
  store_data, 'emus_elon', data = {x: times, v:indgen (npix), $
                                   y: elon_pixel}
  store_data, 'emus_lat', data = {x: times, v:indgen (npix), $
                                  y: lat_pixel}
  store_data, 'emus_sza', data = {x: times, v:indgen (npix), $
                                  y: sza_pixel}
  store_data, 'emus_br',data = {x: times, v:indgen (npix), $
                                  y: br_pixel}
  for j = 0, nb-1 do Store_data, tvar[ng+ j], $
                                 data = {x: times,v:indgen (npix), $
                                         y: reform (rad[*,*, J])}

; append the array of zranges and zlogs
  zrange = [[0, 24], [0, 360], [-90, 90], [0, 180], [-50, 50],[brightness_range]]
  zlog= [0, 0, 0, 0, 0,zlog]
  color_table = [16, 70, 72, 65, 70, brightness_color_table]
  
; find out which along-slit pixels are used
  good = where (finite (disk [0].elon [25,*, 0]))

  for k = 0, ng+nb-1 do begin
     bname = tvar[k]
     ylim,bname,min(good), max (good), 0
     zlim,bname,zrange[0, k], zrange [1, k],zlog[k] ; optimized for color table 43
     options, bname, 'color_table', color_table [k]
     options,bname,'spec',1
     options,bname,'panel_size',panel_size [k]
     options,bname,'ztitle', Ztitle [k]
     options, bname, 'ytitle', ytitle [k]
     options,bname,'yticks',1
     options, bname, 'zticks', 4

     options,bname,'yminor',1
     options,bname,'no_interp',1
     options,bname,'xstyle',1
     options,bname,'ystyle',1
  endfor
  tplot_options, 'bottom', 7
  tplot_options, 'top', 254

  return

end
