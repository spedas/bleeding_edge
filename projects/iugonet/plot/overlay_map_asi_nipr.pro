;+
;	PROCEDURE overlay_map_asi_nipr
;
; :DESCRIPTION:
;    Plot 2D images from all-sky imagers on the plot window set up by map_set.
;
; :PARAMS:
;    asi_vn:   tplot variable names (as strings) to be plotted
;
; :KEYWORDS:
;    set_time: time to plot all-sky imager data 
;              (ex., '2012-01-12/21:30:00' or Unix time)
;    altitude: altitude on which the image data will be mapped.
;              The default value is 110 (km). Available values are 90, 110, 150, 250.
;    position:  position of the plot frame in the plot window
;    colorrange: range of values of colorscale (this can be an array)
;    notimelabel: set to surpress drawing the time label
;    timelabelpos: position of the color scale in the noraml coordinates
;    tlcharsize: size of the characters used for the time label
;    nocolorscale: set to surpress drawing the color scale
;    colorscalepos: position of the color scale in the noraml coordinates.
;                   Default: [0.85, 0.1, 0.87, 0.45]
;    cscharsize: size of the characters used for the colorscale
;
; :AUTHOR:
;    Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/07/08: Created
;
;-
pro overlay_map_asi_nipr, asi_vns, set_time=set_time, $
    altitude=altitude, position=position, $
    colorrange=colorrange, notimelabel=notimelabel, $
    timelabelpos=timelabelpos, tlcharsize=tlcharsize, $
    nocolorscale=nocolorscale, colorscalepos=colorscalepos, $
    cscharsize=cscharsize

;----- initialize the map2d environment -----;
map2d_init

;===== check parameters =====;
npar=n_params()
if npar lt 1 then return
;----- if datvn is the index number for tplot var -----;
vns = tnames(asi_vns)
if total(vns eq '') gt 0 then begin
    print, 'given tplot var(s) does not exist?'
    return
endif

;----- set_time -----;
if ~keyword_set(set_time) then time_tmp=!map2d.time

;----- coord -----;
coord_tmp=!map2d.coord

;----- color range -----;
default_colorrange = [10., 256.]
if ~keyword_set(colorrange) then colorrange = default_colorrange

;===== loop for processing multiple arguments =====;
;----- initialize the combined arrays -----;
cmb_img = '' & cmb_imgscl = '' & cmb_crng = ''
cmb_elev = '' & cmb_lats_corner = '' & cmb_lons_corner = ''
cmb_flag = ''

for ivn=0L, n_elements(vns)-1 do begin
    vn = vns[ivn]

    ;----- obtain image and position data -----;
    get_data_asi_nipr, vn, set_time=time_tmp, $
    altitude=altitude, aacgm=coord_tmp, data=data
    elev=data.elev
    img=reform(data.data)
    if coord_tmp eq 1 then begin  ; AACGM
        lats_cor=data.corner_mlat
        lons_cor=reform(data.corner_mlt)
    endif else begin
        lats_cor=data.corner_glat
        lons_cor=data.corner_glon
    endelse

    ;----- set the color range for image data -----;
    ncrng = size(colorrange, /n_dim)
    case ncrng of
        1: begin  ;given as a 1-d array, used for all data
            crng = colorrange
        end
        2: begin  ;given as a 2-d array, used each for each data
            narr = n_elements(colorrange[0,*])
            crng = reform(colorrange[0:1, ivn < (narr-1)])
        end
        else: begin
            print, 'warning: invalid array is given for scale: use default!'
            crng = default_colorrange
        end
    endcase
    scale_image_values, img, crng, imgscl

    ;----- generate array -----;
    dim=size(elev, /dim)
    nx=dim[0] & ny=dim[1]
    elev=elev[*]
    npxl=n_elements(elev)
    lats_corner=fltarr(npxl, 4)
    lons_corner=fltarr(npxl, 4)
    flag=intarr(npxl)-1 

    ipxl=0L
    for iy=0L, ny-1 do begin
    	for ix=0L, nx-1 do begin
            lats_corner[ipxl,0:3] = transpose( lats_cor[ [ix,ix,ix+1,ix+1],[iy,iy+1,iy+1,iy] ] )
            lons_corner[ipxl,0:3] = transpose( lons_cor[ [ix,ix,ix+1,ix+1],[iy,iy+1,iy+1,iy] ] )
            if total(finite(lats_corner[ipxl, 0:3])) eq 4 then flag[ipxl]=1
            ipxl = ipxl + 1L
        endfor
    endfor

    ;----- append array -----;
    append_array, cmb_elev, elev
    append_array, cmb_img, img[*]
    append_array, cmb_imgscl, imgscl[*]
    append_array, cmb_crng, crng
    append_array, cmb_lats_corner, lats_corner
    append_array, cmb_lons_corner, lons_corner
    append_array, cmb_flag, flag
endfor

;----- sort by increasing elevation angle -----;
sidx = sort(cmb_elev)
cmb_elev = cmb_elev[sidx]
cmb_img = cmb_img[sidx]
cmb_imgscl = cmb_imgscl[sidx]
cmb_lats_corner = cmb_lats_corner[sidx,*]
cmb_lons_corner = cmb_lons_corner[sidx,*]
cmb_flag = cmb_flag[sidx]

;----- Set the plot position -----;
pre_position = !p.position
if keyword_set(position) then begin
!p.position = position
endif else position = !p.position

;----- paint each pixel -----;
for ipxl=0l, n_elements(cmb_elev)-1 do begin
    if cmb_elev[ipxl] ge 8 and finite( cmb_img[ipxl] ) and cmb_flag[ipxl] eq 1 then begin
        polyfill, reform(cmb_lons_corner[ipxl,*]), reform(cmb_lats_corner[ipxl,*]), $
            color=cmb_imgscl[ipxl] 
    endif
endfor

;---- time label -----;
if ~keyword_set(notimelabel) then begin
    if ~keyword_set(tlcharsize) then tlcharsize=1.0
    if keyword_set(timelabelpos) then begin ;customizable by user
        x = !x.window[0] + (!x.window[1]-!x.window[0])*timelabelpos[0] 
        y = !y.window[0] + (!y.window[1]-!y.window[0])*timelabelpos[1]
    endif else begin  ;default position
        x = !x.window[0]+0.02 & y = !y.window[0]+0.02
    endelse
    t = time_tmp
    tstr = time_string(t, tfor='hh:mm:ss')+' UT'
    xyouts, x, y, tstr, /normal, $
        font=1, charsize=tlcharsize
endif

;----- color scale -----;
if ~keyword_set(nocolorscale) then begin
    if ~keyword_set(cscharsize) then cscharsize=1.0
    if keyword_set(colorscalepos) then begin
        cp = colorscalepos
        x0 = !x.window[0] & xs = !x.window[1]-!x.window[0]
        y0 = !y.window[0] & ys = !y.window[1]-!y.window[0]
        cspos= [ x0 + xs * cp[0], $
            y0 + ys * cp[1], $
            x0 + xs * cp[2], $
            y0 + ys * cp[3] ]
    endif else begin
        cspos = [0.85,0.1,0.87,0.45]
    endelse

    pre_yticklen = !y.ticklen
    !y.ticklen = 0.25
    draw_color_scale, range=cmb_crng[0:1,0], $
        pos=cspos, charsize=cscharsize
    !y.ticklen = pre_yticklen
endif

;----- Resotre the original plot position -----;
if ~keyword_set(pre_position) then pre_position=0
!p.position = pre_position

end
