;+
; PROCEDURE set_coords
;
; :DESCRIPTION:
;   Transform the coordinate system of SD RTI-plot-type tplot 
;   variables.
;
; :PARAMS:
;   tplot_vars: tplot variables to be transformed
;   coord:      the coordinate system to which tplot variables 
;               are transformed to. 
;               Options currently available are:
;               'mlat', 'gate', 'glat'
;
; :EXAMPLES:
;   set_coords, 'sd_hok_vlos_1', 'mlat'
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2010/11/18: Created
;   2011/01/07: added glat to coordinate option
; 
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
pro set_coords, tplot_vars, coord, quiet=quiet

  npar = n_params()
  if npar eq 0 then begin
    print, 'Usage:'
    print, "       set_coords, ['var1','var2'...], {'gate'|'glat'|'mlat'|'mlt'}"
    print, "e.g., set_coords, 'sd_hok_vlos_1', 'mlat'"
    return
  endif
  
  ;Initialize
  sd_init
  
  ;Default coordinate system
  if ~keyword_set(coord) then coord = 'gate'
  coord = strlowcase(coord)
  
  ;Check if given tplot var. exists
  tplot_vars = tnames(tplot_vars)
  if tplot_vars[0] eq '' then return
  
  for i=0L, n_elements(tplot_vars)-1 do begin
    
    vn = tplot_vars[i]
    vnstr = strsplit(vn,'_', /extract)
    
    if strmid(vn,0,3) ne 'sd_' then continue ;non sd-tplot var
    
    ;get the radar name and the suffix from the variable name
    stn = vnstr[1] ; radar name code
    prefix = 'sd_'+stn+'_'
    n = min( where( stregex(vnstr, '^((0|1|2|3|4|5|6|7|8|9)+)$') ge 0 ) )
    if n gt 1 then suf = vnstr[n] else begin
      print, 'Cannot find the RG suffix... skip!   ',vn  
      continue
    endelse
    is_azimvar = ( stregex(vn, '_azim(0|1|2|3|4|5|6|7|8|9){2}') ge 0 )
    
    ;Load the data to be drawn and to be used for drawing on a 2-d map
    get_data, vn, data=d, dl=dl, lim=lim
    get_data, prefix+'azim_no_'+suf, data=az
    get_data, prefix+'positioncnt_tbl_'+suf, data=tbl
    
    ;Get dimensions of the data/table arrays
    rgmax = n_elements(tbl.y[0,*,0,0])
    azmmax= n_elements(tbl.y[0,0,*,0])
    ;Transform to arrays of [rgmax,azmmax]
    glonarr = ( reform( tbl.y[0, *, *, 0]) + 360. ) mod 360.
    glatarr =   reform( tbl.y[0, *, *, 1])
     
    ;Cases of Multi-tplot var --> call this pro recursively
    if (size(d))[2] eq 7 then begin
      for n=0, n_elements(d)-1 do begin
        set_coords, d[n], coord, quiet=quiet
        ;print, d[n], coord
      endfor
      get_data, d[0], lim=lim
      yr = minmax(lim.yrange)
      ylim, vn, yr[0],yr[1]
      CASE (coord) OF
        'gate': BEGIN
          options, vn, 'ysubtitle','[range gate]'
        END
        'mlat': BEGIN
          options, vn, 'ysubtitle','Mag. Lat [deg]'
        END
        'glat': BEGIN
          options, vn, 'ysubtitle','GEO Lat [deg]'
        END
        'mlt': BEGIN
          options, vn, 'ysubtitle','MLT [hr]'
        END
      ENDCASE

      continue
    endif
    
    ;;;;;;;
    CASE (coord) OF
    
      'gate': BEGIN
        
        gateno = 0.5+indgen( rgmax )
        
        str_element, d, 'v', gateno, /add_replace
        store_data, vn, data=d, dl=dl, lim=lim
        
        options, vn, 'yrange', minmax(gateno)
        options, vn, 'ystyle', 1
        options, vn, 'ysubtitle','[range gate]'
        
        if ~keyword_set(quiet) then $
          print, vn+': vertical axis --> '+'range gate'
        
      END
      
      'mlat': begin
        
        if is_azimvar then begin
          azimno = fix( strmid( stregex(vn, 'azim(0|1|2|3|4|5|6|7|8|9){2}', /ext), 4,2 ) )
          glat = reform( glatarr[ *, azimno] )
          glon = reform( glonarr[ *, azimno] )
          ;GEO --> AACGM, assuming 400km
          aacgmconvcoord, glat, glon, replicate(400.,rgmax), mlat,mlon,err,/TO_AACGM
          
          str_element, d, 'v', mlat, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endif else begin ;Cases of tplot vars containing all (0-15) beams
          glat = glatarr[ *, *]
          glon = glonarr[ *, *] 
          alt = glat & alt[*,*] = 400. ;km
          aacgmconvcoord, glat,glon,alt, mlat,mlon,err,/TO_AACGM
          ; For Unix ver. AACGM DLM bug 
          if (size(mlat))[0] ne (size(glat))[0] then begin 
            mlat = reform(mlat,rgmax,azmmax) & mlon = reform(mlon,rgmax,azmmax)
            mlat = float(mlat) & mlon = float(mlon)
          endif
          newv = d.y & newv[*,*] = !values.f_nan ;Create an array of the same dimension and initialize it 
          for n=0, azmmax-1 do begin
            idx = where( az.y eq n ) & if idx[0] eq -1 then continue
            newv[idx,*] = replicate(1.,n_elements(idx)) # transpose(mlat[*,n])
          endfor
          
          str_element, d, 'v', newv, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endelse
        
        yr = minmax(d.v)
        ylim, vn, yr[0],yr[1] 
        options, vn, 'ystyle', 1
        options, vn, ysubtitle='Mag. Lat [deg]'
        
        if ~keyword_set(quiet) then $
          print, vn+': vertical axis --> '+'AACGM lat.'

      end
      
      'mlt': begin
      
        if is_azimvar then begin
          azimno = fix( strmid( stregex(vn, 'azim(0|1|2|3|4|5|6|7|8|9){2}', /ext), 4,2 ) )
          glat = reform( glatarr[ *, azimno] )
          glon = reform( glonarr[ *, azimno] )
          ;GEO --> AACGM, assuming 400km
          aacgmconvcoord, glat, glon, replicate(400.,rgmax), mlat,mlon,err,/TO_AACGM
          
          mlonarr = replicate(1., n_elements(d.x)) # transpose(mlon) ; No. of time x rg
          ts = time_struct(d.x) & yrsec = long( (ts.doy-1)*86400. + ts.sod )
          yrarr = ts.year # transpose(replicate(1.,rgmax))
          yrsecarr = yrsec # transpose(replicate(1.,rgmax))
          mltarr = aacgmmlt( yrarr, yrsecarr, mlonarr )
          mlonarr[*] = mltarr[*]  ;a workaround to avoid a bug of Unix AACGM DLM
          
          str_element, d, 'v', mlonarr, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endif else begin ;Cases of tplot vars containing all (0-15) beams
          glat = glatarr[ *, *]
          glon = glonarr[ *, *]
          alt = glat & alt[*,*] = 400. ;km
          aacgmconvcoord, glat,glon,alt, mlat,mlon,err,/TO_AACGM
          ; For Unix ver. AACGM DLM bug
          if (size(mlat))[0] ne (size(glat))[0] then begin
            mlat = reform(mlat,rgmax,azmmax) & mlon = reform(mlon,rgmax,azmmax)
            mlat = float(mlat) & mlon = float(mlon)
          endif
          ;newv = d.y & newv[*,*] = !values.f_nan ;Create an array of the same dimension and initialize it
          mlonarr = d.y & mlonarr[*,*] = !values.f_nan 
          for n=0, azmmax-1 do begin
            idx = where( az.y eq n ) & if idx[0] eq -1 then continue
            mlonarr[idx,*] = replicate(1.,n_elements(idx)) # transpose(mlon[*,n])
          endfor
          ts = time_struct(d.x) & yrsec = long( (ts.doy-1)*86400. + ts.sod )
          yrarr = ts.year # transpose(replicate(1.,rgmax))
          yrsecarr = yrsec # transpose(replicate(1.,rgmax))
          mltarr = aacgmmlt( yrarr, yrsecarr, mlonarr )
          mlonarr[*] = mltarr[*]  ;a workaround to avoid a bug of Unix AACGM DLM
          str_element, d, 'v', mlonarr, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endelse
        
        yr = minmax(d.v)
        ylim, vn, 0,24
        options, vn, 'ystyle', 1
        options, vn, ysubtitle='MLT [hr]'
        
        if ~keyword_set(quiet) then $
          print, vn+': vertical axis --> '+'AACGM MLT'
          
      end
      
      'glat': begin
        
        if is_azimvar then begin
          azimno = fix( strmid( stregex(vn, 'azim(0|1|2|3|4|5|6|7|8|9){2}', /ext), 4,2 ) )
          glat = reform( glatarr[ *, azimno] )
          glon = reform( glonarr[ *, azimno] )
          
          str_element, d, 'v', glat, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endif else begin ;Cases of tplot vars containing all (0-15) beams
          glat = glatarr[ *, *]
          glon = glonarr[ *, *] 
          
          newv = d.y & newv[*,*] = !values.f_nan ;Create an array of the same dimension and initialize it 
          for n=0, azmmax-1 do begin
            idx = where( az.y eq n ) & if idx[0] eq -1 then continue
            newv[idx,*] = replicate(1.,n_elements(idx)) # transpose(glat[*,n])
          endfor
          
          str_element, d, 'v', newv, /add_replace
          store_data, vn, data=d, dl=dl, lim=lim
          
        endelse
        
        yr = minmax(d.v)
        ylim, vn, yr[0],yr[1] 
        options, vn, 'ystyle', 1
        options, vn, ysubtitle='GEO Lat [deg]'
        
        if ~keyword_set(quiet) then $
          print, vn+': vertical axis --> '+'Geographical lat.'
        
      end
      
      ELSE: BEGIN
        print, "Currently only 'gate','mlat', and 'glat' are available for keyword COORD"
        return
      END
      
    ENDCASE

    
  endfor
  
end

