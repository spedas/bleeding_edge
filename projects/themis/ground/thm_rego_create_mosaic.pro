;+
; NAME:
;    THM_REGO_CREATE_MOSAIC
;
; PURPOSE:
;    create mosaic with all REGO ASI
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    THM_REGO_CREATE_MOSAIC,time
;
; INPUTS:
;    Time	like '2006-01-01/05:00:00'
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    cal_files		calibration files if they do not need to be read
;    pgm_file   	do not read CDF, but pgm-files
;    verbose    	print some diagnostics
;    insert		insert stop before end of program
;
;    gif_out    	create a gif-file
;    gif_dir		directory for gif-output
;
;    exclude   		string of station names that should not be plotted
;    show      		string of station names that should only be plotted
;    minval		minimum value for black
;    maxval		maximum value for white
;    minimum_elevation	minimum elevation to plot in degrees
;    mask		mask certain parts of image
;
;    scale              scale for map set
;    central_lon        geographic longitude of center of plot
;    central_lat        geographic latitude of center of plot
;    rotation		rotate map
;    projection 	projection for map set, MAP_PROJ_INFO, PROJ_NAMES=names
;    color_continent    shade of continent fill
;    color_background   shade of background
;
;    zbuffer   		do in z-buffer, not on the screen
;    cursor    		finish with cursor info, loop if cursor>1
;    window    		set window number
;    xsize              xsize of window
;    ysize              ysize of window
;    position=position  position of plot on window (normal coordinates)
;    noerase=noerase    do not erase current window (no effect if {x,y}size set
;    keep_z		keep z-buffer open for further plotting
;
;    no_grid=no_grid	do not plot geomagnetic grid
;    no_midnight=no_midnight	do not plot midnight meridian
;    no_label		do not label mosaic with date and time
;    add_plot           stop because we want to add something
;    force_map		plot map even if there are no images
;
;    xy_pos             xy position
;    location		mark geographic location [lo,la]
;    track1             mark geographic location [lo,la]
;    track2             mark geographic location [lo,la]
;
;    top       		top color to be used for polyfill
;    no_color		do not load color table, use existing
;    xy_cursor		create array of cursor selected values to pass to upper program
;    ssize		size of symbol for location
;    sym_color		color of location
;
;    stoptime		create multiple mosaics
;    timestep		time steps for multiple mosaics in seconds
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    None
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    None
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;    THM_REGO_CREATE_MOSAIC,'2014-12-01/00:50:00'
;    THM_REGO_CREATE_MOSAIC,'2014-12-01/00:50:00',/thumb,exclude='atha'
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey, 02/06/2007
;                based on example from Donovan/Jackel
;
;                2007-03-15, hfrey, thumbnails, keyword exclude
;                2007-03-27, hfrey, special treatment for not mapped thumbsnails
;                2007-12-21, jmm, added explicit set_plot,'z' for zbuffer
;                2008-07-21, jmm, added gif_dir, for output directory option
;                2009-06-17, hfrey, a few additions to make my life easier
;		 2009-11-10, cgabrielse, added xy_cursor keyword for
;		 sending cursor values up level
;                2012-07-02,  jmm, Added color_annotation keyword
;                2015-07-21, hfrey, adapted for REGO images
;
; NOTES:
;
; VERSION:
;   $LastChangedBy: hfrey $
;   $LastChangedDate: 2014-01-07 12:17:57 -0800 (Tue, 07 Jan 2014) $
;   $LastChangedRevision: 13811 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_asi_create_mosaic.pro $
;
;-

PRO THM_REGO_CREATE_MOSAIC,time,$
    cal_files=cal_files,$              ; calibration files already read
    gif_out=gif_out,$                  ; output in gif file
    verbose=verbose,$                  ; print debug messages
    pgm_file=pgm_file,$                ; read raw pgm files
    thumb=thumb,$                      ; force thumbnails over full images
    exclude=exclude,$                  ; exclude certain stations
    top=top,$                          ; set top value for image
    show=show,$                        ; limit stations shown
    scale=scale,$                      ; scale for map set
    central_lat=central_lat,$          ; geographic latitude of center of plot
    central_lon=central_lon,$          ; geographic longitude of center of plot
    color_continent=color_continent,$  ; shade of continent fill
    color_background=color_background,$; shade of background
    position=position,$                ; position of plot on window (normal coordinates)
    xsize=xsize,$                      ; xsize of window
    ysize=ysize,$                      ; ysize of window
    noerase=noerase,$                  ; do not erase current window (no effect if {x,y}size set)
    zbuffer=zbuffer,$		       ; do it in z-buffer
    cursor=cursor,$		       ; finish with cursor info
    projection=projection,$	       ; map projection
    maxval=maxval,$		       ; brightness scaling of images
    minval=minval,$                    ; brightness scaling of images
    window=window,$      	       ; set window number
    rotation=rotation,$                ; rotate map away from North up
    full_minute=full_minute,$          ; process a full minute of pgm files
    minimum_elevation=minimum_elevation,$ ; set minimum elevation
    gif_dir=gif_dir,$                  ; An output directory for the gif output, default is the local working dir.
    force_map=force_map,$              ; force display of empty map
    no_grid=no_grid,$                  ; do not plot grid
    no_midnight=no_midnight,$          ; do not plot midnight meridian
    add_plot=add_plot,$                ; stop so we can add something
    mask_file=mask_file,$    		; mask part of image
    xy_pos=xy_pos,$			; mark specific x,y-location
    location=location,$			; mark geographic location=[long,lat] or [[lo,la],[lo,la],[lo,la]]
    no_color=no_color, $		; do not load color table
    xy_cursor=xy_cursor,$		; create an array that records the cursor output and passes it to upper program
    track1=track1,$			; mark geographic location=[long,lat] or [[lo,la],[lo,la],[lo,la]]
    track2=track2,$			; mark geographic location=[long,lat] or [[lo,la],[lo,la],[lo,la]]
    ssize=ssize,$			; size of symbol for location
    sym_color=sym_color,$		; color of location
    keep_z=keep_z,$			; keep z-buffer open
    stoptime=stoptime,$			; create multiple mosaics
    timestep=timestep,$			; time step in seconds for multiple mosaics
    color_annotation = color_annotation,$ ; color for annotation, via xyouts
    insert=insert,$			; insert stop before end of program
    no_label=no_label,$			; do not label mosaic with date and time
    autocenter=autocenter

	; input check
if keyword_set(verbose) then verbose=systime(1)
if (strlen(time) ne 19) then begin
  dprint, 'Wrong time input'
  dprint, 'Correct value like 2006-01-01/05:00:00'
  return
  endif
if keyword_set(xy_pos) then begin
  dd=size(xy_pos)
  if (dd[2] ne 2) then begin
      dprint, 'XY_pos input wrong!'
      dprint, 'Needs to be given like [[x1,x2,x3,x4,x5,...],[y1,y2,y3,y4,y5,...]]'
      return
      endif
  endif

	; check brightness scaling
if keyword_set(maxval) then begin
  if not keyword_set(minval) then begin
     dprint, 'minval has to be set with maxval'
     return
     endif
  if not keyword_set(show) then begin
     dprint, 'Show has to be set with maxval'
     return
     endif
  if n_elements(show) ne n_elements(maxval) then begin
     dprint, 'N_elements of show and maxval have to match'
     return
  endif
  endif

	; strip time
res=time_struct(time)
year=res.year
month=res.month
day=res.date
hour=res.hour
minute=res.min
second=res.sec

	; setup
thm_init
timespan,time,1,/hour
thm_asi_stations,site,loc
	; add RESU site to list
site=[site,'RESU']
loc=[[loc],[74.7330   ,   265.100]]

	; some more setup
if keyword_set(zbuffer) then map_scale=2.6e7 else map_scale=4.e7
if keyword_set(scale) then map_scale=scale
if not keyword_set(central_lon) then central_lon=255.
if not keyword_set(central_lat) then central_lat=64.
if not keyword_set(xsize) then xsize=500
if not keyword_set(ysize) then ysize=450
if not keyword_set(top) then top=254

	; characters
if keyword_set(zbuffer) then chars=1.15 else chars=1.5

	; some setup
if keyword_set(minimum_elevation) then minimum_elevation_to_plot=minimum_elevation else minimum_elevation_to_plot=8. ;degrees
if (keyword_set(thumb)) then n1=1024l else n1=512l*512l

;color for annotation
If keyword_set(color_annotation) Then xyouts_color = color_annotation[0] Else xyouts_color = 0

     	; clean up before start
names=tnames('clg_as*')
if (names[0] ne '') then store_data,delete=names

	; load cal_files once for the whole loop
if keyword_set(stoptime) then begin
  if keyword_set(show) then thm_load_asi_cal,show,cal_files,/rego else $
  thm_load_asi_cal,'atha fsmi fsim gill rank resu talo',cal_files,/rego
  endif

	; automatic center plot
if keyword_set(autocenter) then begin
   thm_load_asi_cal,show[0],cal_file0
   central_lat=*cal_file0.vars[21].dataptr
   central_lon=*cal_file0.vars[20].dataptr
   endif

	; point to run another mosaic
repeat_loop:

	; search for midnight file
if not keyword_set(no_midnight) then begin
  f=file_search('midnight.sav',count=midnight_count)
  if (midnight_count eq 1) then begin
    midlons=fltarr(40)+!values.f_nan
    ut_hour=float(hour)+float(minute)/60.+float(second)/3600.
    restore,f
    for i=0,39 do begin
      lon=interpol(findgen(141)+start_longitude,reform(midnight[i,*]),ut_hour)
      midlons[i]=lon[0]
      endfor
    bad=where(midlons gt 360.,count)
    if (count gt 0) then midlons[bad]=!values.f_nan
    endif
  endif else midnight_count=0

	; read available data
thm_rego_array,year,month,day,hour,minute,second,strlowcase(site),$
        image,corners,elevation,pixel_illuminated,n_sites,verbose=verbose,$
        cal_files=cal_files,thumb=thumb,$
        show=show,exclude=exclude,insert=insert

	; exclude unwanted sites
if keyword_set(exclude) then begin
  for i=0,n_elements(exclude)-1 do begin
    not_site=where(strlowcase(site) eq strlowcase(exclude[i]),count)
    if (count eq 0) then dprint, 'Not a valid site: ',exclude[i] else begin
        corners[*,*,*,not_site]=!values.f_nan
        image[*,not_site]=!values.f_nan
        endelse
    endfor
  endif

	; fill variables
bytval=fltarr(n_sites)+1.
bitval=fltarr(n_sites)
if keyword_set(maxval) then begin
  for i=0,n_elements(maxval)-1 do begin
    index=where(strlowcase(site) eq strlowcase(show[i]))
    bytval[index]=maxval[i]
    bitval[index]=minval[i]
    endfor
  for i=0,n_sites-1 do image[*,i]=bytscl(image[*,i],min=bitval[i],max=bytval[i])
  endif else begin
  if keyword_set(special) then for i=0,n_sites-1 do bytval[i]=(median(image[0:1023,i]) > 1) else begin
     if keyword_set(full_minute) then begin
        for i=0,n_sites-1 do bytval[i]=(median(image[*,i,*]) > 1)
        for i=0,n_sites-1 do image[*,i,*]=((image[*,i,*]/bytval[i])*64.) < 254
        endif else begin ; prevent divide by zero
        for i=0,n_sites-1 do bytval[i]=(median(image[*,i]) > 1) ; prevent divide by zero
        for i=0,n_sites-1 do image[*,i]=((image[*,i]/bytval[i])*64.) < 254
        endelse
     endelse
  endelse

	; no images found
if (max(bytval) eq 1.) then begin
  dprint, 'No images for ',time
  if not keyword_set(force_map) then begin
     if keyword_set(gif_out) then gif_out=''
     if double(!version.release) lt 8.0d then heap_gc
     return
     endif
  endif

	; exclude unwanted sites
if keyword_set(exclude) then begin
  for i=0,n_elements(exclude)-1 do begin
    not_site=where(strlowcase(site) eq strlowcase(exclude[i]),count)
    if (count eq 0) then dprint, 'Not a valid site: ',exclude[i] else begin
        corners[*,*,*,not_site]=!values.f_nan
        bytval[not_site]=!values.f_nan
        endelse
    endfor
  endif

;=========================================================================
	; generate images for full minute
if keyword_set(full_minute) then begin
time_start=time

	; run through images
for ikk=0,19 do begin

;zbuffer needs to be set before the loadct call in thm_map_set,
;otherwise this bombs the second time through because of reset to 'x'
;later in this program, jmm 21-dec-2007
if(keyword_set(zbuffer)) then set_plot, 'z'

; set up the map
thm_map_set,scale=map_scale,$
     central_lat=central_lat,$           ; geographic latitude of center of plot
     central_lon=central_lon,$           ; geographic longitude of center of plot
     color_continent=color_continent,$   ; shade of continent fill
     color_background=color_background,$ ; shade of background
     position=position,$                 ; position of plot on window (normal coordinates)
     xsize=xsize,$                       ; xsize of window
     ysize=ysize,$                       ; ysize of window
     noerase=noerase,$                   ; do not erase current window (no effect if {x,y}size set
     zbuffer=zbuffer,$
     projection=projection,$
     window=window,$
     rotation=rotation,$
     no_color=no_color

	; normal filling
for pixel=0l,n1-1l do begin
  for i_site=0,n_sites-1 do begin
    if ((pixel_illuminated[pixel,i_site] eq 1) and $
           (elevation[pixel,i_site] gt minimum_elevation_to_plot)) then $
       polyfill,corners[pixel,[0,1,2,3,0],0,i_site],$
            corners[pixel,[0,1,2,3,0],1,i_site],color=image[pixel,i_site, ikk] < top
    if keyword_set(special) then if ((spec_illu[pixel*64 < (n1-1),i_site] eq 1) and $
           (elevation[pixel*64 < (n1-1),i_site] gt minimum_elevation_to_plot)) then begin
       for ijk=0,63 do polyfill,corners[pixel*64+ijk < (n1-1),[0,1,2,3,0],0,i_site],$
            corners[pixel*64+ijk < (n1-1),[0,1,2,3,0],1,i_site],color=image[pixel*64+ijk < (n1-1),i_site] < top
;       stop
       endif
    endfor
  endfor

	; finish map
return_lons=1
return_lats=1
if not keyword_set(no_grid) then thm_map_add,invariant_lats=findgen(4)*10.+50.,invariant_color=210,$
    invariant_linestyle=1,/invariant_lons,return_lons=return_lons,$
    return_lats=return_lats
time=time_string(time_double(time_start)+ikk*3)

if not keyword_set(no_label) then begin
  xyouts,0.005,0.018,time,color=xyouts_color,/normal,charsize=chars
  xyouts,0.005,0.060,'REGO ASI',color=xyouts_color,/normal,charsize=chars
  endif

	; plot midnight file
if (not keyword_set(no_midnight) and midnight_count eq 1) then $
   plots,smooth(midlons-360.,5),findgen(40)+40.,color=255,/data

	; gif output
if keyword_set(gif_out) then begin
   If(keyword_set(gif_dir)) Then gdir = gif_dir Else gdir = './';jmm, 21-jul-2008
   tvlct,r,g,b,/get
   img=tvrd()
	; strip time because it changes through the loop
   res=time_struct(time)
   year=res.year
   month=res.month
   day=res.date
   hour=res.hour
   minute=res.min
   second=res.sec
   out_name='REGO.'+year+'.'+month+'.'+day+'.'+hour+'.'+minute+'.'+second+'.gif'
   write_gif,gdir+out_name,img,r,g,b
   dprint, 'Output in ',out_name
   gif_out=out_name
   endif

if keyword_set(zbuffer) then zbuffer=tvrd()
if not keyword_set(keep_z) and keyword_set(zbuffer) then begin
     device,/close
     set_plot,'x'
   endif

endfor
endif else begin	; end of full_minute loop
;=========================================================================

;zbuffer needs to be set before the loadct call in thm_map_set,
;otherwise this bombs the second time through because of reset to 'x'
;later in this program, jmm 21-dec-2007
if(keyword_set(zbuffer)) then set_plot, 'z'

	; set up the map
thm_map_set,scale=map_scale,$
     central_lat=central_lat,$           ; geographic latitude of center of plot
     central_lon=central_lon,$           ; geographic longitude of center of plot
     color_continent=color_continent,$   ; shade of continent fill
     color_background=color_background,$ ; shade of background
     position=position,$                 ; position of plot on window (normal coordinates)
     xsize=xsize,$                       ; xsize of window
     ysize=ysize,$                       ; ysize of window
     noerase=noerase,$                   ; do not erase current window (no effect if {x,y}size set
     zbuffer=zbuffer,$
     projection=projection,$
     window=window,$
     rotation=rotation,$
     no_color=no_color

	; normal filling
for pixel=0l,n1-1l do begin
  for i_site=0,n_sites-1 do begin
    if ((pixel_illuminated[pixel,i_site] eq 1) and $
           (elevation[pixel,i_site] gt minimum_elevation_to_plot)) then $
       polyfill,corners[pixel,[0,1,2,3,0],0,i_site],$
            corners[pixel,[0,1,2,3,0],1,i_site],color=image[pixel,i_site] < top
    if keyword_set(special) then if ((spec_illu[pixel*64 < (n1-1),i_site] eq 1) and $
           (elevation[pixel*64 < (n1-1),i_site] gt minimum_elevation_to_plot)) then begin
       for ijk=0,63 do polyfill,corners[pixel*64+ijk < (n1-1),[0,1,2,3,0],0,i_site],$
            corners[pixel*64+ijk < (n1-1),[0,1,2,3,0],1,i_site],color=image[pixel*64+ijk < (n1-1),i_site] < top
       endif
    endfor
  endfor

	; finish map
return_lons=1
return_lats=1
thm_map_add,invariant_lats=findgen(4)*10.+50.,invariant_color=210,$
    invariant_linestyle=1,/invariant_lons,return_lons=return_lons,$
    return_lats=return_lats,no_grid=no_grid

if not keyword_set(no_label) then begin
  xyouts,0.005,0.018,time,color=xyouts_color,/normal,charsize=chars
  xyouts,0.005,0.060,'REGO ASI',color=xyouts_color,/normal,charsize=chars
  endif

if keyword_set(verbose) then dprint, 'After map: ',systime(1)-verbose,$
   ' Seconds'

	; search for midnight file
if (not keyword_set(no_midnight) and midnight_count eq 1) then $
   plots,smooth(midlons-360.,5),findgen(40)+40.,color=255,/data

	; stop so we can add something
if keyword_set(add_plot) then stop

	; mark ground tracks of satellites
if keyword_set(track1) then begin
   plots,track1[0,*],track1[1,*],psym=3
   endif

if keyword_set(track2) then begin
   plots,track2[0,*],track2[1,*],psym=4
   endif

if keyword_set(location) then begin
   if keyword_set(ssize) then ssize=ssize else ssize=1
   if keyword_set(sym_color) then scolor=sym_color else scolor=255
   plots,location[0,*],location[1,*],psym=2,symsize=ssize,color=scolor
   endif

if keyword_set(cursor) then begin
   ss=size(cursor)
   xy_cursor=fltarr(cursor,4)
   if (ss[1] ne 2) then cursor=1
   for loop=1,cursor do begin
     dprint, 'Point cursor on map!'
     cursor,x,y,/data
     wait,0.25
     res=convert_coord(x,y,/data,/to_device)
     dprint, 'Location: ',res,x,y
     xy_cursor[loop-1L,*]=[res[0],res[1],x,y]
     endfor
   endif

; input like [[x1,x2,x3,x4,x5,...],[y1,y2,y3,y4,y5,...]]
if keyword_set(xy_pos) then begin
   dd=size(xy_pos)
   if (dd[0] eq 1) then begin
     res=convert_coord(xy_pos[0],xy_pos[1],/to_data,/device)
     dprint, 'Location: ',xy_pos,res[0:1],format='(a12,2i5,2f10.3)'
     xy_pos_out=[xy_pos[0],xy_pos[1],res[0],res[1]]
     endif else begin
     xy_pos_out=fltarr(dd[1],4)
     res=convert_coord(xy_pos[*,0],xy_pos[*,1],/to_data,/device)
     for i1=0L,dd[1]-1L do begin
       dprint, 'Location: ',xy_pos[i1,*],res[0:1,i1],format='(a12,2i5,2f10.3)'
       xy_pos_out[i1,*]=[xy_pos[i1,0],xy_pos[i1,1],res[0,i1],res[1,i1]]
       endfor
     endelse
   xy_pos=xy_pos_out
   endif

	; gif output
if keyword_set(gif_out) then begin
   If(keyword_set(gif_dir)) Then gdir = gif_dir Else gdir = './'
   tvlct,r,g,b,/get
   img=tvrd()
   	; now add the secret code of input parameters
   img[40:43,0]=[13,251,117,239]
   	; time of mosaic
   img[0:6,0]=[year/100,year-(year/100)*100,month,day,hour,minute,second]
   	; thumb flag
   if keyword_set(thumb) then img[7,0]=1 else img[7,0]=0
   	; central_lon and lat of mosaic
   if (central_lon lt 0.) then central_lon=central_lon+360.
   img[8:12,0]=[fix(central_lon)/100,fix(central_lon)-(fix(central_lon)/100)*100,$
               fix((central_lon-fix(central_lon))*100),$
               fix(central_lat),fix((central_lat-fix(central_lat))*100)]
   	; map_scale
   res=strsplit(string(map_scale*1.e10),'e',/extract)
   img[13:15,0]=[fix(res[0]),fix((float(res[0])-fix(res[0]))*100),fix(res[1])-10]
	; xsize and ysize
   img[16:19,0]=[xsize/100,xsize-(xsize/100)*100,ysize/100,ysize-(ysize/100)*100]
  	; rotation
   if keyword_set(rotation) then begin
       if (rotation lt 0.) then rotation=rotation+360.
       img[20:22,0]=[fix(rotation/100),fix(rotation-(fix(rotation)/100)*100),$
             fix((rotation-fix(rotation))*100)]
       endif else img[20:22]=[0,0,0]
   	; minimum elevation
   img[23:24,0]=[fix(minimum_elevation_to_plot),$
       fix((minimum_elevation_to_plot-fix(minimum_elevation_to_plot))*100)]
   	; zbuffer
   if keyword_set(zbuffer) then img[25,0]=1 else img[25,0]=0
   	; code stations
   img[49,0]=n_sites
   for i1=0,n_sites-1 do begin
      case 1 of
      finite(bytval[i1]) eq 0: img[50+i1,0]=0
      bytval[i1] eq 1.: img[50+i1,0]=1
      bytval[i1] gt 1.: img[50+i1,0]=2
      endcase
      endfor
	; construct the name
   out_name='REGO.'+string(year,'(i4.4)')+'.'+string(month,'(i2.2)')+'.'+$
       string(day,'(i2.2)')+'.'+string(hour,'(i2.2)')+'.'+string(minute,'(i2.2)')+$
       '.'+string(second,'(i2.2)')+'.gif'
   write_gif,gdir+out_name,img,r,g,b
   dprint, 'Output in ',out_name
   gif_out=out_name
   tv,img
   endif

if keyword_set(zbuffer) then zbuffer=tvrd()
if not keyword_set(keep_z) and keyword_set(zbuffer) then begin
   device,/close
   set_plot,'x'
   endif

endelse	; single time
;=========================================================================

	; loop of mosaics
if keyword_set(stoptime) then begin
   if keyword_set(timestep) then new_time=time_double(time)+timestep else new_time=time_double(time)+3.d0
	; strip time
   res=time_struct(new_time)
   year=res.year
   month=res.month
   day=res.date
   hour=res.hour
   minute=res.min
   second=res.sec
   if (new_time le time_double(stoptime)) then begin
      time=time_string(new_time)
      goto,repeat_loop
      endif
   endif

if keyword_set(verbose) then dprint, 'Calculation took ',systime(1)-verbose,$
   ' Seconds'

if double(!version.release) lt 8.0d then heap_gc
if keyword_set(insert) then stop
end
