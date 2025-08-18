
;+
;PROCEDURE: spec3d,data
;   Plots 3d data as energy spectra.
;INPUTS:
;   data   - structure containing 3d data  (obtained from get_??() routine)
;		e.g. "get_el"
;KEYWORDS:
;   LIMITS - A structure containing limits and display options.
;             see: "options", "xlim" and "ylim", to change limits
;   UNITS  - convert to given data units before plotting
;   COLOR  - array of colors to be used for each bin
;   BINS   - array of bins to be plotted  (see "edit3dbins" to change)
;   OVERPLOT  - Overplots last plot if set.
;   LABEL  - Puts bin labels on the plot if set.
;
;See "plot3d_new" for another means of plotting data.
;See "conv_units" to change units.
;See "time_stamp" to turn time stamping on and off.
;
;
;CREATED BY:	Davin Larson  June 1995
;FILE:  spec3d.pro
;VERSION 1.25
;LAST MODIFICATION: 02/04/17
;-
pro spec3d,tempdat,   $
  LIMITS = limits, $
  UNITS = units,   $         ; obsolete.  Use units function
  COLOR = col,     $
  BDIR = bdir,     $
  PHI = phi,       $
  THETA = theta,   $
  PITCHANGLE = pang,   $
  VECTOR = vec,    $
  SUNDIR = sundir, $
  a_color = a_color, $
  LABEL = label,   $
  xdat = xdat, $
  ydat = ydat, $
  dydat = dydat, $
  BINS = bins,     $
  VELOCITY = vel, $
  verbose=verbose,  $
  OVERPLOT = oplot
;@wind_com.pro

if size(/type,tempdat) ne 8 || max(tempdat.valid) eq 0 then begin
  dprint, 'Invalid Data',dlevel=2,verbose=verbose
  return
endif

a_color=''
str_element,limits,'a_color',a_color

case strlowcase(strmid(a_color,0,2)) of
'pi': pang=1
'su': sundir=1
'th': theta=1
'ph': phi=1
else:
endcase


str_element,limits,'pitchangle',value=pang
str_element,limits,'sundir',value=sundir
str_element,limits,'thetadir',value=theta


str_element,limits,'units',value=units
data3d = conv_units(tempdat,units)

str_element,limits,'color',value=col

nb = data3d.nbins

project_name = struct_value(data3d,'PROJECT_NAME',default= 'Unknown Project')
data_name = struct_value(data3d,'DATA_NAME',default= 'Unknown Data')

title = project_name+'  '+ data_name
str_element, data3d, 'end_time', success = old_style
If(old_style) Then title = title+'!C'+trange_str(data3d.time,data3d.end_time) $
Else title = title+'!C'+trange_str(data3d.trange[0],data3d.trange[1])

ytitle = units_string(data3d.units_name)

ydat = data3d.data

str_element,limits,'velocity',value=vel
if keyword_set(vel) then begin
   xdat = velocity(data3d.energy,data3d.mass)
   xtitle = "Velocity'  (km/s)"
endif else begin
   xdat = data3d.energy
   xtitle = 'Energy  (eV)'
endelse

;print,minmax(xdat)

str_element,data3d,'bins',bins
str_element,limits,'bins',bins


if keyword_set(phi) then begin
   phi = reform(data3d.phi[0,*])
;   col = bytescale(phi,range=[-180.,180.])
   col = bytescale(phi);,range=[-180.,180.])
endif

if keyword_set(theta) then begin
   theta = reform(data3d.theta[0,*])  ; average theta
;   col = bytescale(theta,range=[-90.,90.])
   col = bytescale(theta);,range=[-90.,90.])
endif

if keyword_set(pang) then str_element,data3d,'magf',vec
if keyword_set(sundir) then vec = [-1.,0.,0.]


if keyword_set(vec)  then begin
   phi = average(data3d.phi,1,/nan)   ; average phi
   theta = average(data3d.theta,1,/nan)  ; average theta
   xyz_to_polar,vec,theta=bth,phi=bph
   p = pangle(theta,phi,bth,bph)
   col = bytescale(p,range=[0.,180.])
endif


if keyword_set(col) then shades  = col
if keyword_set(label) then labels = strcompress(indgen(nb))

if not keyword_set(bins) then bins = replicate(1b,nb)

plot={title:title, $
     xtitle:xtitle,x:xdat,xlog:1, $
     ytitle:ytitle,y:ydat,ylog:1,bins:bins  }

str_element,data3d,'ddata',value =dydat
str_element,plot,'dy',dydat,/add

;wi,lim=limits


mplot,data=plot,COLORS=shades,limits=limits,LABELS=labels,OVERPLOT=oplot


time_stamp


end
