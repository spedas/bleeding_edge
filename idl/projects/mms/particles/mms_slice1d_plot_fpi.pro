;+
; PROCEDURE:
;  spd_slice1d_plot with FPI modifications by Simon Wellenzohn
;
; PURPOSE:
;   Create 1D plot from a 2D particle slice

;   This version allows you to plot the integral over a certain angle section (white lines in the plot) of the 2D distribution.
;   The X axis of the plot created is a histogram with the width of the columns representing the energy channels of FPI.
;
; EXAMPLES:
; 
;  MMS> mms_slice1d_plot_fpi, slice, alpha=[0,0], width=[30,30], xrange=[-2500, 2500], yrange=[1e-25, 1d-22], export=export_dir
;
;
; INPUT:
;  slice: slice returned by spd_slice2d
;  alpha: angle in degrees to the x axis marking the center of the circle sector given for both the - and + x side
;  width: angle in degrees which sets the width of the circle sector given for both - and + x side
;  xrange: sets the xrange in km/s
;  yrange: sets y range in integrated flux
;  export: export path as string
;
; NOTES:
;    minor modifications by egrimes, Jan 2020
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-01-28 17:59:08 -0800 (Tue, 28 Jan 2020) $
; $LastChangedRevision: 28247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_slice1d_plot_fpi.pro $
;-

pro mms_slice1d_plot_fpi, slice, species=species, alpha=alpha, width=width, xrange=xrange, yrange=plot1d, export=export
  compile_opt idl2

  if undefined(species) then species = 'i'
  if species ne 'i' and species ne 'e' then begin
    dprint, dlevel=0, "Error, invalid species specified; valid options are: 'i' (for ions) and 'e' (for electrons)"
    return
  endif
  if undefined(export) then export = ''
  
  ;set parameters for both circle sectors
  l_alpha_width=width[0]/2.d
  r_alpha_width=width[1]/2.d
  l_alpha=alpha[0]
  r_alpha=alpha[1]
  xgrid=slice.xgrid
  ygrid=slice.ygrid
  data=slice.data

  ;select data according to given angle alpha for the positive x side
  x=xgrid[where(xgrid[*] GT 0)]
  r_data=data[where(xgrid[*] GT 0),*]

  r_ylim_segment=make_array(n_elements(x), 2, /double)
  r_ylim_segment[*,0]=abs(x) * tan((r_alpha+r_alpha_width) / !RADEG)
  r_ylim_segment[*,1]=abs(x) * tan((r_alpha-r_alpha_width) / !RADEG)

  ;overplot 2 white lines marking the circle sector in the 2D plot
  oplot, x, r_ylim_segment[*,0], color=fsc_color('white'), thick=4.d, linestyle=0
  oplot, x, r_ylim_segment[*,1], color=fsc_color('white'), thick=4.d, linestyle=0

  r_segment=make_array(n_elements(x), /double)

  FOR i=0, n_elements(x)-1 DO BEGIN
    IF r_ylim_segment[0,0] GT r_ylim_segment[0,1] THEN pixel_inside=where(ygrid[*] LT r_ylim_segment[i,0] AND ygrid[*] GT r_ylim_segment[i,1])
    IF r_ylim_segment[0,0] LT r_ylim_segment[0,1] THEN pixel_inside=where(ygrid[*] GT r_ylim_segment[i,0] AND ygrid[*] LT r_ylim_segment[i,1])
    r_segment[i]=total(r_data[i,pixel_inside])
    IF pixel_inside[0] EQ -1 THEN r_segment[i]=0
  ENDFOR


  ;select data according to given angle alpha for the negative x side
  x=xgrid[where(xgrid[*] LT 0)]
  l_data=data[where(xgrid[*] LT 0),*]

  l_ylim_segment=make_array(n_elements(x), 2, /double)
  l_ylim_segment[*,0]=abs(x) * tan((l_alpha+l_alpha_width) / !RADEG)
  l_ylim_segment[*,1]=abs(x) * tan((l_alpha-l_alpha_width) / !RADEG)

  ;overplot 2 white lines marking the circle sector in the 2D plot
  oplot, x, l_ylim_segment[*,0], color=fsc_color('white'), thick=4.d, linestyle=0
  oplot, x, l_ylim_segment[*,1], color=fsc_color('white'), thick=4.d, linestyle=0

  l_segment=make_array(n_elements(x), /double)

  FOR i=0, n_elements(x)-1 DO BEGIN
    IF l_ylim_segment[0,0] GT l_ylim_segment[0,1] THEN pixel_inside=where(ygrid[*] LT l_ylim_segment[i,0] AND ygrid[*] GT l_ylim_segment[i,1])
    IF l_ylim_segment[0,0] LT l_ylim_segment[0,1] THEN pixel_inside=where(ygrid[*] GT l_ylim_segment[i,0] AND ygrid[*] LT l_ylim_segment[i,1])
    l_segment[i]=total(l_data[i,pixel_inside])
    IF pixel_inside[0] EQ -1 THEN l_segment[i]=0
  ENDFOR

  
  ;final result of X and Y for the 1d plot
  x_1d=xgrid
  y_1d=[l_segment, r_segment]

  ;sum X to real measured FPI channels
  ;omni burst should be already loaded from main scripts 
  tplot_names, '*d'+species+'s_energyspectr_omni_brst*', names=t_names
  get_data, t_names[0], data=mms_data
  v_bins=reform(mms_data.v[0,*])

  ;calculate velocity bins from energy bins
  m_i=1.672621898d-27
  m_e=9.10938356d-31
  eVtoJ=1.6021766208d-19
  Re=6.3781E6
  c=299792458.d
  
  if species eq 'i' then begin
    vel_bins=c*sqrt(1.d - ((v_bins*evtoJ)/(m_i*c^2.d)+1.d)^(-2.d))/1d3
  endif else begin
    vel_bins=c*sqrt(1.d - ((v_bins*evtoJ)/(m_e*c^2.d)+1.d)^(-2.d))/1d3
  endelse
  ;

  ;sum up all data from X to the real FPI bins
  l_segm=make_array(n_elements(vel_bins), /double)
  r_segm=make_array(n_elements(vel_bins), /double)

  ;x_pos=x_1d[250:-1]
  x_pos=x_1d[n_elements(x_1d)/2:-1] ; changed by egrimes, jan 2020

  FOR index_fpi=0, n_elements(vel_bins)-2 DO BEGIN
    index_2d=where(x_pos[*] GE vel_bins[index_fpi] AND x_pos[*] LT vel_bins[index_fpi+1])
    IF index_2d[0] NE -1 THEN BEGIN
      r_segm[index_fpi]=mean(r_segment[index_2d])
    ENDIF
  ENDFOR

  x_pos=x_1d[0:n_elements(x_1d)/2-1] ; changed by egrimes, jan 2020
  l_vel_bins=-reverse(vel_bins)

  FOR index_fpi=0, n_elements(vel_bins)-2 DO BEGIN
    index_2d=where(x_pos[*] GE l_vel_bins[index_fpi] AND x_pos[*] LT l_vel_bins[index_fpi+1])
    IF index_2d[0] NE -1 THEN BEGIN
      l_segm[index_fpi]=mean(l_segment[index_2d])
    ENDIF
  ENDFOR

  x_1d_fpi=[l_vel_bins, vel_bins]
  y_1d_fpi=[l_segm, r_segm]
  ;

  ; set zero values to 1d-26 so plot on the log scale is possible
  y_1d_fpi[where(y_1d_fpi[*] EQ 0)]=1d-26
  ;set values outside 2d slice X ranges to 1d-26
  y_1d_fpi[where(abs(x_1d_fpi[*]) LT slice.rrange[0])]=1d-26

  ;make 1 D plot
    p1=plot(x_1d_fpi, y_1d_fpi, histogram=1, STAIRSTEP=1, $
    yrange=plot1d, ylog=1, xrange=[-slice.rrange[1], slice.rrange[1]],$
    font_size=14, DIMENSIONS=[500, 500])

  p1.Save, export+'_1d.png', BORDER=10, RESOLUTION=500
end