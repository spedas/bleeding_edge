;+
; PROCEDURE:
;       mms_orbit_plot
;
; PURPOSE:
;       Creates a plot showing the spacecraft location
;
;
; KEYWORDS:
;       trange: time range of interest 
;       probes: probes to include in the orbits plot
;       plane: orbital plane to plot (default: 'xy', other options include: 'yz', 'xz')
;       xrange: min and max of the horizontal axis
;       yrange: min and max of the vertical axis
;       coord: coordinate system of the plot (default: gse)
;             other options include: 'eci', 'gsm', 'geo', 'sm', 'gse2000'
;       title: title of the plot; defaults to the time range of the orbit
;       noearth: disable the image of Earth on the figure
;
; EXAMPLES:
;       IDL> mms_orbit_plot, probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16']
;       
; HISTORY:
;       Based on SDC routine that produces historical orbit plots for MMS originally 
;       by Kris Larsen, Kim Kokkonen, Chris Lindholm; egrimes heisted the important parts
;       and turned this into a SPEDAS routine on November 27, 2017
; 
; NOTES: 
;       terminator line on Earth is probably going to be incorrect when plane is specified to be YZ
;       
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-05-27 17:05:37 -0700 (Wed, 27 May 2020) $
; $LastChangedRevision: 28740 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_orbit_plot.pro $
;-

pro mms_orbit_plot, trange=trange, probes=probes, data_rate=data_rate, xrange=xrange, yrange=yrange, plane=plane, coord=coord, title=title, noearth=noearth

  if undefined(plane) then plane = 'xy' else plane = strlowcase(plane)
  if undefined(coord) then coord='gse' else coord=strlowcase(coord)
  if undefined(probes) then probes = [1, 2, 3, 4]
  
  for probe_idx=0, n_elements(probes)-1 do append_array, spacecraft_names, 'MMS'+strcompress(string(probes[probe_idx]), /rem)
  spacecraft_colors = [[0,0,0],[213,94,0],[0,158,115],[86,180,233]]
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_load_mec, trange=tr, data_rate=data_rate, probes=probes, varformat='*_r_'+coord, /time_clip
  
  trange_string = time_string(minmax(time_double(tr)))
  if undefined(title) then title_string = strjoin(trange_string, ' to ') else title_string = title

  tkm2re, 'mms?_mec_r_'+coord
  
  for probe_idx=0, n_elements(probes)-1 do begin
    get_data, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_r_'+coord+'_re', data=d1
    if plane eq 'xy' then begin
      p1 = plot(d1.Y[*, 0], d1.Y[*, 1], xrange=xrange, yrange=yrange, dimensions=[1000,1000],thick=1, xtitle='X Position, Re', $
        ytitle='Y Position, Re', aspect_ratio=1.0, overplot=probe_idx eq 0 ? 0 : 1, color=spacecraft_colors[*, fix(probes[probe_idx])-1])
    endif else if plane eq 'yz' then begin
      p1 = plot(d1.Y[*, 1], d1.Y[*, 2], xrange=xrange, yrange=yrange, dimensions=[1000,1000],thick=1, xtitle='Y Position, Re', $
        ytitle='Z Position, Re', aspect_ratio=1.0, overplot=probe_idx eq 0 ? 0 : 1, color=spacecraft_colors[*, fix(probes[probe_idx])-1])
    endif else if plane eq 'xz' then begin
      p1 = plot(d1.Y[*, 0], d1.Y[*, 2], xrange=xrange, yrange=yrange, dimensions=[1000,1000],thick=1, xtitle='X Position, Re', $
        ytitle='Z Position, Re', aspect_ratio=1.0, overplot=probe_idx eq 0 ? 0 : 1, color=spacecraft_colors[*, fix(probes[probe_idx])-1])
    endif
  endfor
  
  if ~keyword_set(noearth) then begin
    get_rt_path, mec_path
    im = image(mec_path+'/earth_polar1.png', image_dimensions=[2,2], image_location=[-1,-1], overplot=1, title=title_string)
  endif
  
  xl = p1.position[0] + 0.05
  yl = p1.position[3] - 0.05

  for probe_idx=0, n_elements(probes)-1 do begin
    xs = xl + 0.1*probe_idx
    s1 = symbol(xs,yl,symbol='diamond', sym_color=spacecraft_colors[*,fix(probes[probe_idx])-1], overplot=1, /sym_filled, sym_size=1.0)
    t1 = text(xs + 0.015, yl-0.01, spacecraft_names[probe_idx], font_size=18, font_color=spacecraft_colors[*,fix(probes[probe_idx])-1])
  endfor

  t4 = text(p1.position[3]-0.15, 1-p1.position[3]+0.05, strupcase(coord) + ' Coordinates', font_size=8, font_color='black')
end