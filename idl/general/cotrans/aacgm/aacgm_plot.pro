;+
;
;Procedure: AACGM_PLOT
;
;Description:  Parameterized aacgm coordinate plotting routine. Run the routine with the appropriate coordinates
;              and it will plot a grid representing corrected geomagnetic coordinates in magnetic local time.  If
;              you provide no local time, this routine will assume a local time of 2008-01-01/00:00:00 UT
;
;              Based upon aacgm_example of Eric Donovan @ U. Calgary
;              This routine uses AACGM code written by R.J. Barnes,Kile Baker, and Simon Wing.  Their AACGM code was
;              modified slightly for use in the themis distribution.
;
;Keywords(All input lats/lons are in degrees):   
; 
; lat_center:   The latitudinal center of the projection that you want to plot.(Default: 62)
; lon_center:   The longitudinal center of the projection that you want to plot.(Default: 256)
; map_scale:  Set the scale of the map presented. This is the same as the map scale argument to
;             other idl mapping routines. (Default: 42e6)
; height:  The height at which coordinates should be plotted.  Note that coordinates may not be 
;          calculable at low heights when plotting near the equator.(Default: 110) 
; local_time: The time in UT that should be assumed for MLT(default: '2008-01-01/00:00:00' UT)
; lat_range:  A two element array that represents the maximum and minimum latitude
;             that should be calculated.  Smaller ranges speed up calculations.(Default: [50,70])
; lon_range:  A two element array that represents the maximum and minimum longitude
;             that should be calculated(in local magnetic coords) Smaller ranges speed up 
;             calculations. (Default: [0,360])
; lat_step:  The size of latitudinal steps between lines. (Default:5)
; lon_step:  The size of longitudinal steps between lines. (Default:15)
; lab_step:  The number of N-S lines between labels (Default: 6)
; n_lat_pts: The number of points per globe to use when drawing E-W lines. (Default: 360)
; n_lon_pts: The number of points per globe to use when drawing N-S lines. (Default: 180)
; lab_pos:  The argument controls the position of the labels in the N-S direction
;           0: Draws the labels at the closest latitude to the equator(Default)
;           1: Draws the labels at the maximum latitude in the range.
;           -1: Draws the labels at the minimum latitude in the range
;  projection:  The type of projection as a string.  Default is 'orthographic', but you can select any
;           of the projections that are usually available to the map set routine. To see a list
;           of available projections type: 'MAP_PROJ_INFO, PROJ_NAMES=names & print,names'  
;           
; You can also pass in any keywords that the plot command or the map_set command take.  These can be useful for
; things like controlling line thickness when exporting graphics.
; 
; Notes:  
; 1. This routine loads the AACGM coefficients for the current time period( 2005-2010)  If
;    this routine is being used for times outside this period, features need to be added to
;    utilize the aacgmidl routines that load other coordinate sets.
;    
; 2. If you can think of any features that might ease usability please feel free to contact us.
; 
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-09-18 15:48:50 -0700 (Thu, 18 Sep 2008) $
; $LastChangedRevision: 3517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/aacgm/aacgm_plot.pro $
; 
;-

;helper function to print floating point numbers
;the built in routines for int to string conversion 
;leave a bit to be desired  
function fltstring,d,precision=precision

  compile_opt hidden,idl2

  if ~keyword_set(precision) then precision = 18

  if d lt 0 then neg='-' else neg=''

  dt = abs(d)

  d_front = ulong64(dt)

  d_back = ulong64((dt - floor(dt,/l64)) * 10ULL^ulong64(precision)) 

  format = '(I0' + strcompress(string(precision),/remove_all) + ')'

  return,neg+strcompress(string(d_front),/remove_all) + '.' + strcompress(string(d_back,format=format),/remove_all)

end

;mod in idl doesn't work like it does in math or in most other languages
;mod should return a number on the interval [0,m-1] but instead returns a number
;on the interval [-m+1,m-1]. This routine corrects that bug for all positive moduli. 
;Negative moduli should return a number on the interval [-m+1,0]
;This function fixes that
function modp,n,m

  compile_opt hidden, idl2

  return, ((n mod m) + m) mod m

end

;This routine is a little syntactic sugar for the magnetic local time
;conversion.  It takes a time as a string and a reference longitude(generally 0)
;It returns the number of degrees of longitudinal offset from the reference line
function mlt_tm,time,l

  compile_opt hidden,idl2
  
  ts = time_struct(time)
  
  secs = ts.doy*24*60*60+ts.sod
  
  mlt_hrs = calc_mlt(ts.year,secs,l)
  
  return, 360.*mlt_hrs/24.
  
end

pro aacgm_plot, $
  lat_center=lat_center, $
  lon_center=lon_center, $
  map_scale=map_scale, $
  height=height, $
  local_time=local_time, $
  lat_range=lat_range, $
  lon_range=lon_range, $
  lat_step=lat_step, $
  lon_step=lon_step, $
  lab_step=lab_step, $
  n_lat_pts = n_lat_pts, $
  n_lon_pts = n_lon_pts, $
  lab_pos=lab_pos,$
  projection=projection,$
  _extra=_extra

   compile_opt idl2

   aacgmidl
  
   ;set defaults
  
   if ~keyword_set(lat_center) then begin
     lat_center = 62
   endif
   
   if ~keyword_set(lon_center) then begin
     lon_center = 256
   endif
   
   if ~keyword_set(map_scale) then begin
     map_scale = 42e6
   endif
   
   if ~keyword_set(lat_step) then begin
     lat_step = 5
   endif
   
   if ~keyword_set(lon_step) then begin
     lon_step = 15
   endif
   
   if ~keyword_set(lab_step) then begin
     lab_step = 6
   endif
   
   if ~keyword_set(height) then begin
     height = 110
   endif
   
   n_lat = 180 / lat_step
   
   n_lon = 360 / lon_step
 
   if ~keyword_set(lat_range) then begin  
     lat_range = [50,70]
   endif
   
   if ~keyword_set(lon_range) then begin
     lon_range = [0,360]
   endif
   
   if ~keyword_set(local_time) then begin
     local_time = '2008-01-01/00:00:00'
     lab_suffix = ' UT'
   
   endif else begin
     lab_suffix = ' MLT'
   endelse
     
   
   if ~keyword_set(n_lat_pts) then begin 
     n_lat_pts=360
   endif
   
   if ~keyword_set(n_lon_pts) then begin
     n_lon_pts=180
   endif
   
   if ~keyword_set(lab_pos) then begin
     lab_pos = 0
   endif
   
   if ~keyword_set(projection) then begin
     projection = 'orthographic'
   endif

   ;generate a map with continents placed appropriately, centered at the requested location, and at the proper scale
   map_set,name=projection,lat_center,lon_center,scale=map_scale,/continents,_extra=_extra

   ;-------------------------------------------------------------------------------
   ;mlat contours
   ;When this code runs, the data for the E-W lines is drawn
   ;(across longitude along latitude) 
   ;This is done by creating a set of E-W lines in AACGM coordinates,
   ;shifting it in the longitudinal direction by the appropriate local time
   ;offset, and then translating into geographic coordinates with cvn_aacgm
   ;
 
   ;generate the input latitudes
   in_lats = findgen(n_lat)*lat_step - 90
  
   ;this restricts them to the requested range latitudinal subset, if the whole 
   ;range is not selected
   if lat_range[1] - lat_range[0] lt 180 then begin
    
     idx = where(modp(in_lats-lat_range[0],180) ge 0 and modp(in_lats-lat_range[0],180) le modp(lat_range[1]-lat_range[0],180))
   
     in_lats = in_lats[idx]
     
   endif
   
   ;this generates a bunch of points across longitudes at the requested latitudes
   ;n_lat_pts is essentially the resolution of the E-W lines that will be
   ;drawn
   in_lons = findgen(n_lat_pts) * 360. / n_lat_pts
   
   ;this restricts the E-W lines to the requested longitudinal subset
   ;if the whole range is not selected
   if lon_range[1] - lon_range[0] lt 360 then begin
   
     idx = where(modp(in_lons-lon_range[0],360) ge 0 and modp(in_lons-lon_range[0],360) le modp(lon_range[1]-lon_range[0],360))
     
     in_lons = in_lons[idx]
     
     idx = sort(modp(in_lons-lon_range[0],360))
     
     in_lons = in_lons[idx]
     
   endif
   
   ;allocate memory for output in GEO
   v_lat=fltarr(n_elements(in_lats),n_elements(in_lons))
   v_lon=fltarr(n_elements(in_lats),n_elements(in_lons))
   
   ;convert the data
   for i=0,n_elements(in_lats)-1 do begin
     for j=0,n_elements(in_lons)-1 do begin
        cnv_aacgm,in_lats[i],modp(in_lons[j]-mlt_tm(local_time,0),360),height,u,v,r,error,/geo
        if error ne 0 then begin
          v_lat[i,j] = !VALUES.F_NAN
          v_lon[i,j] = !VALUES.F_NAN
        endif else begin
          v_lat[i,j] = u
          v_lon[i,j] = v
        endelse
     endfor
   endfor
   
   ;plot the latitudinal lines(at specific latitudes across longitude)
   for i=0,n_elements(in_lats)-1 do oplot,v_lon[i,*],v_lat[i,*],_extra=_extra
   
   ;-------------------------------------------------------------------------------
   ;mlon contours
   ;When this code runs is the data for the N-S lines is drawn
   ;(along longitude across latitude) 
   ;This is done by creating a set of longitude lines in AACGM coordinates,
   ;shifting it in the longitudinal direction by the appropriate local time
   ;offset, and then translating into geographic coordinates with cvn_aacgm
   ;

   ;generate the positions of the N-S line
   in_lons = findgen(n_lon)*lon_step
   
   ;restrict the N-s lines to a subset of the whole planet longitude,
   ;if requested
   if lon_range[1] - lon_range[0] lt 360 then begin
   
     idx = where(modp(in_lons-lon_range[0],360) ge 0 and modp(in_lons-lon_range[0],360) le modp(lon_range[1]-lon_range[0],360))
     
     in_lons = in_lons[idx]
     
   endif
   
   ;this generates a bunch of points across latidues at the requested longitudes
   ;n_lon_pts is essentially the resolution of the longitude lines that will be
   ;drawn
   in_lats = findgen(n_lon_pts) * 180 / n_lon_pts - 90
   
   ;restrict these lines to a subset of the whole planet longitude, if requested
   if lat_range[1] - lat_range[0] lt 180 then begin
    
     idx = where(modp(in_lats-lat_range[0],180) ge 0 and modp(in_lats-lat_range[0],180) le modp(lat_range[1]-lat_range[0],180))
   
     in_lats = in_lats[idx]
     
     idx = sort(modp(in_lats-lat_range[0],180))
     
     in_lats = in_lats[idx]
     
   endif
   
   ;generate memory for the output in GEO
   u_lat=fltarr(n_elements(in_lats),n_elements(in_lons))
   u_lon=fltarr(n_elements(in_lats),n_elements(in_lons))

   ;do the conversion from AACGM to GEO
   for i=0,n_elements(in_lats)-1 do begin
     for j=0,n_elements(in_lons)-1 do begin
        cnv_aacgm,in_lats[i],modp(in_lons[j]-mlt_tm(local_time,0),360),height,u,v,r,error,/geo
        if error ne 0 then begin
          u_lat[i,j] = !VALUES.F_NAN
          u_lon[i,j] = !VALUES.F_NAN
        endif else begin
          u_lat[i,j] = u
          u_lon[i,j] = v
        endelse
     endfor
   endfor

  ;print the code
  for i=0,n_elements(in_lons)-1 do oplot,u_lon[*,i],u_lat[*,i],_extra=_extra


  ;--------------------------------------------------------------
  ;This code prints out the labels at a subset of longitude lines
 
  ;pick the appropriate latitude for output
  if lab_pos eq 0 then begin
    tmp = min(abs(u_lat[*,0]),idx,/nan) 
  endif else if lab_pos eq 1 then begin
    tmp = max(u_lat[*,0],idx,/nan)
  endif else if lab_pos eq -1 then begin
    tmp = min(u_lat[*,0],idx,/nan)
  endif
  
  ;now loop over N-S lines; placing a label every lab_step
  i=0
  
  while i lt n_elements(in_lons) do begin
  
    xyouts,u_lon[idx,i],u_lat[idx,i],fltstring(in_lons[i]/15,p=2) + lab_suffix,_extra=_extra,charsize=1.5,charthick=2.0,alignment=.5
    i+= lab_step
  
  endwhile

return
end