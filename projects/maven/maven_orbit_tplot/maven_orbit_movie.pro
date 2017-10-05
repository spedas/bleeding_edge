;+
; PROCEDURE:
;       maven_orbit_movie
; PURPOSE:
;       3D visualization of MAVEN orbit using IDL 8 new graphics
; CALLING SEQUENCE:
;       timespan,'2015-01-01'
;       maven_orbit_movie, dim=[640,480], rate=3600
; OPTIONAL KEYWORDS:
;       TRANGE: time range (if not present then timerange() is called)
;       DIMENSIONS: [width,height] (Def: half of the screen size)
;       MOVIENAME: name of the output movie file (Def: 'maven_orbit.mp4')
;       RATE: speed of the movie (Def: 4*3600 = 4 hr/sec)
;       FPS: frames per sec of the movie (Def: 20)
;       ZOOMSCALE: zoom in/out scale (Def: 1.5)
;       FONT_SIZE: font size of the time stamp (Def: 24)
;       BOXSIZE: minmax of the 3D box in km (Def: [-3.,3.]*R_M)
;       BCMODEL: specifies crustal field model (Def: 'morschhauser')
;       SNAP: if set, generate a snapshot instead of a movie
;       TSNAP: time of the snapshot (Def: start time of timerange())
;       FIGNAME: name of the snapshot file (Def: 'maven_orbit.png')
;                most file formats are acceptable
;                (http://www.exelisvis.com/docs/save_method.html)
;       CLOSEWIN: close the graphic window when finished
; CREATED BY:
;       Yuki Harada on 2015-11-04
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-12-08 15:45:18 -0800 (Tue, 08 Dec 2015) $
; $LastChangedRevision: 19545 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_movie.pro $
;-

function maven_orbit_movie_altidx, rmso
;- returns nominal region index[N] of rmso[N,3] in km
  R_M = 3389.9
  x = rmso[*,0]/R_M & y = rmso[*,1]/R_M & z = rmso[*,2]/R_M
  r = (x^2+y^2+z^2)^.5 & s = (y^2+z^2)^.5

  idx = replicate(0,n_elements(x)) ;- 0: SW

  x0  = 0.600 & ecc = 1.026 & L   = 2.081
  phm = 160.*!dtor
  phi   = atan(s,(x - x0))
  rho_s = sqrt((x - x0)^2. + s*s)
  shock = L/(1. + ecc*cos(phi < phm))
  w = where( rho_s lt shock , nw )
  if nw gt 0 then idx[w] = 1    ;- 1: sheath

  x0  = 0.640 & ecc = 0.770 &  L   = 1.080
  phi   = atan(s,(x - x0))
  rho_p = sqrt((x - x0)^2. + s*s)
  mpb = L/(1. + ecc*cos(phi))
  w = where( x gt 0 and rho_p lt mpb , nw )
  if nw gt 0 then idx[w] = 2    ;- 2: MPR
  x0  = 1.600 & ecc = 1.009 & L   = 0.528
  phi   = atan(s,(x - x0))
  phm = 160.*!dtor
  rho_p = sqrt((x - x0)^2. + s*s)
  mpb = L/(1. + ecc*cos(phi < phm))
  w = where( x le 0 and rho_p lt mpb , nw )
  if nw gt 0 then idx[w] = 2    ;- 2: MPR

   w = where( x le 0 and s le 1 , nw )
   if nw gt 0 then idx[w] = 3   ;- 3: wake

   return,idx
end


pro maven_orbit_movie, trange=trange, dimensions=dimensions, moviename=moviename, boxsize=boxsize, fps=fps, rate=rate, font_size=font_size, zoomscale=zoomscale, bcmodel=bcmodel, verbose=verbose, snap=snap, tsnap=tsnap, figname=figname, closewin=closewin

;- return if IDL version < 8
if float(!version.release) lt 8 then begin
   dprint,'This routine requires IDL version 8 or later...'
   return
endif

;- set parameters
R_M = 3389.9
tr = timerange(trange)
if ~keyword_set(dimensions) then dimensions = get_screen_size()/2.
if ~keyword_set(rate) then rate = 4.*3600. ;- 4 hr/sec
if ~keyword_set(boxsize) then boxsize = [-3.,3.]*R_M
if ~keyword_set(moviename) then moviename = 'maven_orbit.mp4'
if ~keyword_set(fps) then fps = 20.
if ~keyword_set(font_size) then font_size = 24
if ~keyword_set(zoomscale) then  zoomscale = 1.5
if ~keyword_set(bcmodel) then bcmodel = 'morschhauser'
if ~keyword_set(tsnap) then tsnap = tr[0] else tsnap = time_double(tsnap)
if ~keyword_set(figname) then figname = 'maven_orbit.png'


;- load spice if not loaded (trange is not checked)
if total(strlen(spice_test('*mvn*'))) eq 0 then mvn_spice_load, trange=trange, verbose=verbose


;- read in crustal field data
fbc = mvn_pfp_file_retrieve('maven/data/mod/bcrust/alt/' $
                            +bcmodel+'_400km_360x180_pc.sav', verbose=verbose)
if total(strlen(fbc)) gt 0 then begin
   restore,fbc
   br = model.br
   brlon = model.lon
   brlat = model.lat
endif else begin
   brlon = findgen(360)+.5
   brlat = findgen(180)-89.5
endelse
xbr = R_M * rebin(cos(brlon*!dtor),360,180) $
      *transpose(rebin(cos(brlat*!dtor),180,360))
ybr = R_M * rebin(sin(brlon*!dtor),360,180) $
      *transpose(rebin(cos(brlat*!dtor),180,360))
zbr = R_M * transpose(rebin(sin(brlat*!dtor),180,360))



;- set up a video stream
dtorb = double(rate)/double(fps)
nstep = long((tr[1] - tr[0])/dtorb) + 1
if ~keyword_set(snap) then begin
   ovid = idlffvideowrite(moviename)
   vidst = ovid.addvideostream(dimensions[0],dimensions[1],fps)
endif else nstep = 1


for irot=0,nstep-1 do begin     ;- movie loop start

   tnow = tr[0] + irot*dtorb
   if keyword_set(snap) then tnow = tsnap
   dprint,verbose=verbose,irot,' /',nstep,' : ',time_string(tnow)



;- set up graphic window
   if size(gr_win,/type) ne 0 then gr_win.erase else gr_win = window(dimensions=dimensions)
   gr_win.refresh,/disable
   gr_win.background_color='black'


;- set up a 3d box
   gr_box = plot3d(/nodata,/overplot,[0],[0],[0], $
                   aspect_r=1,aspect_z=1, $
                   xrange=boxsize,yrange=boxsize,zrange=boxsize, $
                   axis_style=0,/perspective)

;- add MSO axes
   gr_xax = plot3d(/data,/overplot,[0,max(boxsize)],[0,0],[0,0], $
                   color='blue',thick=2)
   gr_yax = plot3d(/data,/overplot,[0,0],[0,max(boxsize)],[0,0], $
                   color='green',thick=2)
   gr_zax = plot3d(/data,/overplot,[0,0],[0,0],[0,max(boxsize)], $
                   color='red',thick=2)



;- add Br/red surface
   if size(br,/type) ne 0 then begin
;- rotate into MSO (cf. quaternion_rotation.pro)
      q = spice_body_att('IAU_MARS','MAVEN_MSO',tnow, $ ;- using center time
                         /quaternion,verbose=verbose)
      t2 =   q[0]*q[1]
      t3 =   q[0]*q[2]
      t4 =   q[0]*q[3]
      t5 =  -q[1]*q[1]
      t6 =   q[1]*q[2]
      t7 =   q[1]*q[3]
      t8 =  -q[2]*q[2]
      t9 =   q[2]*q[3]
      t10 = -q[3]*q[3]

      xbr2 = 2*( (t8 + t10)*xbr + (t6 -  t4)*ybr + (t3 + t7)*zbr ) + xbr
      ybr2 = 2*( (t4 +  t6)*xbr + (t5 + t10)*ybr + (t9 - t2)*zbr ) + ybr
      zbr2 = 2*( (t7 -  t3)*xbr + (t2 +  t9)*ybr + (t5 + t8)*zbr ) + zbr
      brcol = bytescale(br,bottom=255,top=0,range=[-100,100])
      gr_br = surface(/overplot,/texture_interp, $
                      zbr2,xbr2,ybr2,texture_image=brcol,rgb_table=70)

      for ilat=-60,60,30 do begin   ;- lat grids
         xlat = R_M*cos(findgen(101)/50.*!pi)*cos(ilat*!dtor)
         ylat = R_M*sin(findgen(101)/50.*!pi)*cos(ilat*!dtor)
         zlat = R_M*replicate(1.,101)*sin(ilat*!dtor)
         xlat2 = 2*( (t8 + t10)*xlat + (t6 -  t4)*ylat + (t3 + t7)*zlat ) +xlat
         ylat2 = 2*( (t4 +  t6)*xlat + (t5 + t10)*ylat + (t9 - t2)*zlat ) +ylat
         zlat2 = 2*( (t7 -  t3)*xlat + (t2 +  t9)*ylat + (t5 + t8)*zlat ) +zlat
         gr_lat = plot3d(/overplot,linestyle=1,xlat2,ylat2,zlat2)
      endfor
      for ilon=0,330,30 do begin $    ;- lon grids
         xlon = R_M*cos(ilon*!dtor)*cos((findgen(51)/50.-.5)*!pi)
         ylon = R_M*sin(ilon*!dtor)*cos((findgen(51)/50.-.5)*!pi)
         zlon = R_M*sin((findgen(51)/50.-.5)*!pi)
         xlon2 = 2*( (t8 + t10)*xlon + (t6 -  t4)*ylon + (t3 + t7)*zlon ) +xlon
         ylon2 = 2*( (t4 +  t6)*xlon + (t5 + t10)*ylon + (t9 - t2)*zlon ) +ylon
         zlon2 = 2*( (t7 -  t3)*xlon + (t2 +  t9)*ylon + (t5 + t8)*zlon ) +zlon
         gr_lon = plot3d(/overplot,linestyle=1,xlon2,ylon2,zlon2)
      endfor
   endif else gr_br = surface(/overplot,zbr,xbr,ybr,color='red')


;- plot MAVEN orbit
   torb = tnow - dindgen(60*4.5) * 60.d
   rmso = transpose(spice_body_pos('MAVEN','Mars',utc=torb,frame='MAVEN_MSO'))
   altidx = maven_orbit_movie_altidx(rmso)
   colorb = replicate(1b,3,n_elements(altidx))
   colgray = rebin(!color.gray,3,n_elements(altidx))
   colgreen = rebin(!color.green,3,n_elements(altidx))
   colyellow = rebin(!color.yellow,3,n_elements(altidx))
   colblue = rebin(!color.blue,3,n_elements(altidx))
   w = where( altidx eq 0 , nw ) ;- SW
   if nw gt 0 then colorb[*,w] = colgray[*,w]
   w = where( altidx eq 1 , nw ) ;- sheath
   if nw gt 0 then colorb[*,w] = colgreen[*,w]
   w = where( altidx eq 2 , nw ) ;- MPR
   if nw gt 0 then colorb[*,w] = colyellow[*,w]
   w = where( altidx eq 3 , nw ) ;- wake
   if nw gt 0 then colorb[*,w] = colblue[*,w]
   gr_orb = plot3d(/overplot,rmso[*,0],rmso[*,1],rmso[*,2], $
                   thick=3,vert_colors=colorb)

;- add MAVEN_SPACECRAFT axes
   xsc = spice_vector_rotate([1.,0.,0.],tnow,'MAVEN_SPACECRAFT','MAVEN_MSO',check='MAVEN_SPACECRAFT',verbose=-1)
   ysc = spice_vector_rotate([0.,1.,0.],tnow,'MAVEN_SPACECRAFT','MAVEN_MSO',check='MAVEN_SPACECRAFT',verbose=-1)
   zsc = spice_vector_rotate([0.,0.,1.],tnow,'MAVEN_SPACECRAFT','MAVEN_MSO',check='MAVEN_SPACECRAFT',verbose=-1)
   gr_xsc = plot3d([rmso[0,0],rmso[0,0]+xsc[0]*max(boxsize)*.1], $
                   [rmso[0,1],rmso[0,1]+xsc[1]*max(boxsize)*.1], $
                   [rmso[0,2],rmso[0,2]+xsc[2]*max(boxsize)*.1], $
                   /data,/overplot,color='blue',thick=3)                
   gr_ysc = plot3d([rmso[0,0],rmso[0,0]+ysc[0]*max(boxsize)*.1], $
                   [rmso[0,1],rmso[0,1]+ysc[1]*max(boxsize)*.1], $
                   [rmso[0,2],rmso[0,2]+ysc[2]*max(boxsize)*.1], $
                   /data,/overplot,color='green',thick=3)                
   gr_zsc = plot3d([rmso[0,0],rmso[0,0]+zsc[0]*max(boxsize)*.1], $
                   [rmso[0,1],rmso[0,1]+zsc[1]*max(boxsize)*.1], $
                   [rmso[0,2],rmso[0,2]+zsc[2]*max(boxsize)*.1], $
                   /data,/overplot,color='red',thick=3)                



;- add eclipse layer
   phec = findgen(101)/50. * !pi
   xec = rebin(-max(abs(boxsize)) * findgen(101)/100 ,101,101)
   yec = transpose(rebin(cos(phec),101,101)) * R_M
   zec = transpose(rebin(sin(phec),101,101)) * R_M
   gr_ec = surface(/overplot,zec,xec,yec,transparency=50,color='blue')


;- add MPB layer
   x0  = 0.640 & ecc = 0.770 &  L   = 1.080 ;- mpb, x > 0
   thmpb = findgen(101)/100. * !pi
   rmpb = L/(1.+ecc*cos(thmpb))
   xmpb = rmpb*cos(thmpb) + x0
   rhompb = rmpb*sin(thmpb)
   w = where( xmpb gt 0 ,nw)
   xmpb0 = xmpb[w]
   rhompb0 = rhompb[w]

   x0  = 1.600 & ecc = 1.009 & L   = 0.528 ;- mpb, x < 0
   thmpb = findgen(101)/100. * !pi
   rmpb = L/(1.+ecc*cos(thmpb))
   xmpb = rmpb*cos(thmpb) + x0
   rhompb = rmpb*sin(thmpb)
   w = where( xmpb lt 0 ,nw)
   xmpb1 = xmpb[w]
   rhompb1 = rhompb[w]

   xmpb = [xmpb0,xmpb1]
   rhompb = [rhompb0,rhompb1]

   phmpb = findgen(101)/50. * !pi

   nx = n_elements(xmpb)
   xmpb1 = rebin(xmpb,nx,101) * R_M
   ympb1 = rebin(rhompb,nx,101) * transpose(rebin(cos(phmpb),101,nx)) * R_M
   zmpb1 = rebin(rhompb,nx,101) * transpose(rebin(sin(phmpb),101,nx)) * R_M

   for iph=0,75,25 do $
      gr_line = plot3d(/data,/overplot,xmpb1[*,iph],ympb1[*,iph],zmpb1[*,iph],color='yellow',transparency=50,thick=2)

   gr_mpb = surface(/overplot,zmpb1,xmpb1,ympb1,color='yellow',transparency=70)


;- add bow shock layer
   x0  = 0.600 & ecc = 1.026 & L   = 2.081
   thbs = findgen(101)/100. * !pi
   rbs = L/(1.+ecc*cos(thbs))
   xbs = rbs*cos(thbs) + x0
   rhobs = rbs*sin(thbs)
   phbs = findgen(101)/50. * !pi
   nx = n_elements(xbs)
   xbs1 = rebin(xbs,nx,101) * R_M
   ybs1 = rebin(rhobs,nx,101) * transpose(rebin(cos(phbs),101,nx)) * R_M
   zbs1 = rebin(rhobs,nx,101) * transpose(rebin(sin(phbs),101,nx)) * R_M
   for iph=0,75,25 do $
      gr_line = plot3d(/data,/overplot,xbs1[*,iph],ybs1[*,iph],zbs1[*,iph], $
                       color='green',transparency=50,thick=2)
   gr_bs = surface(/overplot,zbs1,xbs1,ybs1,transparency=70,color='green')



;- tail perspective
   gr_box.rotate,/reset
   gr_box.rotate,-100,/xaxis
   gr_box.rotate,100,/zaxis
   gr_box.scale,/reset
   gr_box.scale,zoomscale,zoomscale,zoomscale

   gr_win.refresh
   im_tail = gr_box.copywindow() ;- copy image
   gr_win.refresh,/disable


;- dusk perspective
   gr_box.rotate,/reset
   gr_box.rotate,-70,/xaxis
   gr_box.rotate,-135,/zaxis
   gr_box.scale,/reset
   gr_box.scale,zoomscale,zoomscale,zoomscale

   gr_win.refresh
   im_dusk = gr_box.copywindow() ;- copy image
   gr_win.refresh,/disable


;- dawn pserspective
   gr_box.rotate,/reset
   gr_box.rotate,-100,/xaxis
   gr_box.rotate,-45,/zaxis
   gr_box.scale,/reset
   gr_box.scale,zoomscale,zoomscale,zoomscale
   gr_box.translate,/reset
   gr_box.translate,-0.2,0,0,/normal


   gr_im = image(im_tail,/current,position=[.5,.5,1,1],clip=0) ;- insert image
   gr_im = image(im_dusk,/current,position=[.5,0,1,.5],clip=0) ;- insert image

;- add time stamp
   gr_tx = text(/norm,.05,.9,/onglass,font_size=font_size,time_string(tnow),color='white')

;- add a frame to the video stream / create a snapshot file
   gr_win.refresh
   if ~keyword_set(snap) then tmp = ovid.put(vidst,gr_box.copywindow()) $
   else gr_win.save,figname,width=dimensions[0],height=dimensions[1]
endfor                          ;- movie loop end
if ~keyword_set(snap) then ovid = 0 ;- close the movie file
if keyword_set(closewin) then gr_win.close

end


