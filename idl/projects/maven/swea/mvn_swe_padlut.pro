;+
;PROCEDURE:   mvn_swe_padlut
;PURPOSE:
;  Calculates the pitch angle sorting look up table.
;
;USAGE:
;  mvn_swe_padlut, lut=lut
;
;INPUTS:
;
;KEYWORDS:
;
;       DLAT:        Latitude range of each elevation bin (deg).  This depends
;                    on the sweep table.
;
;                        Default at launch is 22.5 deg.
;                        Actual value is closer to 20 deg.
;
;       LUT:         Named variable to hold the LUT.
;
;       DOPLOT:      Plot the result.
;
;       PRINTAB:     Print the result.
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padlut.pro $
;
;CREATED BY:    David L. Mitchell  03-17-14
;FILE: mvn_swe_padlut.pro
;-
pro mvn_swe_padlut, dlat=dlat, lut=idef, doplot=doplot, printab=printab

  @mvn_swe_com

; Dimensions of lookup table (nlon X nlat) -- hard wired in FSW

  nlon = 16
  nlat = 40

; Center latitudes of lookup table bins

  lon = replicate(0.,nlat)
  lat = -90. + (180./float(nlat))*(findgen(nlat) + 0.5)

; Center longitudes and latitudes of instrument bins
;   slon[i] = center longitude of azimuth bin i
;   slat[j] = center latitude of elevation bin j

  dlon = 22.5
  if not keyword_set(dlat) then dlat = 22.5

  slon = (findgen(16) + 0.5)*dlon
  slat = (findgen(6) + 0.5 - 3.0)*dlat


; If the magnetic latitude is in SWEA's blind spot, then choose the
; great circle within SWEA's fov that is closest to the magnetic 
; field direction.

  latmax = slat[5] + dlat/2.

  idef = intarr(nlon,nlat)

  for i=0,(nlat-1) do begin

    plat = (lat[i] < latmax) > (-latmax)
    plat = plat*cos((lon - slon)*!dtor)

; For each anode sector (azimuth bin) choose the deflector setting
; that provides a look direction closest to the great circle.
;   lower deflector --> [ 0, 1, 2]
;   upper deflector --> [ 3, 4, 5]

    indx = where(plat lt 0., count)
    if (count gt 0.) then idef[indx,i] = ceil(plat[indx]/dlat) + 2
    indx = where(plat ge 0., count)
    if (count gt 0.) then idef[indx,i] = floor(plat[indx]/dlat) + 3

  endfor

; Plot the result

  if keyword_set(doplot) then begin
    if (nlat gt 10) then begin
      limits = {x_no_interp:1, y_no_interp:1, xrange:[0,16], xmargin:[10,10], $
                xstyle:1, yrange:[-90,90], ystyle:1, yticks:6, yminor:3, $
                xtitle:'Azimuth Bin relative to Magnetic Reference Bin', $
                ytitle:'Magnetic Elevation', ztitle:'Deflector Bin', charsize:1.2,$
                zrange:[0,5],zticks:5}

      nbins = n_elements(slon)
      x = fltarr(nbins+2)
      x[1:nbins] = slon/dlon
      x[0] = x[1] - 1.
      x[nbins+1] = x[nbins] + 1
    
      z = intarr(nbins+2,nlat)
      for i=1,16 do z[i,*] = idef[i-1,*]
      z[0,*] = z[1,*]
      z[nbins+1,*] = z[nbins,*]

      specplot,x,lat,z,limits=limits
    
      oplot,[0,16],[-latmax,-latmax],line=2
      oplot,[0,16],[latmax,latmax],line=2
    
      xyouts,8,-75,'Blind Spot',/data,charsize=1.5,align=0.5
      xyouts,8,75,'Blind Spot',/data,charsize=1.5,align=0.5

      blat = -90. + (180./float(nlat))*(findgen(nlat) + 1.)
      for i=0,nlat-1 do oplot,[0.,16.],[blat[i],blat[i]],/line
      blat = -90. + (180./float(nlat))*(findgen(nlat) + 0.2)
      for i=0,nlat-1 do xyouts,3.5,blat[i],string(i,format='(i2)')

    endif else begin

      plot,slon/dlon,idef[*,0],psym=10,xtitle='Anode Bin',ytitle='Deflector Bin',$
           xrange=[0,16],/xsty,yrange=[-0.5,5.5],/ysty,charsize=1.2
  
      for i=1,(nlat-1) do oplot,slon/dlon,idef[*,i],psym=10

    endelse
  endif
  
  if keyword_set(printab) then begin
    for i=0,(nlat-1) do print,i,idef[*,i],format='(i4,3x,16(i4))' 
  endif

  return

end
