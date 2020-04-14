;+
; PROCEDURE:
;       mms_mec_formation_plot
;
; PURPOSE:
;       Creates a plot showing the spacecraft formation
;       at a given time
;       
; INPUT:
;       time:   string containing the date and time to create 
;               the plot for. e.g., 'YYYY-MM-DD/HH:MM'
; 
; KEYWORDS:
;       projection:   project the spacecraft positions 
;               onto all planes
;       
;       xy_projection: project the S/C positions onto the XY plane
;       xz_projection: project the S/C positions onto the XZ plane
;       yz_projection: project the S/C positions onto the YZ plane
;               
;       quality_factor: include the tetrahedron quality factor
;       coord: coordinate system of the formation plot; default is GSE
;              valid options are eci, gsm, geo, sm, gse, gse2000
;       xyz: a 3 x 3 rotation matrix for rotating position data to an
;            arbitrary coordinate system from the coordinate system
;            defined by coord 
;       lmn: a 3 x 3 rotation matrix for rotating position data to an
;            LMN coordinate system from the coordinate system
;            defined by coord (do not use with xyz keyword)
;       sundir: direction of the sun (+x) in the figure (right or left); default is 'right'
;               (+N direction for LMN coordinate)
;       independent_axes: by default, the same scale is used for each axis; set this keyword
;            to use different scales for the x, y, and z axes 
;       plotmargin: margin of the figure (default: 0.3)
;       sc_size: size of the spacecraft on the figure (default: 3)
;      
; VECTOR KEYWORDS:
;   The following keywords allow you to add various types of vectors to the figure, and control the look of the vectors
;         bfield_center: add the average B-field vector to the center of the figure (average of all 4 spacecraft; GSE or GSM coordinates only)
;         bfield_sc: add the B-field vector at each spacecraft (GSE or GSM coordinates only)
;         bfield_color: change the color of the B-field vector (default: red)
;         fgm_data_rate: B-field data rate to use (default: srvy)
;         fgm_normalization: normalization factor of the B-field vector (allows you to scale down/up the vector; default: 1)
;         
;         dis_center: add the average DIS bulk velocity vector to the center of the figure (average of all 4 spacecraft; GSE coordinates only)
;         des_center: add the average DES bulk velocity vector to the center of the figure (average of all 4 spacecraft; GSE coordinates only)
;         dis_sc: add the DIS bulk velocity vector at each spacecraft (GSE coordinates only)
;         des_sc: add the DES bulk velocity vector at each spacecraft (GSE coordinates only)
;         dis_color: change the color of the DIS bulk velocity vector
;         des_color: change the color of the DES bulk velocity vector
;         fpi_data_rate: data rate of the DIS/DES data to use when plotting the vectors (default: fast)
;         fpi_normalization: normalization factor of the bulk velocity vectors (allows you to scale down/up the vectors)
;         
;         vector_x: include a user-specified vector on the plot (x-components)
;         vector_y: include a user-specified vector on the plot (y-components)
;         vector_z: include a user-specified vector on the plot (z-components)
;         vector_colors: color of the user-specified vectors on the plot
;               
; EXAMPLES:
;       mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse'
;       
;       should create something like:
;       https://lasp.colorado.edu/mms/sdc/public/data/sdc/mms_formation_plots/mms_formation_plot_20160108023624.png
;       
;       With vectors
;       mms_mec_formation_plot,'2016-1-08/2:36',fpi_data_rate='fast',fpi_normalization=0.1d,fgm_normalization=1.d,/dis_center,/des_center,/bfield_center,/projection,plotmargin=1.0,sc_size=2.0,sundir='left'
;       mms_mec_formation_plot,'2016-1-08/2:36',fpi_data_rate='fast',fpi_normalization=0.1d,fgm_normalization=1.d,/dis_sc,/des_sc,/bfield_sc,/projection,plotmargin=1.0,sc_size=2.0,sundir='left'
;       mms_mec_formation_plot,'2015-10-16/13:07:02.40',fpi_data_rate='brst',fpi_normalization=0.02d,fgm_data_rate='brst',fgm_normalization=1.d,/dis_center,/des_center,/bfield_center,/projection,plotmargin=0.3,sc_size=2,sundir='left'
;       mms_mec_formation_plot,'2015-10-16/13:07:02.40',fpi_data_rate='brst',fpi_normalization=0.02d,fgm_data_rate='brst',fgm_normalization=1.d,/dis_sc,/des_sc,/bfield_sc,/projection,plotmargin=1.2,sc_size=1.5,sundir='left'
;
;       Sun to the left:
;       mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse', sundir='left'
;       
;       Specify an LMN transformation:
;       mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse', lmn=[[0.00,0.00,1.00],[0.00,-1.00,0.00],[1.00,0.00,0.00]], sundir='left'
;       
;       Specify an XYZ transformation:
;       mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse', xyz=[[0.00,0.00,1.00],[0.00,-1.00,0.00],[1.00,0.00,0.00]], sundir='left'
;
; HISTORY:
;       March 2020: Many updates to vector keywords from Naritoshi Kitamura
;       August 2016: Lots of updates from Naritoshi Kitamura
; 
;       The original copy of this comes from the 
;       SDC version, which was written by Kris Larsen 
;       and Kim Kokkonen at LASP
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-04-13 17:10:08 -0700 (Mon, 13 Apr 2020) $
; $LastChangedRevision: 28573 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_formation_plot.pro $
;-

pro mms_mec_formation_plot, time, projection=projection, quality_factor=quality_factor, $
  xy_projection=xy_projection, xz_projection=xz_projection, yz_projection=yz_projection, $
  coord=coord, lmn=lmn, xyz=xyz, sundir=sundir, independent_axes=independent_axes, bfield_center=bfield_center, $
  fgm_data_rate=fgm_data_rate, fgm_normalization=fgm_normalization, fpi_data_rate=fpi_data_rate, dis_center=dis_center, des_center=des_center, $
  fpi_normalization=fpi_normalization, vector_x=vector_x, vector_y=vector_y, vector_z=vector_z, vector_colors=vector_colors, $
  bfield_sc=bfield_sc, dis_sc=dis_sc, des_sc=des_sc, bfield_color=bfield_color, dis_color=dis_color, des_color=des_color, sc_size=sc_size, plotmargin=plotmargin

  if undefined(coord) then coord='gse' else coord=strlowcase(coord)
  if undefined(sundir) then sundir = 'right'
  if undefined(fgm_data_rate) then fgm_data_rate = 'srvy'
  if undefined(fpi_data_rate) then fpi_data_rate = 'fast'
  if undefined(bfield_color) then bfield_color = [255, 0, 0] ; red
  if undefined(dis_color) then dis_color = [0, 255, 0] ; green
  if undefined(des_color) then des_color = [0, 0, 255] ; blue
  if undefined(sc_size) then sc_size = 3
  if undefined(plotmargin) then plotmargin = 0.3
  
  ; load one minute of position data
  current_time = [time_double(time), time_double(time)+60.]
  mms_load_mec, trange=current_time, probes=[1, 2, 3, 4], varformat='*_r_'+coord, /time_clip
  
  if keyword_set(quality_factor) then begin
      ; load the tetrahedron quality factor
      mms_load_tetrahedron_qf, trange=current_time
      
      get_data, 'mms_tetrahedron_qf', data=tqf
  endif

  if keyword_set(dis_center) || keyword_set(dis_sc) || keyword_set(des_center) || keyword_set(des_sc) then begin
    if coord ne 'gse' then begin
      dprint, dlevel=0, "Error, FPI bulk velocity vectors can only be added in GSE coordinates; " + strupcase(coord) + " requested"
      return
    endif
  endif
  
  if keyword_set(bfield_center) || keyword_set(bfield_sc) then begin
    if ~array_contains(['gse', 'gsm'], coord) then begin
      dprint, dlevel=0, "Error, B-field vectors can only be added in GSE or GSM coordinates; " + strupcase(coord) + " requested"
      return
    endif
  endif
  
  get_data, 'mms1_mec_r_'+coord, data=d1
  get_data, 'mms2_mec_r_'+coord, data=d2
  get_data, 'mms3_mec_r_'+coord, data=d3
  get_data, 'mms4_mec_r_'+coord, data=d4
  
  if ~is_struct(d1) || ~is_struct(d2) || ~is_struct(d3) || ~is_struct(d4) then begin
    dprint, dlevel = 0, 'Error, couldn''t find the spacecraft position for one or more MMS spacecraft. Try a different time'
    return
  endif
  
  if keyword_set(bfield_center) then begin
    if undefined(fgm_normalization) then fgm_normalization=1.d
    mms_load_fgm, trange=current_time, probes=[1, 2, 3, 4], varformat='*_b_'+coord+'*', data_rate=fgm_data_rate, /time_clip
    get_data, 'mms1_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b1
    get_data, 'mms2_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b2
    get_data, 'mms3_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b3
    get_data, 'mms4_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b4
    
    if ~is_struct(b1) || ~is_struct(b2) || ~is_struct(b3) || ~is_struct(b4) then begin
      dprint, dlevel = 0, 'Error, couldn''t find the magnetic field data for one or more MMS spacecraft. Try a different time'
      return
    endif
    
    bx_avg = (b1.y[0, 0]+b2.y[0, 0]+b3.y[0, 0]+b4.y[0, 0])*fgm_normalization/4.0d
    by_avg = (b1.y[0, 1]+b2.y[0, 1]+b3.y[0, 1]+b4.y[0, 1])*fgm_normalization/4.0d
    bz_avg = (b1.y[0, 2]+b2.y[0, 2]+b3.y[0, 2]+b4.y[0, 2])*fgm_normalization/4.0d
  endif
  
  if keyword_set(dis_center) || keyword_set(dis_sc) then append_array, fpi_datatypes, 'dis-moms'
  if keyword_set(des_center) || keyword_set(des_sc) then append_array, fpi_datatypes, 'des-moms'
  
  if ~undefined(fpi_datatypes)then begin
     mms_load_fpi, trange=current_time, probes=[1, 2, 3, 4], datatype=fpi_datatypes, data_rate=fpi_data_rate, /time_clip, varformat='*_d?s_bulkv_'+coord+'*'
     
     if keyword_set(dis_center) || keyword_set(dis_sc) then begin
       get_data, 'mms1_dis_bulkv_'+coord+'_'+fpi_data_rate, data=dis_v1
       get_data, 'mms2_dis_bulkv_'+coord+'_'+fpi_data_rate, data=dis_v2
       get_data, 'mms3_dis_bulkv_'+coord+'_'+fpi_data_rate, data=dis_v3
       get_data, 'mms4_dis_bulkv_'+coord+'_'+fpi_data_rate, data=dis_v4
       
       if ~is_struct(dis_v1) || ~is_struct(dis_v2) || ~is_struct(dis_v3) || ~is_struct(dis_v4) then begin
         dprint, dlevel = 0, 'Error, couldn''t find the DIS data for one or more MMS spacecraft. Try a different time'
         return
       endif
       dis_vx = (dis_v1.y[0, 0]+dis_v2.y[0, 0]+dis_v3.y[0, 0]+dis_v4.y[0, 0])/4.0d
       dis_vy = (dis_v1.y[0, 1]+dis_v2.y[0, 1]+dis_v3.y[0, 1]+dis_v4.y[0, 1])/4.0d
       dis_vz = (dis_v1.y[0, 2]+dis_v2.y[0, 2]+dis_v3.y[0, 2]+dis_v4.y[0, 2])/4.0d
     endif
     if keyword_set(des_center) || keyword_set(des_sc) then begin
       get_data, 'mms1_des_bulkv_'+coord+'_'+fpi_data_rate, data=des_v1
       get_data, 'mms2_des_bulkv_'+coord+'_'+fpi_data_rate, data=des_v2
       get_data, 'mms3_des_bulkv_'+coord+'_'+fpi_data_rate, data=des_v3
       get_data, 'mms4_des_bulkv_'+coord+'_'+fpi_data_rate, data=des_v4

       if ~is_struct(des_v1) || ~is_struct(des_v2) || ~is_struct(des_v3) || ~is_struct(des_v4) then begin
         dprint, dlevel = 0, 'Error, couldn''t find the DES data for one or more MMS spacecraft. Try a different time'
         return
       endif
       des_vx = (des_v1.y[0, 0]+des_v2.y[0, 0]+des_v3.y[0, 0]+des_v4.y[0, 0])/4.0d
       des_vy = (des_v1.y[0, 1]+des_v2.y[0, 1]+des_v3.y[0, 1]+des_v4.y[0, 1])/4.0d
       des_vz = (des_v1.y[0, 2]+des_v2.y[0, 2]+des_v3.y[0, 2]+des_v4.y[0, 2])/4.0d
     endif
  endif

  if not undefined(lmn) then xyz=lmn

  if not undefined(xyz) then begin
    if not undefined(lmn) then begin
      zes = [(reform(d1.Y[0, *]#xyz))[0], (reform(d2.Y[0, *]#xyz))[0], (reform(d3.Y[0, *]#xyz))[0], (reform(d4.Y[0, *]#xyz))[0]]
      yes = [(reform(d1.Y[0, *]#xyz))[1], (reform(d2.Y[0, *]#xyz))[1], (reform(d3.Y[0, *]#xyz))[1], (reform(d4.Y[0, *]#xyz))[1]]
      xes = [(reform(d1.Y[0, *]#xyz))[2], (reform(d2.Y[0, *]#xyz))[2], (reform(d3.Y[0, *]#xyz))[2], (reform(d4.Y[0, *]#xyz))[2]]
    endif else begin
      xes = [(reform(d1.Y[0, *]#xyz))[0], (reform(d2.Y[0, *]#xyz))[0], (reform(d3.Y[0, *]#xyz))[0], (reform(d4.Y[0, *]#xyz))[0]]
      yes = [(reform(d1.Y[0, *]#xyz))[1], (reform(d2.Y[0, *]#xyz))[1], (reform(d3.Y[0, *]#xyz))[1], (reform(d4.Y[0, *]#xyz))[1]]
      zes = [(reform(d1.Y[0, *]#xyz))[2], (reform(d2.Y[0, *]#xyz))[2], (reform(d3.Y[0, *]#xyz))[2], (reform(d4.Y[0, *]#xyz))[2]]
    endelse
  endif else begin
    xes = [d1.Y[0, 0], d2.Y[0, 0], d3.Y[0, 0], d4.Y[0, 0]]
    yes = [d1.Y[0, 1], d2.Y[0, 1], d3.Y[0, 1], d4.Y[0, 1]]
    zes = [d1.Y[0, 2], d2.Y[0, 2], d3.Y[0, 2], d4.Y[0, 2]]
  endelse

  xes = (xes - mean(xes))
  yes = (yes - mean(yes))
  zes = (zes - mean(zes))

  ; get ranges
  if keyword_set(independent_axes) then begin
      if not undefined(lmn) then begin
        if sundir eq 'left' then begin
          xrange = (plotmargin + 1.) * [max(xes), min(xes)]
          yrange = (plotmargin + 1.) * [min(yes), max(yes)]
        endif else begin
          xrange = (plotmargin + 1.) * [min(xes), max(xes)]
          yrange = (plotmargin + 1.) * [max(yes), min(yes)]
        endelse
        zrange = (plotmargin + 1.) * [min(zes), max(zes)]
        light=0
      endif else begin
        if sundir eq 'left' then begin
          xrange = (plotmargin + 1.) * [max(xes), min(xes)]
          yrange = (plotmargin + 1.) * [max(yes), min(yes)]
        endif else begin
          xrange = (plotmargin + 1.) * [min(xes), max(xes)]
          yrange = (plotmargin + 1.) * [min(yes), max(yes)]
        endelse
        zrange = (plotmargin + 1.) * [min(zes), max(zes)]
        light=1
      endelse
  endif else begin
    ; use a common range for all axes (default)
    if not undefined(lmn) then begin
      if sundir eq 'left' then begin
        xrange = (plotmargin + 1.) * [max([xes, yes, zes]), min([xes, yes, zes])]
        yrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
      endif else begin
        xrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
        yrange = (plotmargin + 1.) * [max([xes, yes, zes]), min([xes, yes, zes])]
      endelse
      zrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
      light=0
    endif else begin
      if sundir eq 'left' then begin
        xrange = (plotmargin + 1.) * [max([xes, yes, zes]), min([xes, yes, zes])]
        yrange = (plotmargin + 1.) * [max([xes, yes, zes]), min([xes, yes, zes])]
      endif else begin
        xrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
        yrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
      endelse
      zrange = (plotmargin + 1.) * [min([xes, yes, zes]), max([xes, yes, zes])]
      light=1
    endelse
  endelse
  
  if undefined(fpi_normalization) then begin
    if ~undefined(des_vx) && ~undefined(des_vy) && ~undefined(des_vz) && ~undefined(dis_vx) && ~undefined(dis_vy) && ~undefined(dis_vz) then begin
      fpi_normalization = max(abs([xrange, yrange, zrange]))/(sqrt(dis_vx^2+dis_vy^2+dis_vz^2) > sqrt(des_vx^2+des_vy^2+des_vz^2))
    endif else begin
      if ~undefined(des_vx) && ~undefined(des_vy) && ~undefined(des_vz) then begin
        fpi_normalization = max(abs([xrange, yrange, zrange]))/sqrt(des_vx^2+des_vy^2+des_vz^2)
      endif
      if ~undefined(dis_vx) && ~undefined(dis_vy) && ~undefined(dis_vz) then begin
        fpi_normalization = max(abs([xrange, yrange, zrange]))/sqrt(dis_vx^2+dis_vy^2+dis_vz^2)
      endif
    endelse    
  endif

  ; edges between vertices
  xes1 = [xes[0], xes[1], xes[2], xes[3], xes[0], xes[3], xes[1], xes[0], xes[2]]
  yes1 = [yes[0], yes[1], yes[2], yes[3], yes[0], yes[3], yes[1], yes[0], yes[2]]
  zes1 = [zes[0], zes[1], zes[2], zes[3], zes[0], zes[3], zes[1], zes[0], zes[2]]

  spacecraft_colors = [[40,40,40],[213,94,0],[0,158,115],[86,180,233]]
  spacecraft_names = ['MMS1','MMS2','MMS3','MMS4']

  margin=0.3

  if undefined(lmn) then begin
    p = plot3d(xes1, yes1, zes1, thick=2, color='dim grey', $
      axis_style=2, xtitle='X, km', ytitle='Y, km', ztitle='Z, km', $
      xrange=xrange, yrange=yrange, zrange=zrange, $
      perspective=perspective, margin=margin, hide=~undefined(no_edges))
  endif else begin
    p = plot3d(xes1, yes1, zes1, thick=2, color='dim grey', $
      axis_style=2, xtitle='N, km', ytitle='M, km', ztitle='L, km', $
      xrange=xrange, yrange=yrange, zrange=zrange, $
      perspective=perspective, margin=margin, hide=~undefined(no_edges))
  endelse

  plot2 = plot3d(xes, yes, zes, linestyle='none', color='black', sym_object = orb(lighting=light), $
    sym_size=sc_size, /sym_filled, vert_colors=spacecraft_colors, perspective=1, $
    margin=margin, /overplot)

  ; draw spacecraft projections
  sym_transparency = 60
  
  if keyword_set(xy_projection) || keyword_set(projection) then begin
      z_projection = make_array(4, value=zrange[0])
      plot3z = plot3d(xes, yes, z_projection, sym_object=orb(lighting=0), linestyle='none', $
        sym_size=sc_size, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif

  if keyword_set(xz_projection) || keyword_set(projection) then begin
      y_projection = make_array(4, value=yrange[1])
      plot3y = plot3d(xes, y_projection, zes, sym_object=orb(lighting=0), linestyle='none', $
        sym_size=sc_size, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif
  
  if keyword_set(yz_projection) || keyword_set(projection) then begin
      x_projection = make_array(4, value=xrange[1])
      plot3x = plot3d(x_projection, yes, zes, sym_object=orb(lighting=0), linestyle='none', $
        sym_size=sc_size, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif

  if keyword_set(xy_projection) || keyword_set(projection) then begin
    ; mark origin on xy plane
    w = min(abs([xrange, yrange]))/10
    if zrange[0] lt zrange[1] then delta_z = 0.001 else delta_z = -0.001
    p1 = plot3d([-w, w], [0, 0], make_array(2, value=z_projection[0]+delta_z), thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
    p1 = plot3d([0, 0], [-w, w], make_array(2, value=z_projection[0]+delta_z), thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
  endif 
  
  if keyword_set(yz_projection) || keyword_set(projection) then begin
    ; mark origin on yz plane
    w = min(abs([yrange, zrange]))/10
    if xrange[1] lt xrange[0] then delta_x = 0.001 else delta_x = -0.001
    p2 = plot3d(make_array(2, value=x_projection[0]+delta_x), [-w, w], [0, 0], thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
    p2 = plot3d(make_array(2, value=x_projection[0]+delta_x), [0, 0], [-w, w], thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
  endif
  
  if keyword_set(yz_projection) || keyword_set(projection) then begin
    ; mark origin on xz plane
    w = min(abs([xrange, zrange]))/10
    if yrange[1] lt yrange[0] then delta_y = 0.001 else delta_y = -0.001
    p3 = plot3d([-w, w], make_array(2, value=y_projection[0]+delta_y), [0, 0], thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
    p3 = plot3d([0, 0], make_array(2, value=y_projection[0]+delta_y), [-w, w], thick=1, color='black', $
      /overplot, perspective=perspective, buffer=buffer, margin=margin)
  endif
  
  ; setup the axes
  ax = p.axes
  ax[0].tickfont_size = 7
  ax[1].tickfont_size = 7
  ax[8].showtext = 1
  ax[8].tickfont_size = 7
  ax[2].hide=1
  ax[6].hide=1
  ax[7].hide=1

  x1 = 0.33

  if ~undefined(bfield_center) or ~undefined(bfield_sc) or ~undefined(dis_center) or ~undefined(dis_sc) or ~undefined(des_center) or ~undefined(des_sc) then begin
    yl = 0.07
  endif else yl = 0.03
  
  for s=0,n_elements(spacecraft_names)-1 do begin
    xs = x1 + 0.13*s
    s1 = symbol(xs, yl,symbol='o', sym_color=spacecraft_colors[*,s], overplot=1, /sym_filled, sym_size=2.0)
    t1 = text(xs + 0.02, yl-0.015, spacecraft_names[s], font_size=12, font_color=spacecraft_colors[*,s])
  endfor
 
  vec_lab_count = 0
  x_vec_pos = 0.33
  y_vec_pos = 0.03
  
  if ~undefined(bfield_center) or ~undefined(bfield_sc) then begin
    s2 = symbol(x_vec_pos, y_vec_pos-0.005, symbol='hline', sym_color=bfield_color, overplot=1, /sym_filled, sym_size=2.0)
    t2 = text(x_vec_pos + 0.02, y_vec_pos-0.015, 'FGM', font_size=12, font_color=bfield_color)
    vec_lab_count += 1
  endif
  
  if ~undefined(dis_center) or ~undefined(dis_sc) then begin
    xs = x_vec_pos + 0.13*vec_lab_count
    s2 = symbol(xs, y_vec_pos-0.005, symbol='hline', sym_color=dis_color, overplot=1, /sym_filled, sym_size=2.0)
    t2 = text(xs + 0.02, y_vec_pos-0.015, 'DIS', font_size=12, font_color=dis_color)
    vec_lab_count += 1
  endif
  
  if ~undefined(des_center) or ~undefined(des_sc) then begin
    xs = x_vec_pos + 0.13*vec_lab_count
    s2 = symbol(xs, y_vec_pos-0.005, symbol='hline', sym_color=des_color, overplot=1, /sym_filled, sym_size=2.0)
    t2 = text(xs + 0.02, y_vec_pos-0.015, 'DES', font_size=12, font_color=des_color)
  endif
  
  title_string = 'MMS Formation'
  ; report the exact requested time
  ; even though the actual result time may be a few seconds different
  if undefined(bfield_center) && undefined(dis_center) && undefined(des_center) && undefined(bfield_sc) then title_string2 = time_string(d1.x[0], tformat='YYYY-MM-DD/hh:mm:ss') + ' UTC' else title_string2 = time_string(time_double(time), tformat='YYYY-MM-DD/hh:mm:ss.ff') + ' UTC'
  if ~undefined(tqf) then title_string3 = 'TQF=' + string(tqf.Y[0],format="(%'%5.3f')")

  t = text(x1,.93,title_string,/current,font_size=16, font_color='black')
  t = text(x1,.87,title_string2,/current,font_size=16, font_color='black')
  if ~undefined(tqf) then t = text(x1,.81,title_string3,/current,font_size=16, font_color='black')

  if undefined(lmn) then begin
    if coord ne 'geo' and coord ne 'eci' and undefined(xyz) then t1 = text(0.5, yl+0.05, strupcase(coord)+' Coordinates, Sun to the '+sundir, font_size=8, font_color='black') $
    else if undefined(xyz) then t1 = text(0.5, yl+0.05, strupcase(coord)+' Coordinates', font_size=8, font_color='black')
  endif else begin
    t1 = text(0.5, yl+0.05, 'LMN Coordinates', font_size=8, font_color='black')
  endelse
  t1 = text(0.5, yl+0.025, 'Origin at MMS centroid', font_size=8, font_color='black')
  
  if ~undefined(bx_avg) && ~undefined(by_avg) && ~undefined(bz_avg) && undefined(lmn) && undefined(xyz) then begin
    bplot3d = plot3d([0, bx_avg], [0, by_avg], [0, bz_avg], /overplot, color=bfield_color)

    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      bplot3z = plot3d([0, bx_avg], [0, by_avg], z_projection[0:1]+delta_z, /overplot, color=bfield_color)
    endif

    if keyword_set(xz_projection) || keyword_set(projection) then begin
      bplot3y = plot3d([0, bx_avg], y_projection[0:1]+delta_y, [0, bz_avg], /overplot, color=bfield_color)
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      bplot3x = plot3d(x_projection[0:1]+delta_x,  [0, by_avg], [0, bz_avg], /overplot, color=bfield_color)
    endif
  endif
  
  if keyword_set(dis_center) && ~undefined(dis_vx) && ~undefined(dis_vy) && ~undefined(dis_vz) && undefined(lmn) && undefined(xyz) then begin
    dis_vals = [dis_vx, dis_vy, dis_vz]
    dis_vals_norm = dis_vals*fpi_normalization;;/sqrt(dis_vals[0]^2+dis_vals[1]^2+dis_vals[2]^2)
    displot3d = plot3d([0, dis_vals_norm[0]], [0, dis_vals_norm[1]], [0, dis_vals_norm[2]], /overplot, color=dis_color)
    
    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      displot3z = plot3d([0, dis_vals_norm[0]], [0, dis_vals_norm[1]], z_projection[0:1]+delta_z, color=dis_color, $
        /overplot, perspective=perspective, margin=margin)
    endif

    if keyword_set(xz_projection) || keyword_set(projection) then begin
      displot3y = plot3d([0, dis_vals_norm[0]], y_projection[0:1]+delta_y, [0, dis_vals_norm[2]], color=dis_color, $
        /overplot, perspective=perspective, margin=margin)
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      displot3x = plot3d(x_projection[0:1]+delta_x,  [0, dis_vals_norm[1]], [0, dis_vals_norm[2]], color=dis_color, $
        /overplot, perspective=perspective, margin=margin)
    endif
  endif
  
  if keyword_set(des_center) && ~undefined(des_vx) && ~undefined(des_vy) && ~undefined(des_vz) && undefined(lmn) && undefined(xyz) then begin
    des_vals = [des_vx, des_vy, des_vz]
    des_vals_norm = des_vals*fpi_normalization;/sqrt(des_vals[0]^2+des_vals[1]^2+des_vals[2]^2)
    desplot3d = plot3d([0, des_vals_norm[0]], [0, des_vals_norm[1]], [0, des_vals_norm[2]], /overplot, color=des_color)
    
    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      desplot3z = plot3d([0, des_vals_norm[0]], [0, des_vals_norm[1]], z_projection[0:1]+delta_z, color=des_color, $
        /overplot, perspective=perspective, margin=margin)
    endif

    if keyword_set(xz_projection) || keyword_set(projection) then begin
      desplot3y = plot3d([0, des_vals_norm[0]], y_projection[0:1]+delta_y, [0, des_vals_norm[2]], color=des_color, $
        /overplot, perspective=perspective, margin=margin)
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      desplot3x = plot3d(x_projection[0:1]+delta_x,  [0, des_vals_norm[1]], [0, des_vals_norm[2]], color=des_color, $
        /overplot, perspective=perspective, margin=margin)
    endif
  endif
  
  ; plot user-specified vectors
  if ~undefined(vector_x) && ~undefined(vector_y) && ~undefined(vector_z) then begin
    for vector_id=0, n_elements(vector_x[0, *])-1 do begin
      if undefined(vector_colors) then color=[0, 0, 0] else color=vector_colors[*, vector_id]
      userplot3d = plot3d(vector_x[*, vector_id], vector_y[*, vector_id], vector_z[*, vector_id], /overplot, color=color)
      
      ; also plot projections
      if keyword_set(xy_projection) || keyword_set(projection) then begin
        plot3z = plot3d(vector_x[*, vector_id], vector_y[*, vector_id], z_projection[0:1]+delta_z, color=color, $
          /overplot, perspective=perspective, margin=margin)
      endif
      if keyword_set(xz_projection) || keyword_set(projection) then begin
        plot3y = plot3d(vector_x[*, vector_id], y_projection[0:1]+delta_y, vector_z[*, vector_id], color=color, $
          /overplot, perspective=perspective, margin=margin)
      endif
      
      if keyword_set(yz_projection) || keyword_set(projection) then begin
        plot3x = plot3d(x_projection[0:1]+delta_x,  vector_y[*, vector_id], vector_z[*, vector_id], color=color, $
          /overplot, perspective=perspective, margin=margin)
      endif
    endfor
  endif

  if ~undefined(bfield_sc) && undefined(lmn) && undefined(xyz) then begin
    if undefined(bfield_center) then begin
      mms_load_fgm, trange=current_time, probes=[1, 2, 3, 4], /time_clip, data_rate=fgm_data_rate, varformat='*_b_'+coord+'*'
      get_data, 'mms1_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b1
      get_data, 'mms2_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b2
      get_data, 'mms3_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b3
      get_data, 'mms4_fgm_b_'+coord+'_'+fgm_data_rate+'_l2_bvec', data=b4
    endif

    if undefined(fgm_normalization) then fgm_normalization=1.d
    
    b_data = hash()
    b_data[0] = reform(b1.y[0, *])
    b_data[1] = reform(b2.y[0, *])
    b_data[2] = reform(b3.y[0, *])
    b_data[3] = reform(b4.y[0, *])
    
    for spacecraft_idx=0, 3 do begin
      plot3d = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[2]], /overplot, color=bfield_color)
    endfor

    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3z = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[1]], z_projection+delta_z,  color=bfield_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
    if keyword_set(xz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3y = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[0]], y_projection+delta_y, [zes[spacecraft_idx], zes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[2]], color=bfield_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3x = plot3d(x_projection+delta_x,  [yes[spacecraft_idx], yes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(b_data[spacecraft_idx]*fgm_normalization)[2]], color=bfield_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
  endif

  if ~undefined(dis_sc) && undefined(lmn) && undefined(xyz) then begin
    
    dis_data = hash()
    dis_data[0] = reform(dis_v1.y[0, *])
    dis_data[1] = reform(dis_v2.y[0, *])
    dis_data[2] = reform(dis_v3.y[0, *])
    dis_data[3] = reform(dis_v4.y[0, *])

    for spacecraft_idx=0, 3 do begin
      plot3d = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[2]], /overplot, color=dis_color)
    endfor

    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3z = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[1]], z_projection+delta_z,  color=dis_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
    if keyword_set(xz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3y = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[0]], y_projection+delta_y, [zes[spacecraft_idx], zes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[2]], color=dis_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3x = plot3d(x_projection+delta_x,  [yes[spacecraft_idx], yes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(dis_data[spacecraft_idx]*fpi_normalization)[2]], color=dis_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
  endif

  if ~undefined(des_sc) && undefined(lmn) && undefined(xyz) then begin

    des_data = hash()
    des_data[0] = reform(des_v1.y[0, *])
    des_data[1] = reform(des_v2.y[0, *])
    des_data[2] = reform(des_v3.y[0, *])
    des_data[3] = reform(des_v4.y[0, *])

    for spacecraft_idx=0, 3 do begin
      plot3d = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[2]], /overplot, color=des_color)
    endfor

    ; also plot projections
    if keyword_set(xy_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3z = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[0]], [yes[spacecraft_idx], yes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[1]], z_projection+delta_z,  color=des_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
    if keyword_set(xz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3y = plot3d([xes[spacecraft_idx], xes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[0]], y_projection+delta_y, [zes[spacecraft_idx], zes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[2]], color=des_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif

    if keyword_set(yz_projection) || keyword_set(projection) then begin
      for spacecraft_idx=0, 3 do begin
        plot3x = plot3d(x_projection+delta_x,  [yes[spacecraft_idx], yes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[1]], [zes[spacecraft_idx], zes[spacecraft_idx]+(des_data[spacecraft_idx]*fpi_normalization)[2]], color=des_color, $
          /overplot, perspective=perspective, margin=margin)
      endfor
    endif
  endif

end