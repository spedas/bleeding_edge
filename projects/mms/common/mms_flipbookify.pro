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
;     three_d_interp: use the 3D interpolation method (default)
;     two_d_interp: use the 2D interpolation method
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
;     seconds: specify the # of seconds for each slice
;         (e.g., seconds=1.5 -> plot at every 1.5 seconds)
;     time_step: integer specifying the interval to produce plots at 
;         (e.g., time_step=1 -> plot at every time, time_step=2 -> every other time, etc)
;         
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
;      warning: if this happens to be a full day of srvy mode FGM data, 
;      this will produce > 1 million plots, one at each FGM data point - use the 
;      time_step or seconds keywords to avoid this, e.g., 
;           time_step=10000 for one plot per 10,000 FGM data points
;           seconds=6 for one plot every 6 seconds
;           
;     
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-28 13:48:12 -0800 (Mon, 28 Jan 2019) $
; $LastChangedRevision: 26504 $
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
  ps_xsize=ps_xsize, ps_ysize=ps_ysize, ps_aspect=ps_aspect, nopng=nopng, subtract_spintone=subtract_spintone, $
  fgm_data_rate=fgm_data_rate, seconds=seconds, erange=erange, gif=gif, jpg=jpg
  
  mms_init
  
  if undefined(instrument) then instrument = 'fpi'
  if undefined(species) then species = 'i'
  if undefined(data_rate) then data_rate = 'brst'
  if undefined(fgm_data_rate) then begin
    if data_rate eq 'brst' then fgm_data_rate = 'brst' else fgm_data_rate = 'srvy'
  endif
  
  if ~undefined(include_1d_vx) or ~undefined(include_1d_vy) then lineplot = 1b
  if ~undefined(postscript) && ~undefined(lineplot) then begin
    if undefined(left_margin) then left_margin = 5
    if undefined(right_margin) then right_margin = 100
  endif
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
  if undefined(two_d_interp) and undefined(geometric) then three_d_interp = 1
  if undefined(vid_format) then vid_format = 'mp4'
  if undefined(vid_fps) then vid_fps = 6 ; video frames per second
  if undefined(vid_bit_rate) then vid_bit_rate = 3000
  if ~undefined(charsize) then !p.charsize = charsize
  filename_prefix = 'mms'+probe+'_'+instrument+'_'+species+'_'

  times = spd_times_from_top_panel()
  
  if undefined(trange) then trange = time_double(minmax(times)) else begin
    ; the user specified a trange, so we need to limit the slices to that trange
    ; and draw a box indicating the trange
    trange = time_double(trange)
    new_times_idx = where(times ge (minmax(trange))[0] and times le (minmax(trange))[1], count)
    if count ne 0 then times = times[new_times_idx]
    if undefined(no_box) then draw_box = 1
  endelse
  
  if instrument eq 'fpi' then begin
    name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
    bfield = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec'
    vel_data = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate
    if ~spd_data_exists(vel_data, trange[0], trange[1]) then append_array, datatypes, ['d'+species+'s-dist', 'd'+species+'s-moms'] else append_array, datatypes, 'd'+species+'s-dist'
    if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_fpi, data_rate=data_rate, level=level, datatype=datatypes, probe=probe, trange=trange, /time_clip, /center
    if ~spd_data_exists(bfield, trange[0], trange[1]) then mms_load_fgm, level=level, probe=probe, trange=trange, data_rate=fgm_data_rate, /time_clip
    dist = mms_get_fpi_dist(name, trange=trange, subtract_error=subtract_error, error='mms'+probe+'_d'+species+'s_disterr_'+data_rate)
    if keyword_set(subtract_spintone) && tnames(vel_data) ne '' && tnames('mms'+probe+'_d'+species+'s_bulkv_spintone_gse_'+data_rate) ne '' then begin
      dprint, dlevel = 0, 'Subtracting spin tone from FPI bulk velocity'
      calc, '"'+'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate+'"="'+'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate+'"-"'+'mms'+probe+'_d'+species+'s_bulkv_spintone_gse_'+data_rate+'"'
    endif
  endif else if instrument eq 'hpca' then begin
    name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
    bfield = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec'
    vel_data = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity'
    if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion', /time_clip, /center
    if ~spd_data_exists(vel_data, trange[0], trange[1]) then mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='moments', /time_clip, /center
    if ~spd_data_exists(bfield, trange[0], trange[1]) then mms_load_fgm, level=level, probe=probe, trange=trange, data_rate=fgm_data_rate, /time_clip
    dist = mms_get_hpca_dist(name, trange=trange)
  endif else begin
    dprint, dlevel = 'invalid instrument; valid options: fpi or hpca'
    return
  endelse

  spd_flipbookify, dist, mag_data=bfield, vel_data=vel_data, trange=trange, $
    energy=energy, right_margin=right_margin, left_margin=left_margin, $
    time_step=time_step, xrange=xrange, yrange=yrange, zrange=zrange, $
    slices=slices, box_color=box_color, linestyle=linestyle, thickness=thickness, $
    postscript=postscript, box_style=box_style, box_thickness=box_thickness, no_box=no_box, $
    output_dir=output_dir, video=video, custom_rotation=custom_rotation, geometric=geometric, $
    two_d_interp=two_d_interp, three_d_interp=three_d_interp, title=title, filename_suffix=filename_suffix, $
    vid_format=vid_format, vid_fps=vid_fps, vid_bit_rate=vid_bit_rate, vid_codec=vid_codec, $
    subtract_bulk=subtract_bulk, samples=samples, window=window, center_time=center_time, $
    resolution=resolution, smooth=smooth, log=log, determ_tolerance=determ_tolerance, $
    plotbfield=plotbfield, plotbulk=plotbulk, background_color_index=background_color_index, $
    background_color_rgb=background_color_rgb, all_colorbars=all_colorbars, charsize=charsize, $
    include_1d_vx=include_1d_vx, include_1d_vy=include_1d_vy, lineplot_yrange=lineplot_yrange, $
    lineplot_xrange=lineplot_xrange, lineplot_thickness=lineplot_thickness, $
    ps_xsize=ps_xsize, ps_ysize=ps_ysize, ps_aspect=ps_aspect, nopng=nopng, filename_prefix=filename_prefix, $
    seconds=seconds, erange=erange, gif=gif, jpg=jpg

end