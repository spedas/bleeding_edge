;+
; PROCEDURE:
;     mms_flipbookify
;     
; PURPOSE:
;     Turns the current tplot window into a "flipbook" containing:
;     
;     1) the current figure (vertical line at each time step)
;     2) MMS distribution slices at each time step
;     
;     
; KEYWORDS:
;     trange: limit the time range of plots produced (will draw a box around trange by default)
;     instrument: instrument for the slices (default: fpi)
;     probe:  probe # for the slices (default: 1)
;     level: level of data for the slices (default: l2)
;     data_rate: data rate to use for the slices (default: brst)
;     species: species of the slices; valid options include: (default: 'i')
;         FPI: 'e' or 'i' 
;         HPCA: 'hplus', 'oplus', 'heplus', 'heplusplus'
;     
;     xrange:  two-element array specifying x-axis range for the slices
;     yrange:  two-element array specifying y-axis range for the slices
;     zrange:  two-element array specifying z-axis range for the slices
;     
;     slices: three-element array specifying the slices to plot:
;         'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;         'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;         'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;         'xz':  The x axis is along the data's x axis and y is along the data's z axis
;         'yz':  The x axis is along the data's y axis and y is along the data's z axis
;         'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;         'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;         'perp_xy':  The data's x & y axes are projected onto the plane normal to the B field
;         'perp_xz':  The data's x & z axes are projected onto the plane normal to the B field
;         'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field
;
;         default: ['xy', 'xz', 'yz']
;         
;     three_d_interp: use the 3D interpolation method
;     two_d_interp: use the 2D interpolation method (default, fastest)
;     geometric: use the geometric interpolation method
;     
;     custom_rotation: Applies a custom rotation matrix to the data.  Input may be a
;                   3x3 rotation matrix or a tplot variable containing matrices.
;                   If the time window covers multiple matrices they will be averaged.
;                   This is applied before other transformations
;     
;     /subtract_error: subtract the distErr variable from the FPI distribution before plotting (FPI only)
;     /subtract_bulk: subtract the bulk velocity from the slices before plotting
;     /subtract_spintone: subtract the spin-tone from the bulk velocity data prior to subtracting the bulk velocity data (FPI only)
;     /energy: produce energy slices instead of velocity slices
;     
;     thickness: thickness of the vertical line drawn at each time step
;     linestype: style of the vertical line drawn at each time step
;     
;     note: box_* keywords require that you specify a trange
;     box_color: color of the box
;     box_style: linestyle of the box
;     box_thickness: thickness of the box
;     /no_box: disable the box
;     
;     left_margin: adjust the left-margin of the output images
;     right_margin: adjust the right-margin of the output images (where the 
;         slices are stored)
;     
;     title: title of the plot; accepts common time string formats, e.g.,
;         title="YYYY-MM-DD/hh:mm:ss.fff"
;     
;     time_step: integer specifying the interval to produce plots at 
;         (e.g., time_step=1 -> plot at every time, time_step=2 -> every other time, etc)
;     /postscript: save the images as postscript files instead of PNGs
;     
;     output_dir: directory where the plots are saved (default: 'flipbook/')
;     filename_suffix: suffix to append to the end of the newly created files
;     
;     /video: save the sequence of images as a video (.mp4) - currently only works for PNG
;     vid_format: format of the output video; default .mp4; 
;         (options include: avi flv gif matroska mjpeg mov mp4 swf wav webm)
;     vid_fps: frames per second for the video; default: 6
; 
; EXAMPLES:
;     MMS> .run mms_basic_dayside
;     MMS> mms_flipbookify, data_rate='fast', time_step=10000
;     
;     see examples/advanced/mms_flipbook_crib.pro for more examples
; 
; NOTES:
; 
;    - experimental, work in progress! email problems to: egrimes@igpp.ucla.edu
;    
;    - the default time steps are taken from the first panel in the current window
;      (warning: if this happens to be a full day of srvy mode FGM data, 
;      this will produce > 1 million plots, one at each FGM data point - use the 
;      time_step keyword to avoid this, e.g., time_step=10000 for one plot per
;      10,000 FGM data points)
;     
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-06-27 14:58:21 -0700 (Wed, 27 Jun 2018) $
; $LastChangedRevision: 25408 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_flipbookify.pro $
;-

pro mms_flipbookify, trange=trange, probe=probe, level=level, data_rate=data_rate, $
  energy=energy, right_margin=right_margin, left_margin=left_margin, species=species, $
  instrument=instrument, time_step=time_step, xrange=xrange, yrange=yrange, zrange=zrange, $
  slices=slices, box_color=box_color, linestyle=linestyle, thickness=thickness, $
  postscript=postscript, box_style=box_style, box_thickness=box_thickness, no_box=no_box, $
  output_dir=output_dir, video=video, custom_rotation=custom_rotation, geometric=geometric, $
  two_d_interp=two_d_interp, three_d_interp=three_d_interp, title=title, filename_suffix=filename_suffix, $
  vid_format=vid_format, vid_fps=vid_fps, vid_bit_rate=vid_bit_rate, vid_codec=vid_codec, $
  subtract_bulk=subtract_bulk, samples=samples, window=window, center_time=center_time, $
  resolution=resolution, smooth=smooth, log=log, determ_tolerance=determ_tolerance, $
  plotbfield=plotbfield, plotbulk=plotbulk, background_color_index=background_color_index, $
  background_color_rgb=background_color_rgb, all_colorbars=all_colorbars, charsize=charsize, $
  subtract_error = subtract_error, include_1d_vx=include_1d_vx, include_1d_vy=include_1d_vy, $
  lineplot_yrange=lineplot_yrange, lineplot_xrange=lineplot_xrange, lineplot_thickness=lineplot_thickness, $
  ps_xsize=ps_xsize, ps_ysize=ps_ysize, ps_aspect=ps_aspect, nopng=nopng, subtract_spintone=subtract_spintone
  
  @tplot_com.pro 

  if undefined(instrument) then instrument = 'fpi'
  if undefined(species) then species = 'i'
  if undefined(data_rate) then data_rate = 'brst'
  
  if ~undefined(include_1d_vx) or ~undefined(include_1d_vy) then lineplot = 1b
  if undefined(right_margin) then begin
    if undefined(lineplot) then right_margin = 65 else right_margin = 85
  endif
  if undefined(left_margin) then left_margin = 15
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(output_dir) then output_dir = 'flipbook/'
  if undefined(time_step) then time_step = 1
  if undefined(slices) then slices = ['xy', 'xz', 'yz']
  if undefined(linestyle) then linestyle=2
  if undefined(thickness) then thickness=1
  if undefined(filename_suffix) then filename_suffix = ''
  if undefined(three_d_interp) and undefined(geometric) then two_d_interp = 1
  if undefined(vid_format) then vid_format = 'mp4'
  if undefined(vid_fps) then vid_fps = 6 ; video frames per second
  if undefined(vid_bit_rate) then vid_bit_rate = 3000
  if ~undefined(charsize) then !p.charsize = charsize
  window_num = 0b
  
  
  if ~is_struct(tplot_vars) then begin
    dprint, dlevel=0, 'Error, no tplot window found'
    return
  endif
 
  tpv_opt_tags = tag_names(tplot_vars.options)
  idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
  if icnt gt 0 then begin
    tplotnames = tplot_vars.options.datanames
    tplotnames = tnames(tplotnames, nd, /all, index=ind)
    get_data, tplotnames[0], data=top_panel
    ; in case the top panel contains a pseudovariable
    if ~is_struct(top_panel) && is_array(top_panel) then get_data, top_panel[0], data=top_panel
    if is_struct(top_panel) then times = top_panel.x
  endif else begin
    dprint, dlevel=0, 'Error, no tplot window found'
    return
  endelse
  if undefined(trange) then trange = time_double(minmax(times)) else begin
    ; the user specified a trange, so we need to limit the slices to that trange
    ; and draw a box indicating the trange
    trange = time_double(trange)
    new_times_idx = where(times ge (minmax(trange))[0] and times le (minmax(trange))[1], count)
    if count ne 0 then times = times[new_times_idx]
    if undefined(no_box) then draw_box = 1
  endelse
  tplot_options, 'xmargin', [left_margin, right_margin]

  ; make sure the output directory exists, if not, create it
  dir_search = file_search(output_dir, /test_directory)
  if dir_search eq '' then file_mkdir2, output_dir
  
  if instrument eq 'fpi' then begin
    name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
    bfield = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
    vel_data = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate
    if ~spd_data_exists(vel_data, trange[0], trange[1]) then append_array, datatypes, ['d'+species+'s-dist', 'd'+species+'s-moms'] else append_array, datatypes, 'd'+species+'s-dist'
    if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_fpi, data_rate=data_rate, level=level, datatype=datatypes, probe=probe, trange=trange, /time_clip, /center
    if ~spd_data_exists(bfield, trange[0], trange[1]) then mms_load_fgm, level=level, probe=probe, trange=trange, /time_clip
    dist = mms_get_fpi_dist(name, trange=trange, subtract_error=subtract_error, error='mms'+probe+'_d'+species+'s_disterr_'+data_rate)
    if keyword_set(subtract_spintone) && tnames(vel_data) ne '' && tnames('mms'+probe+'_d'+species+'s_bulkv_spintone_gse_'+data_rate) ne '' then begin
      dprint, dlevel = 0, 'Subtracting spin tone from FPI bulk velocity'
      calc, '"'+'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate+'"="'+'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate+'"-"'+'mms'+probe+'_d'+species+'s_bulkv_spintone_gse_'+data_rate+'"'
    endif
  endif else if instrument eq 'hpca' then begin
    name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
    bfield = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
    vel_data = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity'
    if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion', /time_clip, /center
    if ~spd_data_exists(vel_data, trange[0], trange[1]) then mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='moments', /time_clip, /center
    if ~spd_data_exists(bfield, trange[0], trange[1]) then mms_load_fgm, level=level, probe=probe, trange=trange, /time_clip
    dist = mms_get_hpca_dist(name, trange=trange)
  endif else begin
    dprint, dlevel = 'invalid instrument; valid options: fpi or hpca'
    return
  endelse

  if keyword_set(video) then begin
    video = idlffvideowrite(output_dir+'mms'+probe+'_'+instrument+'_'+species+'_flipbook'+filename_suffix+'.'+vid_format)
    stream = video.addvideostream(tplot_vars.settings.d.x_size, tplot_vars.settings.d.y_size, vid_fps, bit_rate=vid_bit_rate, codec=vid_codec)
  endif
  
  ; avoid the problem with multiple windows open
  window_num = tplot_vars.settings.window
  wset, window_num

  for time_idx=0, n_elements(times)-1, time_step do begin
    if keyword_set(postscript) then popen, output_dir+'mms'+probe+'_'+instrument+'_'+species+'_'+time_string(times[time_idx], tformat='YYYY-MM-DD-hh-mm-ss.fff')+filename_suffix, /land
    slice = spd_slice2d(dist, time=times[time_idx], energy=energy, subtract_bulk=subtract_bulk, geometric=geometric, two_d_interp=two_d_interp, three_d_interp=three_d_interp, custom_rotation=custom_rotation, rotation=slices[0], mag_data=bfield, vel_data=vel_data, samples=samples, window=window, center_time=center_time, resolution=resolution, smooth=smooth, log=log, determ_tolerance=determ_tolerance, fail=fail)
    slice2 = spd_slice2d(dist, time=times[time_idx], energy=energy, subtract_bulk=subtract_bulk, geometric=geometric, two_d_interp=two_d_interp, three_d_interp=three_d_interp, custom_rotation=custom_rotation, rotation=slices[1], mag_data=bfield, vel_data=vel_data, samples=samples, window=window, center_time=center_time, resolution=resolution, smooth=smooth, log=log, determ_tolerance=determ_tolerance, fail=fail) 
    slice3 = spd_slice2d(dist, time=times[time_idx], energy=energy, subtract_bulk=subtract_bulk, geometric=geometric, two_d_interp=two_d_interp, three_d_interp=three_d_interp, custom_rotation=custom_rotation, rotation=slices[2], mag_data=bfield, vel_data=vel_data, samples=samples, window=window, center_time=center_time, resolution=resolution, smooth=smooth, log=log, determ_tolerance=determ_tolerance, fail=fail)
    tplot, title=time_string(times[time_idx], tformat=title), get_plot_position=positions
    
    if ~is_struct(slice) then begin
      dprint, dlevel = 0, 'No slice data; ' + fail
      continue
    endif
    
    top_plot_pos = positions[*, 0]
    if keyword_set(postscript) then padding = .32 else padding = 0.28
    
    if undefined(lineplot) then begin
      slice_pos = [top_plot_pos[2]+padding/2., 0.1, 0.98, .34]
      slice2_pos = [top_plot_pos[2]+padding/2., 0.4, 0.98, .64]
      slice3_pos = [top_plot_pos[2]+padding/2., 0.7, 0.98, .94]
    endif else begin
      available_width = 1.-top_plot_pos[2]-.3 ; .3 padding
      slice_pos = [top_plot_pos[2]+padding/2., 0.1, top_plot_pos[2]+padding/2.+available_width/2., 0.34]
      slice2_pos = [top_plot_pos[2]+padding/2., 0.4, top_plot_pos[2]+padding/2.+available_width/2., 0.64]
      slice3_pos = [top_plot_pos[2]+padding/2., 0.7, top_plot_pos[2]+padding/2.+available_width/2., 0.94]
    endelse
    
    spd_slice2d_plot, slice, window=window_num, /custom, /noerase, position=slice_pos, title='', nocolorbar=undefined(all_colorbars), xrange=xrange, yrange=yrange, zrange=zrange, plotbfield=plotbfield, plotbulk=plotbulk, background_color_index=background_color_index, background_color_rgb=background_color_rgb
    spd_slice2d_plot, slice2, window=window_num, /custom, /noerase, position=slice2_pos, title='', xrange=xrange, yrange=yrange, zrange=zrange, plotbfield=plotbfield, plotbulk=plotbulk, background_color_index=background_color_index, background_color_rgb=background_color_rgb
    spd_slice2d_plot, slice3, window=window_num, /custom, /noerase, position=slice3_pos, title='', nocolorbar=undefined(all_colorbars), xrange=xrange, yrange=yrange, zrange=zrange, plotbfield=plotbfield, plotbulk=plotbulk, background_color_index=background_color_index, background_color_rgb=background_color_rgb

    
    if ~undefined(lineplot) then begin
      line_plot_width = .99-top_plot_pos[2]+padding+available_width/2.
      if ~undefined(include_1d_vx) then begin
        spd_slice1d_plot, thick=lineplot_thickness, color=2, slice, 'x', minmax(slice.xgrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.07, 0.99, 0.33], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        spd_slice1d_plot, thick=lineplot_thickness, color=2, slice2, 'x', minmax(slice2.xgrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.39, 0.99, 0.65], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice2.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        spd_slice1d_plot, thick=lineplot_thickness, color=2, slice3, 'x', minmax(slice3.xgrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.71, 0.99, 0.97], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice3.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        xyouts, 0.95, 0.93, 'f(v!Dx!N)', color=2, /normal
        xyouts, 0.95, 0.61, 'f(v!Dx!N)', color=2, /normal
        xyouts, 0.95, 0.29, 'f(v!Dx!N)', color=2, /normal
      endif
      if ~undefined(include_1d_vy) then begin
        spd_slice1d_plot, thick=lineplot_thickness, color=6, slice, 'y', minmax(slice.ygrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.07, 0.99, 0.33], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        spd_slice1d_plot, thick=lineplot_thickness, color=6, slice2, 'y', minmax(slice2.ygrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.39, 0.99, 0.65], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice2.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        spd_slice1d_plot, thick=lineplot_thickness, color=6, slice3, 'y', minmax(slice3.ygrid), window=window_num, /noerase, position=[top_plot_pos[2]+padding+available_width/2.+0.02, 0.71, 0.99, 0.97], /ylog, yminor=10, yrange=undefined(lineplot_yrange) ? slice3.zrange*[0.999,1.001] : lineplot_yrange, xrange=lineplot_xrange
        xyouts, 0.95, 0.89, 'f(v!Dy!N)', color=6, /normal
        xyouts, 0.95, 0.57, 'f(v!Dy!N)', color=6, /normal
        xyouts, 0.95, 0.25, 'f(v!Dy!N)', color=6, /normal
      endif
    endif
    
    timebar, times[time_idx], linestyle=linestyle, thick=thickness
    if ~undefined(draw_box) then timebar, (minmax(trange))[0], color=box_color, linestyle=box_style, thick=box_thickness
    if ~undefined(draw_box) then timebar, (minmax(trange))[1], color=box_color, linestyle=box_style, thick=box_thickness
    wait, 0.02
    if keyword_set(postscript) then pclose
    if ~keyword_set(postscript) and ~keyword_set(nopng) then makepng, output_dir+'mms'+probe+'_'+instrument+'_'+species+'_'+time_string(times[time_idx], tformat='YYYY-MM-DD-hh-mm-ss.fff')+filename_suffix
    if keyword_set(video) then begin
      void = video.put(stream, tvrd(/true))
    endif
  endfor

end