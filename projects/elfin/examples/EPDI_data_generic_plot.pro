;
; Loads EPDI, and EPDE (when available) and performs pitch angle
; determination and plotting of energy and pitch angle spectra,
; Including precipitating and trapped spectra separately, along with their ratio.
;
pro epdi_data_generic_plot
;
  tplot_options, 'xmargin', [15,9]
;  cwdirname='C:\My Documents\ucla\Elfin\science\EPDI'
;  cwd,cwdirname
;
;  tstart='2021-10-20/07:43'   ;
;  tend='2021-10-20/07:55'
;
;  tstart='2022-01-14/23:00'   ;
;  tend='2022-01-15/23:00'
;
;tstart='2021-10-13/02:43'   ;
;tend='2021-10-13/03:03'
;
;  tstart='2022-03-12/00:00'   ;
;  tend='2022-03-12/24:00'
;
;  tstart='2022-04-02/00:00'   ;
;  tend='2022-04-02/24:00'
;  
;  tstart='2022-05-12/00:00'   ;
;  tend='2022-05-16/24:00'
;
;  tstart='2022-06-14/00:00'   ;
;  tend='2022-06-14/24:00'
;
;  tstart='2022-06-23/00:00'   ;
; tend='2022-06-23/24:00'
;
  tstart='2022-06-23/00:00'   ;
  tend='2022-06-23/24:00'
;
  bird='a'

; SET Time Range
timeduration=time_double(tend)-time_double(tstart)
timespan,tstart,timeduration,/seconds

; LOAD position and attitude
elf_load_state, probes=[bird]
;
stop

; LOAD epde and calculation pitch angles
elf_load_epd, probes=bird, datatype='pef' ; DEFAULT UNITS ARE NFLUX
elf_getspec,probe=bird,species='e',type='nflux' ; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
; LOAD epdi and calculation pitch angles
elf_load_epd, probes=bird, datatype='pif' ; DEFAULT UNITS ARE NFLUX
elf_getspec,probe=bird,species='i',type='nflux',enerbins=[[0,1],[2,3],[4,6],[7,15]] ; == [50,120],[120,210],[210,450],[>450]
;options,'el?_p?f_nflux',spec=0
;elf_load_epd, probes=bird, datatype='pef', type='raw' ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
;elf_load_epd, probes=bird, datatype='pif', type='raw' ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
;options,'el?_p?f_raw',spec=0
;
stop
copy_data,'el'+bird+'_pef_en_spec2plot_para','elx_pef_en_spec2plot_para'
copy_data,'el'+bird+'_pef_en_spec2plot_perp','elx_pef_en_spec2plot_perp'
copy_data,'el'+bird+'_pef_en_spec2plot_anti','elx_pef_en_spec2plot_anti'
copy_data,'el'+bird+'_pif_en_spec2plot_para','elx_pif_en_spec2plot_para'
copy_data,'el'+bird+'_pif_en_spec2plot_perp','elx_pif_en_spec2plot_perp'
copy_data,'el'+bird+'_pif_en_spec2plot_anti','elx_pif_en_spec2plot_anti'
;
calc," 'elx_pef_en_spec2plot_paraovrperp' = 'elx_pef_en_spec2plot_para' / 'elx_pef_en_spec2plot_perp' "
calc," 'elx_pef_en_spec2plot_antiovrperp' = 'elx_pef_en_spec2plot_anti' / 'elx_pef_en_spec2plot_perp' "
calc," 'elx_pif_en_spec2plot_paraovrperp' = 'elx_pif_en_spec2plot_para' / 'elx_pif_en_spec2plot_perp' "
calc," 'elx_pif_en_spec2plot_antiovrperp' = 'elx_pif_en_spec2plot_anti' / 'elx_pif_en_spec2plot_perp' "
;
tplot,'el'+bird+'*pef*omni *pef*antiovrperp el'+bird+$
      '*pif*omni *pif*antiovrperp el'+bird+'*pef*ch?LC el'+bird+'*pif*ch?LC'
tplot_apply_databar
;
stop
;
plotname=!elf.local_data_dir+'EPDI_data_generic_plot_v0'
makepng, plotname
print, 'Plot created: '+plotname
;
end
