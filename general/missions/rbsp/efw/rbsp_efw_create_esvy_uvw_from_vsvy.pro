;+
; NAME: rbsp_efw_create_esvy_uvw_from_vsvy.pro
;       (see rbsp_efw_create_esvy_uvw_from_vsvy_testing.pro to compare to known
;        good data)
; SYNTAX:
; PURPOSE: Create the UVW Ew waveform data from the single-ended measurements.
;          Returns tplot variable rbspx_efw_esvy.
;          This routine is similar to rbsp_load_efw_waveform.pro called with
;          the 'esvy' keyword. That routine will just load Esvy straight from
;          the L1 files. However, the output is based on V12 and V34, which is
;          not useful if one of the antennas is bad. This routine allows you
;          to construct Esvy UVW from any combination of antenna pairs.
; INPUT:    date -> 'yyyy-mm-dd'
;           probe -> 'a' or 'b'
;           bad_probe -> (integer) probe to avoid (1,2,3, or 4)
; KEYWORDS:
;           pairs -> can directly input antenna pairs to be used instead of
;                    just indicating the bad_antennas
;           rerun -> don't reload spice kernels or other stuff
;           method -> 1 = (default) Calculate Ew directly using linear combination of diagonal antenna pairs.
;                         Project the result onto the usual u or v axis. For
;                         ex, if V1 is bad we can calculate V12 from V23 and V24
;           method -> 2 = Calculate Ew using average of good boom pair. Ex, if V1
;                         is bad then E12 = 2*(V3+V4)/2 - V2
;
;           method -> 3 = (NOT WORKING YET) mimic the bad antenna by time-shifting data from adjacent
;                         antenna by 1/4 spinperiod. For ex, if V4 is bad we can
;                         substitute V4 data with time-shifted V1 data. This method
;                         can be useful if two probe potentials are misbehaving. Ex.
;                         2015-03-17 at 20:00. Only V2 and V4 are good.
;                  Comparison of method 1 and 2
;                  method 1 -> disadvantage: shorter baseline for calculating Ew
;                              (length*cos(45)
;                              advantage: No time-shift involved. Higher resolution
;                              for final data product
;                  method 2 -> disadvantage: larger time-shift (1/4 sp as opposed to 1/8)
;                              advantage: longer antenna baselines. Always 100 m.
;
;
; OUTPUT: tplot variable rb_efw_esvy, which is the Efield in UVW coord.
;         This can then be despun using rbsp_uvw_to_mgse.pro or spinfit
;         with rbsp_spinfit.
;
; EXAMPLES: Call for two bad antennas.
;        rbsp_efw_create_esvy_uvw_from_vsvy,'a',bad_antennas=[1,2],method=1
;        For this example V34 will be time-shifted by 1/4 spinperiod to mimic V12
;
;        Call for one bad antenna
;        rbsp_efw_create_esvy_uvw_from_vsvy,'a',bad_antennas=1,method=1
;
;        explicitly define antenna pairs to be used (assume V4 is bad)
;        rbsp_efw_create_esvy_uvw_from_vsvy,'a',pairs=['12','31'],method=1
;        In this case V1 will be time-shifted by 1/4 spinperiod to mimic V4.
;
; HISTORY: Written by Aaron W Breneman, June 2016
; VERSION:
;-

;--modify so that you can explicitly input pairs instead of indicating
;--which antennas are bad


pro rbsp_efw_create_esvy_uvw_from_vsvy,$
  date,$
  probe,$
  bad_probe,$
  testing=testing,$
  method=method,$
  pairs=pairs,$
  no_spice_load=no_spice_load,$
  rerun=rerun


  if ~KEYWORD_SET(method) then method = 1
  timespan,date
  probe = probe


  if ~keyword_set(testing) then testing = 0

  rb = 'rbsp' + probe
  rbv = rb + '_efw_vsvy_'
  rbe = rb + '_efw_esvy_'


  ;load single-ended potentials
  rbsp_load_efw_waveform, probe=probe, datatype='vsvy', coord = 'uvw',/noclean
  split_vec,rb+'_efw_vsvy',suffix='_'+['1','2','3','4','5','6']



  ;Load spice stuff
  if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels


  ;Get antenna pointing direction and stuff
  if ~keyword_set(rerun) then rbsp_load_state,probe=probe,/no_spice_load,$
  datatype=['spinper','spinphase','mat_dsc','Lvec']
  if ~keyword_set(rerun) then rbsp_efw_position_velocity_crib,/no_spice_load,/noplot





  trange = timerange()

  ;get boom lengths
  cp0 = rbsp_efw_get_cal_params(trange[0])
  cp = cp0.a
  boom_length = cp.boom_length
  boom_shorting_factor = cp.boom_shorting_factor




  ;-------------------------------------------------------------------------------
  ;Method 1: Calculate linear combinations of remaining 3 good probes
  ;-------------------------------------------------------------------------------

  if method eq 1 then begin


    ;find probe separation
    boom_length_adj = sqrt(2)*boom_length[0]/2.


    if bad_probe eq 1 then begin

      dif_data,rbv+'3',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E34 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      dif_data,rbv+'2',rbv+'3',newname='tmp'
      get_data,'tmp',data=dd
      E23 = dd.y * 1000./boom_length_adj

      dif_data,rbv+'2',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E24 = dd.y * 1000./boom_length_adj

      E12 = -1*sqrt(2)/2.*(E23 + E24)

    endif

    if bad_probe eq 2 then begin

      dif_data,rbv+'3',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E34 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      dif_data,rbv+'1',rbv+'3',newname='tmp'
      get_data,'tmp',data=dd
      E13 = dd.y * 1000./boom_length_adj

      dif_data,rbv+'1',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E14 = dd.y * 1000./boom_length_adj

      E12 = 1*sqrt(2)/2.*(E13 + E14)
    endif

    if bad_probe eq 3 then begin

      dif_data,rbv+'1',rbv+'2',newname='tmp'
      get_data,'tmp',data=dd
      E12 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      dif_data,rbv+'1',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E14 = dd.y * 1000./boom_length_adj

      dif_data,rbv+'2',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E24 = dd.y * 1000./boom_length_adj

      E34 = 1*sqrt(2)/2.*(E14 + E24)
    endif

    if bad_probe eq 4 then begin

      dif_data,rbv+'1',rbv+'2',newname='tmp'
      get_data,'tmp',data=dd
      E12 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      dif_data,rbv+'1',rbv+'3',newname='tmp'
      get_data,'tmp',data=dd
      E13 = dd.y * 1000./boom_length_adj

      dif_data,rbv+'2',rbv+'3',newname='tmp'
      get_data,'tmp',data=dd
      E23 = dd.y * 1000./boom_length_adj

      E34 = -1*sqrt(2)/2.*(E13 + E23)
    endif


    store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E12],[E34],[E56]]
    options,'rbsp'+probe+'_efw_esvy','ytitle','rbsp'+probe+'_efw_esvy'+'!C[mV/m]'


  endif  ;;method eq 1

  ;-------------------------------------------------------------------------------
  ;Method 2
  ;-------------------------------------------------------------------------------

  if method eq 2 then begin


    get_data,rbv+'1',times,v1
    get_data,rbv+'2',times,v2
    get_data,rbv+'3',times,v3
    get_data,rbv+'4',times,v4

    if bad_probe eq 1 then begin

      dif_data,rbv+'3',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E34 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      E12 = 1*1000.*(v3 + v4 - v2)/boom_length[0]

    endif
    if bad_probe eq 2 then begin

      dif_data,rbv+'3',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E34 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      E12 = -1*1000.*(v3 + v4 - v1)/boom_length[0]

    endif
    if bad_probe eq 3 then begin

      dif_data,rbv+'1',rbv+'2',newname='tmp'
      get_data,'tmp',data=dd
      E12 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      E34 = 1000.*(v1 + v2 - v4)/boom_length[1]

    endif
    if bad_probe eq 4 then begin

      dif_data,rbv+'1',rbv+'2',newname='tmp'
      get_data,'tmp',data=dd
      E12 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      E34 = -1*1000.*(v1 + v2 - v3)/boom_length[1]

    endif

    store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E12],[E34],[E56]]
    options,'rbsp'+probe+'_efw_esvy','ytitle','rbsp'+probe+'_efw_esvy'+'!C[mV/m]'



  endif


  ;
  ; ;-------------------------------------------------------------------------------
  ; ;Method 3
  ; ;-------------------------------------------------------------------------------
  ;
  ;
  ; if method eq 3 then begin
  ;
  ;
  ;   get_data,rb+'_spinper',data=sp
  ;   spinper = median(sp.y)
  ;
  ;
  ;   ;;Decide which antenna pair you want to mimic. The options are 12 or 34 (or 21 or 43)
  ;   ; pairsm = strarr(3)
  ;   ; for i=0,2 do begin
  ;   ;   if pairs[i] eq '12' then pairsm[i] = '12'
  ;   ;   if pairs[i] eq '34' then pairsm[i] = '34'
  ;   ;   if pairs[i] eq '13' then pairsm[i] = '12'
  ;   ;   if pairs[i] eq '14' then pairsm[i] = '12'
  ;   ;   if pairs[i] eq '24' then pairsm[i] = '21' ;-->shift V4 by 1/4 spinper to mimic V1
  ;   ;   if pairs[i] eq '23' then pairsm[i] = '21'
  ;   ; endfor
  ;
  ;
  ;   goodantennas = ['1','2','3','4']
  ;   ;  for i=0,n_elements(bad_probe)-1 do goodantennas[bad_probe[i]-1] = 'x'
  ;   goodantennas[bad_probe-1] = 'x'
  ;
  ;   ;Determine which antenna pairs to use. Note that there's some ambiguity to
  ;   ;this. For ex, if V2 is bad_probe, we can use V1-V3 or V1-V4.
  ;   if ~keyword_set(pairs) then begin
  ;
  ;     pairs = strarr(2)
  ;
  ;
  ;     ;Establish the first antenna pair
  ;     ;both V1 and V2 are good
  ;     if goodantennas[0] ne 'x' and goodantennas[1] ne 'x' then begin
  ;       pairs[0] = '12'
  ;     endif
  ;
  ;     ;both V1 and V2 are bad_probe
  ;     if goodantennas[0] eq 'x' and goodantennas[1] eq 'x' then begin
  ;       pairs[0] = '34'
  ;       ;twobad = 1    ;****IMPLEMENT THIS FOR SPINPERIOD/2 TIME-SHIFT
  ;     endif
  ;
  ;     ;V1 is bad and V2 is good
  ;     if goodantennas[0] eq 'x' and goodantennas[1] ne 'x' then begin
  ;       if goodantennas[2] ne 'x' then pairs[0] = '32' else $
  ;       if goodantennas[3] ne 'x' then pairs[0] = '42'
  ;     endif
  ;
  ;     ;V1 is good and V2 is bad
  ;     if goodantennas[0] ne 'x' and goodantennas[1] eq 'x' then begin
  ;       if goodantennas[2] ne 'x' then pairs[0] = '13' else $
  ;       if goodantennas[3] ne 'x' then pairs[0] = '14'
  ;     endif
  ;
  ;
  ;
  ;     ;Establish the second antenna pair
  ;     ;both V3 and V4 are good
  ;     if goodantennas[2] ne 'x' and goodantennas[3] ne 'x' then begin
  ;       pairs[1] = '34'
  ;     endif
  ;
  ;     ;both V3 and V4 are bad
  ;     if goodantennas[2] eq 'x' and goodantennas[3] eq 'x' then begin
  ;       pairs[1] = '12'
  ;       twobad = 1
  ;     endif
  ;
  ;     ;V3 is bad and V4 is good
  ;     if goodantennas[2] eq 'x' and goodantennas[3] ne 'x' then begin
  ;       if goodantennas[0] ne 'x' then pairs[1] = '14' else $
  ;       if goodantennas[1] ne 'x' then pairs[1] = '24'
  ;     endif
  ;
  ;     ;V3 is good and V4 is bad
  ;     if goodantennas[2] ne 'x' and goodantennas[3] eq 'x' then begin
  ;       if goodantennas[0] ne 'x' then pairs[1] = '31' else $
  ;       if goodantennas[1] ne 'x' then pairs[1] = '32'
  ;     endif
  ;
  ;   endif ;establish "pairs"
  ;
  ;
  ;
  ;
  ;   ;Idealized antenna pairs (static)
  ;   pairsm = ['12','34']
  ;
  ;
  ;   ;extract individual antennas from the pairs
  ;   ;  a0 = strarr(3) & a1 = a0 & am0 = a1 & am1 = a1
  ;
  ;   a1 = strmid(pairs[0],0,1)
  ;   a2 = strmid(pairs[0],1,1)
  ;   a3 = strmid(pairs[1],0,1)
  ;   a4 = strmid(pairs[1],1,1)
  ;
  ;   am1 = '1'
  ;   am2 = '2'
  ;   am3 = '3'
  ;   am4 = '4'
  ;
  ;   ;create the 3D electric field using the unmodified data
  ;   n12 = am1+am2
  ;   n34 = am3+am4
  ;   ename = rb+'_efw_esvy_('+ n12 + ')_and_(' + n34 +')_and_(56)'
  ;
  ;
  ;
  ;
  ;   ;;create electric field (unaltered from V1-V4)
  ;   dif_data,rbv+am1, rbv+am2,$
  ;   newname=rbe+am1+am2
  ;   dif_data,rbv+am3, rbv+am4,$
  ;   newname=rbe+am3+am4
  ;   dif_data,rb+'_efw_vsvy_5', rb+'_efw_vsvy_6',$
  ;   newname=rb+'_efw_esvy_56'
  ;
  ;
  ;
  ;
  ;   get_data,rbe+am1+am2,data=eu
  ;   get_data,rbe+am3+am4,data=ev
  ;   get_data,rb+'_efw_esvy_56',times,ew
  ;
  ;   times = eu.x
  ;
  ;   eu = 1000.*eu.y/boom_length[0]
  ;   ev = 1000.*ev.y/boom_length[1]
  ;
  ;   emag = sqrt(eu^2 + ev^2)
  ;
  ;   store_data,ename,data={x:times,y:[[eu],[ev],[ew]]},dlim=dlim
  ;   store_data,'Emag',times,emag
  ;   options,ename,'ytitle',ename+'!C[mV/m]'
  ;
  ;
  ;
  ;   b1 = 1.  ;unit vector along Eu axis
  ;
  ;   E_dot_b = Eu*b1
  ;   Emag = sqrt(eu^2 + ev^2)
  ;   store_data,'Emag',times,Emag
  ;
  ;
  ;   ;See if new magnitude compares with original
  ;   store_data,'Emag_comb',data=['Emag','Emag_m2']
  ;   options,'Emag_comb','colors',[0,250]
  ;
  ;   tplot,'Emag_comb'
  ;
  ;
  ;   delta = acos(E_dot_b/Emag)/!dtor
  ;   store_data,'delta',times,delta
  ;
  ;
  ;
  ;   if a1 eq '1' then adj_time = 0.
  ;   if a1 eq '2' then stop
  ;   if a1 eq '3' then adj_time = 1*spinper/4.
  ;   if a1 eq '4' then adj_time = -1*spinper/4.
  ;   get_data,rbv+a1,data=v
  ;   store_data,rbv+a1+'_to_'+am1,v.x+adj_time,v.y
  ;
  ;   if a2 eq '2' then adj_time = 0.
  ;   if a2 eq '1' then stop
  ;   if a2 eq '3' then adj_time = -1*spinper/4.
  ;   if a2 eq '4' then adj_time = spinper/4.
  ;   get_data,rbv+a2,data=v
  ;   store_data,rbv+a2+'_to_'+am2,v.x+adj_time,v.y
  ;
  ;   if a3 eq '3' then adj_time = 0.
  ;   if a3 eq '4' then stop
  ;   if a3 eq '1' then adj_time = -1*spinper/4.
  ;   if a3 eq '2' then adj_time = spinper/4.
  ;   get_data,rbv+a3,data=v
  ;   store_data,rbv+a3+'_to_'+am3,v.x+adj_time,v.y
  ;
  ;   if a4 eq '4' then adj_time = 0.
  ;   if a4 eq '3' then stop
  ;   if a4 eq '1' then adj_time = spinper/4.
  ;   if a4 eq '2' then adj_time = -1*spinper/4.
  ;   get_data,rbv+a4,data=v
  ;   store_data,rbv+a4+'_to_'+am4,v.x+adj_time,v.y
  ;
  ;
  ;
  ;   if testing then begin
  ;
  ;     if a1 ne am1 then tplot,[rbv+a1+'_to_'+am1, rbv+am1]
  ;     if a2 ne am2 then tplot,[rbv+a2+'_to_'+am2, rbv+am2]
  ;     if a3 ne am3 then tplot,[rbv+a3+'_to_'+am3, rbv+am3]
  ;     if a4 ne am4 then tplot,[rbv+a4+'_to_'+am4, rbv+am4]
  ;     stop
  ;
  ;   endif
  ;
  ;
  ;
  ;   ;;create electric field (from modified V1-V4)
  ;   dif_data,rbv+a1+'_to_'+am1, rbv+a2+'_to_'+am2,$
  ;   newname=rbe+a1+a2+'_to_'+am1+am2
  ;   dif_data,rbv+a3+'_to_'+am3, rbv+a4+'_to_'+am4,$
  ;   newname=rbe+a3+a4+'_to_'+am3+am4
  ;   dif_data,rb+'_efw_vsvy_5', rb+'_efw_vsvy_6',$
  ;   newname=rb+'_efw_esvy_56'
  ;
  ;
  ;   ;tplot,[rbe+am1+am2,rbe+a1+a2+'_to_'+am1+am2]
  ;   ;tplot,[rbe+am3+am4,rbe+a3+a4+'_to_'+am3+am4]
  ;
  ;
  ;   ;*****
  ;   rbsp_detrend,[rbe+am1+am2,$
  ;   rbe+a1+a2+'_to_'+am1+am2,$
  ;   rbe+am3+am4,$
  ;   rbe+a3+a4+'_to_'+am3+am4],60.*5.
  ;
  ;
  ;   ;compare unaltered to modified electric fields
  ;   store_data,'e12_comp',$
  ;   data=[rbe+a1+a2+'_to_'+am1+am2+'_detrend',$
  ;   rbe+am1+am2+'_detrend']
  ;
  ;   store_data,'e34_comp',$
  ;   data=[rbe+a3+a4+'_to_'+am3+am4+'_detrend',$
  ;   rbe+am3+am4+'_detrend']
  ;
  ;   options,'e12_comp','colors',[0,250]
  ;   options,'e34_comp','colors',[0,250]
  ;
  ;   ylim,['e12_comp','e34_comp'],-2,2
  ;
  ;
  ;
  ;
  ;   if testing then begin
  ;
  ;     if a1 ne am1 or a2 ne am2 then tplot,'e12_comp' else tplot,'e34_comp'
  ;     if testing then tplot,[rbv+a1,rbv+a2,rbv+a3,rbv+a4],/add
  ;
  ;     stop
  ;
  ;     ;;These two should be very similar
  ;     if a1 ne am1 or a2 ne am2 then begin
  ;       ylim,[rbe+a1+a2+'_to_'+am1+am2,rbe+am1+am2],0,0
  ;       tplot,[rbe+a1+a2+'_to_'+am1+am2,rbe+am1+am2]
  ;     endif else begin
  ;       ylim,[rbe+a3+a4+'_to_'+am3+am4,rbe+am3+am4],0,0
  ;       tplot,[rbe+a3+a4+'_to_'+am3+am4,rbe+am3+am4]
  ;     endelse
  ;
  ;
  ;     stop
  ;   endif
  ;
  ;
  ;
  ;   ;;Now give these quantities units of electric field (keep the same
  ;   ;;names). If the pair quantities are reversed, then multiply by -1
  ;   mult = [1.,1.]
  ;   if pairs[0] eq '21' or pairs[0] eq '31' or pairs[0] eq '41' or pairs[0] eq '42' or pairs[0] eq '43' then mult[0] = -1.
  ;   if pairs[1] eq '21' or pairs[1] eq '31' or pairs[1] eq '41' or pairs[1] eq '42' or pairs[1] eq '43' then mult[1] = -1.
  ;
  ;
  ;   ;interpolate these to the unaltered times
  ;   tinterpol_mxn,rbe+a1+a2+'_to_'+am1+am2,times,newname=rbe+a1+a2+'_to_'+am1+am2
  ;   tinterpol_mxn,rbe+a3+a4+'_to_'+am3+am4,times,newname=rbe+a3+a4+'_to_'+am3+am4
  ;
  ;   get_data,rbe+a1+a2+'_to_'+am1+am2,data=eu
  ;   get_data,rbe+a3+a4+'_to_'+am3+am4,data=ev
  ;
  ;
  ;
  ;   data_att = {coord_sys:'uvw'}
  ;   dlim = {data_att:data_att}
  ;
  ;
  ;   if not (a1+a2 eq am1+am2) then n12 = a1+a2+'-to-'+am1+am2 else n12 = a1+a2
  ;   if not (a3+a4 eq am3+am4) then n34 = a3+a4+'-to-'+am3+am4 else n34 = a3+a4
  ;   enamem = rb+'_efw_esvy_('+ n12 + ')_and_(' + n34 +')_and_(56)'
  ;
  ;
  ;
  ;   ;create the 3D electric field using the modified data
  ;   eu = 1000.*mult[0]*eu.y/boom_length[0]
  ;   ev = 1000.*mult[1]*ev.y/boom_length[1]
  ;   ew = 1000.*ew/boom_length[2]
  ;
  ;   store_data,enamem,data={x:times,y:[[eu],[ev],[ew]]},dlim=dlim
  ;   options,enamem,'ytitle',enamem+'!C[mV/m]'
  ;
  ;
  ;
  ;
  ;   stop
  ;
  ;
  ;
  ;   ;;now "pair" is mimicking "pairm". Note that the above
  ;   ;;two don't have to be very similar since they're measuring two
  ;   ;;different full-cadence efields and have different offsets, etc.
  ;
  ;   if testing then begin
  ;
  ;     get_data,ename,data=en
  ;     en.y[*,2] = 0.
  ;     store_data,'ename_tmp',data=en
  ;     options,'ename_tmp','ytitle',ename+'!C[mV/m]'
  ;
  ;
  ;     get_data,enamem,data=en
  ;     en.y[*,2] = 0.
  ;     store_data,'enamem_tmp',data=en
  ;     options,'enamem_tmp','ytitle',enamem+'!C[mV/m]'
  ;
  ;
  ;     rbsp_detrend,['ename_tmp','enamem_tmp'],60.*5.
  ;     options,'ename_tmp_detrend','ytitle',ename+'!C[mV/m]!Cdetrended_20min'
  ;     options,'enamem_tmp_detrend','ytitle',enamem+'!C[mV/m]!Cdetrended_20min'
  ;
  ;
  ;     ylim,['ename_tmp','enamem_tmp']+'_detrend',-40,40
  ;     tplot,['ename_tmp','enamem_tmp']+'_detrend'
  ;
  ;     stop
  ;   endif
  ;
  ;   ;;make a copy for use with rest of program
  ;   copy_data,ename,rb+'_efw_esvy'
  ;
  ;
  ; endif
  ;
  ;
  ;
  ; ;-------------------------------------------------------------------------------
  ; ;Compare both
  ; ;-------------------------------------------------------------------------------
  ;
  ; if KEYWORD_SET(testing) then begin
  ;
  ;   split_vec,enamem
  ;   split_vec,ename
  ;
  ;   yellow_to_orange
  ;   rbsp_detrend,[ename+'_x',enamem+'_x',$
  ;   'Enew_'+a1+a2+'_to_'+am1+am2],60.*5.
  ;
  ;   rbsp_detrend,['Eu_m2v2','Ev_m2v2'],60.*5.
  ;
  ;   store_data,'e12_orig_vs_m1_comp',data=[ename+'_x',enamem+'_x']+'_detrend'
  ;   ;      store_data,'e12_orig_vs_m2_comp',data=[ename+'_x','Enew_'+a1+a2+'_to_'+am1+am2]+'_detrend'
  ;   store_data,'e12_orig_vs_m2_comp',data=[ename+'_x','Eu_m2v2']+'_detrend'
  ;   ;      store_data,'e12_m1_vs_m2_comp',data=[enamem+'_x','Enew_'+a1+a2+'_to_'+am1+am2]+'_detrend'
  ;   store_data,'e12_m1_vs_m2_comp',data=[enamem+'_x','Eu_m2v2']+'_detrend'
  ;   store_data,'e12_orig_vs_m3_comp',data=[ename+'_x','e12_m3_detrend']
  ;
  ;
  ;   options,'e12_orig_vs_m1_comp','colors',[0,75]
  ;   options,'e12_orig_vs_m2_comp','colors',[0,250]
  ;   options,'e12_m1_vs_m2_comp','colors',[75,250]
  ;   options,'e12_orig_vs_m3_comp','colors',[0,200]
  ;
  ;   options,'e12_orig_vs_m3_comp','ytitle','e12Corig!Cvs!Cm3!Ccomp'
  ;
  ;
  ;   ylim,['e12_orig_vs_m1_comp','e12_orig_vs_m2_comp','e12_m1_vs_m2_comp','e12_orig_vs_m3_comp'],-2,2
  ;   ;      tplot,['rbspb_efw_esvy_x','e12_orig_vs_m1_comp','e12_orig_vs_m2_comp','e12_m1_vs_m2_comp','e12_orig_vs_m3_comp']
  ;   tplot,['e12_orig_vs_m2_comp']
  ;
  ;
  ;
  ;
  ;
  ;
  ;   rbsp_detrend,[ename+'_y',enamem+'_y',$
  ;   'Enew_'+a3+a4+'_to_'+am3+am4],60.*20.
  ;
  ;
  ;   store_data,'e34_orig_vs_m1_comp',data=[ename+'_y',enamem+'_y']+'_detrend'
  ;   ;            store_data,'e34_orig_vs_m2_comp',data=[ename+'_y','Enew_'+a3+a4+'_to_'+am3+am4]+'_detrend'
  ;   store_data,'e34_orig_vs_m2_comp',data=[ename+'_y','Ev_m2v2']+'_detrend'
  ;   ;store_data,'e34_m1_vs_m2_comp',data=[enamem+'_y','Enew_'+a3+a4+'_to_'+am3+am4]+'_detrend'
  ;   store_data,'e34_m1_vs_m2_comp',data=[enamem+'_y','Ev_m2v2']+'_detrend'
  ;   store_data,'e34_orig_vs_m3_comp',data=[ename+'_y','e34_m3_detrend']
  ;
  ;
  ;   options,'e34_orig_vs_m1_comp','colors',[0,75]
  ;   options,'e34_orig_vs_m2_comp','colors',[0,250]
  ;   options,'e34_m1_vs_m2_comp','colors',[75,250]
  ;   options,'e34_orig_vs_m3_comp','colors',[0,200]
  ;
  ;   options,'e34_orig_vs_m3_comp','ytitle','e34!Corig!Cvs!Cm3!Ccomp'
  ;
  ;
  ;   ylim,['e34_orig_vs_m1_comp','e34_orig_vs_m2_comp','e34_m1_vs_m2_comp','e34_orig_vs_m3_comp'],-4,4
  ;   ;            tplot,['rbspb_efw_esvy_y','e34_orig_vs_m1_comp','e34_orig_vs_m2_comp','e34_m1_vs_m2_comp','e34_orig_vs_m3_comp']
  ;   tplot,['e34_orig_vs_m2_comp']
  ;
  ;
  ;
  ; endif


end
