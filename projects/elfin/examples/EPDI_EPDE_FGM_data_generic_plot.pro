;
; Loads EPDI, and EPDE (when available) and performs pitch angle
; determination and plotting of energy and pitch angle spectra,
; Including precipitating and trapped spectra separately, along with their ratio.
;
pro epdi_epde_fgm_data_generic_plot
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
  tstart='2022-06-25/08:00'   ;
  tend='2022-06-25/10:00'
;
  bird='a'
;
; for FGM inputs only (temporary)
tstart_fsp='2022-06-25/09:29:00'
tend_fsp='2022-06-25/09:35:40'
sclet=bird
;
;
timeduration=time_double(tend)-time_double(tstart)
timespan,tstart,timeduration,/seconds
tr=timerange()
;
elf_load_state, probes=[bird], trange=tr
;
;;    ============================
;;     read calibrated fgm data (this part will be replaced by elf_load_fgm.pro)
;;    ============================
; read elx_fgs_fsp_dmxl
;fspfiledir='C:\My Documents\ucla\Elfin\MAG\CAL_12_params\FSP_Science_Product\second_data_set_released\'
;filename=strmid(tstart_fsp,0,4)+strmid(tstart_fsp,5,2)+strmid(tstart_fsp,8,2)+'_'+strmid(tstart_fsp,11,2)+strmid(tstart_fsp,14,2)+'_'+strmid(tend_fsp,11,2)+strmid(tend_fsp,14,2)
;ascii2tplot, files=fspfiledir+filename+'_ela_fgs_fsp_dmxl.txt', format_type=0, $
;  tformat='YYYY-MM-DD/hh:mm:ss', tvar_column=[0,1,2],$
;  tvarnames='elx_fgs_fsp_dmxl', delimiter=' '
;options,'elx_fgs_fsp_dmxl',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1

; read elx_fgs_fsp_igrf_dmxl
;ascii2tplot, files=fspfiledir+filename+'_ela_fgs_igrf_dmxl.txt', format_type=0, $
;  tformat='YYYY-MM-DD/hh:mm:ss', tvar_column=[0,1,2],$
;  tvarnames='elx_fgs_fsp_igrf_dmxl', delimiter=' '
;options,'elx_fgs_fsp_igrf_dmxl',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1
;
;calc," 'elx_fgs_res_dmxl' ='elx_fgs_fsp_dmxl' - 'elx_fgs_fsp_igrf_dmxl' "
;
;
elf_load_fgm, probes=bird, trange=tr, /get_support_data
stop
copy_data, 'ela_fgs_fsp_res_dmxl', 'elx_fgs_res_dmxl'
tplot,'elx_fgs_res_dmxl'
get_data,'elx_fgs_res_dmxl',data=elx_fgs_res_dmxl,dl=fgsdl,lim=fgslim
elx_fgs_res_dmxl_det=elx_fgs_res_dmxl
slopex=(elx_fgs_res_dmxl_det.y[-1,0]-elx_fgs_res_dmxl_det.y[0,0])/(elx_fgs_res_dmxl_det.x[-1]-elx_fgs_res_dmxl_det.x[0])
elx_fgs_res_dmxl_det.y[*,0]=elx_fgs_res_dmxl_det.y[*,0]-elx_fgs_res_dmxl_det.y[0,0]-(elx_fgs_res_dmxl_det.x[*]-elx_fgs_res_dmxl_det.x[0])*slopex
slopey=(elx_fgs_res_dmxl_det.y[-1,1]-elx_fgs_res_dmxl_det.y[0,1])/(elx_fgs_res_dmxl_det.x[-1]-elx_fgs_res_dmxl_det.x[0])
elx_fgs_res_dmxl_det.y[*,1]=elx_fgs_res_dmxl_det.y[*,1]-elx_fgs_res_dmxl_det.y[0,1]-(elx_fgs_res_dmxl_det.x[*]-elx_fgs_res_dmxl_det.x[0])*slopey
store_data,'elx_fgs_res_dmxl_detxy',data=elx_fgs_res_dmxl_det,dl=fgsdl,lim=fgslim
slopez=(elx_fgs_res_dmxl_det.y[-1,2]-elx_fgs_res_dmxl_det.y[0,2])/(elx_fgs_res_dmxl_det.x[-1]-elx_fgs_res_dmxl_det.x[0])
elx_fgs_res_dmxl_det.y[*,2]=elx_fgs_res_dmxl_det.y[*,2]-elx_fgs_res_dmxl_det.y[0,2]-(elx_fgs_res_dmxl_det.x[*]-elx_fgs_res_dmxl_det.x[0])*slopez
store_data,'elx_fgs_res_dmxl_detxyz',data=elx_fgs_res_dmxl_det,dl=fgsdl,lim=fgslim
;
elf_load_epd, probes=bird, datatype='pef' ; DEFAULT UNITS ARE NFLUX
elf_getspec,probe=bird,species='e',type='nflux' ; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
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
zlim,'elx_pif_en_spec2plot_antiovrperp',0.05,3,1
;
options,'*_fgs_*','databar',0.
tplot,'*_fgs_res_dmxl_detxy *_fgs_res_dmxl_detxyz *pef*omni *pef*antiovrperp *pif*omni *pif*antiovrperp *pef*ch[0,3]LC *pif*ch[0,2]LC'
tplot_apply_databar
;
stop
;
plotname=!elf.local_data_dir+'epdi_epde_fgm_data_generic_plot_v0'
makepng,plotname
;
end
