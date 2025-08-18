; the purpose of this procedure is to take the various data structures
; contained within the l2a, l2b and l3 files, and bin them in
; integration, in pixel, or both.

pro emm_emus_binning,  FOV_geom, SC_geom, tim, emiss, cal, FOV_binned, SC_binned, Tim_binned, emiss_binned, cal_binned,$
                       binning_int = binning_int, binning_pix = binning_pix, wv_range = wv_range
  
  
  dims =size (emiss [0].radiance,/dimensions)
  nint_native = dims [0]
  npix_native = dims [1]

  
  if nint_native eq 0 then begin
     print, 'No valid data'
     return
  endif
  
  nc = 5                        ; number of corners
  
;===============================================
; BINNING FACTOR.  if this keyword has been set, then we need to
; create a new version of emiss with this binning
  If not keyword_set (binning_int) then binning_int = 1
  if not keyword_set (binning_pix) then binning_pix = 1

  nint_em = ceil(nint_native/binning_int)
  npix_em = ceil(npix_native/binning_pix)
  n_emissions = n_elements (emiss)


  nwv = n_elements (cal [0].radiance [*, 0])

  if binning_int le 1 and binning_pix le 1 then  begin
     print, 'No binning at all requested.  Returning same structures.'
     FOV_binned = FOV_geom
     SC_binned = SC_geom
     Tim_binned = Tim
     emiss_binned = emiss
     cal_binned = cal
     return
  endif else begin
     
     print, ' Creating binned geometry & radiance: '
     before = systime (/seconds)

; how much padding do we need if nint_native is not an integer
; multiple of binning_int?
     Padding_INT =  (nint_em)*binning_int - nint_native

; similarly for the pixel direction
     padding_pix = (npix_em)*binning_pix - npix_native

     emiss_binned = {name: '', $
                     wl_start: fltarr (2), wl_stop: fltarr (2),dof:bytarr(2), $
                     radiance: fltarr (nint_em, npix_em), $
                     rad_err_rand: fltarr (nint_em, npix_em), $
                     rad_err_sys: fltarr (nint_em, npix_em), $
                     counts: fltarr(nint_em, npix_em), $
                     goodness_of_fit: fltarr (nint_em, npix_em), $
                     qlty_flg: bytarr (nint_em, npix_em)}

; initialize the binned calibrated radiance structure to its
; non-binned version
     cal_binned = cal
     caltags = 7; the number of tags with npix x nwv elements

; replicated across all the emissions
     emiss_binned = replicate (emiss_binned,n_emissions)
; copy over these tags
     emiss_binned.name = emiss.name
     emiss_binned.wl_start = emiss.WL_start
     emiss_binned.wl_stop = emiss.WL_stop
     emiss_binned.dof = emiss.dof

     FOV_names = tag_names (FOV_geom)
     SC_names= tag_names (SC_geom)

;==========================================================
; now make binned versionsof the SC and FOV geometry structures

; make a fov structure where the first 10 tags are the same
     FOV_binned = {vx_instr_Mars: fltarr(3)}
     if n_elements (FOV_names) ne 24 then message, $
        'FOV_geom has changed structure. Need to redo this code!'
     for k = 1, 10-1 do FOV_binned = $
        create_struct (FOV_binned,FOV_names[k],FOV_geom [0].(k))

; Now append arrays with the right number of elements including the
; padding
     for k = 10, 11 do FOV_binned = $
        create_struct (FOV_binned, FOV_names[k],fltarr (npix_em,5, 3))
     for k = 12, 23 do FOV_binned = $
        create_struct (FOV_binned, FOV_names[k],fltarr (npix_em,5))
     
;now make it an array of structures
     FOV_binned = replicate (FOV_binned, nint_em)

     SC_binned = replicate (SC_geom[0], nint_em)

     Tim_binned = replicate (Tim [0], nint_EM)

; we need the counts to correctly calculate the error in the  binned
; values
     Counts_emiss = (emiss.radiance/emiss.rad_err_rand)^2
     
; the conversion factor between counts and  brightness
     Flux_factor_emiss = emiss.radiance/counts_emiss

                                ; now do the binning.
; first loop over the integrations
     for i = 0, nint_em-1 do begin
; these are the native indices for this bin
        indices_int = binning_int*i+indgen(binning_int)
; need to trim down the array of native integration indices if it
; would run off the end of the native integrations  array
        if i eq nint_em -1 and padding_int ge 1 then indices_int = $
           indices_int [0:padding_int-1]
; enter the quantity that have only one value or vector per integration
        for k = 0, 4 do SC_binned [i].(k) = mean (SC_geom[indices_int].(k))
        for k = 5, n_tags (SC_geometry)-1 do SC_binned [i].(k) = $
           mean (SC_geom[indices_int].(k),dim = 2)
        for k = 0, 8 do FOV_binned [i].(k) = mean (FOV_geom[indices_int].(k), dim = 2)
        for k = 9, 9 do FOV_binned [i].(k) = mean (FOV_geom[indices_int].(k))
        tim_binned [i].time_ET = mean (Tim [indices_int].time_ET)
        Tim_binned [i].time_UTC = $
           time_string (Mean (time_double (Tim [indices_int].time_UTC)),tformat = $
                        'YYYY-MM-DDThh:mm:ss.fff')
; now loop over the pixels along the slit
        for j = 0, npix_em-1 do begin
; these are the native indices for this bin
           indices_pix = binning_pix*j + indgen (binning_pix)
; similarly, need to trim down the array of native pixel indices if it
; would run off the end of the  native pixel array
           if j eq npix_em -1 and padding_pix ge 1 then indices_pix = $
              indices_pix [0:padding_pix -1]

;now filling the geometry that depend on pixel corners.
; first the two tags (VEC_MSO and VEC_Mars) that are vectors
           
           for k = 10, 11 do begin 
; first do the pixel centers
              FOV_binned [i].(k)[j,0,*] = $
                 mean (mean (FOV_geom [indices_int].(k)[indices_pix, 0,*], $
                             dim = 4), dim = 1)
; then the lower left corner
              FOV_binned [i].(k)[j,1,*] = $
                 FOV_geom [indices_int[0]].(k)[indices_pix[0], 1,*]
; then the lower right corner
              FOV_binned [i].(k)[j,2,*] = $
                 FOV_geom [indices_int[-1]].(k)[indices_pix[0], 2,*]
; then the upper right corner
              FOV_binned [i].(k)[j,3,*] = $
                 FOV_geom [indices_int[-1]].(k)[indices_pix[-1], 3,*]
; than the upper left corner
              FOV_binned [i].(k)[j,4,*] = $
                 FOV_geom [indices_int[0]].(k)[indices_pix[-1], 4,*]
           endfor
;then the remainder of the tags that are single values
           for k = 12, n_tags (FOV_geom)-1 do begin
; first do the pixel centers
              FOV_binned [i].(k)[j,0] = $
                 mean (FOV_geom [indices_int].(k)[indices_pix, 0])
; then the lower left corner
              FOV_binned [i].(k)[j,1] = $
                 FOV_geom [indices_int[0]].(k)[indices_pix[0], 1]
; then the lower right corner
              FOV_binned [i].(k)[j,2] = $
                 FOV_geom [indices_int[-1]].(k)[indices_pix[0], 2]
; then the upper right corner
              FOV_binned [i].(k)[j,3] = $
                 FOV_geom [indices_int[-1]].(k)[indices_pix[-1], 3]
; then the upper left corner
              FOV_binned [i].(k)[j,4] = $
                 FOV_geom [indices_int[0]].(k)[indices_pix[-1], 4]
           endfor
           
; now make sure that the cyclical quantities are averaged correctly
                                ;if finite (total (FOV_geom[indices_int].local_time [indices_pix, 0])) ne 0 then stop
;           FOV_binned [i].ra =  mean_wrap (FOV_geom[indices_int].RA [indices_pix, 0], border = 360.0)
;           FOV_binned [i].lon =  mean_wrap (FOV_geom[indices_int].lon [indices_pix, 0], border = 360.0)
;           FOV_binned [i].local_time =  mean_wrap (FOV_geom[indices_int].local_time [indices_pix, 0], $
;                                                   border = 24.0)

; loops through each wavelength
           for K = 0, nwv-1 do begin
              cal_binned[i].rad_err_sys[k,j] = $
                 mean(cal[indices_int[0]: indices_int [-1]].rad_err_sys[k,indices_pix[0]: indices_pix [-1]],/nan)
              cal_binned [i].corrected_cnts[k, j] = $
                 total(cal[indices_int[0]: indices_int [-1]].corrected_cnts[k,indices_pix[0]: indices_pix [-1]],/nan)
              sat = weighted_Mean (cal[indices_int[0]: indices_int [-1]].radiance [k,indices_pix[0]: indices_pix [-1]], $
                                   cal[indices_int[0]: indices_int [-1]].rad_err_rand [k,indices_pix[0]: indices_pix [-1]])
              cal_binned [i].radiance [k, j] = sat [0]
              cal_binned [i].rad_err_rand [k, j] = sat [1]
           endfor
              

; now loop through each of the emissions
           for k = 0, n_emissions-1 do begin  
; Assume the systematic error in the binned brightness is just the
; average of the systematic errors for each of the pixels within it
              emiss_binned [k].rad_err_sys [i, j] = $
                 mean (emiss[k].rad_err_sys [indices_int[0]: indices_int [-1], $
                                             indices_pix[0]: indices_pix [-1]],/nan)
; sum up the counts in each of the pixels within the bin
              emiss_Binned [k].counts [i, j] = $
                 total (counts_emiss[indices_int[0]: indices_int [-1], $
                               indices_pix[0]: indices_pix [-1], k], /nan)
; calculate the average flux conversion factor for this bin
;              average_flux_factor_emiss =  $
;                 mean (flux_factor_emiss[indices_int[0]: indices_int [-1], $
;                                   indices_pix[0]: indices_pix [-1], k],/nan)

; calculate the binned radiance by multiplying the number of counts by
; the conversion factor between counts and brightness
                                ;       emiss_binned [k].radiance [i, j] = $
                                ;          emiss_Binned [k].counts [i, j]*average_flux_factor_emiss
; calculate a weighted mean for the radiance
              rat = $
                 weighted_mean (emiss [k].radiance[indices_int[0]: indices_int [-1], $
                                                   indices_pix[0]: indices_pix [-1]], $
                                emiss[k].rad_err_rand[indices_int[0]: indices_int [-1], $
                                                      indices_pix[0]: indices_pix [-1]])
              emiss_binned [k].radiance [i, j] = rat [0]
              
;add the random errors in quadrature
                                ; bin, by adding
              emiss_binned [k].rad_err_rand [i, j] = rat [1]
              
           endfor
        endfor
     endfor

     after = systime (/seconds)
     print, 'Time taken: ', after - before, ' seconds'
     print, ''
  endelse
end

