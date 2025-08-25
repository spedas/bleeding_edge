;+
; PROCEDURE:
;       slice2d
; PURPOSE:
;       creates a 2-D slice of the 3-D distribution function
; CALLING SEQUENCE:
;       slice2d, dat
; INPUTS:
;       dat: standard 3d data structure (cf. 3d_structure.pro)
; KEYWORDS:
;       all optional
;       ROTATION: (case insensitive)
;         'xy': the x axis is v_x and the y axis is v_y. (DEFAULT)
;         'xz': the x axis is v_x and the y axis is v_z.
;         'yz': the x axis is v_y and the y axis is v_z.
;       rotations shown below require valid MAGF tag in the data structure
;         'BV': the x axis is v_para (to the magnetic field) and
;               the bulk velocity is in the x-y plane.
;         'BE': the x axis is v_para (to the magnetic field) and
;               the VxB direction is in the x-y plane.
;         'perp': the x-y plane is perpendicular to the B field,
;                 while the x axis is the velocity projection on the plane.
;         'perp_xy': the x-y plane is perpendicular to the B field,
;                    while the x axis is the x projection on the plane.
;         'perp_xz': the x-y plane is perpendicular to the B field,
;                    while the x axis is the x projection on the plane.
;         'perp_yz': the x-y plane is perpendicular to the B field,
;                    while the x axis is the y projection on the plane.
;       ANGLE: the lower and upper angle limits of the slice selected
;              to plot (DEFAULT [-20,20]).
;       THIRDDIRLIM: the limits of the velocity component perpendicular to
;                    the slice plane (Def: inactivated)
;                    Once activated, the ANGLE keyword would be invalid.
;       XRANGE: vector specifying the xrange (Def: adjusted to energy range)
;       RANGE: vector specifying the color range
;              (Def: from min to max of the unsmoothed, uninterpolated data)
;       ERANGE: specifies the energy range to be used (Def: all energy)
;       UNITS: specifies the units ('eflux', 'df', etc.) (Def. is 'df')
;       NOZLOG: specifies a linear Z axis
;       POSITION: positions the plot using a 4-vector
;       NOFILL: doesn't fill the contour plot with colors
;       NLINES: says how many lines to use if using NOFILL
;               (DEFAULT 60, MAX 60)
;       NOOLINES: suppresses the black contour lines
;       NUMOLINES: how many black contour lines (DEFAULT 20, MAX 60)
;       REMOVEZERO: removes the data with zero counts for plotting
;       SHOWDATA: plots all the data points over the contour (symsize = showdata)
;       VEL: specifies the bulk velocity in the instrument coordinates
;            used for subtraction & rotation (default is calculated with v_3d)
;       NOGRID: forces no triangulation (no interpolation)
;       NOSMOOTH: suppresses smoothing
;                 IF NOT SET, DEFAULT IS SMOOTH (boxcar smoothing w/ width=3)
;       SUNDIR: specifies the sun direction in the instrument coordinates
;               if set, sun direction line is plotted
;       NOVELLINE: suppresses the red velocity line
;       SUBTRACT: Can take on a value from 0 to 4:
;           0 : do nothing
;           1 : subtract the bulk velocity before plotting
;                 if there are few data points around (0,0), use
;                 ThirdDirLim keyword to select data points
;           2 : subtract the X component of the bulk velocity before plotting
;                 (useful for cuts in the Y-Z plane)
;           3 : subtract the Y component of the bulk velocity before plotting
;                 (useful for cuts in the X-Z plane)
;           4 : subtract the Z component of the bulk velocity before plotting
;                 (useful for cuts in the X-Y plane)
;       RESOLUTION: resolution of the mesh (DEFAULT 51)
;       ISOTROPIC: forces the scaling of the X and Y axes to be equal
;       XTITLE, YTITLE, ZTITLE, TITLE: set titles
;       NOPLOT: if set, does not generate a plot
;       DATPLOT: returns a structure which contains data used to plot
;       other keywords are passed to contour
; CREATED BY:
;       Yuki Harada on 2014-05-26
;       Modified from 'thm_esa_slice2d' written by Arjun Raj & Xuzhi Zhou
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/slice2d.pro $
;-

;- copied from 'thm_cal_rot' for non-THEMIS users
function slice2d_cal_rot,v1,v2

  a=v1/(total(v1^2))^.5
  d=v2/(total(v2^2))^.5
  c=crossp(a,d)
  c=c/(total(c^2))^.5
  b=-crossp(a,c)
  b=b/(total(b^2))^.5

  rotinv = dblarr(3,3)
  rotinv(0,*) = a
  rotinv(1,*) = b
  rotinv(2,*) = c

  rot = invert(rotinv)
 
  return, rot
end

;- main procedure
pro slice2d, dat, rotation=rotation, angle=angle, thirddirlim=thirddirlim, xrange=xrange, range=range, erange=erange, units=units, nozlog=nozlog, position=position, nofill=nofill, nlines=nlines, noolines=noolines, numolines=numolines, removezero=removezero, showdata=showdata, vel=vel, nogrid=nogrid, nosmooth=nosmooth, sundir=sundir, novelline=novelline, subtract=subtract, resolution=resolution, isotropic=isotropic, xtitle=xtitle, ytitle=ytitle, ztitle=ztitle, title=title, noplot=noplot, datplot=datplot, _extra=_extra, verbose=verbose


;- default setting
if not keyword_set(units) then units = 'df'
if not keyword_set(rotation) then rotation = 'xy' else rotation = strlowcase(rotation)
if not keyword_set(angle) then angle = [-20.,20.]
if not keyword_set(nlines) then nlines = 60
if not keyword_set(nozlog) then zlog = 1 else zlog = 0
if not keyword_set(nofill) then fill = 1 else fill = 0
if not keyword_set(resolution) then resolution = 51
if resolution mod 2 eq 0 then resolution = resolution + 1
if not keyword_set(numolines) then numolines = 20
if not keyword_set(position) then begin
   x_size = !d.x_size & y_size = !d.y_size
   xsize = .77
   yoffset = 0.
   d = 1.
   if y_size le x_size then $
      position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize * y_size/x_size,.13*d + xsize + yoffset] else $
         position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize,.13*d + xsize *x_size/y_size + yoffset]
   ;- just copied from 'thm_esa_slice2d'
   ;- is this the best default position?
endif
if strmid(strupcase(!version.os_family), 0, 3) eq 'WIN' then lb = string([13B, 10B]) else lb = string(10B) 


;- valid data check
if dat.valid ne 1 then begin
   dprint, 'Not valid data!!!'
   return
endif


;- convert units
dat2 = conv_units(dat,units)


;- set ene-sangle bin flag
bins_2d = fltarr(dat2.nenergy,dat2.nbins)
sizeokay = 0
if tag_exist(dat2,'bins') eq 1 then begin
   checksize = size(dat2.bins)
   if checksize[0] eq 2 then begin
      if checksize[1] eq dat2.nenergy and checksize[2] eq dat2.nbins then begin
         sizeokay = 1
      endif
   endif
endif
if sizeokay eq 1 then begin
   bins_2d[*,*] = dat2.bins[*,*]
endif else begin
   bins_2d[*,*] = 1.
   dprint,'No BINS tag or the BINS size does not match (Nene, Nsangle)'
   dprint,'All bins are used'
endelse


;- set energy range
if not keyword_set(erange) then begin
   erange = [ min(dat2.energy) , max(dat2.energy) ]
endif else begin
   idx = where( dat2.energy[*,0] ge erange[0] $
                 and dat2.energy[*,0] le erange[1] , idx_cnt )
   if idx_cnt gt 0 then begin
      erange = [ min(dat2.energy[idx,0]) , max(dat2.energy[idx,0]) ]
   endif else begin
      dprint,'No data points in that energy range!!!'
      return
   endelse
endelse


;- set mass (note that uits are eV/(km/sec)^2)
if tag_exist(dat2,'mass') eq 1 then begin
   mass = dat2.mass
endif else begin
   dprint,'No mass info in the 3D data!!!'
   dprint,'Add a mass tag to the structure by using, e.g., str_element'
   dprint,'for electrons:'
   dprint,"> str_element,dat, 'MASS', 5.6856591e-6, /add"
   dprint,'for protons, mass = 1836*5.6856591e-6 eV/(km/sec)^2'
   return
endelse


;- set magnetic field vector
if rotation ne 'xy' and rotation ne 'xz' and rotation ne 'yz' then begin
   if tag_exist(dat2,'magf') eq 1 then begin
      bvec = dat2.magf
      if total(bvec^2) ne 0 and total(finite(bvec)) eq 3 then begin
         dprint, dlevel=2, verbose=verbose, $
                 lb + '  Magntic field is taken from MAGF tag in the data structure' + $
                 lb + '  bvec =' + string(bvec, '(3(a0))')
      endif else begin
         dprint,'Invalid MAGF:',bvec
         return
      endelse
   endif else begin
      dprint,'No MAGF tag in the data structure!!!'
      dprint,'Add a valid MAGF tag by using, e.g., extract_tags'
      return
   endelse
endif


;=== sort data into cartesian coordinates (v_x, v_y, v_z) ===
totalx = fltarr(1) & totaly = fltarr(1) & totalz = fltarr(1)
ncounts = fltarr(1)             ;- add all data for plots into a 1-D array

for i=0,dat2.nenergy-1 do begin
   currbins = where( bins_2d[i,*] ne 0 $
                     and dat2.energy[i,*] le erange[1] $
                     and dat2.energy[i,*] ge erange[0] $
                     and finite(dat2.data[i,*]) eq 1 , nbins )
   if nbins gt 0 then begin
      x = fltarr(nbins) & y = fltarr(nbins) & z = fltarr(nbins)

      ;- obsolete
;;       w = where( dat2.phi eq 0. , nw ) ;- deals w/ colinear err @triangulate
;;       if nw gt 0 then dat2.phi = dat2.phi + .00001
      ;- obsolete

      sphere_to_cart,1,reform(dat2.theta[i,currbins]),reform(dat2.phi[i,currbins]), x,y,z
      totalx = [totalx, x * reform(sqrt(2*dat2.energy[i,currbins]/mass))]
      totaly = [totaly, y * reform(sqrt(2*dat2.energy[i,currbins]/mass))]
      totalz = [totalz, z * reform(sqrt(2*dat2.energy[i,currbins]/mass))]
      ncounts = [ncounts, reform(dat2.data[i, currbins])]
   endif
endfor

totalx = totalx[1:*]            ;- the first ones were dummies
totaly = totaly[1:*]
totalz = totalz[1:*]
ncounts = ncounts[1:*]

newdata = {v:fltarr(n_elements(totalx),3), n:fltarr(n_elements(totalx))}
newdata.v[*,0] = totalx         ;- v_x [km/s]
newdata.v[*,1] = totaly         ;- v_y [km/s]
newdata.v[*,2] = totalz         ;- v_z [km/s]
newdata.n = ncounts
;=== sort data into cartesian coordinates (v_x, v_y, v_z) ===


;- set velocity
if keyword_set(vel) then begin
   vvec = vel
   dprint, dlevel=2, verbose=verbose, 'Velocity used for subtraction/rotation/display is' + string(vel, '(3(a0))')
endif else begin 
   vvec = v_3d(dat2)
   dprint,'Velocity used for subtraction/rotation/display is V_3D' + string(vvec, '(3(a0))'), dlevel=2, verbose=verbose
endelse


;- velocity subtraction
if not keyword_set(subtract) then begin 
   dprint, 'No velocity subtraction', dlevel=2, verbose=verbose
endif else begin
   case subtract of
     2 : begin
           dprint, 'Subtracting V_x', dlevel=2, verbose=verbose
           newdata.v[*,0] = newdata.v[*,0] - vvec[0]
           vvec[0] = 0.
           subtract = 0
         end
     3 : begin
           dprint, 'Subtracting V_y', dlevel=2, verbose=verbose
           newdata.v[*,1] = newdata.v[*,1] - vvec[1]
           vvec[1] = 0.
           subtract = 0
         end
     4 : begin
           dprint, 'Subtracting V_z', dlevel=2, verbose=verbose
           newdata.v[*,2] = newdata.v[*,2] - vvec[2]
           vvec[2] = 0.
           subtract = 0
         end
     else : begin
              dprint, 'Subtracting velocity vector', dlevel=2, verbose=verbose
              newdata.v[*,0] = newdata.v[*,0] - vvec[0]
              newdata.v[*,1] = newdata.v[*,1] - vvec[1]
              newdata.v[*,2] = newdata.v[*,2] - vvec[2]
            end
   endcase
endelse


;=== rotation to the required frame of reference ===
if rotation eq 'bv' then rot = slice2d_cal_rot( bvec, vvec )
if rotation eq 'be' then rot = slice2d_cal_rot( bvec, crossp(bvec,vvec) )
if rotation eq 'xy' then rot = slice2d_cal_rot( [1,0,0], [0,1,0] )
if rotation eq 'xz' then rot = slice2d_cal_rot( [1,0,0], [0,0,1] )
if rotation eq 'yz' then rot = slice2d_cal_rot( [0,1,0], [0,0,1] )
if rotation eq 'perp' then begin
   rot = slice2d_cal_rot( crossp(crossp(bvec,vvec),bvec), crossp(bvec,vvec) )
endif
if rotation eq 'perp_xy' then begin
   rot = slice2d_cal_rot( crossp(crossp(bvec,[1,0,0]),bvec), crossp(crossp(bvec,[0,1,0]),bvec) )
endif
if rotation eq 'perp_xz' then begin
   rot = slice2d_cal_rot( crossp(crossp(bvec,[1,0,0]),bvec), crossp(crossp(bvec,[0,0,1]),bvec) )
endif
if rotation eq 'perp_yz' then begin
   rot = slice2d_cal_rot( crossp(crossp(bvec,[0,1,0]),bvec), crossp(crossp(bvec,[0,0,1]),bvec) )
endif

newdata.v = newdata.v # rot
vvec = vvec # rot
if keyword_set(sundir) then begin
   sundir2 = sundir # rot
;;    if sundir2[1] ne 0 then $     ;- assumes axisymmetry
;;       ysun = sqrt( sundir2[1]^2 + sundir2[2]^2 )*sundir2[1]/abs(sundir2[1]) $
;;    else ysun = 0.
   ysun = sundir2[1]            ;- simple projection
   xsun = sundir2[0]
endif
;=== rotation to the required frame of reference ===


;- set plot arrays
xplot = newdata.v[*,0]
yplot = newdata.v[*,1]
zplot = newdata.v[*,2]
cntplot = newdata.n


;=== confine angles/third dir ===
if keyword_set(ThirdDirlim) then angle = [-90.,90.]
r = sqrt( xplot^2 + yplot^2 + zplot^2 )
eachangle = asin( zplot/r )
angle1 = min(angle)
angle2 = max(angle)

idx = where( eachangle*!radeg ge angle1 $
             and eachangle*!radeg le angle2 , idx_cnt )
if idx_cnt gt 0 then begin
   xplot = xplot[idx]
   yplot = yplot[idx]
   zplot = zplot[idx]
   cntplot = cntplot[idx]
endif else begin
   dprint,'No data points at that angle!!!'
   return
endelse
if keyword_set(ThirdDirlim) then begin
   idx = where( zplot ge min(ThirdDirLim) and zplot le max(ThirdDirLim) , idx_cnt )
   if idx_cnt gt 0 then begin
      xplot = xplot[idx]
      yplot = yplot[idx]
      zplot = zplot[idx]
      cntplot = cntplot[idx]
   endif else begin
      dprint,'No data points at that third direction limit!!!'
      return
   endelse
endif
;=== confine angles/third dir ===


;- remove nevative values, if any
idx = where( cntplot ge 0 , idx_cnt )
if idx_cnt gt 0 then begin
   xplot = xplot[idx]
   yplot = yplot[idx]
   zplot = zplot[idx]
   cntplot = cntplot[idx]
endif else begin
   dprint,'There are no data values >= 0!!!'
   return
endelse


;- remove zero values (is this keyword necessary??)
if keyword_set(removezero) then begin
   idx = where( cntplot ne 0 , idx_cnt )
   if idx_cnt gt 0 then begin
      xplot = xplot[idx]
      yplot = yplot[idx]
      zplot = zplot[idx]
      cntplot = cntplot[idx]
   endif else begin
      dprint,'There are only zero data values'
   endelse
endif


;=== sort data into unique data points in x-y plane ===
yplot = yplot(sort(xplot)) ;- sort x
cntplot = cntplot(sort(xplot))
xplot = xplot(sort(xplot))

uni2 = uniq(xplot) ;- last element in each set of non-unique elements
uni1 = [ 0, uni2[0:n_elements(uni2)-2]+1 ] ;- first element in each set

kk = 0
for i=0,n_elements(uni2)-1 do begin
   xploti = xplot[ uni1[i]:uni2[i] ]
   yploti = yplot[ uni1[i]:uni2[i] ]
   cntploti = cntplot[ uni1[i]:uni2[i] ]

   xploti = xploti[ sort(yploti) ] ;- sort y
   cntploti = cntploti[ sort(yploti) ]   
   yploti = yploti[ sort(yploti) ]

   idx2 = uniq(yploti)
   if n_elements(idx2) eq 1 then begin
      idx1 = 0
   endif else begin
      idx1 = [ 0, idx2[0:n_elements(idx2)-2]+1 ]
   endelse
   for j=0,n_elements(idx2)-1 do begin
      yplot[kk] = yploti[idx1[j]]
      xplot[kk] = xploti[idx1[j]]
      if idx1[j] eq idx2[j] then begin ;- unique data point
         cntplot[kk] = cntploti[idx1[j]]
      endif else begin ;- non-unique data points, taking the mean value
         cnt_mom = moment( cntploti[ idx1[j]:idx2[j] ] )
         cntplot[kk] = cnt_mom[0]
      endelse
      kk = kk +1
   endfor
endfor
xplot = xplot[0:kk-1]
yplot = yplot[0:kk-1]
cntplot = cntplot[0:kk-1]
;=== sort data into unique data points in x-y plane ===


;- set xrange
if not keyword_set(xrange) then begin
   xmax = max(abs([xplot,yplot]))
   xrange = [ -1*xmax, xmax ]
endif else xmax = max(abs(xrange))


;- set color range
if not keyword_set(range) then begin
   if not keyword_set(xrange) then begin
      cntmax = max(cntplot)
      cntmin = min(cntplot)
      if cntmax ne 0 and cntmin eq 0 then $
         cntmin = min( cntplot[where(cntplot ne 0)] )
   endif else begin
      cntmax = max(cntplot[ where( abs(xplot) le xmax and abs(yplot) le xmax ) ])
      cntmin = min(cntplot[ where( abs(xplot) le xmax and abs(yplot) le xmax ) ])
      if cntmax ne 0 and cntmin eq 0 then $
         cntmin = min( cntplot[where( cntplot ne 0 and abs(xplot) le xmax and abs(yplot) le xmax )] )
   endelse
endif else begin
   cntmin = min(range)
   cntmax = max(range)
endelse


;- set contour levels
if keyword_set(nozlog) then begin
   levels = indgen(nlines)/float(nlines)*(cntmax-cntmin) + cntmin
endif else begin
   levels = 10.^( indgen(nlines)/float(nlines)*(alog10(cntmax)-alog10(cntmin)) + alog10(cntmin) )
endelse
if not keyword_set(noolines) then begin
   if keyword_set(nozlog) then begin
      levels2 = indgen(numolines)/float(numolines)*(cntmax-cntmin) + cntmin
   endif else begin
      levels2 = 10.^( indgen(numolines)/float(numolines)*(alog10(cntmax)-alog10(cntmin)) + alog10(cntmin) )
   endelse
endif


;- set colors
colors = round( (indgen(nlines)+1)*(!d.table_size-9)/nlines ) + 7


;- set x & y titles
if rotation eq 'bv' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_para [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_V [km/s]'
endif
if rotation eq 'be' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_para [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_E [km/s]'
endif
if rotation eq 'xy' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_x [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_y [km/s]'
endif
if rotation eq 'xz' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_x [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_z [km/s]'
endif
if rotation eq 'yz' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_y [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_z [km/s]'
endif
if rotation eq 'perp' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_perp_V [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_E [km/s]'
endif
if rotation eq 'perp_xy' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_perp_x [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_y [km/s]'
endif
if rotation eq 'perp_xz' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_perp_x [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_z [km/s]'
endif
if rotation eq 'perp_yz' then begin
   if ~keyword_set(xtitle) then xtitle = 'v_perp_y [km/s]'
   if ~keyword_set(ytitle) then ytitle = 'v_perp_z [km/s]'
endif


;=== plot the data ===
if ~keyword_set(title) then $
   title = dat2.data_name+' '+time_string(dat2.time) $
           +'->'+strmid(time_string(dat2.end_time),11,8)

xg = !values.f_nan
yg = !values.f_nan
surf = !values.f_nan
if not keyword_set(nogrid) then begin
   spacing = (xrange[1]-xrange[0])/(resolution-1)

;;    triangulate, xplot, yplot, tr, b
   qhull, xplot, yplot, tr, /delaunay ;- qhull generally performs better than triangulate (cf. spd_slice2d_2di.pro)

   idx = where( ( xplot[tr[0,*]] + xplot[tr[1,*]] + xplot[tr[2,*]] )^2 $
                + ( yplot[tr[0,*]] + yplot[tr[1,*]] + yplot[tr[2,*]] )^2 $
                gt min( xplot^2 + yplot^2 ) , idx_cnt )
   if idx_cnt gt 0 then tr = tr[*,idx]

   surf = trigrid( xplot, yplot, cntplot, tr, [spacing,spacing], $
                   [ xrange[0], xrange[0], xrange[1], xrange[1] ], $
                   xgrid=xg, ygrid=yg  )
   if not keyword_set(nosmooth) then surf = smooth(surf,3)
   if n_elements(xg) mod 2 ne 1 then $
      dprint, 'The line plots are invalid', n_elements(xg)

   if ~keyword_set(noplot) then begin
      contour,surf,xg,yg, $
              /closed, levels=levels, c_color=colors, fill=fill, $
              ticklen=-0.01, isotropic=isotropic, $
              xstyle=1, xrange=xrange, xtitle=xtitle,$
              ystyle=1, yrange=xrange, ytitle=ytitle, $
              title=title, position=position, _extra=_extra
      if not keyword_set(noolines) then begin
         contour,surf,xg,yg, $
                 /closed, /noerase, levels=levels2,  $
                 ticklen=0, isotropic=isotropic, color=0, $
                 xstyle=5, xrange=xrange,$
                 ystyle=5, yrange=xrange, position=position
      endif
   endif                        ;- noplot
endif else begin
   if ~keyword_set(noplot) then begin
      contour,cntplot,xplot,yplot, /irregular, $
              /closed, levels=levels, c_color=colors, fill=fill, $
              ticklen=-0.01, isotropic=isotropic, $
              xstyle=1, xrange=xrange, xtitle=xtitle,$
              ystyle=1, yrange=xrange, ytitle=ytitle, $
              title=title, position=position, _extra=_extra
      if not keyword_set(noolines) then begin
         contour,cntplot,xplot,yplot, /irregular, $
                 /closed, /noerase, levels=levels2,  $
                 ticklen=0, isotropic=isotropic, color=0, $
                 xstyle=5, xrange=xrange,$
                 ystyle=5, yrange=xrange, position=position
      endif
   endif                        ;- noplot
endelse

if not keyword_set(subtract) then begin
;- inner circle (minimum energy)
   circx = cos(findgen(361)*!dtor)*sqrt(2.*erange[0]/mass)
   circy = sin(findgen(361)*!dtor)*sqrt(2.*erange[0]/mass)
   if ~keyword_set(noplot) then polyfill,circx,circy,/fill,color=!p.background ;- fill the inner circle
   if ~keyword_set(noplot) then oplot,circx,circy,thick=2
;- outer circle (maximum energy)
   circx = cos(findgen(361)*!dtor)*sqrt(2.*erange[1]/mass)
   circy = sin(findgen(361)*!dtor)*sqrt(2.*erange[1]/mass)
   if ~keyword_set(noplot) then oplot,circx,circy,thick=2
   if ~keyword_set(noplot) and ~keyword_set(novelline) then oplot,[0,vvec[0]],[0,vvec[1]],col= !d.table_size-9
endif ;- Since velocity subtraction modifies energy boundaries, inner & outer circles are plotted only when no subtraction is conducted

if ~keyword_set(noplot) and keyword_set(sundir) then oplot,[0,xsun*xmax],[0,ysun*xmax]

if ~keyword_set(ztitle) then ztitle = units_string(dat2.units_name)
if ~keyword_set(noplot) then draw_color_scale, range=[cntmin,cntmax], log=zlog, yticks=10, title = ztitle

if ~keyword_set(noplot) and keyword_set(showdata) then oplot,xplot,yplot,psym=1,symsize=showdata
datplot = {x:xplot,y:yplot,v:cntplot,xg:xg,yg:yg,vg:surf}
;=== plot the data ===


end
