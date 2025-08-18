;+
;Procedure:
;  spd_pgs_make_tplot
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
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 16:08:31 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19675 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_make_tplot.pro $
;-

pro spd_pgs_make_tplot, name, x=x, y=y, z=z, units=units, tplotnames=tplotnames, _extra=ex

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
             ztitle:spd_units_string(units,/units_only),minzlog:1,data_att:{units:units}$
          ;   ,zrange:zrange $
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
  
  ;limit default z range based on units
  ;thm_pgs_set_spec_zlimits, name, units_lc

  tplotnames=array_concat(name,tplotnames)

end
