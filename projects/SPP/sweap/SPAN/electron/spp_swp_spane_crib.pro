;--------------------------------------------------------------------
; PSP SPAN-E Crib
; foo
; 
; $Author: phyllisw2 $
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2017-09-28 11:55:33 -0700 (Thu, 28 Sep 2017) $
; $LastChangedRevision: 24055 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spane_crib.pro $
;--------------------------------------------------------------------



pro misc2
  hkp= spp_apdat('36E'x)
  s=hkp.data.array
  
  naan = !values.f_nan
 ; sgn= fix(s.mram_wr_addr_hi eq 1) - fix(s.mram_wr_addr_hi eq 2)
sgns = [!values.f_nan,1.,-1., !values.f_nan]
  sgn = sgns[0 > s.mram_wr_addr_hi < 3]
  def = s.mram_wr_addr * sgn
;  def = s.mram_wr_addr *  sign(s.adc_vmon_def1 - s.adc_vmon_def2)
  store_data,'DEF1-DEF2',s.time,float(def)

end



pro spane_center_energy,tranges=tt,emid=emid,ntot=ntot

  channels = [3,2,1,0,8,9,10,11,12,13,14,15,7,6,5,4]
  rotation = [-108.,-84,-60,-36,-21,-15,-9,-3,3.,9,15,21,36,60,84,108]
  emid = replicate(0.,16)
  ntot = replicate(0.,16)
  xlim,lim,4500,5500
  
  for i=0,15 do begin
    trange=tt[*,i]
    scat_plot,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange,lim=lim,xvalue=x,yvalue=y,ydimen= channels[i]
    ntot[i] = total(y)
    emid[i] = total(x*y)/total(y)
  endfor

;  Emid = [5070, 5107, 5112,

end


pro spane_deflector_scan,tranges = trange
    scat_plot,/swap_interp,'DEF1-DEF2','spp_spane_spec_CNTS2',trange=trange,lim=lim,xvalue=x,yvalue=y,ydimen= 4
end


pro spane_threshold_scan,tranges=trange,lim=lim   ;now obsolete
  swap_interp=0
  xlim,lim,0,512
  ylim,lim,10,10000,1
  options,lim,psym=4  
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,1],lim=lim,xvalue=x,yvalue=y,ydimen= 4;,color=4
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,0],lim=lim,xvalue=x,yvalue=y,ydimen= 4,color=6,/overplot
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,2],lim=lim,xvalue=x,yvalue=y,ydimen= 4,color=2,/overplot
end


pro spane_threshold_scan_phd,tranges=trange,lim=lim
  
  if ~keyword_set(trange) then ctime,trange,npo=2
  swap_interp=0
  xlim,lim,0,550
  ylim,lim,10,5000,1
  options,lim,psym=4
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_p1_CNTS',trange=trange,lim=lim,xvalue=dac,yvalue=cnts,ydimen= 4;,color=4
  range = [80,500]
  xp = dgen(8,range=range)
  yp = xp*0+500
  xv = dgen()
  !p.multi = [0,1,2]
  yv = spline_fit3(xv,xp,yp,param=p,/ylog)
  fit,dac,cnts,param=p
  pf,p,/over
 ; wi,2
  plot,dac,cnts,psym=4,xtitle='Threshold DAC level',ytitle='Counts'
  ;pf,p,/over
  plt1 = get_plot_state()
  xv = dgen(range=range)
;  wi,3
  plot,xv,-deriv(xv,func(xv,param=p)),xtitle='Threshold DAC level',ytitle='PHD'
  plt2= get_plot_state()
  
end




f= spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/z320/20160331_125002_/PTP_data.dat' )
f= spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/PTP_data.dat' )


;files = spp_swp_spane_functiontest1_files()

files = f

spp_swp_startup



spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160729_150358_FLTAE_digital/PTP_data.dat' )

spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/PTP_data.dat' )
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/GSE_all_msg.dat' )
spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160802_081922_flightToFlight_contd2/PTP_data.dat' )
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160802_081922_flightToFlight_contd2/GSE_all_msg.dat' )


spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160727_115654_large_packet_test/PTP_data.dat')
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160727_115654_large_packet_test/GSE_all_msg.dat')

spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160805_125639_ramp_up/GSE_all_msg.dat')  ; Ion ramp in which SWEMULATOR reset?
spp_ptp_file_read, spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-3/20160920_084426_BfltBigCalChamberEAscan/PTP_data.dat.gz')
spp_ptp_file_read, spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-3/20160923_165136_BfltContinuedPHDscan/PTP_data.dat')




;   spane B flight CO pre conformal coat
files = spp_file_retrieve(/elec,/cal,trange=['2016 9 28 12','2016 9 29 8']) 




 trange =  '2016 10 '+ ['18/04','19/22']   ; SPANE - A flght in Cal chamber:  MCP test; NOT PREENV CAL
 
 ; SPANAe Pre Env Cal data
 trange = '2016 11 '+ ['18/16','18/18']  ; SPAN-Ae FM preEnv Cal 'spane_ph_thresh_scan' ; incomplete, need tony to parse file?
 trange = '2016 11 '+ ['18/17','18/18']  ; SPAN-Ae FM preEnv Cal 'spane_thresh_scan' (No MCP)
 trange = '2016 11 '+ ['18/21','18/23']  ; SPAN-Ae FM postcoat w/ attenuator: Full rotation (angles incorrect, ROT not zeroed)
 trange = '2016 11 '+ ['19/00','19/02']  ; SPAN-Ae FM quick EA scan ; no egun values present :(
 trange = '2016 11 '+ ['19/02','19/04']  ; SPAN-Ae FM rotation @ 2degrees Yaw, which has been shown to be the beam emit angle
 trange = '2016 11 '+ ['20/00','20/07']  ; SPAN-Ae FM thresh & MCP scan @ 2degrees Yaw named SPANAe_preEnvCal_mcpTest.png
 trange = '2016 11 '+ ['21/01','21/23']  ; SPAN-Ae FM deflector test, ;skipped anode 11? ;MRAM (indicates Def dac) does not indicate correctly. will require fixes in the future
 trange = '2016 11 '+ ['21/23','21/24']  ; SPAN-Ae FM full rotation: half @ 0DegYaw, half at 2DegYaw.
 trange = '2016 11 '+ ['21/23','22/02']  ; SPAN-Ae FM spoiler test
 ; currently the files cut off at 18:40 on the 23rd.
 ; SPAN-Ae pre Env Pt 2
 trange = '2016 12 '+ ['07/19','07/22'] ; SPAN-Ae FM pre-Vibe pt 2 EA scan at 1keV
 trange = '2016 12 '+ ['08/00','08/03'] ; SPAN-Ae FM pre-Vibe pt 2 EA scan at 500eV
 trange = '2016 12 '+ ['08/18','08/21'] ; SPAN-Ae FM pre-Vibe pt 2 IDL simulation replication
 trange = '2016 12 '+ ['08/23','09/01'] ; SPAN-Ae FM pre-Vibe pt 2 full dual direction rotation
 trange = '2016 12 '+ ['09/00','09/02'] ; SPAN-Ae FM pre-Vibe pt 2 Spoiler Test at 500eV
 

  

 ;;SPANB PRE VIBE CAL
 ; Note that these should be loaded as spanea
 ;NOTE NO ATTENUATOR MOTIONS.
  trange = '2016 11 '+ ['28/18','28/19'] ; SPAN-B FM FPGAcheck
  trange = '2016 11 '+ ['28/19','28/21'] ; SPAN-B FM ph thresh scan (changing pulse height on test pulser)
  trange = '2016 11 '+ ['28/20','28/21'] ; SPAN-B FM thresh scan. (changing threshold with no input but noise)
  trange = '2016 11 '+ ['28/21','29/05'] ; contains a rotation scan
  trange = '2016 11 '+ ['29/04','29/08'] ; SPAN-B FM ea quick scan - missing data for some anodes
  trange = '2016 11 '+ ['29/15','29/21'] ; SPAN-B FM mcpTest - missing data because of cable? Or maybe because of maja.
  trange = ['2016 11 29/23','2016 12 01/01'] ; SPAN-B FM deflector test - missing data because of cable.
  trange = '2016 11 '+ ['29/01','29/02'] ; SPAN-B FM rotation @ 1keV
  trange = '2016 12 '+ ['05/12','06/00']
  trange = '2016 12 '+ ['05/19','06/00'] ; SPAN-B FM IDL sim test again, after cable got fixed.
  trange = '2016 12 '+ ['06/02','06/05'] ; SPAN-B FM pre-Vibe 500eV EA scan

  trange = '2016 12 '+ ['05/19','06/00'] ; SPAN-B FM pre-Vibe sweep yaw test w/ correction of yawlin (other version is yaw only)
  trange = '2016 12 '+ ['05/23','06/02'] ; SPAN-B FM pre-Vibe low energy electrons grab
  trange = '2016 12 '+ ['06/18','06/19'] ; SPAN-B FM pre-Vibe 500eV full rotation
  trange = '2016 12 '+ ['06/18','06/20'] ; SPAN-B FM pre-Vibe 500eV Deflector test @ Anode 2
  trange = '2016 12 '+ ['06/20','06/22'] ; SPAN-B FM pre-Vibe 500eV Deflector test @ Anode 8
 
  trange = '2016 12 '+ ['02/23','03/01'] ; SPAN-B FM pre-Vibe spoiler test @ 2degrees Yaw & full rotation @ 2degrees yaw
  trange = '2016 12 '+ ['02/18','02/22'] ; SPAN-B FM pre-Vibe deflector test on anodes 14 & 15
  
 files = spp_file_retrieve(/elec,/cal,trange=trange)
 trange = '2016 12 '+ ['02/00','03/12'] ; SPAN-B FM pre-Vibe last load
 trange = '2016 12 '+ ['01/00','02/00'] ; SPAN-B FM pre-Vibe contains nothing
 
 
 ;; SPANB TBAL & cover opening Malfunction
 trange = '2016 12 '+ ['22/06','22/11'] ;tli SPAN-B FM TBAL cover opening - failure. SPANB is XX
 trange = '2016 12 '+ ['22/18','22/20'] ; SPAN-B FM TBAL cover opening - indicating open. SPANB is XX
 trange = '2016 12 '+ ['23/16','24/03'] ; SPAN-B FM TBAL temeprature data - op heater. SPANB is Cold. No science data.
 spp_ptp_file_read, spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20161223_163710_test/PTP_data.dat') ;SPANB second cycling attempt cover open
 trange = '2016 12 '+ ['28/23','29/12'] ; second attempt at opening cover; no DAG, after official TBAL. Cover opens when SPANB warms.
 files = spp_file_retrieve(/spaneb,/snout2,trange=trange)
 ;the following files are located in /spaneb, no clue why!
 trange = '2017 01 '+ ['05/00','05/01'] ; cover opening attempt semi cold - opened but after timeout.
 trange = '2017 01 '+ ['06/22','06/23'] ; second cover opening attempt at cold - opened less than timeout
 
 
 ;; SPANB TV 
 trange = '2017 01 '+ ['11/16','11/18'] ; SPAN-B FM Cover Test post tbal, pre tvac, turn on & cpt.
 trange = '2017 01 '+ ['12/18','13/05'] ; SPAN-B FM turn on and low voltage CPT
 trange = '2017 01 '+ ['13/17','14/10'] ; SPAN-B FM Anode 5 failure #1
 trange = '2017 01 '+ ['14/19','15/09'] ; SPAN-B FM Anode 5 failure #2
 
 ;; SPAN-Ae Cal chamber re-check
 trange = '2017 02 '+ ['06/00','07/00'] ; SPAN-Ae re-check after correction of MCP support structure. Ramp up and manipulations
 trange = '2017 02 '+ ['07/11','07/12'] ; SPAN-Ae rotation
 
 ;; SPAN-B Cal chamber re-check: started on Feb 13th. Instrument is noisy.
 trange = '2017 02 '+ ['13/23','14/01'] ; energy angle scan
 trange = '2017 02 '+ ['14/02','14/04'] ; energy angle scan
 trange = '2017 02 '+ ['14/04','14/06'] ; energy angle scan with attenuator
 
 
 ;; SPAN-B Cal:
 ; At some point before Feb 25th @ noon local time, maja quit recording.
 
 ;; SPAN-Ae TVAC
  ;20170221_155456_TVAC-SPAI/PTP_data.dat' name of file that contains missing SPANAe data from MAJA
 ; started on Feb 13th, ops started the 15th.
 trange = '2017 02 ' + ['15/00','16/00'] ; first op day
 trange = '2017 02 ' + ['15/17','15/18'] ; cover opening cold (~-50)
 ;SPAN-B TVAC something...
 trange = '2017 02 ' + ['18/00','19/00'] ; NOISY AS FUCK
 trange = '2017 02 ' + ['19/08','20/08'] ; still fucking noisy, what the fuck??
 trange = '2017 02 ' + ['20/08','21/08'] ; noisy until ~ 1800 on the 20th. Then it looks pretty normal.
 
 ;; SPAN-Ae TBAL
 trange = '2017 02 ' + ['26/20','27/12'] ; searching for cover open
 trange = '2017 02 ' + ['27/10','27/11'] ; when cover finally opens
 
 
 ;; SPAN-B postEnvCal
 trange = '2017 02 ' + ['26/03','26/08'] ; first EA scan at 1keV. Anode 4 is missed. data is missing on MAJA before this.
 trange = '2017 02 ' + ['26/16','27/01'] ; MCP test
 ;trange = '2017 02 ' + ['27/05', ; not an actual deflector scan - limit on yaw not set right..
 trange = '2017 02 ' + ['27/18','27/20'] ; deflector test for anode zero
 trange = '2017 02 ' + ['28/04','28/07'] ; spoiler test, attenuator out.
 trange = '2017 03 ' + ['01/17','01/19'] ; partial rotation at funky yaw + linear angle; looks like anodes 1&2 are not as well illuminated. Odd.
 trange = '2017 03 ' + ['01/18','02/02'] ; deflector test on anodes 0,4,8,12,15
 trange = '2017 03 ' + ['02/11','02/15'] ; yaw angle test, lower value got a bit scrambled.
 trange = '2017 03 ' + ['02/17','02/19'] ; rotation scan back & forth @ 1keV 2deg yaw. 5 & 9 are a bit lopsided
 trange = '2017 03 ' + ['02/19','02/22'] ; EA scan w/ attenuator out, spoiler DAC = 1024s, 1keV
 trange = '2017 03 ' + ['03/02','03/03'] ; wide scan in yaw with deflectors sweeping. Strange aliasing.
 trange = '2017 03 ' + ['03/08','03/11'] ; EA scan with attenuator out at 5keV.
 trange = '2017 03 ' + ['03/18','03/24'] ; MCP + Threshold test at 5keV.DIM

 ;; SPAN-Ae postEnvCal
 trange = ; ramp up MCPs
 ;trange = ['2017 03 28/02','2017 03 29/00']
 trange = '2017 03 ' + ['28/04','28/06'] ; CPT at HV, begins with threshold tests
 trange = '2017 03 ' + ['28/22','29/01'] ; Gun scan @ 900eV
 trange = '2017 03 ' + ['29/01','29/03'] ; rotations @ 900eV
 trange = '2017 03 ' + ['29/08','29/10'] ; spoiler test
 trange = '2017 03 ' + ['29/05','29/08'] ; EA scan
 trange = '2017 03 ' + ['29/15','29/17'] ; EA scan
 trange = '2017 03 ' + ['29/18','29/20'] ; rotation both ways
 trange = '2017 03 ' + ['29/19','29/23'] ; spoiler + rotation test (mode 2)
 trange = '2017 03 ' + ['30/01','31/01'] ; spoiler tests.
 trange = '2017 03 ' + ['31/17','31/
 trange = ['2017 03 31/01','2017 04 01/01'] ;includes rotation & yaw test
 ;trange = ['2017 03 28/02','2017 03 29/00'] ; loaded currently


;  Get recent data files:
files = spp_file_retrieve(/spanea,/cal,recent=1/24.)   ; get last 1 hour of data from server
files = spp_file_retrieve(/spanea,/cal,recent=4/24.)   ; get last 4 hours of data from server

; Read  (Load) files
spp_ptp_file_read,files


; Real time data collection:
spp_init_realtime,/spanea,/cal,/exec


tplot, 'manip*',/add
spp_swp_tplot,/setlim
spp_swp_tplot,'SE'
spp_swp_tplot,'SE_hv'
spp_swp_tplot,'SE_lv'
spp_swp_tplot,'SE'


; print information on collected data
spp_apdat_info,/print



; get SPANE-A HKP data:
hkp = spp_apdat('36e'x)

hkp.help

hkp.print

printdat, hkp.strct

printdat, hkp.data      ; return the 

printdat, hkp.data.array   ; return a copy of the data array

printdat, hkp.data.size    ; return the number of elements in the data array

printdat, hkp.data.typename   ; return the typename of the data array 

printdat,  hkp.data.array[-1]  ; return the current last element of the data array










tplot,'*CNTS *DCMD_REC *VMON_MCP *VMON_RAW *ACC*'


if 0 then begin
  tplot,'spp_spane_?_ar_????_p1*',/names
  
  
  
  
endif





if 1 then begin
  options,'spp_spane_spec_CNTS',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS1',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS2',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
endif else begin
  options,'spp_spane_spec_CNTS',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS1',spec=1,yrange=[-1,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS2',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
endelse


if 0 then begin
  tplot,'spp_spani_hkp_HEMI_CDI spp_manip_MROTPOS spp_spani_tof_TOF APID spp_spani_rates_VALID_CNTS
  tplot,'spp_spani_ar_full_p0_m?_*_SPEC2'
  tplot,'spp_spani_ar_full_p1_m?_*_SPEC2'
  
  
  store_data,'ALL_C',data='spp_*_C'
  store_data,'ALL_V',data='spp_*_V'
  store_data,'ALL_ERR_CNT',data='spp_*_ERR_CNT'
  store_data,'ALL_ERR',data='spp_*_ERR'
  store_data,'ALL_CMD_CNT',data='spp_*_CMDS_*'
  !y.style=3
  tplot_options,'ynozero',1
  
  tplot,'APID'
  tplot,'spp_*_TEMPS ALL_? *NYS*',/add
  tplot,'ALL_ERR_CNT',/add
  tplot,'ALL_ERR',/add
  tplot,'ALL_CMD_CNT',/add
  tplot,/add,'spp*hkp*ERR_CNT'
  tplot,/add,'spp_*_C'
;  tplot/
  
endif




end

