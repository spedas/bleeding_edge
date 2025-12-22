function load_ac_fields
;
; returns array of succesfully stored names, '' if none...
;
catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    show_dqis
    if defined(new_names) then begin
        catch,/cancel
        return,new_names
    endif else begin
        catch,/cancel
        return,''
    endelse
endif
;
;page 2:
;  VLF 0-16kHz, 64 bands, E and B
;  
;  Total VLF power, E and B
;  
;  HF E and B, 0-2 MHz, 64 bands
;
;  Total HF power, E and B 200 kHz-2 MHz

twopi = 2.d*!dpi
jev = 1.6022d-19
em = jev/9.11d-31
mu_0 = 2.d*twopi*1.d-07
eps_0 = 8.8542d-12
mi_me = 1836.1d
min_gap = 6.0                   ; gaps bigger than this need to be
                                ; nan'd to prevent interpolation

;
; define units conversions for power quantities...put both in
; eV/m^3 ...calibrated SFA and DSP units for E and B are (V/m)^2/Hz
; and (nT)^2/Hz. 
;
; **This has now been commented out!!**
;
;epwr_units = ((0.5d*eps_0)/jev)
;bpwr_units = 1.d-18*((0.5d/mu_0)/jev)
;
epwr_units = 1.0
bpwr_units = 1.0
ecolor = byte(float(!d.n_colors) *0.6) ; red for ct 39
bcolor = byte(float(!d.n_colors) *0.9) ; green for ct 39

;epwr_lab = '!4e!3!D0!NE!E2!N/2'   ; eps_0*E^2/2
;bpwr_lab = 'B!E2!N/2!4l!3!D0!N' ; B^2/2*mu_0
epwr_lab = 'E!E2!N(V/m)!E2!N'
bpwr_lab = 'B!E2!N(nT)!E2'

fnan = !values.f_nan
dnan = !values.d_nan
;
; spectrogram bandwith limits in kHz...
;
elf_min = .032
elf_max = 2.0
vlf_min = elf_max
vlf_max = 16.384
hf_min = vlf_max
hf_max = 2.e+03
;
; default number of freqs...
;
nhf = 59L
nvlf = 56L
nelf = 62L
;
; default freqs...need to specify them, so that missing quantities
; won't produce cdf entries of non-standard size and mess up the daily
; cdf production. Yes, there are 10,000 better ways to do this. BP
;
hff = [37.5437, 70.9312, 104.319, 137.706, 171.094, 204.481, 237.869, $
       271.256, 304.644, 338.031, 371.419, 404.806, 438.194, 471.581, $
       504.969, 538.356, 571.744, 605.131, 638.519, 671.906, 705.294, $
       738.681, 772.069, 805.456, 838.844, 872.231, 905.619, 939.006, $
       972.394, 1005.78, 1039.17, 1072.56, 1105.94, 1139.33, 1172.72, $
       1206.11, 1239.49, 1272.88, 1306.27, 1339.66, 1373.04, 1406.43, $
       1439.82, 1473.21, 1506.59, 1539.98, 1573.37, 1606.76, 1640.14, $
       1673.53, 1706.92, 1740.31, 1773.69, 1807.08, 1840.47, 1873.86, $
       1907.24, 1940.63, 1974.02] 

vlff = [2.17600, 2.43200, 2.68800, 2.94400, 3.20000, 3.45600, 3.71200, $
        3.96800, 4.22400, 4.48000, 4.73600, 4.99200, 5.24800, 5.50400, $
        5.76000, 6.01600, 6.27200, 6.52800, 6.78400, 7.04000, 7.29600, $
        7.55200, 7.80800, 8.06400, 8.32000, 8.57600, 8.83200, 9.08800, $
        9.34400, 9.60000, 9.85600, 10.1120, 10.3680, 10.6240, 10.8800, $
        11.1360, 11.3920, 11.6480, 11.9040, 12.1600, 12.4160, 12.6720, $
        12.9280, 13.1840, 13.4400, 13.6960, 13.9520, 14.2080, 14.4640, $
        14.7200, 14.9760, 15.2320, 15.4880, 15.7440, 16.0000, 16.2560]

elff = [0.032, 0.064, 0.096, 0.128, 0.160, 0.192, 0.224, 0.256, 0.288, $
        0.320, 0.352, 0.384, 0.416, 0.448, 0.480, 0.512, 0.544, 0.576, $
        0.608, 0.640, 0.672, 0.704, 0.736, 0.768, 0.800, 0.832, 0.864, $
        0.896, 0.928, 0.960, 0.992, 1.024, 1.056, 1.088, 1.120, 1.152, $
        1.184, 1.216, 1.248, 1.280, 1.312, 1.344, 1.376, 1.408, 1.440, $
        1.472, 1.504, 1.536, 1.568, 1.600, 1.632, 1.664, 1.696, 1.728, $
        1.760, 1.792, 1.824, 1.856, 1.888, 1.920, 1.952, 1.984]

elff = fltarr(62)
elff[0:56] = [0.032, 0.064, 0.096, 0.128, 0.160, 0.192, 0.224, 0.256, 0.288, $
              0.320, 0.352, 0.384, 0.416, 0.448, 0.480, 0.512, 0.544, 0.576, $
              0.608, 0.640, 0.672, 0.704, 0.736, 0.768, 0.800, 0.832, 0.864, $
              0.896, 0.928, 0.960, 0.992, 1.024, 1.056, 1.088, 1.120, 1.152, $
              1.184, 1.216, 1.248, 1.280, 1.312, 1.344, 1.376, 1.408, 1.440, $
              1.472, 1.504, 1.536, 1.568, 1.600, 1.632, 1.664, 1.696, 1.728, $
              1.760, 1.792, 1.824]
elff[57:61] = [1.856, 1.888, 1.920, 1.952, 1.984]

if find_handle('spin_times') eq 0 then begin
    message,'calling LOAD_SPIN_TIMES...',/continue
    good_spin = load_spin_times(spin = 180,/orbit)
    if not good_spin then begin
        message,'can''t load spin times! This is very bad!',/continue
        catch,/cancel
        return,''
    endif    
endif
get_data,'spin_times',data=ss
nt = n_elements(ss.x)
ybins = 64                      ; number of frequency bins


if load_fields_modes() eq 0 then begin
    message,'Unable to determine fields modes...no AC fields can be ' + $
      'loaded...',/continue
    return,''
endif

repeat begin
    get_data,'Fmode',data=modes,index=index
    if index eq 0 then begin
        if load_fields_modes() eq 0 then begin
            message,'Unable to determine fields modes...no AC fields can be ' + $
              'loaded...',/continue
            return,''
        endif
    endif
endrep until index ne 0

if n_elements(uniq([modes.mode])) gt 2 then begin
    message,'WARNING! Some DSP data is being lost!',/continue
endif

mpick =  (where(modes.mode ne 255))(0)

if mpick ge 0 then begin
    mp = modes.mode(mpick)
endif else begin
    message,'Nothing but back orbit!',/continue
    return,''
endelse

;case 1 of
;    ((mp eq 18) or $
;     (mp eq 21)):begin
;        vlfe_dqd = 'DspSubChan1'
;        vlfb_dqd = 'DspSubChan5'
;    end
;    else:begin
vlfe_dqd = 'DspADC_V5-V8HG'
vlfb_dqd = 'DspADC_Mag3ac'
;    end
;endcase


vlf_e	= get_fa_fields( vlfe_dqd,       /all,/cal,/spin, ybins = ybins)
vlf_b	= get_fa_fields( vlfb_dqd,       /all,/cal,/spin, ybins = ybins)
hf_e	= get_fa_fields('SfaAve_V5-V8',  /all,/cal,/spin, ybins = ybins)
hf_b	= get_fa_fields('SfaAve_Mag3AC', /all,/cal,/spin, ybins = ybins)
elf_e   = get_fa_fields(vlfe_dqd,        /all,/cal,/spin)
elf_b   = get_fa_fields(vlfb_dqd,        /all,/cal,/spin)

if not vlf_e.valid then begin
    vlf_e = get_fa_fields('DspADC_V5-V8',/all,/cal,/spin, ybins = $
                          ybins)
    elf_e   = get_fa_fields('DspADC_V5-V8',/all,/cal,/spin)
endif

tplot_names, names = old_names
nold = n_elements(old_names)

if hf_e.valid then begin
    fpick = select_range(hf_e.yaxis,hf_min,hf_max,nf)
    if (nf ne nhf) then begin
        message,'incorrect number of HF freqs',/continue
    endif
    hfespec = alog10(hf_e.comp1(*,fpick))
    nan_gap, hf_e.time, hfespec, min_gap
    hfefreq = hf_e.yaxis(fpick)
    store_data,'HF E', $
      data={x:hf_e.time, $
            y:hfespec, $
            v:hfefreq}
    
    nt = n_elements(hf_e.time)
    bw = replicate(1,nt)#(hf_e.yaxis(fpick+1l)-hf_e.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    hepwr = total(hf_e.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    hf_e = {valid:0l, $
            yaxis:hff, $
            comp1:fltarr(nt,nhf), $
            time:dblarr(nt)}
    hf_e.comp1(*) = fnan
    hfespec = hf_e.comp1
    hfefreq = hff
    hepwr = fltarr(nt)
    hepwr(*) = fnan
endelse

if vlf_e.valid then begin
    fpick = select_range(vlf_e.yaxis,vlf_min,vlf_max,nf)
    if (nf ne nvlf) then begin
        message,'incorrect number of VLF freqs',/continue
    endif
    vlfespec =alog10(vlf_e.comp1(*,fpick)) 
    nan_gap, vlf_e.time,vlfespec , min_gap
    vlfefreq = (vlf_e.yaxis(fpick))
    store_data,'VLF E', $
      data={x:vlf_e.time, $
            y:vlfespec, $
            v:vlfefreq}
    
    nt = n_elements(vlf_e.time)
    bw = replicate(1,nt)#(vlf_e.yaxis(fpick+1l)-vlf_e.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    lepwr = total(vlf_e.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    vlf_e = {valid:0l, $
             yaxis:vlff, $
             comp1:fltarr(nt,nvlf), $
             time:dblarr(nt)}
    vlf_e.comp1(*) = fnan
    vlfespec = vlf_e.comp1
    vlfefreq = vlff
    lepwr = fltarr(nt)
    lepwr(*) = fnan
endelse

if elf_e.valid then begin
    fpick = select_range(elf_e.yaxis,elf_min,elf_max,nf)
    if (nf ne nelf) then begin
        message,'incorrect number of ELF freqs',/continue
    endif

    nt = n_elements(elf_e.time)
    elfefreq = elf_e.yaxis(fpick)
    elfespec = alog10(elf_e.comp1(*,fpick))
    nan_gap, elf_e.time, elfespec, min_gap
    
    store_data,'ELF E', $
      data={x:elf_e.time,y:elfespec,v:elfefreq}
    
    bw = replicate(1,nt)#(elf_e.yaxis(fpick+1l)-elf_e.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    eepwr = total(elf_e.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    elf_e = {valid:0l, $
             yaxis:elff, $
             comp1:fltarr(nt,nelf), $
             time:ss.x}
    elf_e.comp1(*) = fnan
    elfefreq = elff
    elfespec = elf_e.comp1
    eepwr = fltarr(nt)
    eepwr(*) = fnan
endelse

if hf_b.valid then begin
    fpick = select_range(hf_b.yaxis,hf_min,hf_max,nf)
    if (nf ne nhf) then begin
        message,'incorrect number of HF freqs',/continue
    endif
    hfbspec = alog10(hf_b.comp1(*,fpick))
    nan_gap, hf_b.time, hfbspec, min_gap
    hfbfreq = hf_b.yaxis(fpick)
    store_data,'HF B',data={x:hf_b.time, $
                            y:hfbspec, $
                            v:hfbfreq}
    
    nt = n_elements(hf_b.time)
    bw = replicate(1,nt)#(hf_b.yaxis(fpick+1l)-hf_b.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    hbpwr = total(hf_b.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    hf_b = {valid:0l, $
            yaxis:hff, $
            comp1:fltarr(nt,nhf), $
            time:dblarr(nt)}
    hf_b.comp1(*) = fnan
    hfbspec = hf_b.comp1
    hfbfreq = hff
    hbpwr = fltarr(nt)
    hbpwr(*) = fnan
endelse

if vlf_b.valid then begin
    fpick = select_range(vlf_b.yaxis,vlf_min,vlf_max,nf)
    if (nf ne nvlf) then begin
        message,'incorrect number of VLF freqs',/continue
    endif
    vlfbspec =alog10(vlf_b.comp1(*,fpick)) 
    nan_gap, vlf_b.time, vlfbspec, min_gap
    vlfbfreq = vlf_b.yaxis(fpick)
    store_data,'VLF B', $
      data={x:vlf_b.time,y:vlfbspec,v:vlfbfreq}
    
    nf = n_elements(fpick)
    nt = n_elements(vlf_b.time)
    bw = replicate(1,nt)#(vlf_b.yaxis(fpick+1l)-vlf_b.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    lbpwr = total(vlf_b.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    vlf_b = {valid:0l, $
             yaxis:vlff, $
             comp1:fltarr(nt,nvlf), $
             time:dblarr(nt)}
    vlf_b.comp1(*) = fnan
    vlfbspec = vlf_b.comp1
    vlfbfreq = vlff
    lbpwr = fltarr(nt)
    lbpwr(*) = fnan
endelse

if elf_b.valid then begin
    fpick = select_range(elf_b.yaxis,elf_min,elf_max,nf)
    if (nf ne nelf) then begin
        message,'incorrect number of ELF freqs',/continue
    endif

    nt = n_elements(elf_b.time)
    elfbfreq = elf_b.yaxis(fpick)
    elfbspec = alog10(elf_b.comp1(*,fpick))
    nan_gap, elf_b.time, elfbspec, min_gap
    
    store_data,'ELF B', $
      data={x:elf_b.time,y:elfbspec,v:elfbfreq}
    
    bw = replicate(1,nt)#(elf_b.yaxis(fpick+1l)-elf_b.yaxis(fpick))
    bw(*,0) = bw(*,0)/2.
    bw(*,nf-1l) = bw(*,nf-1l)/2.
    ebpwr = total(elf_b.comp1(*,fpick)*bw,2) ; trapezoidal integration
endif else begin
    elf_b = {valid:0l, $
             yaxis:elff, $
             comp1:fltarr(nt,nelf), $
             time:ss.x}
    elfbfreq = elff
    elf_b.comp1(*) = fnan
    elfbspec = elf_b.comp1
    ebpwr = fltarr(nt)
    ebpwr(*) = fnan
endelse
;
;    
if defined(hepwr) and defined(hbpwr) and  $
  (hf_e.valid or hf_b.valid) then begin
    hepwr = hepwr * epwr_units
    hbpwr = hbpwr * bpwr_units / 100.
    hpwr = float([[hepwr],[hbpwr]])
    nan_gap, hf_e.time, hpwr, min_gap
    store_data,'HF PWR',data={x:hf_e.time,y:hpwr}              
endif

if defined(lepwr) and defined(lbpwr) and $
  (vlf_e.valid or vlf_b.valid) then begin
    lepwr = lepwr * epwr_units
    lbpwr = lbpwr * bpwr_units / 100.
    lpwr = float([[lepwr],[lbpwr]])
    nan_gap, vlf_e.time, lpwr, min_gap
    store_data,'VLF PWR',data={x:vlf_e.time,y:lpwr}
endif

if defined(eepwr) and defined(ebpwr) and $
  (elf_e.valid or elf_b.valid) then begin
    eepwr = eepwr * epwr_units
    ebpwr = ebpwr * bpwr_units / 100.
    epwr = float([[eepwr],[ebpwr]])
    nan_gap, elf_e.time, epwr, min_gap
    store_data,'ELF PWR',data={x:elf_e.time,y:epwr}
endif

if find_handle('B_model') eq 0 then begin
    tran = var_range(ss.x)
    get_fa_orbit,tran(0),tran(1),/all
endif
get_data,'B_model',data=b_model
bmag = interp(sqrt(total(b_model.y^2,2)),b_model.x,ss.x)*1.d-09 ; Tesla

wce = (em*bmag/twopi)/1000.     ; electron cyclotron, kHz
store_data,'w_ce',data={x:ss.x,y:wce},dlimit={colors:[bcolor],thick:1}
wcp = ((em/mi_me)*bmag/twopi)/1000. ; proton cyclotron, kHz
store_data,'w_cp',data={x:ss.x,y:wcp},dlimit={colors:[bcolor],thick:1}

tplot_names,names = new_names
nnew = n_elements(new_names)
if nnew gt nold then begin
    new_names = new_names(nold:nnew-1l)
endif else begin
    new_names = ''
endelse
;
; store data for cdf...place arrays of nans in spots  where data are
; not valid. 
;
if not defined(nt) then nt = 1L

if find_handle('fields_modebar') ne 0 then begin
    get_data,'fields_modebar',data=mbar
    modebar = mbar.y
    vmbar = mbar.v
    xmbar = mbar.x
endif else begin
    mbar = {x:ss.x,y:bytarr(n_elements(ss.x),3),v:[0,1,2]}
endelse

cdfout0 = {time:ss.x(0),  $
           hf_e_spec:reform(hfespec(0,*)), $
           vlf_e_spec:reform(vlfespec(0,*)), $
           elf_e_spec:reform(elfespec(0,*)), $
           hf_b_spec:reform(hfbspec(0,*)), $
           vlf_b_spec:reform(vlfbspec(0,*)),  $
           elf_b_spec:reform(elfbspec(0,*)), $
           hf_pwr:reform(hpwr(0,*)),  $
           vlf_pwr:reform(lpwr(0,*)), $
           elf_pwr:reform(epwr(0,*)), $
           modebar:reform(modebar(0,*))}


cdfnv = {  hf_e_freq:hfefreq,  $
           vlf_e_freq:vlfefreq,  $
           elf_e_freq:elfefreq, $
           hf_b_freq:hfbfreq, $
           vlf_b_freq:vlfbfreq,  $
           elf_b_freq:elfbfreq, $
           vmbar:vmbar}

nfhfe = n_elements(hfefreq)
nfvle = n_elements(vlfefreq)
nfele = n_elements(elfefreq)
nfhfb = n_elements(hfbfreq)
nfvlb = n_elements(vlfbfreq)
nfelb = n_elements(elfbfreq)
nvmbar = n_elements(vmbar)
npwr = 2

cdfout = replicate(cdfout0,nt)
cdfout(*).time		 = ss.x
cdfout(*).hf_e_spec	 = reform(transpose(hfespec),nfhfe,nt,/overwrite)
cdfout(*).vlf_e_spec 	 = reform(transpose(vlfespec),nfvle,nt,/overwrite)
cdfout(*).elf_e_spec 	 = reform(transpose(elfespec),nfele,nt,/overwrite)
cdfout(*).hf_b_spec	 = reform(transpose(hfbspec),nfhfb,nt,/overwrite)
cdfout(*).vlf_b_spec	 = reform(transpose(vlfbspec),nfvlb,nt,/overwrite)
cdfout(*).elf_b_spec	 = reform(transpose(elfbspec),nfelb,nt,/overwrite)
cdfout(*).hf_pwr	 = reform(transpose(hpwr),npwr,nt,/overwrite)
cdfout(*).vlf_pwr	 = reform(transpose(lpwr),npwr,nt,/overwrite)
cdfout(*).elf_pwr	 = reform(transpose(epwr),npwr,nt,/overwrite)
cdfout(*).modebar	 = reform(transpose(modebar),nvmbar,nt,/overwrite)

is_nan =  ((finite(lpwr[*,0]) eq 0) and (finite(hpwr[*,0]) eq 0) and $
           (finite(lpwr[*,1]) eq 0) and (finite(hpwr[*,1]) eq 0))

this = lindgen(nt-2l) + 1L
prev = this - 1L
next = this - 2L
cdfpick = this[where((is_nan[this] eq 0) or  $
                     ((is_nan[next] eq 0) and (is_nan[this] eq 1)) or $
                     ((is_nan[prev] eq 0) and (is_nan[this] eq 1)))]
if is_nan[0] eq 0 then cdfpick = [0,cdfpick]
if is_nan[nt-1l] eq 0 then cdfpick = [cdfpick,nt-1l]

cdfout = cdfout(cdfpick)

store_data,'ac_cdf',data = {vary:cdfout,novary:cdfnv, $
                            tv:tag_names(cdfout0), $
                            tnv:tag_names(cdfnv)}

catch,/cancel

return,new_names

end



