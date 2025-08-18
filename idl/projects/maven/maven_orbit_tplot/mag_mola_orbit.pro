;+
;PROCEDURE:   mag_mola_orbit
;PURPOSE:
;  Plots a set of [longitude,latitude] positions over a MAG-MOLA
;  map.
;
;USAGE:
;  mag_mola_orbit, lon, lat
;
;INPUTS:
;       lon:       East longitude (0 to 360 degrees).
;
;       lat:       Latitude (-90 to 90 degrees).
;
;                  Note: lon and lat must have the same number
;                        of elements.
;
;KEYWORDS:
;       PSYM:       Symbol type (same as for plot).
;
;       NOSYM:      Do not plot symbol at s/c position.
;
;       LSTYLE:     Line style (same as for plot).
;
;       COLOR:      Line/symbol color (same as for plot).
;
;       RESET:      Read in the MAG-MOLA or MAG-LANGLAIS image and 
;                   calculate the plot size and position.
;
;       NOERASE:    Do not refresh the plot for each [lon, lat] point.
;
;       BIG:        Use a 1000x500 MAG-MOLA image.
;
;       DBR:        Use a 1000x500 dBr/dt image.
;                   (Note: dBr/dt is approx. the same as dBr/dlat.)
;
;       LANGLAIS:   Use a variable size map of the radial component of
;                   the Langlais spherical harmonic expansion evaluated
;                   at a constant altitude:
;                       1 -> 160 km  (approx. electron footpoint altitude)
;                       2 -> 250 km
;
;       LLIM:       A structure of keywords for controlling the window
;                   size and plotting options for the Langlais map.  This
;                   allows you to zoom in on a region.  Any keywords accepted
;                   by CONTOUR and SPECPLOT are allowed.  Only the X dimension
;                   of the window (LLIM.XSIZE) is used.  The Y dimension is
;                   calculated so that the pixels per degree is the same in
;                   longitude and latitude.  Default contour levels (LLIM.LEVELS)
;                   are [-70,-50,-30,-10,10,30,50,70].
;
;                   You can also specify tagname WASH, which controls how many
;                   color indices away from light gray to extend the red-to-blue
;                   shading for the Langlais map.  Default = 50.  Smaller values
;                   make the shading more washed out.  Set LLIM.WASH=0 to show 
;                   contour map without shading.
;
;                   Use tagname COMPONENT to specify which component of the
;                   magnetic field to plot: 'BR' (radial), 'BT' (north), 
;                   'BP' (east), 'B' (magnitude).  Default: LLIM.COMPONENT='BR'.
;
;       BAZEL:      If set to a 3xN element array of the magnetic field in
;                   the local azimuth-elevation frame, plot a magnetic field
;                   azimuth whisker with the origin at the spacecraft location.
;                   All whiskers are the same length, so they act as "compass
;                   needles".
;
;       CAZEL:      If set, the BAZEL whisker colors are set according to a
;                   rainbow table, where blue = radial out, and red = radial in.
;                   If not set, all the whiskers are same color as the symbols.
;                   Default = 1.
;
;       BSCALE:     Sets the scale of the BAZEL whiskers.  Default = 1.
;
;       TERMINATOR: Overlay the terminator at the time specified by this
;                   keyword.
;
;       SHADOW:     If TERMINATOR is set, specifies which "terminator" to
;                   plot.
;                      0 : Optical shadow boundary at surface.
;                      1 : Optical shadow boundary at s/c altitude.
;                      2 : EUV shadow boundary at s/c altitude.
;                      3 : EUV shadow at electron absorption altitude.
;
;       SITES:      A 2 x N array of surface locations to plot.
;
;       SLAB:       Text labels for each of the sites.
;
;       SCOL:       Color for each of the sites.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-12-31 18:34:56 -0800 (Tue, 31 Dec 2024) $
; $LastChangedRevision: 33026 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mag_mola_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro mag_mola_orbit, lon, lat, psym=psym, lstyle=lstyle, color=color, $
                    reset=reset, big=big, noerase=noerase, title=title, $
                    terminator=ttime, shadow=shadow, alt=alt, sites=sites, $
                    slab=slab, scol=scol, dbr=dbr, rwin=rwin, nosym=nosym, $
                    bazel=bazel, bscale=bscale, langlais=lang, llim=llim, $
                    cazel=cazel

  common magmola_orb_com, img, ppos, k
  @putwin_common

  Twin = !d.window
  Owin = 29

  if ((size(k,/type) ne 8) or keyword_set(reset)) then begin
    k = {title:'', xsize:1082, ysize:572, scale:1., csize:1.2, psym:1, levels: [10,30,50,70], $
         wash:50, gray:142, xrange:[0,360], xticks:4, xminor:3, yrange:[-90,90], yticks:2, $
         yminor:3, lstyle:0, color:2, xtitle:'East Longitude', ytitle:'Latitude', component:'br'}
  endif
  if (size(title,/type) eq 7) then k.title = title
  if (n_elements(psym) gt 0) then k.psym = fix(psym[0]) < 8
  if (n_elements(lstyle) gt 0) then k.lstyle = fix(lstyle[0])
  if (n_elements(color) gt 0) then k.color = fix(color[0])

  dosym = ~keyword_set(nosym)
  if not keyword_set(noerase) then eflg = 1 else eflg = 0
  if keyword_set(ttime) then doterm = 1 else doterm = 0
  if keyword_set(shadow) then sflg = shadow else sflg = 0
  if (n_elements(bazel) eq 3L*n_elements(lon)) then doazel = 1 else doazel = 0
  cazel = keyword_set(cazel)
  bscale = keyword_set(bscale) ? float(bscale[0]) : 1.
  sz = size(sites)
  nsites = 0
  if ((sz[0] eq 1) and (sz[1] ge 2)) then nsites = 1
  if ((sz[0] eq 2) and (sz[1] eq 2)) then nsites = sz[2]
  dolab = (size(slab,/type) eq 7)
  scol2 = replicate(6,nsites>1)
  ncol = n_elements(scol)
  if (ncol gt 0) then scol2[0:(ncol-1)<(nsites-1)] = scol[0:(ncol-1)<(nsites-1)]
  if (ncol lt nsites) then scol2[ncol:(nsites-1)] = scol[ncol-1]
  scol = scol2

  if (size(rwin,/type) gt 0) then begin
    key = {rel:fix(rwin[0]), dx:10, top:1}
  endif else begin
    undefine, mnum
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
    key = {monitor:mnum, dx:10}
  endelse

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if ((size(img,/type) eq 0) or keyword_set(reset)) then begin
         
    if keyword_set(lang) then begin
      case lang of
          2  : fname = file_which('langlais_250km.sav')
        else : fname = file_which('langlais_160km.sav')
      endcase
      restore, file=fname

      initct,1070,previous_ct=pct,previous_rev=prev    ; red-to-blue color table
      if (size(llim,/type) eq 8) then begin
        tags = tag_names(llim)
        for i=0,(n_elements(tags)-1) do str_element, k, tags[i], llim.(i), /add_replace
      endif

      str_element, k, 'component', ztag
      case strupcase(ztag) of
        'BR' : begin
                 z = bmod.br
                 k.gray = 142
               end
        'BT' : begin
                 z = bmod.bt
                 k.gray = 123
               end
        'BP' : begin
                 z = bmod.bp
                 k.gray = 125
               end
        'B'  : begin
                 z = sqrt(bmod.br^2. + bmod.bt^2. + bmod.bp^2.)
                 k.gray = 180
               end
        else : begin
                 print,"Component not recognized: ",ztag
                 return
               end
      endcase

      k.xsize *= k.scale
      k.scale = 1.
      str_element, k, 'no_color_scale', 1, /add_replace
      str_element, k, 'xstyle', 5, /add_replace
      str_element, k, 'ystyle', 5, /add_replace

      str_element, k, 'bottom', (k.gray - k.wash) > 7, /add_replace  ; washed out reds
      str_element, k, 'top', (k.gray + k.wash) < 254, /add_replace   ; washed out blues

      k.xrange = minmax(k.xrange)
      k.yrange = minmax(k.yrange)

      xpix = !d.x_ch_size*total(!x.margin)
      ypix = !d.y_ch_size*total(!y.margin)
      pix2deg = (k.xsize - xpix)/(k.xrange[1] - k.xrange[0])
      str_element, k, 'ysize', pix2deg*(k.yrange[1] - k.yrange[0]) + ypix, /add_replace

      if (!p.background ne 255) then begin
        revvid
        vswap = 1
      endif else vswap = 0

      win,Owin,xsize=k.xsize,ysize=k.ysize,key=key
      plot,[-1.],[-1.],xrange=k.xrange,/xsty,yrange=k.yrange,/ysty,xticks=k.xticks,xminor=k.xminor,$
         yticks=k.yticks,yminor=k.yminor,xtitle=k.xtitle,ytitle=k.ytitle,charsize=k.csize
      if (k.wash gt 0) then specplot, bmod.lon, bmod.lat, z, /overplot, limits=k
      contour, z, bmod.lon, bmod.lat, levels=k.levels, color=2, /overplot
      contour, z, bmod.lon, bmod.lat, levels=(-reverse(k.levels)), c_line=0, color=6, /overplot

      img = tvrd(/true)  ; store into image, so that it doesn't need to be redrawn later
      ppos = [0.,0.,k.xsize,k.ysize]  ; image takes up entire window

      if (vswap) then revvid
      initct,pct,reverse=prev
      eflg = 1
    endif else begin
      if keyword_set(big) then fname = file_which('MAG_MOLA_lg.bmp') $
                          else fname = file_which('MAG_MOLA.bmp')
      if keyword_set(dbr) then fname = file_which('DBR_TOPO_lg.bmp')

      if (fname eq '') then begin
        print, "MAG_MOLA.bmp not found!"
        return
      endif
      img = read_bmp(fname,/rgb)
      sz = size(img)

      xoff = round(34.*k.csize)
      yoff = round(30.*k.csize)
      i = sz[2] + (2*xoff)
      j = sz[3] + (2*yoff)

      if (keyword_set(big) or keyword_set(dbr)) then begin
	    win, Owin, xsize=1082, ysize=572, key=key
	  endif else begin
	    win, Owin, xsize=757, ysize=409, key=key
	  endelse

      px = [0.0, 1.0] * !d.x_vsize + xoff + 16
      py = [0.0, 1.0] * !d.y_vsize + yoff + 10
      ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]

      k.xrange = [0,360]
      k.yrange = [-90,90]
      k.xticks = 4
      k.xminor = 3
      k.yticks = 2
      k.yminor = 3
    endelse

    eflg = 1
  endif

  wset, owin

  if (eflg) then tv,img,ppos[0],ppos[1],/true
  if (~keyword_set(lang)) then begin
    position = ppos
    pen = 255
  endif else begin
    undefine, position
    pen = 0
  endelse

  plot,[-1.],[-1.],position=position,/device, $
    xrange=k.xrange,yrange=k.yrange,xticks=k.xticks,xminor=k.xminor, $
    yticks=k.yticks,yminor=k.yminor,/xstyle,/ystyle,/noerase,charsize=k.csize, $
    xtitle=k.xtitle, ytitle=k.ytitle, title=k.title, color=pen
  
  if (doterm) then begin
    mvn_mars_terminator, ttime, result=tdat, shadow=sflg
    oplot,tdat.tlon,tdat.tlat,color=1,psym=4,symsize=1
    oplot,[tdat.slon],[tdat.slat],color=5,psym=8,symsize=3
  endif

  if (dolab) then begin
    for i=0,(nsites-1) do xyouts,sites[0,i],sites[1,i],slab[i],align=0.5,charsize=1.5,color=scol[i],charthick=2
  endif else begin
    for i=0,(nsites-1) do oplot,[sites[0,i]],[sites[1,i]],psym=8,symsize=1.5,color=scol[i]
  endelse

  if (dosym) then oplot,[lon],[lat],psym=k.psym,color=k.color,linestyle=k.lstyle,thick=2,symsize=1.4
  if (doazel) then begin
;   initct,1070,previous_ct=pct,previous_rev=prev    ; red-to-blue color table, affects performance
      nwhisk = n_elements(lon)
      bscl = 7.*bscale  ; whisker scale factor in degrees
      azim = atan(bazel[*,1],bazel[*,0])
      lon1 = lon + bscl*cos(azim)
      lat1 = lat + bscl*sin(azim)
      cwhisk = cazel ? round(((-bazel[*,2] + 1.)/2.)*(254. - 7.) + 7.) : replicate(k.color, nwhisk)
      for i=0,(nwhisk-1) do oplot,[lon[i],lon1[i]],[lat[i],lat1[i]],color=cwhisk[i],thick=2
;   initct,pct,reverse=prev
  endif
  if keyword_set(alt) then xyouts,[lon]+2,[lat]+2,string(round(alt),format='(i4)'),color=k.color,charsize=k.csize

  wset,twin

  return

end
