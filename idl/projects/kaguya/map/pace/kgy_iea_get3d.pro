;+
; FUNCTION:
;       kgy_iea_get3d
; PURPOSE:
;       returns an IEA 3D data structure
; CALLING SEQUENCE:
;       dat = kgy_iea_get3d(time)
; OPTIONAL INPUTS:
;       time: gets data at this time - otherwise uses index or clicks
;             Can be in any format accepted by time_double.
; KEYWORDS:
;       index: gets data at this index value in the common block
;       cntcorr: conducts count correction (event & trash correction)
;       sabin: sorts into solid angle bins instead of (Npol,Naz)
;                compatible with the SSL infrastructure (Def: sabin=1)
;       INFOangle: uses angles in the INFO files (Def: INFOangle = 1)
; CREATED BY:
;       Yuki Harada on 2014-07-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2025-02-20 21:55:42 -0800 (Thu, 20 Feb 2025) $
; $LastChangedRevision: 33143 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_iea_get3d.pro $
;-

function kgy_iea_get3d, time, index=index, cntcorr=cntcorr, sabin=sabin, infoangle=infoangle, verbose=verbose, gettimes=gettimes

@kgy_pace_com
@kgy_lmag_com

if size(sabin,/type) eq 0 then sabin = 1
if size(infoangle,/type) eq 0 then infoangle = 1

if keyword_set(gettimes) then begin
   times = $
      time_double( string(iea_header_arr[*].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
      + iea_header_arr[*].time_ms/1d3 $
      ;; time_double( string(iea_header_arr[*].yyyymmdd,format='(i8.8)') $
      ;;              +string(iea_header_arr[*].hhmmss,format='(i6.6)'), $
      ;;              tformat='YYYYMMDDhhmmss' ) $
      + iea_header_arr[*].time_resolution / 2.d3
   return,times
endif

if (n_elements(time) ne 1) and (size(index,/type) eq 0) then $
   ctime,t,npoints = 1
if n_elements(time) eq 1 then t = time_double(time)
if n_elements(iea_header_arr) eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'No iea data are stored'
   return, {project_name:'Kaguya MAP/PACE',data_name:'IEA',valid:0}
endif
if size(index,/type) eq 0 then begin
   times = $
      time_double( string(iea_header_arr[*].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
      + iea_header_arr[*].time_ms/1d3 $
      ;; time_double( string(iea_header_arr[*].yyyymmdd,format='(i8.8)') $
      ;;              +string(iea_header_arr[*].hhmmss,format='(i6.6)'), $
      ;;              tformat='YYYYMMDDhhmmss' ) $
      + iea_header_arr[*].time_resolution / 2.d3
   tmp = min( abs( times - t ), i )
   theindex = iea_header_arr[i].index
endif else begin
   theindex = ulong(index)
   i = where(iea_header_arr[*].index eq theindex , i_cnt )
   if i_cnt ne 1 then begin
      dprint,dlevel=0,verbose=verbose,'kgy_iea_get3d: INVALID INDEX'
      return, {project_name:'Kaguya MAP/PACE',data_name:'IEA',valid:0}
   endif
endelse

start_time = $
   time_double( string(iea_header_arr[i].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
   + iea_header_arr[i].time_ms/1d3

end_time = $
   time_double( string(iea_header_arr[i].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
   + iea_header_arr[i].time_ms/1d3 $
   + iea_header_arr[i].time_resolution / 1.d3

integ_t = 16./iea_header_arr[i].sampl_time         ;- integration time [sec]

delta_t = iea_header_arr[i].time_resolution/1000.  ;- time resolution

ram = iea_header_arr[i].svs_tbl ;- svg_tbl???

case iea_header_arr[i].type of
   '80'XB: begin                ;- TYPE80 32x4x16
      valid = 1
      enesq = reform(iea_info_str.ene_sqno_4x16[ram,*,0,0])
      polsq = reform(iea_info_str.pol_sqno_4x16[ram,0,*,0])

      energy = replicate(0., 32,4,16)
      theta = replicate(0., 32,4,16)
      phi = replicate(0., 32,4,16)
      gfactor = replicate(0.d, 32,4,16)
      eff = replicate(0.6, 32,4,16) ;- to be replaced by eff tbl
      bins = replicate(1, 32,4,16)

      gfactor[enesq[*],polsq[*],*] = iea_info_str.gfactor_4x16[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(iea_fov_str.ene[ram,*]),32,4,16) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(iea_fov_str.pol4[ram,*,*]),32,4,16)
         phi[*,*,*] = transpose(rebin(iea_fov_str.az16[*],16,4,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            iea_info_str.ene_4x16[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = iea_info_str.pol_4x16[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = iea_info_str.az_4x16[ram,*,*,*]
         idx_0 = where( gfactor eq 0 , idx_0_cnt )
         if idx_0_cnt gt 0 then bins[idx_0] = 0
      endelse

      denergy = replicate(0., 32,4,16)
      dtheta = replicate(90./4.,32,4,16)
      dphi = replicate(360./16.,32,4,16)
      domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      denergy[0,*,*] = energy[1,*,*] - energy[0,*,*]
      denergy[31,*,*] = energy[31,*,*] - energy[30,*,*]
      denergy[indgen(30)+1,*,*] $
         = (energy[indgen(30)+2,*,*]-energy[indgen(30),*,*])/2.

      ii = where( iea_type80_arr.index eq theindex )
      cnt = float(iea_type80_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = cnt
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         event = float(iea_type80_arr[ii].event)
         trash = float(iea_type80_arr[ii].trash)
         idx_nan = where( event eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then event[idx_nan] = !values.f_nan
         idx_nan = where( trash eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then trash[idx_nan] = !values.f_nan
         ;- trash correction
         numer = total(cnt,3,/nan) + total(trash,3,/nan)
         denom = total(cnt,3,/nan)
         ccnt = cnt
         for i_pol=0,3 do begin
            idx_ne0 = where( denom[*,i_pol] ne 0 , idx_ne0_cnt )
            if idx_ne0_cnt gt 0 then begin
               ccnt[idx_ne0,i_pol,*] = cnt[idx_ne0,i_pol,*]*rebin(numer[idx_ne0,i_pol]/denom[idx_ne0,i_pol],idx_ne0_cnt,1,16)
           endif
         endfor
         ;- event correction
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
         endif
         corr = 1
      endelse

      data = replicate(0., 32,4,16)
      data[enesq[*],polsq[*],*] = ccnt[*,*,*]

      if keyword_set(sabin) then begin
         olddata = data
         data = replicate(0., 32,64)
         oldenergy = energy
         energy = replicate(0., 32,64)
         oldtheta = theta
         theta = replicate(0., 32,64)
         oldphi = phi
         phi = replicate(0., 32,64)
         oldgfactor = gfactor
         gfactor = replicate(0.d, 32,64)
         oldeff = eff
         eff = replicate(0., 32,64)
         oldbins = bins
         bins = replicate(1, 32,64)
         olddenergy = denergy
         denergy = replicate(0., 32,64)
         olddtheta= dtheta
         dtheta = replicate(0.,32,64)
         olddphi = dphi
         dphi = replicate(0.,32,64)
         for i_pol=0,3 do begin
            data[*,i_pol+indgen(16)*4] = olddata[*,i_pol,indgen(16)]
            energy[*,i_pol+indgen(16)*4] = oldenergy[*,i_pol,indgen(16)]
            theta[*,i_pol+indgen(16)*4] = oldtheta[*,i_pol,indgen(16)]
            phi[*,i_pol+indgen(16)*4] = oldphi[*,i_pol,indgen(16)]
            gfactor[*,i_pol+indgen(16)*4] = oldgfactor[*,i_pol,indgen(16)]
            eff[*,i_pol+indgen(16)*4] = oldeff[*,i_pol,indgen(16)]
            bins[*,i_pol+indgen(16)*4] = oldbins[*,i_pol,indgen(16)]
            denergy[*,i_pol+indgen(16)*4] = olddenergy[*,i_pol,indgen(16)]
            dtheta[*,i_pol+indgen(16)*4] = olddtheta[*,i_pol,indgen(16)]
            dphi[*,i_pol+indgen(16)*4] = olddphi[*,i_pol,indgen(16)]
         endfor
         domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      endif
   end
   '81'XB: begin                ;- TYPE81 32x16x64
      valid = 1
      enesq = reform(iea_info_str.ene_sqno_16x64[ram,*,0,0])
      polsq = reform(iea_info_str.pol_sqno_16x64[ram,0,*,0])

      energy = replicate(0., 32,16,64)
      theta = replicate(0., 32,16,64)
      phi = replicate(0., 32,16,64)
      gfactor = replicate(0.d, 32,16,64)
      eff = replicate(0.6, 32,16,64) ;- to be replaced by eff tbl
      bins = replicate(1, 32,16,64)

      gfactor[enesq[*],polsq[*],*] = iea_info_str.gfactor_16x64[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(iea_fov_str.ene[ram,*]),32,16,64) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(iea_fov_str.pol16[ram,*,*]),32,16,64)
         phi[*,*,*] = transpose(rebin(iea_fov_str.az64[*],64,16,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            iea_info_str.ene_16x64[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = iea_info_str.pol_16x64[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = iea_info_str.az_16x64[ram,*,*,*]
         idx_0 = where( gfactor eq 0 , idx_0_cnt )
         if idx_0_cnt gt 0 then bins[idx_0] = 0
      endelse

      denergy = replicate(0., 32,16,64)
      dtheta = replicate(90./16.,32,16,64)
      dphi = replicate(360./64.,32,16,64)
      domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      denergy[0,*,*] = energy[1,*,*] - energy[0,*,*]
      denergy[31,*,*] = energy[31,*,*] - energy[30,*,*]
      denergy[indgen(30)+1,*,*] $
         = (energy[indgen(30)+2,*,*]-energy[indgen(30),*,*])/2.

      ii = where( iea_type81_arr.index eq theindex )
      cnt = float(iea_type81_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = cnt
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         event = float(iea_type81_arr[ii].event)
         trash = float(iea_type81_arr[ii].trash)
         idx_nan = where( event eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then event[idx_nan] = !values.f_nan
         idx_nan = where( trash eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then trash[idx_nan] = !values.f_nan
         ;- trash correction
         numer = total(cnt,3,/nan) + total(trash,3,/nan)
         denom = total(cnt,3,/nan)
         ccnt = cnt
         for i_pol=0,15 do begin
            idx_ne0 = where( denom[*,i_pol] ne 0 , idx_ne0_cnt )
            if idx_ne0_cnt gt 0 then begin
               ccnt[idx_ne0,i_pol,*] = cnt[idx_ne0,i_pol,*]*rebin(numer[idx_ne0,i_pol]/denom[idx_ne0,i_pol],idx_ne0_cnt,1,64)
            endif
         endfor
         ;- event correction
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
         endif
         corr = 1
      endelse

      data = replicate(0., 32,16,64)
      data[enesq[*],polsq[*],*] = ccnt[*,*,*]

      if keyword_set(sabin) then begin
         olddata = data
         data = replicate(0., 32,1024)
         oldenergy = energy
         energy = replicate(0., 32,1024)
         oldtheta = theta
         theta = replicate(0., 32,1024)
         oldphi = phi
         phi = replicate(0., 32,1024)
         oldgfactor = gfactor
         gfactor = replicate(0.d, 32,1024)
         oldeff = eff
         eff = replicate(0., 32,1024)
         oldbins = bins
         bins = replicate(1, 32,1024)
         olddenergy = denergy
         denergy = replicate(0., 32,1024)
         olddtheta= dtheta
         dtheta = replicate(0.,32,1024)
         olddphi = dphi
         dphi = replicate(0.,32,1024)
         for i_pol=0,15 do begin
            data[*,i_pol+indgen(64)*16] = olddata[*,i_pol,indgen(64)]
            energy[*,i_pol+indgen(64)*16] = oldenergy[*,i_pol,indgen(64)]
            theta[*,i_pol+indgen(64)*16] = oldtheta[*,i_pol,indgen(64)]
            phi[*,i_pol+indgen(64)*16] = oldphi[*,i_pol,indgen(64)]
            gfactor[*,i_pol+indgen(64)*16] = oldgfactor[*,i_pol,indgen(64)]
            eff[*,i_pol+indgen(64)*16] = oldeff[*,i_pol,indgen(64)]
            bins[*,i_pol+indgen(64)*16] = oldbins[*,i_pol,indgen(64)]
            denergy[*,i_pol+indgen(64)*16] = olddenergy[*,i_pol,indgen(64)]
            dtheta[*,i_pol+indgen(64)*16] = olddtheta[*,i_pol,indgen(64)]
            dphi[*,i_pol+indgen(64)*16] = olddphi[*,i_pol,indgen(64)]
         endfor
         domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      endif
   end
   '82'XB: begin                ;- s_cnt = SW centered 128 bins, just uses cnt
      valid = 1
      enesq = reform(iea_info_str.ene_sqno_16x64[ram,*,0,0])
      polsq = reform(iea_info_str.pol_sqno_16x64[ram,0,*,0])

      energy = replicate(0., 32,16,64)
      theta = replicate(0., 32,16,64)
      phi = replicate(0., 32,16,64)
      gfactor = replicate(0.d, 32,16,64)
      eff = replicate(0.6, 32,16,64) ;- to be replaced by eff tbl
      bins = replicate(1, 32,16,64)

      gfactor[enesq[*],polsq[*],*] = iea_info_str.gfactor_16x64[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(iea_fov_str.ene[ram,*]),32,16,64) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(iea_fov_str.pol16[ram,*,*]),32,16,64)
         phi[*,*,*] = transpose(rebin(iea_fov_str.az64[*],64,16,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            iea_info_str.ene_16x64[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = iea_info_str.pol_16x64[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = iea_info_str.az_16x64[ram,*,*,*]
         idx_0 = where( gfactor eq 0 , idx_0_cnt )
         if idx_0_cnt gt 0 then bins[idx_0] = 0
      endelse

      denergy = replicate(0., 32,16,64)
      dtheta = replicate(90./16.,32,16,64)
      dphi = replicate(360./64.,32,16,64)
      domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      denergy[0,*,*] = energy[1,*,*] - energy[0,*,*]
      denergy[31,*,*] = energy[31,*,*] - energy[30,*,*]
      denergy[indgen(30)+1,*,*] $
         = (energy[indgen(30)+2,*,*]-energy[indgen(30),*,*])/2.

      ii = where( iea_type82_arr.index eq theindex )
      cnt = float(iea_type82_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = cnt
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         event = float(iea_type82_arr[ii].event)
         idx_nan = where( event eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then event[idx_nan] = !values.f_nan
         ccnt = cnt
         ;- event correction
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(event[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
         endif
         corr = 1
      endelse

      data = replicate(0., 32,16,64)
;      data[enesq[*],polsq[*],*] = ccnt[*,*,*]
      data[enesq[*],*,*] = ccnt[*,*,*] ;- no polar sort

      if keyword_set(sabin) then begin
         olddata = data
         data = replicate(0., 32,1024)
         oldenergy = energy
         energy = replicate(0., 32,1024)
         oldtheta = theta
         theta = replicate(0., 32,1024)
         oldphi = phi
         phi = replicate(0., 32,1024)
         oldgfactor = gfactor
         gfactor = replicate(0.d, 32,1024)
         oldeff = eff
         eff = replicate(0., 32,1024)
         oldbins = bins
         bins = replicate(1, 32,1024)
         olddenergy = denergy
         denergy = replicate(0., 32,1024)
         olddtheta= dtheta
         dtheta = replicate(0.,32,1024)
         olddphi = dphi
         dphi = replicate(0.,32,1024)
         for i_pol=0,15 do begin
            data[*,i_pol+indgen(64)*16] = olddata[*,i_pol,indgen(64)]
            energy[*,i_pol+indgen(64)*16] = oldenergy[*,i_pol,indgen(64)]
            theta[*,i_pol+indgen(64)*16] = oldtheta[*,i_pol,indgen(64)]
            phi[*,i_pol+indgen(64)*16] = oldphi[*,i_pol,indgen(64)]
            gfactor[*,i_pol+indgen(64)*16] = oldgfactor[*,i_pol,indgen(64)]
            eff[*,i_pol+indgen(64)*16] = oldeff[*,i_pol,indgen(64)]
            bins[*,i_pol+indgen(64)*16] = oldbins[*,i_pol,indgen(64)]
            denergy[*,i_pol+indgen(64)*16] = olddenergy[*,i_pol,indgen(64)]
            dtheta[*,i_pol+indgen(64)*16] = olddtheta[*,i_pol,indgen(64)]
            dphi[*,i_pol+indgen(64)*16] = olddphi[*,i_pol,indgen(64)]
         endfor
         domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      endif
   end
endcase

magf = [!values.f_nan,!values.f_nan,!values.f_nan]
if size(lmag_sat,/tname) eq 'STRUCT' then begin
   idx_mag = where( lmag_sat.time ge start_time $
                    and lmag_sat.time le end_time , idx_mag_cnt )
   if idx_mag_cnt gt 0 then begin
      magf[0] = mean(lmag_sat[idx_mag].bsat[0],/nan)
      magf[1] = mean(lmag_sat[idx_mag].bsat[1],/nan)
      magf[2] = mean(lmag_sat[idx_mag].bsat[2],/nan)
   endif else magf[*] = interp( transpose(lmag_sat.bsat), lmag_sat.time, (start_time+end_time)/2d, interp=129, /no_ex )
endif

dat = { $
      project_name:'Kaguya MAP/PACE', $
      data_name:'IEA', $
      valid:valid, $
      units_name:'Counts', $
      units_procedure:'kgy_pace_convert_units', $
      cnt_corr:corr, $

      time:start_time, $
      end_time:end_time, $
      integ_t:integ_t, $
      delta_t:delta_t, $

      sensor:long(iea_header_arr[i].sensor), $ ;- sensor ID
      mode:long(iea_header_arr[i].mode), $   ;- data mode
      mode2:long(iea_header_arr[i].mode2), $ ;- sub-data mode
      type:long(iea_header_arr[i].type), $   ;- data type
      ver:long(iea_header_arr[i].ver), $     ;- data version
      svg:long(iea_header_arr[i].svg_tbl), $ ;- IMA IEA
      sva:long(iea_header_arr[i].sva_tbl), $
      svs:long(iea_header_arr[i].svs_tbl), $ ;- RAM?
      obs:long(iea_header_arr[i].obs_tbl), $

      nbins:long(iea_header_arr[i].pol_step)*long(iea_header_arr[i].az_step), $
      nenergy:long(iea_header_arr[i].ene_step), $
      ntheta:long(iea_header_arr[i].pol_step), $
      nphi:long(iea_header_arr[i].az_step), $
      nevent:long(iea_header_arr[i].event_step), $
      ntrash:long(iea_header_arr[i].trash_step), $

      energy:energy, $
      theta:theta, $
      phi:phi, $
      gfactor:gfactor, $
      eff:eff, $
      bins:bins, $

      enesq:enesq, $
      polsq:polsq, $

      denergy:denergy, $
      dtheta:dtheta, $
      dphi:dphi, $
      domega:domega, $

      mass:5.6856591e-6*1836., $
      charge: 1., $
      sc_pot:!values.f_nan, $
      magf:magf, $
      vsw:[!values.f_nan,!values.f_nan,!values.f_nan], $
      spice_frame:'SELENE_M_SPACECRAFT', $

      header:iea_header_arr[i], $

      data:data $
      }

return,dat

end
