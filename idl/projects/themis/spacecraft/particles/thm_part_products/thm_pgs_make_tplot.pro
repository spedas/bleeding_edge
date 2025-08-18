;+
;Procedure:
;  thm_pgs_make_tplot
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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-04-05 13:48:59 -0700 (Wed, 05 Apr 2017) $
;$LastChangedRevision: 23120 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_make_tplot.pro $
;-

pro thm_pgs_make_tplot, name, x=x, y=y, z=z, units=units, tplotnames=tplotnames, _extra=ex

    compile_opt idl2, hidden


  if ~keyword_set(units) then begin
    units = 'eflux'
  endif
  
  units_lc = strlowcase(units)
  
  if units_lc eq 'eflux' then begin
    units_s = 'eV/(cm^2-sec-sr-eV)'
  endif else if units_lc eq 'flux' then begin
    units_s = '1/(cm^2-sec-sr-eV)'
  endif else if units_lc eq 'rate' then begin
    units_s = '#/sec'
  endif else if units_lc eq 'crate' then begin
    units_s = '#/sec'
  endif else if units_lc eq 'counts' then begin
    units_s = '#'
  endif else if units_lc eq 'df' then begin
    units_s = '1/(cm^3-(km/s)^3)'
  endif else begin
    units_s = units
  endelse

  ;general settings for all spectrograms
  dlimits = {ylog:0, zlog:1, spec:1, ystyle:1, zstyle:1,$
             extend_y_edges:1,$ ;if this option is not set, tplot only plots to bin center on the top and bottom of the specplot
             x_no_interp:1,y_no_interp:1,$ ;copied from original thm_part_getspec, don't think this is strictly necessary, since specplot interpolation is disabled by default
             ztitle:units_s,minzlog:1,data_att:{units:units_s}} 

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
  thm_pgs_set_spec_zlimits, name, units_lc

  tplotnames=array_concat(name,tplotnames)

end