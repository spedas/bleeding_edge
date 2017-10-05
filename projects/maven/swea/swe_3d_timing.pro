;+
;PROCEDURE:   swe_3d_timing
;PURPOSE:
;  Disassembles A0 packets and sorts data in time sequence.
;
;USAGE:
;  swe_3d_timing
;
;INPUTS:
;
;KEYWORDS:
;       TRANGE:       Time range for processing, in any format
;                     accepted by time_double().
;
;       ANODE:        Anode number to process.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_timing.pro $
;
;CREATED BY:    David L. Mitchell  06-25-13
;FILE: swe_3d_timing.pro
;-
pro swe_3d_timing, trange=trange, anode=anode

  @mvn_swe_com

  if (size(swe_3d,/type) eq 8) then begin

    if keyword_set(trange) then begin
      tmin = min(time_double(trange),max=tmax)
      tndx = where((swe_3d.time ge tmin) and (swe_3d.time le tmax), npkt)
      i0 = min(tndx)
      i1 = max(tndx)
    endif else begin
      npkt = n_elements(swe_3d)
      i0 = 0L
      i1 = npkt - 1L
    endelse

    if not keyword_set(anode) then anode = 0

; Index map for extracting 16x6 anode/deflection bins from 80 angles

    dfwd = intarr(16,6)
    dfwd[*,0] = indgen(16)/2
    for i=1,4 do dfwd[*,i] = indgen(16) + 16*i
    dfwd[*,5] = indgen(16)/2 + 8
    dfwd = transpose(dfwd)  ; 6 deflections X 16 anodes
    drev = reverse(dfwd,1)  ; deflections in reverse order

; Deflection bins

    ifwd = indgen(6) + 1    ; 6 deflection bins (bin 0 is discarded)
    irev = reverse(ifwd)    ; deflection bins in reverse order

; Calculate sample times and energies for grouping parameter g = 0,1,2

    tvec = dindgen(448)*(1.95D/448D)  ; 7 deflections X 64 energies = 448 steps

    tsam0 = dblarr(6L*64L)            ; 6 deflections X 64 energies = 384 steps (g = 0)
    esam0 = fltarr(6L*64L)
    for j=0,63 do begin
      tsam0[(j*6):(j*6 + 5)] = tvec[(j*7) + ifwd]  ; discard every 7th defl bin
      esam0[(j*6):(j*6 + 5)] = float(j)
    endfor

    tsam1 = dblarr(6L*32L)            ; 6 deflections X 32 energies = 192 steps (g = 1)
    esam1 = fltarr(6L*32L)
    for j=0,31 do begin
      tsam1[(j*6):(j*6 + 5)] = (tsam0[j*12 + ifwd - 1] + tsam0[(j+1)*12 - ifwd])/2D
      esam1[(j*6):(j*6 + 5)] = (esam0[j*12 + ifwd - 1] + esam0[(j+1)*12 - ifwd])/2D
    endfor

    tsam2 = dblarr(6L*16L)            ; 6 deflections X 16 energies = 96 steps  (g = 2)
    esam2 = fltarr(6L*16L)
    for j=0,15 do begin
      tsam2[(j*6):(j*6 + 5)] = (tsam1[j*12 + ifwd - 1] + tsam1[j*12 + ifwd + 5])/2D
      esam2[(j*6):(j*6 + 5)] = (esam1[j*12 + ifwd - 1] + esam1[j*12 + ifwd + 5])/2D
    endfor

; Initialize data arrays

    dtime = [0D]
    ddat = [0.]
    engy = ddat
    defl = ddat

; Fill data arrays

    for i=i0,i1 do begin
      ddd = swe_3d[i]
    
      case ddd.n_e of
        64 : begin
               dtime = [dtime, ddd.time + tsam0]
               engy = [engy, esam0]

               for j=0,63 do begin
                 dtmp = ddd.data[*,j]
                 if (j mod 2) then begin                 ; fill left
                   ddat = [ddat, dtmp[drev[*,anode]]]
                   defl = [defl, irev]
                 endif else begin                        ; fill right
                   ddat = [ddat, dtmp[dfwd[*,anode]]]
                   defl = [defl, ifwd]
                 endelse
               endfor
             end
        32 : begin
               dtime = [dtime, ddd.time + tsam1]
               engy = [engy, esam1]

               for j=0,31 do begin
                 dtmp = ddd.data[*,j]
                 ddat = [ddat, dtmp[dfwd[*,anode]]]      ; fill right
                 defl = [defl, ifwd]
               endfor
             end
        16 : begin
               dtime = [dtime, ddd.time + tsam2]
               engy = [engy, esam2]

               for j=0,15 do begin
                 dtmp = ddd.data[*,j]
                 ddat = [ddat, dtmp[dfwd[*,anode]]]      ; fill right
                 defl = [defl, ifwd]
               endfor
             end
      endcase

    endfor

; Trim arrays

    dtime = dtime[1L:*]
    ddat = ddat[1L:*]
    engy = engy[1L:*]
    defl = defl[1L:*]

; Create TPLOT variables

    store_data,'ddat_svy',data={x:dtime, y:ddat}
    options,'ddat_svy','ytitle','3D Svy Timing (A' + string(anode,format='(i2.2)') + ')'
    options,'ddat_svy','psym',1
    ylim,'ddat_svy',-10,300,0

    store_data,'engy_svy',data={x:dtime, y:engy}
    options,'engy_svy','psym',3
    ylim,'engy_svy',-1,64,0

    store_data,'defl_svy',data={x:dtime, y:defl}
    options,'defl_svy','psym',3
    ylim,'defl_svy',0,7,0

  endif else print,"No A0 data to process."

  if (size(swe_3d_arc,/type) eq 8) then begin

    if keyword_set(trange) then begin
      tmin = min(time_double(trange),max=tmax)
      tndx = where((swe_3d_arc.time ge tmin) and (swe_3d_arc.time le tmax), npkt)
      i0 = min(tndx)
      i1 = max(tndx)
    endif else begin
      npkt = n_elements(swe_3d_arc)
      i0 = 0L
      i1 = npkt - 1L
    endelse

    if not keyword_set(anode) then anode = 0

; Index map for extracting 16x6 anode/deflection bins from 80 angles

    dfwd = intarr(16,6)
    dfwd[*,0] = indgen(16)/2
    for i=1,4 do dfwd[*,i] = indgen(16) + 16*i
    dfwd[*,5] = indgen(16)/2 + 8
    dfwd = transpose(dfwd)  ; 6 deflections X 16 anodes
    drev = reverse(dfwd,1)  ; deflections in reverse order

; Deflection bins

    ifwd = indgen(6) + 1    ; 6 deflection bins (bin 0 is discarded)
    irev = reverse(ifwd)    ; deflection bins in reverse order

; Calculate sample times and energies for grouping parameter g = 0,1,2

    tvec = dindgen(448)*(1.95D/448D)  ; 7 deflections X 64 energies = 448 steps

    tsam0 = dblarr(6L*64L)            ; 6 deflections X 64 energies = 384 steps (g = 0)
    esam0 = fltarr(6L*64L)
    for j=0,63 do begin
      tsam0[(j*6):(j*6 + 5)] = tvec[(j*7) + ifwd]  ; discard every 7th defl bin
      esam0[(j*6):(j*6 + 5)] = float(j)
    endfor

    tsam1 = dblarr(6L*32L)            ; 6 deflections X 32 energies = 192 steps (g = 1)
    esam1 = fltarr(6L*32L)
    for j=0,31 do begin
      tsam1[(j*6):(j*6 + 5)] = (tsam0[j*12 + ifwd - 1] + tsam0[(j+1)*12 - ifwd])/2D
      esam1[(j*6):(j*6 + 5)] = (esam0[j*12 + ifwd - 1] + esam0[(j+1)*12 - ifwd])/2D
    endfor

    tsam2 = dblarr(6L*16L)            ; 6 deflections X 16 energies = 96 steps  (g = 2)
    esam2 = fltarr(6L*16L)
    for j=0,15 do begin
      tsam2[(j*6):(j*6 + 5)] = (tsam1[j*12 + ifwd - 1] + tsam1[j*12 + ifwd + 5])/2D
      esam2[(j*6):(j*6 + 5)] = (esam1[j*12 + ifwd - 1] + esam1[j*12 + ifwd + 5])/2D
    endfor

; Initialize data arrays

    dtime = [0D]
    ddat = [0.]
    engy = ddat
    defl = ddat

; Fill data arrays

    for i=i0,i1 do begin
      ddd = swe_3d_arc[i]
    
      case ddd.n_e of
        64 : begin
               dtime = [dtime, ddd.time + tsam0]
               engy = [engy, esam0]

               for j=0,63 do begin
                 dtmp = ddd.data[*,j]
                 if (j mod 2) then begin                 ; fill left
                   ddat = [ddat, dtmp[drev[*,anode]]]
                   defl = [defl, irev]
                 endif else begin                        ; fill right
                   ddat = [ddat, dtmp[dfwd[*,anode]]]
                   defl = [defl, ifwd]
                 endelse
               endfor
             end
        32 : begin
               dtime = [dtime, ddd.time + tsam1]
               engy = [engy, esam1]

               for j=0,31 do begin
                 dtmp = ddd.data[*,j]
                 ddat = [ddat, dtmp[dfwd[*,anode]]]      ; fill right
                 defl = [defl, ifwd]
               endfor
             end
        16 : begin
               dtime = [dtime, ddd.time + tsam2]
               engy = [engy, esam2]

               for j=0,15 do begin
                 dtmp = ddd.data[*,j]
                 ddat = [ddat, dtmp[dfwd[*,anode]]]      ; fill right
                 defl = [defl, ifwd]
               endfor
             end
      endcase

    endfor

; Trim arrays

    dtime = dtime[1L:*]
    ddat = ddat[1L:*]
    engy = engy[1L:*]
    defl = defl[1L:*]

; Create TPLOT variables

    store_data,'ddat_arc',data={x:dtime, y:ddat}
    options,'ddat_arc','ytitle','3D Arc Timing (A' + string(anode,format='(i2.2)') + ')'
    options,'ddat_arc','psym',1
    ylim,'ddat_arc',-10,300,0

    store_data,'engy_arc',data={x:dtime, y:engy}
    options,'engy_arc','psym',3
    ylim,'engy_arc',-1,64,0

    store_data,'defl_arc',data={x:dtime, y:defl}
    options,'defl_arc','psym',3
    ylim,'defl_arc',0,7,0

  endif else print,"No A1 data to process."
  
  return

end
