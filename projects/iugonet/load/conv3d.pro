;+
; PROCEDURE: CONV3D
;   conv3d, tvar3d, $
;           selparam_idx=selparam_idx, $
;           selparam_dat=selparam_dat, $
;           newname=newname
;
; PURPOSE:
;   Convert 3D data to 2D or 1D data
;
; KEYWORDS:
;   tvar3d: tplot variables for 3D data
;   selparam_idx: a vector with 3 elements to identify the loaded variables
;           when converting 3D data to 2D or 1D data.
;   selparam_dat: a vector with 3 elements to identify the coordinate.
;           when converting 3D data to 2D or 1D data.
;   newname: if set, then name of the converted data will be newname.
;           This keyword is available only when selparam_idx is set.
;
; EXAMPLE:
;   conv3d, 'kyushugcm_T', selparam_idx=[0,0,1], selparam_dat=[30., 50., 0]
;       loads 1D data along z-axis at (x,y)=(30.,50.).
;
;   conv3d, 'kyushugcm_T', selparam_idx=[1,1,0], selparam_dat=[0., 0., 100.]
;       loads 2D data on the x-y plane at z=100.
;
; Written by Y.-M. Tanaka, Dec.24, 2012 (ytanaka at nipr.ac.jp)
;-

pro conv3d, tvar3d, selparam_idx=selparam_idx, selparam_dat=selparam_dat, $
	newname=newname

;----- default -----;
if n_params() eq 0 then begin
    message,'No input argument.'
    return
endif

if ~keyword_set(selparam_idx) or ~keyword_set(selparam_dat) then begin
    message,'selparam_idx and selparam_dat are not defined.'
    return
endif

tplot_tmp=tnames(tvar3d)
len=strlen(tplot_tmp)

if keyword_set(newname) then begin
    tvar_new=newname
endif else begin
    tvar_new=tvar3d
endelse

if len eq 0 then begin
    print, 'No such tplot variables.'
    return
endif else begin
    ;----- Loop for tvars -----;
    get_data, tplot_tmp, data=d, lim=lim, dlim=dlim

    v1=d.v1
    v2=d.v2
    v3=d.v3

    idx1=where(selparam_idx eq 1)
    case n_elements(idx1) of
        1: begin 
            case idx1 of
                0: begin
                    iv2=where(abs(v2 - selparam_dat[1]) eq min(abs(v2 - selparam_dat[1])), cnt)
                    if cnt gt 1 then iv2=iv2[0]
                    iv3=where(abs(v3 - selparam_dat[2]) eq min(abs(v3 - selparam_dat[2])), cnt)
                    if cnt gt 1 then igv3=igv3[0]
                    dy=reform(d.y[*, *, iv2, iv3])
                    store_data, tvar_new, data={x:d.x, y:dy, v:d.v1}, lim=lim, dlim=dlim
                end
                1: begin
                    iv1=where(abs(v1 - selparam_dat[0]) eq min(abs(v1 - selparam_dat[0])), cnt)
                    if cnt gt 1 then iv1=iv1[0]
                    iv3=where(abs(v3 - selparam_dat[2]) eq min(abs(v3 - selparam_dat[2])), cnt)
                    if cnt gt 1 then igv3=igv3[0]
                    dy=reform(d.y[*, iv1, *, iv3])
                    store_data, tvar_new, data={x:d.x, y:dy, v:d.v2}, lim=lim, dlim=dlim
                end
                2: begin
                    iv1=where(abs(v1 - selparam_dat[0]) eq min(abs(v1 - selparam_dat[0])), cnt)
                    if cnt gt 1 then iv1=iv1[0]
                    iv2=where(abs(v2 - selparam_dat[1]) eq min(abs(v2 - selparam_dat[1])), cnt)
                    if cnt gt 1 then iv2=iv2[0]
                    dy=reform(d.y[*, iv1, iv2, *])
                    store_data, tvar_new, data={x:d.x, y:dy, v:d.v3}, lim=lim, dlim=dlim
                end
            endcase
        end
        2: begin
            case idx1[0]+idx1[1] of
                1: begin
                    iv3=where(abs(v3 - selparam_dat[2]) eq min(abs(v3 - selparam_dat[2])), cnt)
                    if cnt gt 1 then igv3=igv3[0]
                    dy=reform(d.y[*, *, *, iv3])
                    store_data, tvar_new, data={x:d.x, y:dy, v1:d.v1, v2:d.v2}, lim=lim, dlim=dlim
                end
                2: begin
                    iv2=where(abs(v2 - selparam_dat[1]) eq min(abs(v2 - selparam_dat[1])), cnt)
                    if cnt gt 1 then iv2=iv2[0]
                    dy=reform(d.y[*, *, iv2, *])
                    store_data, tvar_new, data={x:d.x, y:dy, v1:d.v1, v2:d.v3}, lim=lim, dlim=dlim
                end
                3: begin
                    iv1=where(abs(v1 - selparam_dat[0]) eq min(abs(v1 - selparam_dat[0])), cnt)
                    if cnt gt 1 then iv1=iv1[0]
                    dy=reform(d.y[*, iv1, *, *])
                    store_data, tvar_new, data={x:d.x, y:dy, v1:d.v2, v2:d.v3}, lim=lim, dlim=dlim
                end
            endcase
        end
    endcase
endelse

end


