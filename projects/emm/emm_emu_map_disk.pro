; This routine takes as input a structure or array of structures (each
; element of the array corresponds to a single swath), with the
; following tags, where:
;            nint: number of integrations
;            npix: number of pixels along the slit
;            nc:   number of pixel corners plus center (5)
;            nb  : number of emission features
 
;             date_String: any date string for the name of the output
;             file

;             time:   1D array of UNIX times (nint)
;             elon:   2D array of longitudes (nint,npix, nc)
;             lat:    2D array of latitudes (nint,npix, nc)
;             bands:  1D array of emission features (nb)
;             Rad:    3D array of Radiances (nint,npix, nb)
;             sc_alt: 1D array of spacecraft altitudes (nint)
;            elon_ssc:1D array of spacecraft altitudes (nint)
;             lat_ssc:1D array of spacecraft altitudes (nint)
            

; The "other" keyword is meant to be the name of a tag in the disk
; structure with the same dimensions as radiance that we want to plot
; the same way.

; the 'stitch' keyword is used if we want to tie together the swaths
; into a combined image


pro emm_emu_map_disk, disk, bands_wanted = bands_wanted, zrange = zrange, zlog = zlog, $
                       Color_Table = Color_table, mode = mode, no_crustal = no_crustal,$
                       ztitle = ztitle, other = other,no_grid= no_grid, $
                       satellite = satellite, hammer = hammer, cylindrical = cylindrical,$
                       output_directory = output_directory,  jpeg = jpeg, $
                       zticks = zticks, retrieval = retrieval,$
                      nxmap = nxmap, nymap = nymap, stitch = stitch,$
                      mean_brightness_map = mean_brightness_map, $
                      stitched_brightness_map = stitched_brightness_map
                      

  If not keyword_set (output_directory) then output_directory = $
     '~/work/emm/emus/data/aurora_figures/'
     



  if keyword_set (other) then begin
     names = tag_names (disk)
     yes = Where (names eq other)
  endif

  If keyword_set (retrieval) then begin
     names = tag_names (disk)
     yes = where (names eq 'COLDEN')
  endif

; bands_wanted is an array of indices for the bands we want
  if not keyword_set (bands_wanted) then bw = $
     indgen (n_elements (disk [0].bands)) else bw = $
     bands_wanted
  nb= n_elements (bw)

   if not keyword_set (zlog) then zlog = intarr (nb)

   If not keyword_set (mode) then mode = replicate ('',nb)
  !p.multi = 0
  if not keyword_set (color_table) then Color_Table = replicate (8, nb)

 
  if not keyword_set (zrange) then begin
     zrange = fltarr(2, nb)
     for k = 0, nb-1 do zrange [*, k] = minmax (disk.rad[*,*, k])
  endif

  if not keyword_set(zticks) then zticks = 6
; number of images
  n_images = n_elements (disk)

  r_planet = 3396d0 + 150.0

  if not keyword_set (nxmap) then begin
     if keyword_set (satellite) then begin
        nxmap=800               ;1200
        nymap=800               ;600
     endif else if keyword_set (hammer) then begin
        nxmap=1100
        nymap=550
     endif else if keyword_set (cylindrical) then begin
        nxmap = 720
        nymap = 360
     endif
  endif
  if not keyword_set (ztitle) then ztitle = disk[0].bands [bw]+', R'
  if n_elements (ztitle) ne nb then ztitle = replicate (ztitle [0],nb)

  if n_finite (disk.lat) lt 10 then return
  

; this catches the unusual situation where the first "good"
; integration, i.e. within the time bounds, is actually not the first
; swath

  nint = n_elements (where (disk[0].time gt 1e9))
  if nint eq 1 then begin
     nint = n_elements (where (disk[1].time gt 1e9))
     if  nint eq 1 then nint = n_elements (where (disk[2].time gt 1e9))
  endif
  
 ; this stores an image shaded by the spatial index of each pixel; 0 used to mean no contribution
  spatial_map = make_array(nxmap,nymap,nint,n_images,value=0,/byte)
 ; stores images of brightness for each integration
  brightness_map = make_array(nb,nxmap,nymap,nint,n_images,value=!values.f_nan)
; Mean brightness combining all integrations together in each swath
  mean_brightness_map = make_array (nb,nxmap,nymap,n_images,value=!values.f_nan) 
; Mean brightness combining all integrations and all swaths
  stitched_brightness_map= make_array (nb,nxmap,nymap,value=!values.f_nan) 
;n_contribute is a two dimensional array of the number of integrations
;contributing to that pixel


  n_contribute = intarr(nxmap,nymap, n_images)

;,scale=20e6/asin(r_mars/norm(r));
  ;  plot, [0],[0],/nodata,xr=[0,360],yr=[-90,90],xstyle=4,ystyle=4,xmargin=[0,0],ymargin=[0,0],/isotropic
  ;  plot, [0],[0],/nodata,xr=[0,360],yr=[-90,90],xmargin=[0,0],ymargin=[0,0],/isotropic
  npix = n_elements (disk[0].Local_time[0,*])
  x = make_array(4,/double)
  y = make_array(4,/double)
  
  swath_Count = 0
  for l= 0,n_images -1 do begin
     if n_finite (disk[l].elon) eq 0 then continue
     swath_count++
     set_plot,'Z'
     device,dec=0
     Device, Set_Resolution=[nxmap,nymap], Z_Buffer=0, set_pixel_depth=8
     loadct,0

     If keyword_set (satellite) then begin
        map_set, /satellite, $
                 sat_p=[(disk[0].SC_ALT[nint/2]+r_planet)/r_planet, 0.0, 0.0], $
                 disk[0].lat_ssc[nint/2], disk[0].elon_ssc[nint/2],/isotropic,/noborder, $
                 xmargin = 0, ymargin = 0
     endif else if keyword_set (hammer) then begin
        map_set, 0, 180.0, 0,/Hammer,/grid,/isotropic, $
                 xmargin = 0, ymargin = 0,/horizon
     endif else if keyword_set (cylindrical) then begin
; need to offset the center of the cylindrical map
        Offset_elon = round(disk[l].elon_ssc[nint/2])
        map_set, 0, offset_Elon, 0,/cylindrical, /isotropic, $
                 xmargin = [0, 0], ymargin = 0
     endif


     for i = 0, nint-1 do begin       ; iterate over integrations
        for j = 0, npix-1 do begin   ; iterate over spatial elements
           ;if Total (disk[L].mrh [i, j,*]) gt 651 then continue
           
           x = reform (disk [l].Elon [i, j, 1:4])
           y = reform (disk [l].lat [i, j, 1:4])
           if ~x.isFinite() or abs(mean(y)) gt 88 then continue 
           polyfill, x,y, color= j ; solid fill polygon
                         ;    wait, 0.15 & $
        endfor
        empty                   ; make sure everything got drawn for this integration
        spatial_map[*,*,i, l] = tvrd() ; copy the image from the z-buffer over to storage array
        erase            ; clear the image of this integration so we can make the next one
        
;this is the contribution to all spots on the map from this particular
;integration.
        
        if keyword_set (other) or Keyword_set (retrieval) then begin           
           for k = 0,nb -1 do brightness_map[k,*,*,i, l] = $
              disk[l].(yes) [i,spatial_map [*,*, i, l], bw[k]]
        endif else begin
           for k = 0,nb -1 do brightness_map[k,*,*,i, l] = $
              disk[l].rad [i,spatial_map [*,*, i, l], bw[k]]
        endelse
     endfor
     print,l
; find out how many integrations have nonzero contributions to each
; pixel of the output image (not EMUS pixel)      
     temp = (reform (spatial_map [*,*,*, l]) gt 0)
     
;n_contribute is a two dimensional array of the number of integrations
;contributing to that pixels
     
     n_contribute[*,*, l] = total (temp, 3)

     ; explicitly make NaN any pixel with n_contribute = 0
     bad = where (n_contribute[*,*, l] eq 0)
     if bad [0] eq -1 then stop

; add up the contributions from all of the integrations for just this
; swath
     for k = 0,nb -1 do begin
        mean_brightness_map[k,*,*,l] = $
           total (reform(brightness_map[k,*,*,*,l],$
                         nxmap,nymap,nint),3,/nan)/$
           reform (n_contribute [*,*, l])
       
        temp = reform (mean_brightness_map [k,*,*, l])
        temp [bad] = sqrt( -3.2)
        Mean_brightness_map [k,*,*, l] = temp
        

; now must undo the offset that was necessary for the map projection
        if keyword_set (cylindrical) then shift = offset_Elon -180 else $
           shift = 0
        new_indices = (indgen (nxmap) + shift + nxmap) mod nxmap
        temp = Reform (mean_brightness_map [k,*,*, l])
        Temp [new_indices,*] = mean_brightness_map [k,*,*, l]
        mean_brightness_map [k,*,*, l] = temp
; make an image for just this swath
        set_plot,'X'
       
        if keyword_set (jpeg) then begin
; this is diagnostic
           if 2 eq 5 then begin
              !p.multi = [0, 1, 2]
              
              loadct2, 33
              elon_array = array (0.5, 359.5, 360)
              lat_array = array (-89.5, 89.5, 180)
              
              Specmap,elon_array, lat_array, reform (mean_brightness_map [0,*,*, l]), limit = $
                      {no_interp: 1, zrange: [2, 50], zlog: 1}
              Specmap,elon_array, lat_array, reform (n_contribute [*,*, l]), limit = $
                      {no_interp: 1, zrange: [0, 20], zlog: 0}
              
              i=10
              scatter_specmap,disk [0, L].elon [*,*, 0], disk [0, L].lat [*,*, 0], $
                              disk [0, L].rad [*,*, k], zlog = 0, zrange = [2, 50], $
                              PSY = 3

                specmap,elon_array, lat_array, reform (spatial_map [*,*, i, L]), limit = $
                         {no_interp: 1, zrange: [2, 50], zlog: 1, $
                         title:  'i = '+ roundst(i)} & $
                
              
              for i = 1, nint-1 do begin & $
                 specmap,elon_array, lat_array, reform (brightness_map [0,*,*, i, l]), limit = $
                         {no_interp: 1, zrange: [2, 50], zlog: 1, $
                         title:  'i = '+ roundst(i)} & $
                        specmap,elon_array, lat_array, $
                         total(reform(brightness_map[k,*,*,0:i,l],$
                                      nxmap,nymap,i+1),3,/nan),limit = $
                         {no_interp: 1, zrange: [2, 50], zlog: 1}& $             
                 wait, 0.15 & $
              endfor
           endif
           
           
           
           device,dec=0
           
           if color_table [k] lt 75 then begin
              loadct, color_table[k] 
              if color_table [k] eq 12 then generate_custom_color_table, 12
           endif else begin
              loadcsvcolorbar, color_table[k], /noqual
           endelse

           window,xs=nxmap,ys=nymap,retain=2
                                ;  tvscl,mean_brightness_map,/nan
           If keyword_set (satellite) then begin
              map_set, /satellite, $
                       sat_p=[(disk[0].SC_ALT[nint/2]+r_planet)/r_planet, 0.0, 0.0], $
                       disk[0].lat_ssc[nint/2], disk[0].elon_ssc[nint/2],$
                       /isotropic,/noborder, $
                       xmargin = 0, ymargin = 0
           endif else if keyword_set (hammer) then begin
              map_set,0, 180.0, 0, /Hammer,/grid,/isotropic, $
                      xmargin = 0, ymargin = 0,/horizon
           endif else if keyword_set (cylindrical) then begin
              map_set, 0, offset_Elon,/cylindrical,/grid,/isotropic, $
                       xmargin = 0, ymargin = 0
           endif

           if keyword_set (zlog) then begin
              if zlog[k] then begin
                 draw = alog10 (reform (mean_brightness_map[k,*,*,l])) 
                 low = alog10(zrange [0, k])
                 hi = alog10 (zrange [1, k])
              endif else begin
                 draw =reform (mean_brightness_map[k,*,*,l])
                 low = zrange [0, k]
                 hi = zrange [1, k]
              endelse
           endif  else begin
              draw =reform (mean_brightness_map[k,*,*,l])
              low = zrange [0, k]
              hi = zrange [1, k]
           endelse
           
; All exact zeros result only from NaNs. set all zeros to NaNs
           
           zero = where(draw eq 0.00)
           if zero[0] ne -1 then draw[zero] = sqrt(-5.5)
           
           tv,bytscl(draw,min=low, max=hi,/nan)
           
           loadct2,0
                                ;stop
           If not keyword_set (no_grid) then fixed_map_grid,glinestyle=0,glinethick=1,$
              color=155,latdel=30.,increment=1.0,/horizon,/label,charsize=2, $
              lons = array (0, 360, 13), $
              lonnames = roundst(array (0, 360, 13))

; ad magnetic field contours
           if not keyword_set (no_crustal) then draw_crustal_fields_on_map,/BR, $
              altitud = 400, contours = [-20,-10, 10, 20], $
              Color_table = 34, color_positive = 1, Color_negative = 3, $
              /no_label, thick = 0.6

           if color_table [k] lt 75 then begin
              loadct, color_table[k] 
              if color_table [k] eq 12 then generate_custom_color_table, 12
           endif else begin
              loadcsvcolorbar, color_table[k], /noqual
           endelse
           
           
           final_image =tvrd(/true)
           pixpos = $
              round(convert_coord(!x.window, !y.window, $
                                  /norm, /to_device))
           npx = pixpos(0, 1)-pixpos(0, 0)
           npy = pixpos(1, 1)-pixpos(1, 0)
           xposition = pixpos(0, 0)
           yposition = pixpos(1, 0)
           
           wdelete, 0
           window,1, xs = npx*1.33, ys = npy
;        mywin, x = npx*1.33, y = npy, window_ID = 1
           
           if color_table [k] lt 75 then begin
              loadct, color_table[k] 
              if color_table [k] eq 12 then generate_custom_color_table, 12
           endif else begin
              loadcsvcolorbar, color_table[k], /noqual
           endelse
           
           
           tv, final_image, true = 1
; record the time on the image
           xyouts, nxmap*1.05, nymap*0.95, align= 1.0,$
                   time_string (disk[l].time[0],tformat = 'YYYY-MM-DD/hh:mm'), $
                   charsize = 2.6,/device
; record the spacecraft solar zenith angle on the image
           sc_sza = sza(disk [l].SC_POS [0, 10], disk [l].SC_POS [1, 10],$
                        disk [l].SC_POS [2, 10])
           xyouts, nxmap*1.05, nymap*0.88, align= 1.0,$
                   'SC SZA: '+roundst(sc_sza, dec = -1), $
                   charsize = 2.6,/device
; record the spacecraft local time on the image
           mso2lt, disk [l].SC_POS [0, 10], disk [l].SC_POS [1, 10],$
                   disk [l].SC_POS [2, 10], disk[l].latss[0], slt
           xyouts, nxmap*1.05, nymap*0.81, align= 1.0,$
                   'SC LT: '+roundst(slt, dec = -1), $
                   charsize = 2.6,/device

           
           if keyword_set (satellite) then begin
              projection = 'sat'
              pos = [0.83, 0.02, 0.87, 0.98]
           endif else if keyword_set (hammer) then begin
              projection = 'hammer'
              pos = [0.83, 0.02, 0.87, 0.98]
           endif else if keyword_set (cylindrical) then begin
              projection = 'cylindrical'
              pos = [0.86, 0.02, 0.90, 0.98]
           endif
           draw_color_scale, range = zrange[*,k], brange = [0, 255], $
                             pos = [0.83, 0.02, 0.87, 0.98], $
                             yticks = zticks, $
                             title = ztitle [k], charsize = 2.7, $
                             charthick = 2, log = zlog[k]

           if keyword_set (no_crustal) then CF = 'no_cf' else CF = ''

; here we deal with  how to convert the string describing the fitted
; emission to something that can go into the file name without causing errors
           bits = strsplit (disk[l].bands [bw[k]],/extract)
           nbits =n_elements (bits)
           band_string = ''
           if bits [-1] eq 'singlet' or $
              bits [-1] eq 'doublet' or $
              Bits [-1] eq 'triplet' or $
              bits [-1] eq 'multiplet' then begin
; we don't need the additional letter specifying whether it's a
; singlet, doublet, triplet, multiplet, so omit those
              for i = 0, nbits-2 do band_string = band_string+ bits [i]
           endif else if bits [-2] eq '+' then begin
; can't have any plus signs in the string
              for i = 0, nbits-3 do band_string = band_string+ bits [i]
           endif else begin
              for i = 0, nbits-1 do band_string = band_string+ bits [i]
           endelse
           if keyword_set (retrieval) then band_string = disk [0].colden_string [bw [k]]
           date_string =  disk [l].date_string
           ct = roundst(color_table [k])
           filename = output_directory + projection + '_' +$
                                                band_string + '_ct'+ct+'_' +$
                                                date_string + '_' +mode[l] +$
                                                CF +'.jpg'
           if keyword_set (jpeg) then make_JPEG,filename
           
        endif
     endfor
  endfor
  
;==================================================
; We've made individual swaths.  Now tie them all together.

  if swath_count gt 1 and keyword_set (stitch) then begin
     print, 'Averaging overlapping integrations...'
; need to figure out how many integrations are contributing to each
; pixel of our image    
     for K = 0, nb-1 do begin
        stitched_brightness_map[k,*,*] = mean (reform (Mean_brightness_map [k,*,*,*]),$
                                               dim = 3,/nan)
        if not keyword_set (JPEG) then continue
        set_plot,'X'
        
        device,dec=0
          if color_table [k] lt 75 then begin
           loadct, color_table[k] 
           if color_table [k] eq 12 then generate_custom_color_table, 12
        endif else begin
           loadcsvcolorbar, color_table[k], /noqual
        endelse
   
        window,xs=nxmap,ys=nymap,retain=2

        If keyword_set (satellite) then begin
           map_set, /satellite, $
                    sat_p=[(disk[0].SC_ALT[nint/2]+r_planet)/r_planet, 0.0, 0.0], $
                    disk[0].lat_ssc[nint/2], disk[0].elon_ssc[nint/2],$
                    /isotropic,/noborder, $
                    xmargin = 0, ymargin = 0
        endif else if keyword_set (hammer) then begin
           map_set, 0, 180.0, 0,/Hammer,/grid,/isotropic, $
                    xmargin = 0, ymargin = 0,/horizon
        endif else if keyword_set (cylindrical) then begin
           Offset_elon = round(mean(disk.elon_ssc[nint/2], /nan))
        
           map_set, 0, 180.0, 0,/cylindrical,/grid,/isotropic, $
                    xmargin = 0, ymargin = 0
        endif

        if zlog [k] then begin
           draw = alog10 (reform (stitched_brightness_map[k,*,*])) 
           low = alog10(zrange [0, k])
           hi = alog10 (zrange [1, k])
        endif else begin
           draw =reform ( stitched_brightness_map[k,*,*])
           low = zrange [0, k]
           hi = zrange [1, k]
        endelse
        zero = where(draw eq 0.00)
        if zero[0] ne -1 then draw[zero] = sqrt(-5.5)
        
       
        tv,bytscl(draw,min=low, max=hi,/nan)

        loadct2,0
        If not keyword_set (no_grid) then fixed_map_grid,glinestyle=0,glinethick=1,$
           color=155,londel=30.,latdel=30.,increment=1.0,/horizon,/label,charsize=2



; ad magnetic field contours
        loadct2, 0
        if not keyword_set (no_crustal) then draw_crustal_fields_on_map,/BR, $
           altitud = 400, contours = [-20,-10, 10, 20], $
           Color_table = 34, color_positive = 1, Color_negative = 3, $
           /no_label, thick = 0.6

        final_image =tvrd(/true)
        pixpos = $
           round(convert_coord(!x.window, !y.window, $
                               /norm, /to_device))
        npx = pixpos(0, 1)-pixpos(0, 0)
        npy = pixpos(1, 1)-pixpos(1, 0)
        xposition = pixpos(0, 0)
        yposition = pixpos(1, 0)
        
        wdelete, 0
         window,1, xs = npx*1.33, ys = npy
;        mywin, x = npx*1.33, y = npy, window_ID = 1

        tv, final_image, true = 1
        xyouts, nxmap*1.05, nymap*0.95, align= 1.0,time_string (disk[0].time[0],tformat = $
                                                                    'YYYY-MM-DD/hh:mm'), $
                charsize = 2.6,/device


          if color_table [k] lt 75 then begin
           loadct, color_table[k] 
           if color_table [k] eq 12 then generate_custom_color_table, 12
        endif else begin
           loadcsvcolorbar, color_table[k], /noqual
        endelse
     
    
        draw_color_scale, range = zrange[*,k], brange = [0, 255], $
                          pos = [0.83, 0.02, 0.87, 0.98], $
                          yticks = zticks, $
                          title = ztitle [k], charsize = 2.6, $
                          charthick = 2, log = zlog[k]
          if keyword_set (no_crustal) then CF = 'no_cf' else CF = ''
; here we deal with  how to convert the string describing the fitted
; emission to something that can go into the file name without causing errors
           bits = strsplit (disk[l].bands [bw[k]],/extract)
           nbits =n_elements (bits)
           band_string = ''
           if bits [-1] eq 'singlet' or $
              bits [-1] eq 'doublet' or $
              Bits [-1] eq 'triplet' or $
              bits [-1] eq 'multiplet' then begin
; we don't need the additional letter specifying whether it's a
; singlet, doublet, triplet, multiplet, so omit those
              for i = 0, nbits-2 do band_string = band_string+ bits [i]
           endif else if bits [-2] eq '+' then begin
; can't have any plus signs in the string
              for i = 0, nbits-3 do band_string = band_string+ bits [i]
           endif else begin
              for i = 0, nbits-1 do band_string = band_string+ bits [i]
           endelse
 
         if keyword_set (retrieval) then band_string = disk [0].colden_string [bw [k]]

        date_string =  disk [0].date_string
        
        ct = roundst(color_table [k])
        if keyword_set (satellite) then projection = 'Sat'
        if keyword_set (hammer) then projection = 'hammer'
        if keyword_set (cylindrical) then projection = 'cylindrical'
        ;if l ge n_elements(mode) then stop
        if keyword_set (jpeg) then make_JPEG,output_directory + 'Stitched' + $
                                             projection + '_' +$
                                             band_string + '_ct'+ct+'_' +$
                                             date_string + '_' +mode[0] +$
                                             CF +'.jpg'
     endfor          
  endif


  
end
