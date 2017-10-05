;+
;PROCEDURE:   swe_pad_timing
;PURPOSE:
;  Disassembles A2 packets and sorts data in time sequence.
;
;USAGE:
;  swe_pad_timing
;
;INPUTS:
;
;KEYWORDS:
;       TRANGE:       Time range for processing, in any format
;                     accepted by time_double().
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad_timing.pro $
;
;CREATED BY:    David L. Mitchell  06-25-13
;FILE: swe_pad_timing.pro
;-
pro swe_pad_timing, trange=trange

  @mvn_swe_com

  if (size(a2,/type) eq 8) then begin

    if keyword_set(trange) then begin
      tmin = min(time_double(trange),max=tmax)
      tndx = where((a2.time ge tmin) and (a2.time le tmax), npkt)
      j0 = min(tndx)
      j1 = max(tndx)
    endif else begin
      npkt = n_elements(a2)
      j0 = 0L
      j1 = npkt - 1L
    endelse

    n_e = swe_ne[a2[j0:j1].group]
    nspec = long(total(n_e,/integer))

    ptime = dblarr(nspec)
    pdat = fltarr(nspec,16)

    tvec = dindgen(448)*(1.95D/448D)
    tsam0 = dblarr(64)
    tsam1 = dblarr(32)
    tsam2 = dblarr(16)

    for j=0,63 do tsam0[j] = total(tvec[(j*7+1):(j*7+6)])/6D
    for j=0,31 do tsam1[j] = total(tsam0[(2*j):(2*j+1)])/2D
    for j=0,15 do tsam2[j] = total(tsam1[(2*j):(2*j+1)])/2D

    k = 0L
    for j=j0,j1 do begin
      case (a2[j].group) of
        0 : begin
              ptime[k:(k+63)] = a2[j].time + tsam0
              pdat[k:(k+63),*] = transpose(a2[j].data)
              k = k + 64L
            end

        1 : begin
              ptime[k:(k+31)] = a2[j].time + tsam1
              pdat[k:(k+31),*] = transpose(a2[j].data[*,0:31])
              k = k + 32L
            end

        2 : begin
              ptime[k:(k+15)] = a2[j].time + tsam2
              pdat[k:(k+15),*] = transpose(a2[j].data[*,0:15])
              k = k + 16L
            end
      endcase
    endfor
  
    store_data,'pdat_svy',data={x:ptime, y:pdat, v:findgen(16)}
    options,'pdat_svy','ytitle','Pad Svy Timing'
    options,'pdat_svy','psym',1
    ylim,'pdat_svy',-10,300,0

  endif else print,"No A2 data to process."

  if (size(a3,/type) eq 8) then begin

    if keyword_set(trange) then begin
      tmin = min(time_double(trange),max=tmax)
      tndx = where((a3.time ge tmin) and (a3.time le tmax), npkt)
      j0 = min(tndx)
      j1 = max(tndx)
    endif else begin
      npkt = n_elements(a3)
      j0 = 0L
      j1 = npkt - 1L
    endelse

    n_e = swe_ne[a3[j0:j1].group]
    nspec = long(total(n_e,/integer))

    ptime = dblarr(nspec)
    pdat = fltarr(nspec,16)

    tvec = dindgen(448)*(1.95D/448D)
    tsam0 = dblarr(64)
    tsam1 = dblarr(32)
    tsam2 = dblarr(16)

    for j=0,63 do tsam0[j] = total(tvec[(j*7+1):(j*7+6)])/6D
    for j=0,31 do tsam1[j] = total(tsam0[(2*j):(2*j+1)])/2D
    for j=0,15 do tsam2[j] = total(tsam1[(2*j):(2*j+1)])/2D

    k = 0L
    for j=j0,j1 do begin
      case (a3[j].group) of
        0 : begin
              ptime[k:(k+63)] = a3[j].time + tsam0
              pdat[k:(k+63),*] = transpose(a3[j].data)
              k = k + 64L
            end

        1 : begin
              ptime[k:(k+31)] = a3[j].time + tsam1
              pdat[k:(k+31),*] = transpose(a3[j].data[*,0:31])
              k = k + 32L
            end

        2 : begin
              ptime[k:(k+15)] = a3[j].time + tsam2
              pdat[k:(k+15),*] = transpose(a3[j].data[*,0:15])
              k = k + 16L
            end
      endcase
    endfor
  
    store_data,'pdat_arc',data={x:ptime, y:pdat, v:findgen(16)}
    options,'pdat_arc','ytitle','Pad Arc Timing'
    options,'pdat_arc','psym',1
    ylim,'pdat_arc',-10,300,0

  endif else print,"No A3 data to process."

  return

end
