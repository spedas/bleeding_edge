;--------------------------------------------------------------------
; PSP SPAN Crib
; 
; Currently this holds all the scrap pieces from calibration / instrument development, which will get moved
; Also includes a log of the calibration files and instructions for processing them
; 
; In the future this will include instructions for looking at flight data:  IN PROG
; 
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-01-29 16:17:12 -0800 (Tue, 29 Jan 2019) $
; $LastChangedRevision: 26514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_span_crib.pro $
;--------------------------------------------------------------------

; BASIC STEPS TO LOOKING AT DATA
; 
; Notes on Data Names:
; 
;   SPAN-E produces two products for data taken during the same 
;   time interval: a "P0" and a "P1" packet. The P0 packet will 
;   always be a higher-dimension product than the P1 packet. By
;   default, P0 is a 16X32X8 3D spectrum, and P1 is a 32 reduced 
;   energy spectrum. 
;   
;   SPAN-E also produces Archive and Survey data - expect the
;   Survey data all the time during encounter. Archive is few 
;   and far between since it's high rate data and takes up a lot
;   of downlink to pull from the spacecraft. 
;   
;   The last thing you need to know is that SPAN-E alternates
;   every other accumulation period sweeping either over the 
;   "Full" range of energies and deflectors, or a "Targeted" 
;   range where the signal is at a maximum.
;   
;   Therefore, when you look at the science data from SPAN-E, 
;   you can pull a "Survey, Full, 3D" distribution by calling
;   
;   IDL> tplot_names, '*sp[a,b]*SF0*SPEC*
;   
;   And the slices through that distribution will be called.
;   
;   Enjoy!
;   
;   



pro spp_swp_span_download_files,trange=trange

pathname = 'psp/data/sci/
L2_prefix='psp/data/sci/sweap/'
L2_fileformat = 'psp/data/sci/sweap/SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_*_YYYYMMDD_v??.cdf'

spxs = ['spa','spb']
types = ['sf0','sf1','st1','st0']   ; add archive when available
tr = timerange(trange)

foreach type,types do begin
  foreach spx, spxs do begin
    fileformat = str_sub(L2_fileformat,'SP?', spx)              ; instrument string substitution
    fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
    L2_files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix)
  endforeach
endforeach

end


pro spp_swp_span_load,spxs=spxs,types=types,trange=trange,no_load=no_load

  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if 0 then begin
    spxs = orderedhash()
    spxs['spa'] = list('sf0','sf1','st1','st0')
    spxs['spb'] = spxs['spa']
    spxs['spi'] = list('sf20','sf10')
    spxs['spc'] = list('L2i')    
  endif
  prefix = 'psp/data/sci/sweap/'
  
  if ~keyword_set(stypes) then stypes = ['sf0','sf1','st1','st0']   ; add archive when available
  tr = timerange(trange)
  L2_fileformat = 'SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_*_YYYYMMDD_v??.cdf'
  foreach type,types do begin
    foreach spx, spxs do begin
      fileformat = str_sub(L2_fileformat,'SP?', spx)              ; instrument string substitution
      fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
      L2_files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=prefix,verbose=2)
      if keyword_set(no_load) then continue
      cdf2tplot,l2_files
    endforeach
  endforeach

end



pro spp_swp_spx_conv_units,d3d,scale=scale,units
  dprint,'do nothing',dlevel=3
;  ap = spp_apdat('spa_sf0')
;  d3d = spp_swp_spe_3dstruct(dat[i])
;  printdat,d3d
;  for a=0,15 do begin

end


pro spplot,trange,cursor=cursor,zero=zero,lim=lim

if ~isa(lim) then begin
  ylim,lim,10,1e6,1
endif

d3d1 = spp_swp_3dstruct('spa_sf0',trange=trange,cursor=cursor)
wi,1
wshow,1
spec3d,d3d1,lim=lim,/phi

wi,2
wshow,2
plot3d_new,d3d1,zero=zero

d3d2 = spp_swp_3dstruct('spb_sf0',trange=trange)
wi,3,/wshow
spec3d,d3d2,lim=lim,/phi
wi,4,/wshow
plot3d_new,d3d2,zero=zero
timebar,trange

wshow,2
wshow,4
wshow,1
wshow,3
;wshow,4


end


if 0 then begin
  timespan,'2018 10 2',70
  spp_swp_ssr_makefile
  spp_swp_spe_make_l2 
  spp_swp_spi_make_l2 
endif


if 0 then begin
  
  tplot_options,'datagap',7200*2
  spp_swp_tplot,/setlim
  spp_swp_tplot,'swem2'
  spp_swp_tplot,'sa_sum'
  spp_swp_tplot,'sb_sum'
  spp_swp_tplot,'si_rate1',/setlim
  
  tplot,/add,'spp_spi_SF20_NRG_SPEC'
endif



if 0 then begin
  loadct2,43
  spp_swp_spc_load
  zlim,'psp_swp_spc_l2i_diff_charge_flux_density',1,50,1
  
  spp_swp_spe_load
  zlim,'psp_swp_sp[ab]_*EFLUX',100,1e4
  
;  spp_swp_tplot,setlim=2
  tplot_options,'datagap',7200.*3
  
  zlim,'spp_sp[ab]_SF0_NRG_SPEC',10,1e5,1
  
  
  tplot,'spp_spi_rates_VALID_CNTS spp_spi_SF23_NRG_SPEC spp_spi_SF22_NRG_SPEC spp_spi_SF21_NRG_SPEC spp_spi_SF20_NRG_SPEC psp_swp_spc_l2i_diff_charge_flux_density',/rev
  
  tplot,'spp_sp[ab]_SF0_NRG_SPEC',/add
  
  tplot,'psp*EFLUX',/add
  
  timespan,['2018 10 1','2018 12 10']
  tplot
endif



if 0 then begin
  !p.charsize=1.6
  set_plot,'z'
  init_devices,colort=43
  device,set_res=[4000,1000] 
  init_devices,colorta = 43
  tplot, trange = ['2018 8 8','2018 12 14']
  timebar,'2018 8 12'
  makepng,'ztest'
  set_plot,'x'
  init_devices,colort=43
  
  tplot
 
endif


;spp_swp_span_load,spxs='spa',types='sf0'

end

