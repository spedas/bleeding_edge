;+
;Procedure:
;  thm_part_slice2d_getinfo
;
;
;Purpose:
;  Helper function for thm_part_slice2d_plot.
;  Forms various title annotations based on the slice's metadata.
;
;
;Input:
;  slice: 2D slice structure from thm_part_slice2d
;  
;
;Output:
;  title: (string) Title to appear at the top of the plot.
;  subtitle: (string) Subtitle appearing below TITLE.
;  xtitle: (string) Title for x axis.
;  ytitle: (string) Title for y axis.
;  ztitle: (string) Title for z axis.
;
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/plotting/thm_part_slice2d_getinfo.pro $
;
;-

; Procedure to generate titles for plot and axes
;
pro thm_part_slice2d_getinfo, slice, title=title, subtitle=subtitle, $
                               xtitle=xtitle, ytitle=ytitle, ztitle=ztitle

    compile_opt idl2, hidden


  ; Plot title
  if arg_present(title) and ~keyword_set(title) then begin
    title = 'th'+strlowcase(slice.probe)+' ' + $
            strjoin(slice.dist,'/') + $
            ' ('+strupcase(slice.rot)+') ' + $
;            string(10b) + $ 
            time_string(slice.trange[0]) + $
            ' -> '+strmid(time_string(slice.trange[1]),11,8)
  endif


  ; X,Y axes labels
  xc = 1 & yc = 1
  if (arg_present(xtitle) or arg_present(ytitle)) and $
     (~keyword_set(xtitle) or ~keyword_set(ytitle)) then begin
    xt = 'x'   ;Defaults
    yt = 'y'
    xyunits = slice.xyunits
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
      'rgeo': xt = '!Dr (GEI)!N'
      'mrgeo': xt = '!D-r (GEI)!N'
      'phigeo': yt = '!DEast (GEI)!N'
      'mphigeo': yt = '!DWest (GEI)!N'
      'phism': yt = '!DEast (SM)!N'
      'mphism': yt = '!DWest (SM)!N'
      'xgse': xt = 'x!DGSE!N'
      'ygsm': yt = 'y!DGSM!N'
      'zdsl': yt = 'z!DDSL!N'
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
    xt += ' ('+xyunits+')'
    yt += ' ('+xyunits+')'
    
    ; specify original physical coords
    coords = slice.coord
    fac_coords = ['rgeo','mrgeo','phigeo','mphigeo', $
                  'phism','mphism','xgse','ygsm','zdsl']
    facidx = where(strlowcase(slice.rot) eq fac_coords, nfac)
    if nfac gt 0 then coords = slice.rot
    if xc then xt += ' ('+strupcase(coords)+')'
    if yc then yt += ' ('+strupcase(coords)+')'

    ; check for rotation out of x-y plane and label
    if n_elements(slice.orient_m) gt 1 then begin
      xvec = [1,0,0]##slice.orient_m
      yvec = [0,1,0]##slice.orient_m
      if in_set(xvec eq [1,0,0],0) then begin
        xv = strtrim(xvec,2)
        xt += ' - Using ('+ $
                  thm_part_slice2d_removezeros(xv[0])+', '+ $
                  thm_part_slice2d_removezeros(xv[1])+', '+ $
                  thm_part_slice2d_removezeros(xv[2])+') as x-axis'
      endif
      if in_set(yvec eq [0,1,0],0) then begin
        yv = strtrim(yvec,2)
        yt += ' - Using ('+ $
                  thm_part_slice2d_removezeros(yv[0])+', '+ $
                  thm_part_slice2d_removezeros(yv[1])+', '+ $
                  thm_part_slice2d_removezeros(yv[2])+') as y-axis'
      endif
    endif
    
    ;ensure custom titles are not overwritten
    if ~keyword_set(xtitle) then xtitle = xt
    if ~keyword_set(ytitle) then ytitle = yt
    
  endif
  
  
  ; Z axis label
  if arg_present(ztitle) and ~keyword_set(ztitle) then begin 
    ; convert time window to string and trim zeros
    twin = thm_part_slice2d_removezeros(strtrim(slice.twin,2))
    ztitle = units_string(strlowcase(slice.units))
  endif


  ; Label slice type
  if arg_present(type) then begin
    type = (['Geo','2D nn','2D i','3D i'])[slice.type]
  endif


end
