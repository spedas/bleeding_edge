;+
; PROCEDURE:
;       kgy_orbit_snap
; PURPOSE:
;       Plots Kaguya orbits in SSE and ME coordinates.
;       Hold down the left mouse button and slide for a movie effect.
; KEYWORDS:
;       
; CREATED BY:
;       Yuki Harada on 2018-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 00:52:42 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/kgy_orbit_snap.pro $
;-

pro kgy_orbit_snap, tsnap=tsnap, tres=tres, refreshdata=refreshdata, commononly=commononly, window=window, nowindow=nowindow, keepwin=keepwin, symsize=symsize, title=title

rL = 1737.4
rE = 6374.4


if ~keyword_set(tres) then tres = 4d
if ~keyword_set(brrange) then brrange = [-10,10] else brrange=minmax(brrange)
if ~keyword_set(symsize) then symsize = 1

tplot_options, get_opt=topt
times = topt.trange_full[0] + tres*dindgen(long((topt.trange_full[1]-topt.trange_full[0])/tres))

;;; exclude times in spk gaps
in_gaps = kgy_spk_gaps(times)
w = where( ~in_gaps , nw )
if nw eq 0 then begin
   dprint,'No valid times'
   return
endif
times = times[w]


;;; retrieve common block
common kgy_orbit_snap_com,kgy,brmod
if keyword_set(refreshdata) then undefine,kgy,brmod

;;; get kgy pos
if size(kgy,/type) ne 8 then begin
   if total(strlen(spice_test('*SELENE*'))) eq 0 then kk = kgy_spice_kernels(/load)
   kgy = {times:times}
   sse = spice_body_pos('SELENE', 'Moon', frame='SSE', utc=times)
   str_element,/add,kgy,'sse',sse
   gse = spice_body_pos('SELENE', 'Earth', frame='GSE', utc=times)
   str_element,/add,kgy,'gse',gse
   geo = spice_body_pos('SELENE', 'Moon', frame='MOON_ME', utc=times)
   cart_to_sphere,geo[0,*],geo[1,*],geo[2,*],r,lat,lon,/ph_0_360
   str_element,/add,kgy,'r',r
   str_element,/add,kgy,'lat',lat
   str_element,/add,kgy,'lon',lon
endif

;;; load Bc data
if size(brmod,/type) ne 8 then begin
   @kgy_svm_com
   if size(svm30_dat,/type) eq 0 then kgy_svm_load,/svm30only
   if size(svm30_dat,/type) eq 4 then begin
      brlon = reform(svm30_dat[0,*])
      brlat = reform(svm30_dat[1,*])
      lonidx = long(brlon*2)       ;- 0 to 359.5, .5 deg res
      latidx = long(brlat*2) + 179 ;- -89.5 to 89.5, .5 deg res
      br = fltarr(720,359)
      for i=0l,720l*359-1 do br[lonidx[i],latidx[i]] = svm30_dat[4,i]
      brmod = {br:br,lon:findgen(720)*.5,lat:findgen(359)*.5-89.5}
   endif
endif
brlevels = brrange[0] + findgen(9)/8.*(brrange[1]-brrange[0])
brcol = bytescale(brlevels,bottom=205,top=50,range=minmax(brlevels))

if keyword_set(commononly) then return


;;; set up windows
if ~keyword_set(nowindow) then begin
str_element, topt, 'window', value=Twin, success=ok
if (not ok) then Twin = !d.window

dsize = get_screen_size()
if keyword_set(window) then Swin = window else begin
   window, /free, xsize=dsize[0]/2., ysize=dsize[1], xpos=0,ypos=0
   Swin = !d.window
endelse
endif

wkgy = where(kgy.times ge topt.trange[0] and kgy.times le topt.trange[1] ,nwkgy )
circ = findgen(361)*!dtor
half = findgen(181)*!dtor
quat = findgen(91)*!dtor
theta = (findgen(321)-160.) / !radeg
theta135 = (findgen(271)-135.) / !radeg

if size(tsnap,/type) eq 0 then begin
   print, 'Use button 1 to select time; button 3 to quit.'
   ctime,t,npoints=1,/silent
endif else t = tsnap



ok = 1
while (ok) do begin

   tmp = min(abs(kgy.times-t),ikgy)
   if ~keyword_set(nowindow) then wset, Swin

   colkgy = 2

   ;;; X-Y
   plot,[0],/nodata,/isotropic,position=[.15,.7,.5,.95], $
        xtitle='X!dSSE!n [km]',xrange=[2000,-2000],xstyle=1, $
        ytitle='Y!dSSE!n [km]',yrange=[2000,-2000],ystyle=1, $
        title=title
   oplot,cos(circ)*rL,sin(circ)*rL
   polyfill,[0,0,-sin(half)]*rL,[1,-1,cos(half)]*rL,/line_fill,spacing=.1,orien=45
   if nwkgy gt 0 then oplot,kgy.sse[0,wkgy],kgy.sse[1,wkgy],psym=3,color=colkgy
   plots,kgy.sse[0,ikgy],kgy.sse[1,ikgy],psym=4,thick=2,color=colkgy,symsize=symsize

   ;;; X-Y GSE
   plot,[0],/nodata,/isotropic,/noerase,position=[.55,.7,.95,.95], $
        xtitle='X!dGSE!n [R!dE!n]',xrange=[80,-80],xstyle=1, $
        ytitle='Y!dGSE!n [R!dE!n]',yrange=[80,-80],ystyle=1, $
        title=title
   oplot,cos(circ),sin(circ)
   ;;; magnetopause model --- [Shue et al., 1997]
   Dp = 1.                      ; [nPa]
   Bz = 0.                      ; [nT]
   if Bz ge 0 then begin
      r0=(11.4+0.013*Bz)*Dp^(-1./6.6)
   endif else begin
      r0=(11.4+0.14*Bz)*Dp^(-1./6.6)
   endelse
   alpha=(0.58-0.010*Bz)*(1.+0.010*Dp)
   r=r0*(2./(1.+cos(theta)))^alpha
   oplot,r*cos(theta),r*sin(theta)
   ;;; magnetopause model --- [Shue et al., 1997]
   ;;; hyperbolic bow shock, see JGR 1981, p.11401, Slavin Fig.7
   L = 23.5
   ecc = 1.15
   xoffset = 3.
   r = L/(1+ecc*cos(theta135))
   oplot,r*cos(theta135)+xoffset,r*sin(theta135)
   ;;; hyperbolic bow shock, see JGR 1981, p.11401, Slavin Fig.7
   if nwkgy gt 0 then oplot,kgy.gse[0,wkgy]/rE,kgy.gse[1,wkgy]/rE,psym=3,color=colkgy
   plots,kgy.gse[0,ikgy]/rE,kgy.gse[1,ikgy]/rE,psym=4,thick=2,color=colkgy,symsize=symsize


   ;;; X-Z
   plot,[0],/nodata,/isotropic,/noerase,position=[.15,.375,.5,.625], $
        xtitle='X!dSSE!n [km]',xrange=[2000,-2000],xstyle=1, $
        ytitle='Z!dSSE!n [km]',yrange=[-2000,2000],ystyle=1, $
        title=title
   oplot,cos(circ)*rL,sin(circ)*rL
   polyfill,[0,0,-sin(half)]*rL,[1,-1,cos(half)]*rL,/line_fill,spacing=.1,orien=45
   if nwkgy gt 0 then oplot,kgy.sse[0,wkgy],kgy.sse[2,wkgy],psym=3,color=colkgy
   plots,kgy.sse[0,ikgy],kgy.sse[2,ikgy],psym=4,thick=2,color=colkgy,symsize=symsize

   ;;; Y-Z
   plot,[0],/nodata,/isotropic,/noerase,position=[.55,.375,.95,.625], $
        xtitle='Y!dSSE!n [km]',xrange=[-2000,2000],xstyle=1, $
        ytitle='Z!dSSE!n [km]',yrange=[-2000,2000],ystyle=1, $
        title=title
   oplot,cos(circ)*rL,sin(circ)*rL
   if nwkgy gt 0 then oplot,kgy.sse[1,wkgy],kgy.sse[2,wkgy],psym=3,color=colkgy
   plots,kgy.sse[1,ikgy],kgy.sse[2,ikgy],psym=4,thick=2,color=colkgy,symsize=symsize


   ;;; Lon-Lat
   plot,[0],/nodata,/noerase,position=[.2,.07,.8,.3], $
        xtitle='Longitude [deg.]',xrange=[0,360],xstyle=1,xticks=4, $
        ytitle='Latitude [deg.]',yrange=[-90,90],ystyle=1,yticks=4, $
        xticklen=-.01,yticklen=-.01
   if size(brmod,/type) ne 0 then begin
      loadct2,70,prev=prev
      lim = {zrange:brrange,no_color_scale:1,position:[.2,.07,.8,.3], $
             xtitle:'Longitude [deg.]',xrange:[0,360],xstyle:1,xticks:4, $
             ytitle:'Latitude [deg.]',yrange:[-90,90],ystyle:1,yticks:4, $
             xticklen:-.01,yticklen:-.01}
      specplot,brmod.lon,brmod.lat,brmod.br,lim=lim,/overplot
      draw_color_scale,range=brrange,brange=[205,50],title='Br at 30 km alt. [nT]',yticklen=-.5
      if prev le 74 then loadct2,prev
   endif
   if nwkgy gt 0 then oplot,kgy.lon[wkgy],kgy.lat[wkgy],psym=3,color=colkgy
   plots,kgy.lon[ikgy],kgy.lat[ikgy],psym=4,thick=2,color=colkgy,symsize=symsize



   if size(tsnap,/type) eq 0 then begin
      wset,Twin
      ctime,t,npoints=1,/silent
      if (data_type(t) eq 5) then ok = 1 else ok = 0
   endif else ok = 0
endwhile

if ~keyword_set(nowindow) and ~keyword_set(keepwin) then wdelete,Swin




end
