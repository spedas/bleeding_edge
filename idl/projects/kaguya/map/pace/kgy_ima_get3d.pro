;+
; FUNCTION:
;       kgy_ima_get3d
; PURPOSE:
;       returns an IMA 3D data structure
;       sums up all mass channels and assumes protons
;       Use kgy_ima_get4d (to be developed) to get mass separated data
; CALLING SEQUENCE:
;       dat = kgy_ima_get3d(time)
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_ima_get3d.pro $
;-

function kgy_ima_get3d, time, index=index, cntcorr=cntcorr, sabin=sabin, infoangle=infoangle, verbose=verbose, gettimes=gettimes

@kgy_pace_com
@kgy_lmag_com

if size(sabin,/type) eq 0 then sabin = 1
if size(infoangle,/type) eq 0 then infoangle = 1

if keyword_set(gettimes) then begin
   times = $
      time_double( string(ima_header_arr[*].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
      + ima_header_arr[*].time_ms/1d3 $
      + ima_header_arr[*].time_resolution / 2.d3
   return,times
endif

if (n_elements(time) ne 1) and (size(index,/type) eq 0) then $
   ctime,t,npoints = 1
if n_elements(time) eq 1 then t = time_double(time)
if n_elements(ima_header_arr) eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'No ima data are stored'
   return, {project_name:'Kaguya MAP/PACE',data_name:'IMA',valid:0}
endif
if size(index,/type) eq 0 then begin
   times = $
      time_double( string(ima_header_arr[*].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
      + ima_header_arr[*].time_ms/1d3 $
      + ima_header_arr[*].time_resolution / 2.d3
   tmp = min( abs( times - t ), i )
   theindex = ima_header_arr[i].index
endif else begin
   theindex = ulong(index)
   i = where(ima_header_arr[*].index eq theindex , i_cnt )
   if i_cnt ne 1 then begin
      dprint,dlevel=0,verbose=verbose,'kgy_ima_get3d: INVALID INDEX'
      return, {project_name:'Kaguya MAP/PACE',data_name:'IMA',valid:0}
   endif
endelse

start_time = $
   time_double( string(ima_header_arr[i].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
   + ima_header_arr[i].time_ms/1d3

end_time = $
   time_double( string(ima_header_arr[i].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
   + ima_header_arr[i].time_ms/1d3 $
   + ima_header_arr[i].time_resolution / 1.d3

integ_t = 16./ima_header_arr[i].sampl_time         ;- integration time [sec]

delta_t = ima_header_arr[i].time_resolution/1000.  ;- time resolution

ram = ima_header_arr[i].svs_tbl ;- svg_tbl???

case ima_header_arr[i].type of
   '40'XB: begin                ;- TYPE40 4x32x1024
      valid = 1
      enesq = reform(ima_info_str.ene_sqno_4x16[ram,*,0,0])
      polsq = reform(ima_info_str.pol_sqno_4x16[ram,0,*,0])

      energy = replicate(0., 32,4)
      theta = replicate(0., 32,4)
      phi = replicate(0., 32,4)
      gfactor = replicate(0.d, 32,4)
      eff = replicate(0.6, 32,4) ;- to be replaced by eff tbl
      bins = replicate(1, 32,4)

      ch_type40 = 4         ;- TYPE40 no az info, uses channel 4 (cf. momcal.c)
      gfactor[enesq[*],*] = ima_info_str.gfactor_4x16[ram,*,*,ch_type40]
      gfactor[*,polsq[*]] = gfactor[*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*] = $ ;- keV -> eV
            rebin(reform(ima_fov_str.ene[ram,*]),32,4) * 1000. 
         energy[*,polsq[*]] = energy[*,*]
         theta[enesq[*],*] $
            = -rebin(reform(ima_fov_str.pol4[ram,*,*]),32,4)
         theta[*,polsq[*]] = theta[*,*]
      endif else begin
         energy[enesq[*],*] = $
            ima_info_str.ene_4x16[ram,*,*,ch_type40]*1000. ;- keV -> eV
         energy[*,polsq[*]] = energy[*,*]
         theta[enesq[*],*] = ima_info_str.pol_4x16[ram,*,*,ch_type40]
         theta[*,polsq[*]] = theta[*,*]
         idx_0 = where( gfactor eq 0 , idx_0_cnt )
         if idx_0_cnt gt 0 then bins[idx_0] = 0
      endelse

      denergy = replicate(0., 32,4)
      dtheta = replicate(90./4.,32,4)
      dphi = replicate(360.,32,4)
      domega = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
      denergy[0,*] = energy[1,*] - energy[0,*]
      denergy[31,*] = energy[31,*] - energy[30,*]
      denergy[indgen(30)+1,*] $
         = (energy[indgen(30)+2,*]-energy[indgen(30),*])/2.

      ii = where( ima_type40_arr.index eq theindex )
      cnt = float(ima_type40_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = transpose(total(cnt,3,/nan)) ;- all mass ch
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         ccnt = transpose(total(cnt,3,/nan)) ;- all mass ch
         event = float(ima_type40_arr[ii].event)
         idx_nan = where( event eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then event[idx_nan] = !values.f_nan
         ;- event correction
         tofeve = reform(event[1,*] + event[2,*] + event[3,*])
         poseve = reform(event[0,*])
         denom = total( ccnt[2*indgen(16),*]+ccnt[2*indgen(16)+1,*] ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*] = ccnt[2*idx_ne0,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4)
            ccnt[2*idx_ne0+1,*] = ccnt[2*idx_ne0+1,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4)
         endif
         corr = 1
      endelse

      data = replicate(0., 32,4)
      data[enesq[*],*] = ccnt   ;- TYPE40 pol sorted

      if keyword_set(sabin) then begin
         ;- no need to sort
      endif
   end
   '41'XB: begin                ;- TYPE41 32x16x64
      valid = 1
      enesq = reform(ima_info_str.ene_sqno_16x64[ram,*,0,0])
      polsq = reform(ima_info_str.pol_sqno_16x64[ram,0,*,0])

      energy = replicate(0., 32,16,64)
      theta = replicate(0., 32,16,64)
      phi = replicate(0., 32,16,64)
      gfactor = replicate(0.d, 32,16,64)
      eff = replicate(0.6, 32,16,64) ;- to be replaced by eff tbl
      bins = replicate(1, 32,16,64)

      gfactor[enesq[*],polsq[*],*] = ima_info_str.gfactor_16x64[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(ima_fov_str.ene[ram,*]),32,16,64) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(ima_fov_str.pol16[ram,*,*]),32,16,64)
         phi[*,*,*] = transpose(rebin(ima_fov_str.az64[*],64,16,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            ima_info_str.ene_16x64[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = ima_info_str.pol_16x64[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = ima_info_str.az_16x64[ram,*,*,*]
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

      ii = where( ima_type41_arr.index eq theindex )
      cnt = float(ima_type41_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = cnt
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         event = float(ima_type41_arr[ii].event)
         trash = float(ima_type41_arr[ii].trash)
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
         tofeve = reform(event[1,*] + event[2,*] + event[3,*])
         poseve = reform(event[0,*])
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,16,64)
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
   '42'XB: begin                ;- TYPE42 32x4x16
      valid = 1
      enesq = reform(ima_info_str.ene_sqno_4x16[ram,*,0,0])
      polsq = reform(ima_info_str.pol_sqno_4x16[ram,0,*,0])

      energy = replicate(0., 32,4,16)
      theta = replicate(0., 32,4,16)
      phi = replicate(0., 32,4,16)
      gfactor = replicate(0.d, 32,4,16)
      eff = replicate(0.6, 32,4,16) ;- to be replaced by eff tbl
      bins = replicate(1, 32,4,16)

      gfactor[enesq[*],polsq[*],*] = ima_info_str.gfactor_4x16[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(ima_fov_str.ene[ram,*]),32,4,16) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(ima_fov_str.pol4[ram,*,*]),32,4,16)
         phi[*,*,*] = transpose(rebin(ima_fov_str.az16[*],16,4,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            ima_info_str.ene_4x16[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = ima_info_str.pol_4x16[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = ima_info_str.az_4x16[ram,*,*,*]
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

      ii = where( ima_type42_arr.index eq theindex )
      cnt = float(ima_type42_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = cnt
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         event = float(ima_type42_arr[ii].event)
         trash = float(ima_type42_arr[ii].trash)
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
         tofeve = reform(event[1,*] + event[2,*] + event[3,*])
         poseve = reform(event[0,*])
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
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
   '43'XB: begin                ;- TYPE43 8x32x4x16
      valid = 1
      enesq = reform(ima_info_str.ene_sqno_4x16[ram,*,0,0])
      polsq = reform(ima_info_str.pol_sqno_4x16[ram,0,*,0])

      energy = replicate(0., 32,4,16)
      theta = replicate(0., 32,4,16)
      phi = replicate(0., 32,4,16)
      gfactor = replicate(0.d, 32,4,16)
      eff = replicate(0.6, 32,4,16) ;- to be replaced by eff tbl
      bins = replicate(1, 32,4,16)

      gfactor[enesq[*],polsq[*],*] = ima_info_str.gfactor_4x16[ram,*,*,*]

      if not keyword_set(INFOangle) then begin
         energy[enesq[*],*,*] = $ ;- keV -> eV
            rebin(reform(ima_fov_str.ene[ram,*]),32,4,16) * 1000. 
         theta[enesq[*],polsq[*],*] $
            = -rebin(reform(ima_fov_str.pol4[ram,*,*]),32,4,16)
         phi[*,*,*] = transpose(rebin(ima_fov_str.az16[*],16,4,32))
      endif else begin
         energy[enesq[*],polsq[*],*] = $
            ima_info_str.ene_4x16[ram,*,*,*] * 1000. ;- keV -> eV
         theta[enesq[*],polsq[*],*] = ima_info_str.pol_4x16[ram,*,*,*]
         phi[enesq[*],polsq[*],*] = ima_info_str.az_4x16[ram,*,*,*]
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

      ii = where( ima_type43_arr.index eq theindex )
      cnt = float(ima_type43_arr[ii].cnt)
      idx_nan = where( cnt eq uint(-1) , idx_nan_cnt)
      if idx_nan_cnt gt 0 then cnt[idx_nan] = !values.f_nan
      if not keyword_set(cntcorr) then begin
         ccnt = total(cnt,1,/nan) ;- all mass ch
         corr = 0
      endif else begin          ;- count correction (cf. momcal.c)
         cnt = total(cnt,1,/nan) ;- all mass ch
         event = float(ima_type43_arr[ii].event)
         trash = float(ima_type43_arr[ii].trash)
         idx_nan = where( event eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then event[idx_nan] = !values.f_nan
         idx_nan = where( trash eq uint(-1) , idx_nan_cnt)
         if idx_nan_cnt gt 0 then trash[idx_nan] = !values.f_nan
         trash = total(trash,1,/nan) ;- all mass ch
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
         tofeve = reform(event[1,*] + event[2,*] + event[3,*])
         poseve = reform(event[0,*])
         denom = total( total(ccnt[2*indgen(16),*,*] $
                              +ccnt[2*indgen(16)+1,*,*] ,/nan,3) ,/nan,2)
         idx_ne0 = where( denom ne 0, idx_ne0_cnt )
         if idx_ne0_cnt gt 0 then begin
            ccnt[2*idx_ne0,*,*] = ccnt[2*idx_ne0,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
            ccnt[2*idx_ne0+1,*,*] = ccnt[2*idx_ne0+1,*,*]*rebin(tofeve[idx_ne0]/denom[idx_ne0],idx_ne0_cnt,4,16)
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
      data_name:'IMA', $
      valid:valid, $
      units_name:'Counts', $
      units_procedure:'kgy_pace_convert_units', $
      cnt_corr:corr, $

      time:start_time, $
      end_time:end_time, $
      integ_t:integ_t, $
      delta_t:delta_t, $

      sensor:long(ima_header_arr[i].sensor), $ ;- sensor ID
      mode:long(ima_header_arr[i].mode), $   ;- data mode
      mode2:long(ima_header_arr[i].mode2), $ ;- sub-data mode
      type:long(ima_header_arr[i].type), $   ;- data type
      ver:long(ima_header_arr[i].ver), $     ;- data version
      svg:long(ima_header_arr[i].svg_tbl), $ ;- IEA IMA
      sva:long(ima_header_arr[i].sva_tbl), $
      svs:long(ima_header_arr[i].svs_tbl), $ ;- RAM?
      obs:long(ima_header_arr[i].obs_tbl), $

      nbins:long(ima_header_arr[i].pol_step)*long(ima_header_arr[i].az_step), $
      nenergy:long(ima_header_arr[i].ene_step), $
      ntheta:long(ima_header_arr[i].pol_step), $
      nphi:long(ima_header_arr[i].az_step), $
      nevent:long(ima_header_arr[i].event_step), $
      ntrash:long(ima_header_arr[i].trash_step), $

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

      header:ima_header_arr[i], $

      data:data $
      }

return,dat

end
