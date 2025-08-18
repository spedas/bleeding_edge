
;+
; Name: thm_crib_trace
;
; Purpose:crib to demonstrate use of Tsyganenko trace routines, and means for generating plots of trace routines.
;
; Notes: 1. run it by compiling in idl and then typing ".go"
;        or copy and paste.  If you want, you can just edit the parameters for the
;        routine and run it as is.
;        
;        2. There are commented sections, to do things like plot positions of ground stations and other spacecraft, or use other fields model.
;           Just uncomment these sections to enable the desired behavior
;
; SEE ALSO: idl/external/IDL_GEOPACK/trace/ttrace_crib.pro
;           idl/ssl_general/cotrans/aacgm/aacgm_example.pro
;           idl/themis/examples/thm_crib_tplotxy.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 11:14:02 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13081 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_trace.pro $
;-

compile_opt idl2

;sets background and color table
thm_init

;NOTE: there is code further down in the file that you can uncomment
;to generate various output formats like EPS and PNG

;you may want to control the thickness of the generated plots
;to make the lines in the output more visible when exported
;you can do so with these variables
axisthick = 4.0
charthick = 2.0
linethick = 4.0
charsize = 2.0
symsize = 1.0

landscape=1 ; set landscape = 1 if you want to make any postscripts generated in landscape

encapsulated=1 ; set encapsulated = 1 if you want any postscripts generated to be eps

;NOTE: you still need to go uncomment the appropriate lines in the code below to activate postscript output

date = '2008-03-27/02:00:00' ;date to be plotted
hrs = 3  ;specifies the interval over which data will be loaded
         ;this mainly has an effect on the amount of position
         ;data that will be loaded and plotted
         
sdate = time_double(date)-3600*hrs/2
edate = time_double(date)+3600*hrs/2

timespan,sdate,hrs,/hour

;generate parameters for the tsyganenko model

;This code generates parameters for the tsyganenko model
;actual kp values can be found at: http://www.ngdc.noaa.gov/stp/GEOMAG/kp_ap.html
model = 't89'
par = 2.0D ; use kp 2.0 for t89 model

;Uncomment this code to use t01 model(or t96 or ts04)
;model = 't01' ;set = to 't96' or 't04s' to use other models
;kyoto_load_dst
;omni_hro_load
;
;tdegap,'kyoto_dst',/overwrite
;tdeflag,'kyoto_dst','linear',/overwrite
;       
;tdegap,'OMNI_HRO_1min_BY_GSM',/overwrite
;tdeflag,'OMNI_HRO_1min_BY_GSM','linear',/overwrite
;       
;tdegap,'OMNI_HRO_1min_BZ_GSM',/overwrite
;tdeflag,'OMNI_HRO_1min_BZ_GSM','linear',/overwrite
;       
;tdegap,'OMNI_HRO_1min_proton_density',/overwrite
;tdeflag,'OMNI_HRO_1min_proton_density','linear',/overwrite
;       
;tdegap,'OMNI_HRO_1min_flow_speed',/overwrite
;tdeflag,'OMNI_HRO_1min_flow_speed','linear',/overwrite
;       
;store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']
;      
;;get_tsy_params generates parameters for t96,t01, & t04s models
;get_tsy_params,'kyoto_dst','omni_imf',$ 
;  'OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed',model,/speed,/imf_yz
;   
;par = model + '_par'

;********************************************************
;This section generates XZ plot
;********************************************************
;generate points from which to trace for XZ projection

x = [-22,-22,-22,-22,-17,-12,-8,-5,-3,2,4,7,8,8]
y = replicate(0,14)
z = [10,7,4,0,replicate(0,9),4]

times = replicate(time_double(date),14)

trace_pts_north =  [[x],[y],[z]]
trace_pts_south =  [[x],[y],[-1*z]] 

store_data,'trace_pts_north',data={x:times,y:trace_pts_north}
store_data,'trace_pts_south',data={x:times,y:trace_pts_south}

;trace the field lines
ttrace2iono,'trace_pts_north',trace_var_name = 'trace_n', $
external_model=model,par=par,in_coord='gsm',out_coord=$
'gsm'
ttrace2iono,'trace_pts_south',trace_var_name = 'trace_s',$
external_model=model,par=par,in_coord='gsm',out_coord=$
'gsm', /south

window,xsize=800,ysize=600

xrange = [-22,10] ;x range of the xz plot
zrange = [-11,11] ;z range of the xz plot

;generate the plot of field lines
tplotxy,'trace_n',versus='xrz',xrange=xrange,yrange=zrange,charsize=charsize,title="XZ field line/probe position plot",xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick,ymargin=[.15,.1]
tplotxy,'trace_s',versus='xrz',xrange=xrange,yrange=zrange,/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
 
colors=['m','r','g','c','b']  ;colors for probes
probes = ['a','b','c','d','e'] ;the probes to be marked
A = FINDGEN(17) * (!PI*2/16.) ;makes a circular symbol to mark spacecraft position
USERSYM, COS(A), SIN(A), /FILL 

;--------------------------
;Plot Themis probe positions on X-Z plot
 
;load probe positions
thm_load_state,probe=probes,coord='gsm'
tkm2re,'th'+probes+'_state_pos',/replace 
    
;plot the probe positions
for i = 0,n_elements(probes) - 1 do begin
  
  probe = probes[i]
  color = colors[i]
      
  varname = 'th'+probe+'_state_pos'
  
  ;plot position in KM   
  get_data,varname,data=d
  
  ;skip if no valid data on day
  if ~is_struct(d) then continue

  ;find midpoint      
  tmp = min(abs(d.x - time_double(date)),probe_pos)
      
  tplotxy,varname,versus='xrz',/over,color=color,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
  plotxy,reform(d.y[probe_pos,*],1,3),psym=8,color=color,symsize=symsize,versus='xrz',/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
  
endfor
;---------------------------------------

;---------------------------------------------------------------------------
;Plot GOES probe positions on X-Z plot

;goesprobes = ['g10','g11','g12']
;
;thm_load_goesmag,probe=goesprobes
;tkm2re,goesprobes+'_pos_gsm',/replace ;convert to earth radii
;
;for i = 0,n_elements(goesprobes) - 1 do begin
;  
;  probe = goesprobes[i]
;  color = colors[i]
;      
;  varname = probe+'_pos_gsm'
;  
;  ;plot position in KM   
;  get_data,varname,data=d
;  ;skip if no valid data on day
;  if ~is_struct(d) then continue
;
;  ;find midpoint      
;  tmp = min(abs(d.x - time_double(date)),probe_pos)    
;  tplotxy,varname,versus='xrz',/over,color=color,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
;  plotxy,reform(d.y[probe_pos,*],1,3),psym=8,color=color,symsize=symsize,versus='xrz',/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
;  
;endfor
;----------------------------------------------------------------


;----------------IMAGE EXPORT CODE HERE----------------------------------
;Uncomment to generate png of XZ plot
;makepng,'XZplot'

;Uncomment next 3 lines to generate postscript of XZ plot
;popen,'XZplot',encapsulated=encapsulated,land=landscape
;
;tplotxy
;
;pclose

;------------------------------------------------------------------

;press .c to continue
stop

;********************************************************
;This section generates  XY plot
;********************************************************

;generate data for XY plot

;points for this plot will be generated from an ellipse

h = -5  ;x coordinate of ellipse center

k = 0   ;y coordinate of ellipse center

a = 15 ; size of semimajor axis

b = 12 ; size of semiminor axis


t = !DPI*dindgen(20)/10.

x = h + a*cos(t)
y = k + b*sin(t)

z = replicate(0D,20)

times = replicate(time_double(date),20)

trace_pts =  [[x],[y],[z]] 

store_data,'trace_pts',data={x:times,y:trace_pts}

;trace the field lines
ttrace2iono,'trace_pts',trace_var_name = 'trace_n2',$
external_model=model,par=par,in_coord='gsm',out_coord=$
'gsm'

ttrace2iono,'trace_pts',trace_var_name = 'trace_s2',$
external_model=model,par=par,in_coord='gsm',out_coord=$
'gsm',/south

window,1,xsize=800,ysize=600


xrange = [-24,14] ;x range of the xy plot
yrange = [-17,17] ;y range of the xy plot


;generate the plot of field lines
tplotxy,'trace_n2',versus='xry',xrange=xrange,yrange=yrange,charsize=charsize,title="XY field line/probe position plot",xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick,ymargin=[.15,.1]
tplotxy,'trace_s2',versus='xry',/over,linestyle=2,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick

colors=['m','r','g','c','b']  ;colors for probes
probes = ['a','b','c','d','e'] ;the probes to be marked
A = FINDGEN(17) * (!PI*2/16.) ;makes a circular symbol to mark spacecraft position
USERSYM, COS(A), SIN(A), /FILL 


;------------------------------------------------------
;Plot THEMIS probe positions on XY plot
;load probe positions
thm_load_state,probe=probes,coord='gsm'
tkm2re,'th'+probes+'_state_pos',/replace 
    
;plot the probe positions
for i = 0,n_elements(probes) - 1 do begin
  
  probe = probes[i]
  color = colors[i]
      
  varname = 'th'+probe+'_state_pos'
  
  ;plot position in KM   
  get_data,varname,data=d
  ;skip if no valid data on day
  if ~is_struct(d) then continue

  ;find midpoint      
  tmp = min(abs(d.x - time_double(date)),probe_pos)
      
  tplotxy,varname,versus='xry',/over,color=color,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
  plotxy,reform(d.y[probe_pos,*],1,3),psym=8,color=color,symsize=symsize,versus='xry',/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
  
endfor
;-----------------------------------------------

;-----------------------------------------------
;Plot GOES probe positions on XY plot

;goesprobes = ['g10','g11','g12']
;
;thm_load_goesmag,probe=goesprobes
;tkm2re,goesprobes+'_pos_gsm',/replace ;convert to earth radii
;    
;;plot the probe positions
;for i = 0,n_elements(goesprobes) - 1 do begin
;  
;  probe = goesprobes[i]
;  color = colors[i]
;      
;  varname = probe+'_pos_gsm'
;  
;  ;plot position in KM   
;  get_data,varname,data=d
;  ;skip if no valid data on day
;  if ~is_struct(d) then continue
;
;  ;find midpoint      
;  tmp = min(abs(d.x - time_double(date)),probe_pos)
;      
;  tplotxy,varname,versus='xry',/over,color=color,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
;  plotxy,reform(d.y[probe_pos,*],1,3),psym=8,color=color,symsize=symsize,versus='xry',/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick
;  
;  
;endfor

;----------------------------------------------------


;----------------IMAGE EXPORT CODE HERE----------------------------------
;Uncomment to generate png of XY plot
;makepng,'XYplot'

;Uncomment next 3 lines to generate PS of XY plot
;popen,'XYplot',encapsulated=encapsulated,land=landscape
;
;tplotxy
;
;pclose

;------------------------------------------------------------------

stop

;********************************************************
;This section generates Ionospheric plot
;********************************************************

colors=['m','g','c','b']  ;colors for probes
probes = ['a','c','d','e'] ;the probes to be marked, Probe B doesn't reliably trace to the ionosphere with this time/date/model

A = FINDGEN(17) * (!PI*2/16.) ;makes a circular symbol to mark spacecraft position
USERSYM, COS(A), SIN(A), /FILL 

window,2,xsize=800,ysize=600

;----------------IMAGE EXPORT CODE HERE----------------------------------

;Uncomment this line and the pclose line at the end of the file to generate PS of Ionospheric plot
;NOTE: Data will not be plotted in the visible window when making this Postscipt
;popen,'IONOPlot',encapsulated=encapsulated,land=landscape

;------------------------------------------------------------------

;generate a grid with MLT on it
aacgm_plot,local_time='2008-03-27/02:00:00',map_scale=52e6,thick=linethick,mlinethick=linethick,charthick=charthick,charsize=charsize,/noborder

;load spacecraft position
thm_load_state,probe=probes,coord='geo'

time_clip,'th?_state_pos',sdate,edate,/replace

;trace footpoints and label
for i = 0,n_elements(probes)-1 do begin

  probe=probes[i]
  color=(get_colors(colors[i]))[0]

  outname = 'th'+probe+'_ifoot'

  ttrace2iono,'th'+probe+'_state_pos',external_model=model,/km,$
    par=par,in_coord='geo',out_coord='geo',newname=outname

  xyz_to_polar,outname

  get_data,outname+'_phi',data=d

  ;skip if data doesn't exist
  if ~is_struct(d) then continue

  i_lon=d.y

  get_data,outname+'_th',data=d

  i_lat=d.y
  
  plots,i_lon,i_lat,color=color,thick=linethick
  
  tmp = min(abs(d.x - time_double(date)),probe_pos)
  
  plots,i_lon[probe_pos],i_lat[probe_pos],psym=8,color=color,symsize=symsize,thick=linethick
  
endfor

;--------------------------------------
;This section overplots ground station position on the map
;get groundstation positions
;thm_asi_stations,labels,locations
;
;plotting 4 ground stations from the list(of 24)
;for stations not in this list, you'll need to look up the location
;for i = 0,4-1 do begin
;
;  print,labels[i]
;  plots,locations[1,i*6],locations[0,i*6],psym=6,color=(i mod 7)+1,symsize=symsize,thick=linethick
;
;endfor
;-------------------------------------

;-----------------------------------
;This section traces goes footpoints
; and plots their position on the map
;
;goesprobes=['g10']
;g_color = 6
;
;for i = 0,n_elements(goesprobes)-1 do begin
;
;  probe=goesprobes[i]
;
;  g_in_name = probe+'_pos_gei'
;  g_out_name = probe+'_footpoint'
;
;  thm_load_goesmag,probe=probe
;  time_clip,g_in_name,sdate,edate,/replace
;  ttrace2iono,g_in_name,external_model=model,/km,$
;    par=par,in_coord='gei',out_coord='geo',newname=g_out_name
;    
;  xyz_to_polar,g_out_name
;
;  get_data,g_out_name+'_phi',data=d
;
;  ;skip plot if data unavailable
;  if ~is_struct(d) then continue
;
;  i_lon=d.y
;
;  get_data,g_out_name+'_th',data=d
;
;  i_lat=d.y
;    
;  plots,i_lon,i_lat,color=g_color,thick=linethick
;  tmp = min(abs(d.x - time_double(date)),probe_pos)
;  plots,i_lon[probe_pos],i_lat[probe_pos],psym=8,color=g_color,symsize=symsize,thick=linethick
;  
;endfor
;----------------

;----------------IMAGE EXPORT CODE HERE----------------------------------

;Uncomment this line to generate PS of ionospheric plot
;pclose

;Uncomment to make png of ionospheric plot
;makepng,'IONOplot'

;------------------------------------------------------------------

 
end
