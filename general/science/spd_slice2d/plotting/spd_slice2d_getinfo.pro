;+
;Procedure:
;  spd_slice2d_getinfo
;
;
;Purpose:
;  Helper function for spd_slice2d_plot.
;  Forms various title annotations based on the slice's metadata.
;
;
;Input:
;  slice: 2D slice structure from spd_slice2d
;  
;
;Output:
;  title: (string) Title to appear at the top of the plot.
;  xtitle: (string) Title for x axis.
;  ytitle: (string) Title for y axis.
;  ztitle: (string) Title for z axis.
;
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-11 17:20:48 -0800 (Fri, 11 Dec 2015) $
;$LastChangedRevision: 19620 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/plotting/spd_slice2d_getinfo.pro $
;
;-
pro spd_slice2d_getinfo, slice, title=title, short_title=short_title, $
                         xtitle=xtitle, ytitle=ytitle, ztitle=ztitle

    compile_opt idl2, hidden


  ; Plot title
  if undefined(title) then begin
    
    coord = slice.coord eq '' ? '':slice.coord+' '
    msec = slice.trange[1]-slice.trange[0] lt 1.
    
    if keyword_set(short_title) then begin
      ;time range and # of samples only
      title = strmid(time_string(slice.trange[0],msec=msec),11)+' > '+ $
              strmid(time_string(slice.trange[1],msec=msec),11)+ $
              ' ('+strtrim(fix(slice.n_samples),2)+')'
    endif else begin
      ;full title
      title = slice.project_name+' '+slice.spacecraft+' '+slice.data_name+ $
            ' ('+strtrim(coord+slice.rot)+') ' + $
                   time_string(slice.trange[0],msec=msec)+' -> ' + $
            strmid(time_string(slice.trange[1],msec=msec),11) + $
            ' ('+strtrim(fix(slice.n_samples),2)+')'
    endelse

  endif


  ; X,Y axes labels
  if undefined(xtitle) or undefined(ytitle) then begin
    xc = 1 & yc = 1 ;flags to label starting coords
    xt = 'x'   ;Defaults
    yt = 'y'
    case strlowcase(slice.rot) of 
      'bv': begin
        xt = '!DB!N'
        yt = '!DV!N'
        xc = 0 & yc = 0
      end
      'be': begin
        xt = '!DB!N'
        yt = '!DB x V!N'
        xc = 0 & yc = 0
      end
      'xy': begin
        xt = 'x'
        yt = 'y'
      end
      'xz': begin
        xt = 'x'
        yt = 'z'
      end
      'yz': begin
        xt = 'y'
        yt = 'z'
      end
      'xvel': begin
        xt = 'x'
        yt = '!DV!N'
        yc = 0
      end
      'perp': begin
        xt = '!DV perp B!N'
        yt = '!DB x V!N'
        xc = 0 & yc = 0
      end
      'perp_xy': begin
        xt = 'x!Dperp!N'
        yt = 'y!Dperp!N'
      end
      'perp_xz': begin
        xt = 'x!Dperp!N'
        yt = 'z!Dperp!N'
      end
      'perp_yz': begin
        xt = 'y!Dperp!N' 
        yt = 'z!Dperp!N'
      end
      else: begin
        xt = 'x!D?!N'  ;shouldn't be used
        yt = 'y!D?!N'
      end
    endcase
    
    ; add prefix
    if keyword_set(slice.energy) then begin
      xyprefix = slice.rlog ? 'log(E)':'E'
    endif else begin
      xyprefix = slice.rlog ? 'log(V)':'V'
    endelse
    xt = xyprefix + xt
    yt = xyprefix + yt
    
    ; add units 
    xt += ' ('+slice.xyunits+')'
    yt += ' ('+slice.xyunits+')'
    
    ; specify original physical coords
    if slice.coord ne '' then begin
      if xc then xt += ' ('+strupcase(slice.coord)+')'
      if yc then yt += ' ('+strupcase(slice.coord)+')'
    endif

    ; check for rotation out of x-y plane and label
    if ~array_equal(slice.orient_matrix, [[1.,0,0],[0,1,0],[0,0,1]]) then begin
      xvec = [1,0,0]##slice.orient_matrix
      yvec = [0,1,0]##slice.orient_matrix

      xv = strtrim(xvec,2)
      xt += ' - Using ('+ $
                spd_slice2d_removezeros(xv[0])+', '+ $
                spd_slice2d_removezeros(xv[1])+', '+ $
                spd_slice2d_removezeros(xv[2])+') as x-axis'

      yv = strtrim(yvec,2)
      yt += ' - Using ('+ $
                spd_slice2d_removezeros(yv[0])+', '+ $
                spd_slice2d_removezeros(yv[1])+', '+ $
                spd_slice2d_removezeros(yv[2])+') as y-axis'
    endif
    
    ;ensure custom titles are not overwritten
    if undefined(xtitle) then xtitle = xt
    if undefined(ytitle) then ytitle = yt
    
  endif
  
  
  ; Z axis label
  if undefined(ztitle) then begin 
    units = spd_units_string(strlowcase(slice.units))
    if units eq 'Unknown' then units = slice.units
    ztitle = units
  endif


end
