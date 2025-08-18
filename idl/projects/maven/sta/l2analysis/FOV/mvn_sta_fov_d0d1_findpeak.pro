;+
;Find the position of the peak eflux in d0 / d1 data products. The simple way to do this is to find the peak eflux,
;but sometimes the peak can be broad and can cover several anode-deflector bins instead of just one. This routine
;attempts to determine which case exists by first finding the bin with peak eflux, and then checking the bins around this. This routine
;thus assumes that the "beam" of ions is to first order represented by the peak in eflux. This an assumption, and may not be
;true.
;The routine finds neighboring bins around the peak bin, highest eflux first, until the total eflux is >= 75% of the total eflux.
;To keep things simple, the routine can only search the 8 bins surrounding the initial bin that contains the overall peak eflux.
;
;
;data_in: 16x4 d0/d1 data structure for the mass and energy range requied, obtained by eg:
;     dat0 = mvn_sta_get_d0(index=i)
;     mvn_sta_convert_units, dat0, 'eflux'
;     data1 = dat0.data
;     -> set any data1 elements outside the requested mass or energy range to zero.
;     data2 = total(data2, 1, /nan) ;sum across energy dimension
;     data3 = total(data3, 2, /nan) ;sum across mass mass
;     data4 = transpose(reform(data4, 4, 16))   ;break to 16Ax4D. CMF checked and confirmed that this is the correct order to reform
;     data_in = data4
;     
;
;peakinfo: output structure containing information about the "peak beam" found by the routine:
;         xPK, yPK: indices of the peak beam in the FOV, as outputs. If a broad beam is found, these are each 4 element long arrays, corresponding
;                   to the indices for the 2x2 FOV bin.
;         peakflux: float: % of eflux in the peak bin.
;         EFratio: % of the total eflux that lies in the "peak" beam.
;         BeamType: float: 1: at least 75% of the eflux lies in a single A-D bin. Likely a narrow beam.
;                          2: between 50% and 75% of the eflux lies in a 2x2 A-D square. Likely a broader beam.
;                          3: less than 50% of the eflux lies in the 2x2 A-D square. Likely a diffuse plasma / no clear beam.
;         pts: array [2,n] long, containing the x and y indices of A-D bins that make up the found beam.
;         beamflux: float: % eflux containe with all pts in the beam.
;         EFsuccess: 1 = routine successful, 0 = routine unsuccessful.
;         EFsize: float: the number of A-D bins that comprise the beam (eg number of rows in pts).
;
;-

pro mvn_sta_fov_d0d1_findpeak, data_in, peakinfo=peakinfo

  ;####Find peak eflux in d data:
  maxEF = max(data_in, imax, /nan)
  rowI = floor(imax/16.) ;row indice in 16x4 format
  colI = imax mod 16.   ;column indice in 16x4 format

  EFtot = total(data_in, /nan)  ;total eflux

  Pval = 70.  ;Peak is found when eflux in the bins reaches this % value.

  ;8 points surrounding the peak, to be checked:
  npts=8l  ;8 here, don't include middle peak bin
  pts0 = fltarr(2,npts)  ;x,y pos for each of the 9 bins
  pts0[0, 0:2] = colI-1l  ;shift left one
  pts0[0, 3:4] = colI   ;center; NO MIDDLE PEAK BIN
  pts0[0, 5:7] = colI+1l  ;shift right
  pts0[1, 0:2] = [rowI-1l, rowI, rowI+1l]
  pts0[1, 3:4] = [rowI-1l, rowI+1l]  ;NO MIDDLE PEAK BIN
  pts0[1, 5:7] = [rowI-1l, rowI, rowI+1l]

  ;Find points that need to loop around in anode number
  iCH = where(pts0[0,*] lt 0, niCH)
  if niCH gt 0 then pts0[0,iCH] = 15.
  iCH = where(pts0[0,*] gt 15, niCH)
  if niCH gt 0 then pts0[0,ICH] = 0

  ;Find points outside of deflector. No loop, set to NaN and remove
  iCH = where(pts0[1,*] lt 0, niCH)
  if niCH gt 0 then pts0[1,iCH] = !values.f_nan
  iCH = where(pts0[1,*] gt 3, niCH)
  if niCH gt 0 then pts0[1,ICH] = !values.f_nan

  iKP = where(finite(pts0[1,*]) eq 1, niKP1)
  pts2 = pts0[*,iKP]  ;retain rows within defl FOV.

  EFtmp = 100.*maxEF/EFtot  ;% of eflux in peak bin
  EFpk = EFtmp  ;% flux in the main peak bin

  if finite(EFtmp) eq 1 then begin
    if EFtmp lt Pval then begin
      eflux_tmp = fltarr(niKP1)  ;store eflux around peak in here
      for eff = 0l, niKP1-1l do eflux_tmp[eff] = data_in[pts2[0,eff], pts2[1,eff]]  ;add eflux

      isort = reverse(sort(eflux_tmp))  ;descending order

      eflux_tmp_sort = eflux_tmp[isort]
      xpts_sort = pts2[0,isort]  ;x and y bin indices in descending order
      ypts_sort = pts2[1,isort]

      breakk = 0
      pkct = 0.  ;counter

      while breakk eq 0 do begin
        EFtmp = 100.*(maxEF + total(eflux_tmp_sort[0:pkct],/nan))/EFtot  ;% eflux with additional bins

        if EFtmp gt Pval then begin
          xpts_out = xpts_sort[0:pkct]  ;save indices of bins used
          ypts_out = ypts_sort[0:pkct]

          breakk = 1
          EFsuccess=1
        endif else begin
          pkct += 1.  ;add one to counter
          if pkct eq niKP1 then begin
            breakk=1  ;if we went through all points but still don't have enough eflux, decide we can't find a peak.
            EFsuccess=0
            xpts_out = xpts_sort[0:pkct-1]  ;save indices of bins used. Note that for this fail case,
            ypts_out = ypts_sort[0:pkct-1]  ;the code has tried all bins and so pkct=n_elements(ypts_sort)
          endif
        endelse

      endwhile

      ;Add peak bin to these points:
      ;if EFsuccess=0, have to reduce pkct by 1 as code has tried all bins, and need array sizes to match
      if EFsuccess eq 1 then pkct2 = pkct else pkct2=pkct-1l
      pts = fltarr(2,pkct2+2l)
      pts[0,0:pkct2] = xpts_out
      pts[1,0:pkct2] = ypts_out
      pts[0,pkct2+1l] = colI
      pts[1,pkct2+1l] = rowI

    endif else begin
      pkct = 1l
      pts = [colI, rowI]  ;indices for FOV when peak is just one square
      EFsuccess=1
    endelse

    npts = n_elements(pts[0,*])  ;the beamsize is the number of bins need to find the beam

  endif else begin
    EFsuccess=0  ;when no eflux at all
    EFtmp = 0.
    EFpk = 0.
    pts = [colI, rowI]
    npts=0.
  endelse


  peakinfo = create_struct('xPK'      ,   colI     , $
                          'yPK'      ,   rowI     , $
                          'peakflux' ,   EFpk     , $  ;% eflux in the main peak
                          'pts'      ,   pts      , $  ;points for the entire beam
                          'beamflux' ,   EFtmp    , $  ;% of flux in the beam (all points) (formerly EFratio)
                          'EFsuccess',   EFsuccess, $
                          'EFsize'   ,   npts     )  ;number of bins in the beam (formerly EFtype)

end