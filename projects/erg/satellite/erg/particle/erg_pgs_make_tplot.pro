;+
;Procedure:
;  erg_pgs_make_tplot
;
;Purpose:
;  Create tplot variable with standard spectrogram settings.
;
;
;Input:
;  name: name of new tplot variable to create
;  x: x axis (time)
;  y: y axis 
;  z: z axis (data)
;  _extra: Any other keywords used will be passed to tplot and
;          set in the dlimits of the new variable.
;          (e.g. ylog=1 to set logarithmic y axis)
;
;
;Output:
;  Creates a tplot variable.
;  tplotnames=tplotnames : Concatenates the name of the new variable onto tnames argument
;
;Notes:
;
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release 
;  
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-

pro erg_pgs_make_tplot, name, x=x, y=y, z=z, units=units, tplotnames=tplotnames, $
                        relativistic=relativistic, _extra=ex

    compile_opt idl2, hidden


;  if ~keyword_set(units) then begin
;    units = 'f (s!U3!N/cm!U6!N)'
;  endif
  
   if ~keyword_set(units) then begin
     units = ''
   endif
  
;  idx = where(y gt 0,c)
;  if c gt 0 then begin
;    zrange = minmax(z[idx])
;    zrange[0] = floor(zrange[0])
;    zrange[1] = ceil(Zrange[1])
;  endif else begin
;    zrange = [1,1]
;  endelse
  
  ;general settings for all spectrograms
  dlimits = {ylog:0, zlog:1, spec:1, ystyle:1, zstyle:1,$
             extend_y_edges:1,$ ;if this option is set, tplot only plots to bin center on the top and bottom of the specplot
             x_no_interp:1,y_no_interp:1,$ ;copied from original thm_part_getspec, don't think this is strictly necessary, since specplot interpolation is disabled by default
             ztitle:'['+erg_units_string(units,/units_only, relativistic=relativistic)+']', minzlog:1, data_att:{units:units}, $
             ztickformat:'pwr10tick', zticklen:-0.4     $
             } 

  ;add/modify settings through extra keyword
  extract_tags, dlimits, ex
  
  ;spectrograms are built with time along dimension 2,
  ;tplot assumes time along dimension 1
  if dimen2(y) gt 1 then y = transpose(temporary(y))
  
  ;store the data
  store_data, name, $
              data = {x:x, y:transpose(temporary(z)), v:y}, $
              dlimits = dlimits ;,verbose=0

  ;; options
  str_element, ex, 'ysubtitle', val, success=s
  if s then options, name, 'ysubtitle', '['+val+']'
  
  
  ;limit default z range based on units
  ;thm_pgs_set_spec_zlimits, name, units_lc

  tplotnames=array_concat(name,tplotnames)

end
