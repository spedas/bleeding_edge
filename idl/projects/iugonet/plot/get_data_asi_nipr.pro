;+
; PROCEDURE get_data_asi_nipr
;
; :DESCRIPTION:
;    Extract the ASI data at the designated time from the tplot variable 
;    and make the structure.
;
; :PARAMS:
;    asi_vn: tplot variable name (as string)
;
; :KEYWORDS:
;    set_time: set the time (UNIX time) to get 2D data (can be an array)
;    altitude: set the altitude on which the image data will be mapped.
;              The default value is 110 (km).
;    aacgm: set to obtain the position data in the AACGM coordinates
;    data: output data as the structure which have the tags as follows;
;          name: tplot variable name
;          set_time: the designated time (array)
;          dat_time: the actual time (array)
;          data: image data
;          alti: altitude (scalar)
;          azim: azimuth angle for each pixel of the images
;          elev: elevation angle for each pixel of the images
;          center_glat: geographic latitude for the center of each pixel
;          center_glon: geographic longitude
;          corner_glat: geographic latitude for the corner of each pixel
;          corner_glon: geographic longitude
;          center_mlat: aacgm latitude for the center of each pixel
;          center_mlon: aacgm longitude
;          center_mlt: magnetic local time
;          corner_mlat: aacgm latitude for the corner of each pixel
;          corner_mlon: aacgm longitude
;          corner_mlt: magnetic local time
;
; :AUTHOR:
;    Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/07/08: Created
;
;-
pro get_data_asi_nipr, asi_vn, set_time=set_time, $
    altitude=altitude, aacgm=aacgm, data=data

;----- initialize the map2d environment -----;
map2d_init

;----- output data -----;
data=''

;===== check parameters =====;
npar=n_params()
if npar lt 1 then return
;----- if asi_vn is the index number for tplot var -----;
vn = tnames(asi_vn)
if total(vn eq '') gt 0 then begin
    print, 'given tplot var(s) does not exist?'
    return
endif

;----- set_time -----;
if ~keyword_set(set_time) then begin
    t0 = !map2d.time
    get_timespan, tr
    if t0 ge tr[0] and t0 le tr[1] then begin
        set_time = t0 
    endif else begin
        set_time = (tr[0]+tr[1])/2.  ; take the center of the designated time range
    endelse
endif

;----- altitude -----;
if ~keyword_set(altitude) then altitude=110.  ; 90, 110, 150, 250km

;----- aacgm -----;
if ~keyword_set(aacgm) then aacgm=!map2d.coord

;----- obtain azimuth and elevation angle -----;
azel_vn=vn+'_azel'  ; tplot variables for azel
azel_vn = tnames(azel_vn)
if total(azel_vn eq '') gt 0 then begin
    print, 'no azimuth and elevation angle data: '+azel_vn+'!!!'
    return
endif
get_data, azel_vn, data=azel
azim=reform(azel.y[0, *, *, 0])
elev=reform(azel.y[1, *, *, 0])

;----- obtain corner position data -----;
cor_vn=vn+'_pos_cor'  ; tplot variables for position
cor_vn = tnames(cor_vn)
if total(cor_vn eq '') gt 0 then begin
    print, 'no corner position data: '+cor_vn+'!!!'
    return
endif else begin
    get_data, cor_vn, data=cor_dat
    altvec=cor_dat.v2
    ialt=where(fix(altvec/1000.) eq fix(altitude), cnt)
    if cnt eq 0 then begin
        print, 'no corner position data for the designated altitude!!!'
        return
    endif
    corner_glat=reform(cor_dat.y[0, ialt, *, *, 0])
    corner_glon=reform(cor_dat.y[1, ialt, *, *, 0])
endelse

;----- obtain center position data -----;
cen_vn=vn+'_pos_cen'  ; tplot variables for position
cen_vn = tnames(cen_vn)
if total(cen_vn eq '') gt 0 then begin
    print, 'no center position data: '+cen_vn+'!!!'
    return
endif else begin
    get_data, cen_vn, data=cen_dat
    altvec=cen_dat.v2
    ialt=where(fix(altvec/1000.) eq fix(altitude), cnt)
    if cnt eq 0 then begin
        print, 'no center position data for the designated altitude!!!'
        return
    endif
    center_glat=reform(cen_dat.y[0, ialt, *, *, 0])
    center_glon=reform(cen_dat.y[1, ialt, *, *, 0])
endelse

;----- obtain mlat mlon -----;
corner_mlat='' & corner_mlon=''
center_mlat='' & center_mlon=''
if keyword_set(aacgm) then begin
    ;----- Load the S-H coefficients -----;
    ts = time_struct(set_time)
    aacgmloadcoef, ts.year
    ;----- corner mlat mlon -----;
    altmat = corner_glat & altmat[*] = altitude ;***** altitude in km *****;
    aacgmconvcoord, corner_glat, corner_glon, altmat, $
        corner_mlat, corner_mlon, err, /to_aacgm
    ;----- center mlat mlon -----;
    altmat = center_glat & altmat[*] = altitude ;***** altitude in km *****;
    aacgmconvcoord, center_glat, center_glon, altmat, $
        center_mlat, center_mlon, err, /to_aacgm
endif

;----- initialize output arrays -----;
ntime=n_elements(set_time)
dim=size(azim, /dim)
nx=dim[0] & ny=dim[1]
set_time_all = ''
dat_time_all = ''
image_all = fltarr(ntime, nx, ny)

if keyword_set(aacgm) then begin
    center_mlt_all  = fltarr(ntime, nx, ny)
    corner_mlt_all  = fltarr(ntime, nx+1, ny+1)
endif else begin
    center_mlt_all  = ''
    corner_mlt_all  = ''
endelse

for itime=0L, ntime-1 do begin
    stime=time_double(set_time[itime])

    ;----- obtain image data for the designated time -----;
    get_data, vn, data=d
    tidx = nn(d.x, stime)
    if tidx lt 0 then continue
    image = reform(d.y[tidx, *, *])
    dtime=d.x[tidx]

    ;----- check if data for the designated time is obtained or not. -----;
    crt_dt=10.
    dt = abs(stime - d.x[tidx])
    if dt lt crt_dt then note = '  (ok)' else note = ' !!! not within '+string(fix(crt_dt))+' sec !!!'
    print, '========== '+vn+' =========='
    print, 'designated time: '+time_string(stime)
    print, '  ASI data time: '+time_string(dtime), tidx, note
    d = 0L ;initialize the variable to save the memory

    ;----- append array -----;
    append_array, set_time_all, stime
    append_array, dat_time_all, dtime
    image_all[itime, *, *] = image

    ;----- ontain mlt -----;
    if keyword_set(aacgm) then begin
        ts = time_struct(stime)
        ;----- center mlt -----;
        yrs = fix(center_mlat) & yrs[*] = ts.year
        yrsec = long(center_mlat) & yrsec[*] = long( (ts.doy-1)*86400. + ts.sod )
        mlt = aacgmmlt( yrs, yrsec, center_mlon ) 
        mlt = ( ( mlt + 24. ) mod 24. ) / 24.*360. ; [deg]
        igt=where(mlt gt 180., cnt)
        if cnt gt 0 then mlt[igt] -= 360.
        center_mlt_all[itime, *, *] =mlt

        ;----- corner mlt -----;
        yrs = fix(corner_mlat) & yrs[*] = ts.year
        yrsec = long(corner_mlat) & yrsec[*] = long( (ts.doy-1)*86400. + ts.sod )
        mlt = aacgmmlt( yrs, yrsec, corner_mlon ) 
        mlt = ( ( mlt + 24. ) mod 24. ) / 24.*360. ; [deg]
        igt=where(mlt gt 180., cnt)
        if cnt gt 0 then mlt[igt] -= 360.
        corner_mlt_all[itime, *, *] =mlt
    endif
endfor

data={name:vn, set_time:set_time_all, dat_time:dat_time_all, $
    data:image_all, alti:altitude, azim:azim, elev:elev, $
    center_glat:center_glat, center_glon:center_glon, $
    corner_glat:corner_glat, corner_glon:corner_glon, $
    center_mlat:center_mlat, center_mlon:center_mlon, center_mlt:center_mlt_all, $
    corner_mlat:corner_mlat, corner_mlon:corner_mlon, corner_mlt:corner_mlt_all}

end
