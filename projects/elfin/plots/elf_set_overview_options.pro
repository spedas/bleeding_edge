; PROCEDURE:
;         elf_set_overview_options
;
; PURPOSE:
;         This routine takes the spectral data displayed in the ELFIN summary plots
;         and sets up the 
;
; KEYWORDS:
;         trange: start time and stop time to be used for the plot
;                (format can be time string ['2020-03-20','2020-03-21']
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         no_switch: obsolete keyword that was used early on to not switch out the energy bin values
;                    this should be removed from this routine and from epde_plot_overviews
;
; OUTPUT:
;
; EXAMPLE:
;         elf_update_data_availability_table, '2020-03-20', probe='a', instrument='epd'
;
;-
pro elf_set_overview_options, probe=probe, trange=trange, no_switch=no_switch

   if ~keyword_set(probe) then probe='a' else probe=probe

   if ~keyword_set(no_switch) then begin
     ; make sure that the energy bins are set
     get_data, 'el'+probe+'_pef_nflux', data=pef_nflux, dlimits=pef_nflux_dl, limits=pef_nflux_l
     get_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     if pef_nflux.v[0] LT omni.v[0] then omni.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     get_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     if pef_nflux.v[0] LT anti.v[0] then anti.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     get_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     if pef_nflux.v[0] LT perp.v[0] then perp.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     get_data, 'el'+probe+'_pef_en_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
     if pef_nflux.v[0] LT para.v[0] then para.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT omni.v[0] then begin
      omni.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT anti.v[0] then begin
      anti.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT perp.v[0] then begin
      perp.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
      if size(omni,/type) EQ 8 && pef_nflux.v[0] LT para.v[0] then begin
        para.v[0]=pef_nflux.v[0]
        store_data, 'el'+probe+'_pef_en_reg_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
      endif
   endif
 
   ; set up titles  
   options, 'el'+probe+'_pef_en_spec2plot_omni', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_omni', 'ztitle','nflux' 
   options, 'el'+probe+'_pef_en_spec2plot_omni', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_anti', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_anti', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_spec2plot_anti', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_perp', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_perp', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_spec2plot_perp', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_para', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_para', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_spec2plot_para', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', 'ztitle','nflux'
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', 'ysubtitle','[keV]'
   
   ; set up zlimits for the spectral data
   ;options, 'el'+probe+'_bt89_sm_NED', charsize=.8
   ;options, 'el'+probe+'_bt89_sm_NED', colors=[251, 155, 252]
   zlim, 'el'+probe+'_pef_en_spec2plot_omni', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_spec2plot_anti', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_spec2plot_perp', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_spec2plot_para', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 2.e3, 2.e7
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch1LC',1.e3, 4.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 1.e2, 1.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 1.e1, 2.e4
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_omni', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_anti', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_perp', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_para', 1.e1, 2.e7
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 2.e3, 2.e7
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 1.e3, 4.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 1.e2, 1.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 1.e1, 2.e4

   options, 'el'+probe+'_pef_en_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_para',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_para',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC',zstyle=1

   options, 'el'+probe+'_pef_en_spec2plot_omni',charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_anti',charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_perp',charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_para',charsize=.9
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC',charsize=.9
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC',charsize=.9
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC',charsize=.9
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC',charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni',charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti',charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp',charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_para',charsize=.9
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',charsize=.9
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',charsize=.9
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC',charsize=.9
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC',charsize=.9

   ; set up y and z titles
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 'ztitle','nflux'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC', 'ztitle','nflux'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ztitle','nflux'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ztitle','nflux'  
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ztitle','nflux'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ztitle','nflux'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 'ztitle','nflux'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 'ztitle','nflux'

   ; set the range for the z axis
   options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','nflux'
   options,'el?_p?f_pa*spec2plot_ch0LC*','zrange',[2e3,2e7]
   options,'el?_p?f_pa*spec2plot_ch1LC*','zrange',[1e3,4e6]
   options,'el?_p?f_pa*spec2plot_ch2LC*','zrange',[1e2,1e6]
   options,'el?_p?f_pa*spec2plot_ch3LC*','zrange',[1e1,2e4]
   options,'el?_p?f_pa*spec2plot_ch0LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch1LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch2LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch3LC*','zstyle',1
   options,'el?_p?f_en_spec2plot*','zrange',[1e1,2e7]
   options,'el?_p?f_en_spec2plot*','zstyle',1
   options,'el?_p?f_en_reg_spec2plot*','zrange',[1e1,2e7]
   options,'el?_p?f_en_reg_spec2plot*','zstyle',1

   options, 'el'+probe+'_pef_en_spec2plot_omni','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_anti','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_perp','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_para','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_para','extend_edges',1

end
