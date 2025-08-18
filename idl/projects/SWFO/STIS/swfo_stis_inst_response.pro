; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-04-28 15:06:46 -0700 (Mon, 28 Apr 2025) $
; $LastChangedRevision: 33277 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response.pro $
; $Id: swfo_stis_inst_response.pro 33277 2025-04-28 22:06:46Z rjolitz $






function swfo_stis_nonlut2map,mapname=mapname,lut=lut ,  sensor=sensor

  calval = swfo_stis_inst_response_calval()
  ;  particle = resp.particle_name
  ;  ;  dprint, 'Energy lost calc for', simstat.particle_name
  ;  if ~keyword_set(tid) then tid = 0
  ;  if ~keyword_set(fto) then fto = 4
  ;  ifto_type = calval.names_fto[tid,fto-1]
  ;  particle_fto = particle+'-'+ifto_type
  ;  dprint,particle_fto



  nbins = max(lut)+1   ; don't use this now
  ;if nbins gt 256 then message,"Don't use this code"

  ;if keyword_set(mapname) or not keyword_set(lut) then lut = swfo_stis_create_lut(mapname,mapnum=mapnum)
  mapsize = (max(lut)+1) > 672
  if mapsize gt 256  then dprint,'Default MAP in use'

  psym = [1,4]
  colors = [0,2,4,6,3,1,5]
  colors = [0,2,4,6,3,1,0,6]
  nan = !values.f_nan
  bmap =  {sens:0, bin:0, name:'',enum:0, fto:0, det:0 , tid:0, ADC:[0,0L],  num:0,  ok:0, $
    color:0 ,psym:0, type:0 , $
    geom: nan, $
    ;  FACE:0, $
    overflow:0b,  $
    nw:0,  $
    adcm: 0L, $
    adc_avg:nan         ,  adc_delta:nan  , $
    nrg_meas:nan    , nrg_meas_delta:nan, $
    nrg_inc :nan  , nrg_inc_delta:nan, $
    nrg_lost: nan , $
    gde: nan, $
    e0_inc: nan, $
    e0_inc_delta:nan,  $
    ; dummy place holders for convienience
    rate: nan,  $
    counts: nan,  $
    flux: nan,  $
    d_flux: nan, $
    df_f: nan, $
    valid: 1 }

  bmaps = replicate(bmap,nbins)


  ;remap = indgen(16)
  ;remap[[0,1,10,11]] = 0    ; allow
  ;remap[[0,1]] = 0                  ; Non events  'x'
  det =    [0,1,2,4,3,5,6,7,0]                                 ; det number
  ;geom = [!values.f_nan,.0013,.13]
  ;geoms = geom [  [0,1,2,1,2,1,2,1 ]  ]
  ;adcm =   [0,1,1,1,2,2,2,4,0]    ; multiplier
  ;names = strsplit('X O T OT F FO FT FTO Mixed',/extract)
  ;names = strsplit('X 1 2 1-2 3 1-3 2-3 1-2-3 Total',/extract)
  ;names = strsplit('X 1 2 12 3 13 23 123 Mixed',/extract)
  adcm  = [0,1,1,2,1,2,2,4]

  geoms = calval.geoms_tid_fto

  ;names = reform( transpose( [['A-'+names],['B-'+names]]))
  names = calval.names_fto
  ;realfto = remap[lindgen(2L^15) / 2L^12]
  b=0
  ;lut[*,*,0] =674
  for fto=1,7 do begin
    for tid=0,1 do begin
      ;lut0 =  reform( lut[*,tid,fto-1])
      for esteps = 0,48-1 do begin
        ;if fto[0] eq fto[1] then fto = fto[0] else fto = 8   ;  the value of 8 signifies a bin with mixed types
        bmap.name = names[tid,fto-1]
        bmap.fto = fto
        bmap.bin = b
        bmap.det = det[fto]
        bmap.color = colors[bmap.det]
        bmap.tid = tid
        bmap.psym = psym[tid]
        bmap.geom = geoms[tid,fto-1]
        w = where(/null,lut eq b  , nw)
        if nw eq 0 then   message,'Error'
        adcvals = w mod 2L^15
        adc = minmax( adcvals  )+ [0,1]
        bmap.adc = adc
        bmap.num = adc[1] - adc[0]
        bmap.nw = nw
        bmap.ok = (bmap.num eq nw) and bmap.fto ne 8
        bmap.adcm = adcm[fto]
        bmap.adc *= bmap.adcm    ; OT and FT are doubled,  FTO is quadrupled
        bmap.overflow = max(adc) ge 2L^15
        ; bmap.face = (fix((bmap.fto and 1) ne 0) - fix((bmap.fto and 4) ne 0)) * (bmap.tid ? 1 : -1)
        bmaps[b++] = bmap

      endfor
    endfor

  endfor

  ;bmaps.x = (bmaps.adc[1] + bmaps.adc[0])/2.
  ;bmaps.dx = bmaps.adc[1] - bmaps.adc[0]

  bmaps.adc_avg = (bmaps.adc[1] + bmaps.adc[0])/2.
  bmaps.adc_delta = bmaps.adc[1] - bmaps.adc[0]


  if keyword_set(sensor) then begin
    adc_scales = calval.adc_scales
    bmaps.sens = sensor
    erange = fltarr(2,nbins)
    dac2nrg= calval.nrg_scales
    for i=0,nbins-1 do begin
      erange[*,i] = bmaps[i].adc * dac2nrg[bmaps.tid,bmaps[i].fto-1]
      ;erange[*,i] = swfo_stis_cal_adc2nrg(bmaps[i].adc,bmaps[i].tid,bmaps[i].fto)
    endfor

    bmaps.nrg_meas    = average(erange,1)

    bmaps.nrg_lost = 0.
    w = where(bmaps.name eq 'O-1' or bmaps.name eq 'O-3', nw,/null)
    bmaps[w].nrg_lost = calval.proton_O_dl
    func = struct_value(calval.NRGLOST_VS_NRGMEAS,'Proton-O-3')
    if isa(func) then   bmaps[w].nrg_lost = func(param = func, bmaps[w].nrg_meas)   ; overwrite with better values

    w = where(bmaps.name eq 'F-1' or bmaps.name eq 'F-3', nw,/null)
    bmaps[w].nrg_lost = calval.electron_F_dl
    func = struct_value(calval.NRGLOST_VS_NRGMEAS,'Electron-F-3')
    if isa(func) then   bmaps[w].nrg_lost = func(param = func, bmaps[w].nrg_meas)   ; overwrite with better values

    bmaps.nrg_inc  = bmaps.nrg_meas + bmaps.nrg_lost   ; approximate correction


    bmaps.nrg_meas_delta   = reform(erange[1,*]-erange[0,*])
    bmaps.nrg_inc_delta = bmaps.nrg_meas_delta
    w = where(bmaps.overflow)
    overflow_fudge = .3  ;   This value is arbitrary - but at least better than the default
    bmaps[w].nrg_meas_delta = bmaps[w].nrg_meas * overflow_fudge
    bmaps[w].nrg_meas += bmaps[w].nrg_meas_delta / 2
  endif else dprint,'Please supply sensor number'

  return,bmaps
end





;  This routine modifies the big "data" array to include a few new elements:  FTO[2] EM[2] and BIN[2]    Each TID is treated separately
;  any event that triggers both TIDs will be counted as two separate events.
pro swfo_stis_inst_bin_response,simstat,data,new_seed=new_seed,noise_level=noise_level,mapnum=mapnum,bmap=bmap,data_sample=data_sample
  ;common swfo_stis_inst_bin_response_com , seed
  calval = swfo_stis_inst_response_calval()
  if size(/type,simstat) ne 8  then begin
    undefine,data
    return
  endif
  if n_elements(new_seed) ne 0 then seed = new_seed
  str_element,/add,simstat,'seed',new_seed
  n = n_elements(data)
  if n le 1 then begin
    dprint,'Must have at least 2 successful events'
    return
  endif
  ;str_element,simstat,'sensornum',sensornum
  sensornum = simstat.sensornum
  if ~keyword_set(mapnum) then str_element,simstat,'mapnum',mapnum
  if ~keyword_set(noise_level) then str_element,simstat,'noise_level',noise_level
  if n_elements(noise_level) ne 1 then noise_level=  1.
  ;if n_elements(sensornum) ne 1 then sensornum=1
  ;if n_elements(mapnum) ne 1 then mapnum = 8
  noise_rms =   calval.nrg_sigmas    * noise_level        ; noise O T F in kev
  thresholds =    calval.nrg_thresholds   * noise_level   ; noise_rms *    5 ;sigma threshold
  one_n = replicate(1,n)
  str_element,/add,data,'fto',bytarr(2,n)
  str_element,/add,data,'em',fltarr(2,n)
  str_element,/add,data,'bin',intarr(2,n)
  if keyword_set(mapnum) then begin
    message,'Not working anymore'
    dprint , 'LUT setup for map: ',mapnum

    shft = [0,1,1,2,1,2,2,4]      ; 2^(nbits-1)   nbits = number of bits that are set within an FTO pattern
    ;  shft[*] = 1    ; might want to consider eliminating this step in the FPGA
    lut = swfo_stis_create_lut(mapnum=mapnum)
    mapname = swfo_stis_mapnum_to_mapname(mapnum)
    bmap = swfo_stis_lut2map(lut=lut,sensor=sensornum)
    lut = fix( reform(lut,4096,2,8) )    ;   order is: [ADCval, TID,  FTOpattern ]
    lut[*,*,0] = 256                 ;  not triggered (not detected)  these are FTO=0 (non) events
    ;   lut[*,*,5] = 257                 ;  FO event     changed for SWFO
    for side=0,1 do begin
      ;   slabel = side ? 'B' : 'A'
      ;   ec3 = side ? data.b : data.a                          ; collected (deposited) energy in each of 3 detectors
      ec3 = data.edep[*,side]                                     ; energy deposited in each of 3 detectors for that side
      noise3 =  (noise_rms[*,side] # one_n) * randomn(seed,3,n)     ; generate noise in kev
      em3 = ec3 + noise3
      fto3 = em3 gt (thresholds[*,side] # one_n)           ; determine FTO pattern  based on # above  threshold
      em3 = em3 * fto3                                             ; clear untriggered channels
      em  = total(em3,1)                                           ; total energy in all 3 triggered channels
      scl3 = (adc_scale[*,side] # one_n)
      adc3 = long(em3 * scl3)  <  4095
      ftocode = reform(fto3 ## [1,2,4])                        ; This does  properly account for FO events!!
      adc = total(/pres,adc3,1) / shft[ftocode]    ; FT and OT  adc values are divided by 2,  FTO are divided by 4
      adc_bin = lut[adc,side * one_n,ftocode]       ; determine ADC bin
      data.fto[side] = ftocode
      data.em[side] = em
      data.bin[side] = adc_bin
      ;   if keyword_set(add) then begin
      ;     str_element,/add,data,slabel+'_em',em
      ;     str_element,/add,data,slabel+'_fto',ftocode
      ;     str_element,/add,data,slabel+'_adc',adc
      ;     str_element,/add,data,slabel+'_bin',adc_bin
      ;   endif
    endfor
  endif else begin
    dprint , 'Non-LUT setup'
    lut = uintarr(2L^15, 2, 8 )   + 680
    map = swfo_stis_adc_map(data_sample=data_sample)
    bin = 0
    for fto = 1,7 do begin
      for tid=0,1 do begin
        ch = (fto-1)*2 + tid
        for e=0,47 do begin
          a0= map.adc0[e,ch]
          a1= a0 + map.dadc[e,ch] -1
          lut[a0:a1,tid,fto] = bin
          bin++
        endfor
      endfor
    endfor

    shft = [0,1,1,2,1,2,2,4]      ; 2^(nbits-1)   nbits = number of bits that are set within an FTO pattern
    adc_scales = calval.adc_scales       ;   replicate(237./59.5,3,2)
    ; stop   ; not finished  map required here

    for side=0,1 do begin
      ;   slabel = side ? 'B' : 'A'
      ;   ec3 = side ? data.b : data.a                          ; collected (deposited) energy in each of 3 detectors
      ec3 = data.edep[*,side]                                     ; energy deposited in each of 3 detectors for that side
      noise3 =  (noise_rms[*,side] # one_n) * randomn(seed,3,n)     ; generate noise in kev
      em3 = ec3 + noise3
      fto3 = em3 gt (thresholds[*,side] # one_n)           ; determine FTO pattern  based on # above  threshold
      em3 = em3 * fto3                                             ; clear untriggered channels
      em  = total(em3,1)                                           ; total energy in all 3 triggered channels
      scl3 = (adc_scales[*,side] # one_n)
      adc3 = long(em3 * scl3)  <  (2L ^15 -1)
      ftocode = reform(fto3 ## [1,2,4])                        ; This does  properly account for FO events!!
      adc = total(/pres,adc3,1) / shft[ftocode]    ; FT and OT  adc values are divided by 2,  FTO are divided by 4
      adc_bin = lut[adc,side * one_n,ftocode]       ; determine ADC bin
      data.fto[side] = ftocode
      data.em[side] = em
      data.bin[side] = adc_bin
      ;   if keyword_set(add) then begin
      ;     str_element,/add,data,slabel+'_em',em
      ;     str_element,/add,data,slabel+'_fto',ftocode
      ;     str_element,/add,data,slabel+'_adc',adc
      ;     str_element,/add,data,slabel+'_bin',adc_bin
      ;   endif
    endfor
    mapname = 'Non-LUT'

    bmap = swfo_stis_nonlut2map(lut=lut,sensor=sensornum)

  endelse
  str_element,/add,simstat,'noise_level',noise_level
  str_element,/add,simstat,'thresholds',thresholds
  str_element,/add,simstat,'mapnum',mapnum
  str_element,/add,simstat,'mapname',mapname
  str_element,/add,simstat,'lut',lut
  str_element,/add,simstat,'bmap',bmap

end






function swfo_stis_inst_response,simstat,data0,mapnum=mapnum ,noise_level=noise_level,filter=filter , data_sample=data_sample,bmap=bmap
  if n_elements(data0) le 1 then begin
    dprint,'Must have at least 2 successful events'
    return,0
  endif

  response = simstat

  swfo_stis_inst_bin_response,response,data0,mapnum=mapnum,noise_level=noise_level , data_sample=data_sample ,bmap=bmap
  nbins = n_elements(bmap)

  w= where( swfo_stis_response_data_filter(response,data0,_extra=filter,filter=out_filter),nw)
  if nw le 1 then begin
    dprint,'Filter leaves no data. Must have at least 2 successful events'
    ;   return,0
  endif
  if nw lt 10 then begin
    dprint,'Very few samples.',nw
  endif
  if nw ne 0 then data=data0[w]

  if nw ne n_elements(data0) then begin
    dprint,'Filter: ',nw,' removed out of',n_elements(data0)
  endif

  ;str_element,simstat,'nsuccess',nw
  ;str_element,simstat,'type',type
  ;str_element,simstat,'sensornum',sensornum
  str_element,simstat,'npart',npart
  str_element,simstat,'sim_energy_range',simrange
  str_element,simstat,'sim_energy_log',simlog
  str_element,simstat,'n_omega',n_omega
  ;str_element,simstat,'noise_level',noise_level
  str_element,simstat,'desc',desc
  str_element,simstat,'sim_area',area_mm2
  str_element,simstat,'xbinsize',xbinsize
  str_element,simstat,'ybinsize',ybinsize

  str_element,out_filter,'fdesc',fdesc

  area_cm2 = area_mm2/100.
  ;if n_elements(noise_level) ne 1 then noise_level=1.
  ;if n_elements(sensornum) ne 1 then sensornum=0
  ;if n_elements(type) ne 1 then type=0               ;  -1: electrons,  1:protons,   2:???
  if ~keyword_set(xbinsize) then xbinsize=   1/40. ; .025       ;
  if ~keyword_set(ybinsize) then ybinsize= xbinsize

  if ~keyword_set(simlog) then message,'This code is not yet configured for linear sampling. Only logrithmic sampling is defined'

  srange =  simlog ? alog10(simrange) : simrange
  brange=  minmax([1.,simrange] )        ;[1.,100e3]

  xlog=1
  ylog=1
  xbinrange = brange
  ybinrange = brange
  ndata = n_elements(data)
  ;ND = npart * xbinsize / (srange[1] - srange[0])
  nx_einc = long((xlog ? alog10(xbinrange[1]/xbinrange[0]) : xbinrange[1]-xbinrange[0]) / xbinsize)
  ny_emeas= long((ylog ? alog10(ybinrange[1]/ybinrange[0]) : ybinrange[1]-ybinrange[0]) / ybinsize)
  xs0 = xlog ? alog(xbinrange[0]) : xbinrange[0]
  ys0 = ylog ? alog(ybinrange[0]) : ybinrange[0]
  ND = double(npart) / nx_einc                          ; number of particles per E-incident step (this assumes proper statistics) 
  if ~keyword_set(n_omega) then n_omega = 2L
  G4=fltarr(nx_einc,ny_emeas,8,2)
  ny_bins = nbins  
  adcbin_hist = lonarr(nx_einc,n_omega,ny_bins)
  adcbin_index= lindgen(nx_einc,n_omega,ny_bins)
  bin_val = indgen(ny_bins)
  ei_val = ( (indgen(nx_einc)+.5d) *xbinsize) + xs0
  if xlog then begin
    ei_val = 10.d^ ei_val
    de_inc = ei_val * xbinsize  * alog(10.)   ; close approximation
  endif
  
  em_val = ( (indgen(ny_emeas)+.5d) *ybinsize) + ys0
  if ylog then em_val = 10.d^ em_val
  if ndata ne 0 then begin
    einc = data.einc
    one_n = replicate(1,ndata)
    for side=0,1 do begin
      ftocode = data.fto[side]
      adc_bin = data.bin[side]
      em      = data.em[side]
      einc_bin = long(  (xlog ? alog10(einc/xbinrange[0]) : einc-xbinrange[0]) / xbinsize )
      omega_bin = data.dir[0] gt 0                                ;  separate into two 'angle' bins based on the x direction
      ind = adcbin_index[einc_bin,omega_bin,adc_bin]
      h = histogram(ind,binsize=1,min=0,max= nx_einc*ny_bins*n_omega-1)
      adcbin_hist += h
      for fto = 0,7 do begin
        ;       if fto eq 0 then ok = ftocode gt 0 else $
        ok = fto eq ftocode
        w = where(ok,nw)
        if nw eq 0 then begin
          dprint,dlevel=3,side,fto, ' Not encountered ',desc
          continue
        endif
        G2 = histbins2d(einc[w],em[w],ei_val2,em_val2,xbinsize=xbinsize,ybinsize=ybinsize,xrange=xbinrange,yrange=ybinrange,xlog=xlog,ylog=ylog)
        G2 = G2/ND * area_cm2   *!dpi  ; *2* 4 ; normalize to area  (cm^2) * 4pi ster
        if ~keyword_set(g4) then G4 = replicate(0.,[size(/dimen,G2),8,2] )
        G4[*,*,fto,side] = g2
      endfor
    endfor
  endif

  ; The following is only true for simlog == 1
  ;ND = npart * xbinsize / (srange[1] - srange[0])   ; number of particles per incident energy bin
  M = adcbin_hist * (area_cm2 / nd) * !pi
  dE = xbinsize * alog(10.) * ( ei_val # replicate(1.,ny_bins)  )  ; energy width
  Mde = total(M,2) * dE    ; include energy width in matrix


  str_element,/add,response,'bmap',bmap
  str_element,/add,response,'ndata',ndata
  str_element,/add,response,'nd',nd
  str_element,/add,response,'xlog',xlog
  str_element,/add,response,'ylog',ylog
  str_element,/add,response,'xbinsize',xbinsize
  str_element,/add,response,'ybinsize',ybinsize
  str_element,/add,response,'xbinrange',xbinrange
  str_element,/add,response,'ybinrange',ybinrange
  str_element,/add,response,'e_inc',ei_val
  str_element,/add,response,'de_inc',de_inc
  str_element,/add,response,'e_meas',em_val
  str_element,/add,response,'G4',g4
  str_element,/add,response,'nbins',nbins
  str_element,/add,response,'bin3',adcbin_hist
  str_element,/add,response,'GB3' , adcbin_hist *  (response.sim_area /100 / response.nd * 3.14)
  str_element,/add,response,'mde', Mde
  str_element,/add,response,'bin_val',bin_val
  ;peakeinc = swfo_stis_inst_response_peakeinc(response,width=10)
  ;str_element,/add,response,'peakeinc',peakeinc
  str_element,/add,response,'fdesc',fdesc
  str_element,/add,response,'filter',out_filter
  
  
  p_pks = swfo_stis_inst_response_peakeinc(response,pk2s=p_pk2s,test=test)   ; this will fill the e0_inc and gde elements of the bmap array


  return,response
end




