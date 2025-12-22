;	@(#)default_ac_limits.pro	1.11	
pro default_ac_limits, SDT = sdt
;
; contains plot limits for ac quantities. This used to be in
; LOAD_AC_FIELDS, but I moved it over so the CDF stuff could use it
; too. 
;
twopi = 2.d*!dpi
jev = 1.6022d-19
em = jev/9.11d-31
mu_0 = 2.d*twopi*1.d-07
eps_0 = 8.8542d-12
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
epwr_units = 1.0d
bpwr_units = 1.0d
ecolor = byte(float(!d.n_colors) *0.6) ; red for ct 39
bcolor = byte(float(!d.n_colors) *0.9) ; green for ct 39

;epwr_lab = '!4e!3!D0!NE!E2!N/2'   ; eps_0*E^2/2
;bpwr_lab = 'B!E2!N/2!4l!3!D0!N' ; B^2/2*mu_0
epwr_lab = 'E!E2!N(V/m)!E2!N'
bpwr_lab = 'B!E2!N(nT)!E2'
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
; base 10 log of SFA limits, (V/m)^2 or (nT)^2, both per sqrt(Hz). 
;
sfa_emin = -15.
sfa_emax = -7.
sfa_bmin = -11.
sfa_bmax = -5.
;
; base 10 log of DSP limits, (V/m)^2 or (nT)^2, both per sqrt(Hz). 
;
dsp_emin = -13.
dsp_emax = -3.
dsp_bmin = -15.
dsp_bmax = -9.
;
; base 10 log of DSP limits, (V/m)^2 or (nT)^2, both per sqrt(Hz), for
; ELF band.
;
elf_emin = -11
elf_emax = -1.
elf_bmin = -13.
elf_bmax = -7.


ybins = 64                      ; number of frequency bins

if keyword_set(sdt) then begin
    hife = 'HF E'   
    vlfe = 'VLF E'  
    elfe = 'ELF E'  
    hifb = 'HF B'   
    vlfb = 'VLF B'  
    elfb = 'ELF B'  
    hpwr = 'HF PWR' 
    vpwr = 'VLF PWR'
    epwr = 'ELF PWR'
    mbar = 'fields_modebar'
endif else begin
    hife = 'HF_E_SPEC'              
    vlfe = 'VLF_E_SPEC'            
    elfe = 'ELF_E_SPEC'            
    hifb = 'HF_B_SPEC'             
    vlfb = 'VLF_B_SPEC'            
    elfb = 'ELF_B_SPEC'            
    hpwr = 'HF_PWR'           
    vpwr = 'VLF_PWR'          
    epwr = 'ELF_PWR'
    mbar = 'MODEBAR'
endelse

if find_handle(hife) ne 0 then begin
    store_data,hife, $
      dlimit={spec:1,ystyle:1,zrange:[sfa_emin,sfa_emax], $
              ytitle:'HF E !C!C kHz',ylog:1, $
             ztitle:'log!C!C(V/m)!E2!N/Hz'}
endif

if find_handle(vlfe) ne 0 then begin
    store_data,vlfe, $
      dlimit={spec:1, ytitle:'VLF E !C!C kHz',ystyle:1, $
             zrange:[dsp_emin,dsp_emax],ylog:1, $
             ztitle:'log!C!C(V/m)!E2!N/Hz'}
endif

if find_handle(elfe) ne 0 then begin
    store_data,elfe, $
      dlimit={spec:1, ytitle:'ELF E !C!C kHz',ystyle:1, $
             zrange:[elf_emin,elf_emax],ylog:1, $
             ztitle:'log!C!C(V/m)!E2!N/Hz'}
endif

if find_handle(hifb) ne 0 then begin
    store_data,hifb, $
      dlimit={spec:1,ystyle:1,zrange:[sfa_bmin,sfa_bmax], $
             ytitle:'HF B !C!C kHz',ylog:1, $
             ztitle:'log!C!CnT!E2!N/Hz'}
endif

if find_handle(vlfb) ne 0 then begin
    store_data,vlfb, $
      dlimit={spec:1,ytitle:'VLF B !C!C kHz',ystyle:1, $
             zrange:[dsp_bmin,dsp_bmax],ylog:1, $
             ztitle:'log!C!CnT!E2!N/Hz'}
endif

if find_handle(elfb) ne 0 then begin
    store_data,elfb, $
      dlimit={spec:1, ytitle:'ELF B !C!C kHz',ystyle:1, $
             zrange:[elf_bmin,elf_bmax],ylog:1, $
             ztitle:'log!C!CnT!E2!N/Hz'}
endif

if find_handle(hpwr) ne 0 then begin
    store_data,hpwr, $
      dlimit={colors:[ecolor,bcolor],panel_size:0.5,yticks:1, $
              ylog:1, $
              ytitle:'HF',yrange:[1.e-12,1.e-07], $
              ytickv:[1.e-12,1.e-07],ytickname:['10!E-12!N','10!E-7!N'], $
              yname2:['10!E-10!N','10!E-5!N']}              
endif

if find_handle(vpwr) ne 0 then begin
    vpyrange = [1.e-15,1.e-05]
    ratio = vpyrange(1)/vpyrange(0)
    labpos = vpyrange(0)*(ratio^[0.2,0.8])
    store_data,vpwr, $
      dlimit={colors:[ecolor,bcolor],panel_size:0.5,yticks:1, $
              labels:[epwr_lab,bpwr_lab],labflag:0, $
              labpos:[labpos],ylog:1, $
              ytitle:'VLF',yrange:vpyrange, $
              ytickv:vpyrange,ytickname:['10!E-15!N','10!E-5!N'], $
              yname2:['10!E-13!N','10!E-7!N']}
endif

if find_handle(epwr) ne 0 then begin
    store_data,epwr, $
      dlimit={colors:[ecolor,bcolor],panel_size:0.5,yticks:1, $
              ylog:1, $
              ytitle:'ELF',yrange:[1.e-10,1.e-02], $
              ytickv:[1.e-10,1.e-02],ytickname:['10!E-10!N','10!E-2!N'], $
              yname2:['10!E-8!N','10!E0!N']}
endif

if find_handle('w_ce') ne 0 then begin
    store_data,'w_ce',dlimit={colors:[bcolor],thick:1}
endif

if find_handle('w_cp') ne 0 then begin
    store_data,'w_cp',dlimit={colors:[bcolor],thick:1}
endif

if find_handle(mbar) ne 0 then begin
    get_data,mbar,data=mbardat
    store_data,mbar, $
      dlimit={ystyle:1,panel_size:0.17, $
              yticks:1,ytickv:[0,1],ytickname:[' ',' '], $
              ytitle:' ',no_color_scale:1,y_no_interp:1, $
              spec:1, colors:[255b,127b],$
              zrange:[0,255],ticklen:0,x_no_interp:1}
endif 

return
end



