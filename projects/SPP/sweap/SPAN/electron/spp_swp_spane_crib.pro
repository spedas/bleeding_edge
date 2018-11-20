;--------------------------------------------------------------------
; PSP SPAN-E Crib
; 
; Currently this holds all the scrap pieces from calibration / instrument development, which will get moved
; Also includes a log of the calibration files and instructions for processing them
; 
; In the future this will include instructions for looking at flight data:  IN PROG
; 
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-11-06 14:43:56 -0800 (Tue, 06 Nov 2018) $
; $LastChangedRevision: 26058 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spane_crib.pro $
;--------------------------------------------------------------------

; BASIC STEPS TO LOOKING AT DATA
; 
; 1: Choose & set a time range. 
;     Format: trange = ['YYYY MM DD/HH','YYYY MM DD/HH']
;                                 OR
;              trange = 'YYYY MM' + ['DD/HH', 'DD/HH']    ; use if the month is the same for start/end days
;
; 2: Set which files to download.
;     2a: Calibration Data
;       Format: files = spp_file_retrieve(/instrument, /chamber, trange = trange)
;       Options: Instrument : /spanea, /spaneb, /spani, /spc, /swem
;              Chamber :    /snout2, /tv, /cal, /crypt, /rm133
;     2b: Raw SSR Files
;       Format: files = spp_file_retrieve(/ssr, trange = trange)
; 
; 3: Decommutate files
;     3a: Calibration Data
;       IDL> spp_ptp_file_read, files
;     3b: Raw SSR Files
;       IDL> spp_ssr_file_read, files
; 4: Plot things
;     To get a summary of data:
;       IDL> spp_swp_spane_tplot, 'sumplot', /setlim
;     To get a listing of all span-a/b tplot variables:
;       IDL> tplot_names, '*sp[a,b]*
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
;   For questions or comments about the data:
;   Phyllis Whittlesey
;   phyllisw@berkeley.edu
;   I really do want to work with you!
;   
;   
; note that table files are doubled until [insert date here]



pro nothing
;;----SPAN-E Flight Commissioning Data----;;
trange = '2018 09 ' + ['05/20','06/18'] ; first light / first HV ramp up, table 10-10 or 5-5
trange = '2018 09 ' + ['08/04','08/06'] ; transient slew in commissioning
trange = '2018 09 ' + ['08/08','08/10']; spoiler tests in commissioning
trange = '2018 09 ' + ['17/06','17/18'] ; Tables were loaded, funny packet business
trange = '2018 09 ' + ['21/03','21/04'] ; ~ 15 minutes worth of not much going on
trange = '2018 09 ' + ['24/12','28/04'] ; Table switching, SPAN-B overcurrent (table issue), not much else
trange = '2018 10 ' + ['02/04','02/17'] ; 14 hours of nominal solar wind before Venus
trange = '2018 10 ' + ['03/01','03/09'] ; Venus Encounter Data
trange = '2018 10 ' + ['03/16','04/00'] ; post Venus Cruise phase data


;;----SPAN-E TVAC TESTING @ GODDARD (2018)----;;
; Use the following:
; files = spp_file_retrieve(/swem, /goddard, trange = trange)
trange = '2018 03 ' + ['07/16','08/01'] ; fields wpc testing with electron gun
trange = '2018 03 ' + ['08/00','08/04'] ; threshold tests @ each anode w/electron gun stimuli
trange = '2018 03 ' + ['08/03','08/06'] ; threshold tests @ MCP values, spoiler test, and energy sweep (also powerdown)


;;----SPAN-Ae FINAL CALIBRATION FILES----;;

trange = '2017 03 ' + ['28/01','28/05'] ; ramp up MCPs ; uses standard tables
;trange = ['2017 03 28/02','2017 03 29/00']
trange = '2017 03 ' + ['28/04','28/06'] ; CPT at HV, begins with threshold tests ; slut_py_index_reduced_20170327_223504_2000
trange = '2017 03 ' + ['28/22','29/01'] ; Gun scan @ 900eV ; slut_py_index_reduced_20170328_130600_2000
trange = '2017 03 ' + ['29/01','29/03'] ; rotations @ 900eV; ; midway through rotation switches to fixgain = 13 * 2. files do not reflect this. slut_py_index_reduced_20170328_183755_2000
trange = '2017 03 ' + ['29/08','29/10'] ; spoiler test
trange = '2017 03 ' + ['29/05','29/08'] ; EA scan @ what energy?
trange = '2017 03 ' + ['29/15','29/17'] ; EA scan @ what energy?
trange = '2017 03 ' + ['29/18','29/20'] ; rotation both ways
trange = '2017 03 ' + ['29/19','29/23'] ; spoiler + rotation test (mode 2)
trange = '2017 03 ' + ['30/01','31/01'] ; spoiler tests.
;trange = '2017 03 ' + ['xx/xx','31/06'] ; lots of re-writing tables. After this the table type characteristically changes
;trange = '2017 03 ' + ['31/06','31/13'] ; deflector test @900eV, but linear & deflector values jacked up.
trange = '2017 03 ' + ['31/18','31/22'] ; deflector test anodes 0,8,15, @ 900eV electrons.
;trange = '2017 03 ' + ['31/21','31/23'] ; rotation through anodes with all sweeping
;trange = '2017 03 ' + ['31/22','31/24'] ; rotation through anodes with only hem sweeping. Bad manipulator data
trange = '2017 03 ' + ['31/18','31/24']
;trange = '2017 04 ' + ['01/01','01/03'] ; deflector test for anode 0, all deflections coarse @ 3600eV
trange = '2017 04 ' + ['01/03','01/08'] ; deflector test anodes 0,8,15 @ 3600eV electrons 
;trange = '2017 04 ' + ['01/10','01/17'] ; Not much happening.
trange = '2017 04 ' + ['01/19','01/23'] ; Energy/yaw scan @ ~1keV (roughly, table center)
trange = '2017 04 ' + ['02/04','02/06'] ; spoiler scan @ 900eV. Everything sweeping (save spoiler)
trange = '2017 04 ' + ['02/08','02/10'] ; rotation scan @ 3500eV, not sweeping deflector.
trange = '2017 04 ' + ['02/09','02/11'] ; energy/angle scan @ 3500eV
;trange = '2017 04 ' + ['02/10','02/13'] ; another energy/angle scan @ 3500eV, but with different maxima than previous. Can't figure why, might be change in configuration of UV lamp
;trange = '2017 04 ' + ['02/13','02/16'] ; Miscellaneous testing of unknown type
;trange = '2017 04 ' + ['02/15','02/17'] ; Spoiler testing misc.


;;----SPAN-B FINAL CALIBRATION FILES----;;

files = spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-3/20170224_102402_none/PTP_data.dat') ; includes the first threshold test with no HV and a pulse height test
trange = '2017 02 ' + ['26/03','26/08'] ; first EA scan at 1keV. Anode 4 is missed. data is missing on MAJA before this, waiting Mercer's completion
;trange = '2017 02 ' + ['26/08','26/16'] ; just sitting on anode 0
trange = '2017 02 ' + ['26/19','27/01'] ; threshold & mcp test @ 1keV
trange = '2017 02 ' + ['27/05','27/06'] ; rotation @ 1keV for all anodes
;trange = '2017 02 ' + ['27/06','27/17'] ; yaw gone awry, not very useful deflection test @ 1keV
trange = '2017 02 ' + ['27/18','27/20'] ;  deflector test anode 0 only @ 1keV electrons 
;trange = '2017 02 ' + ['27/20','28/04'] ; failed remainder of deflector test & not much happening.
trange = '2017 02 ' + ['28/04','28/07'] ; spoiler scan @ 1keV
;trange = '2017 02 ' + ['28/07','28/10'] ; nothing going on.
trange = '2017 02 ' + ['28/10','28/15'] ; rotation and energy/angle scan w/ atten in @ 1keV
;trange = ['2017 02 28/15','2017 03 01/16']; missing data. Chamber break? Either way ramp up is missing, as well as attenuator Out command.
trange = '2017 03 ' + ['01/17','01/18'] ; rotation @ 1keV, attenuator out.
trange = '2017 03 ' + ['01/18','02/02'] ; deflector test anodes 0,4,8,12,15 @ 1keV. one manipulator error in center, restarted test @ 8.
;trange = '2017 03 ' + ['02/02','02/06'] ; nothing going on. turned off sweeping hemisphere
trange = '2017 03 ' + ['02/06','02/07'] ; manual hemisphere sweep @ anode 12, 1keV
;trange = '2017 03 ' + ['02/07','02/11'] ; nothing going on.
trange = '2017 03 ' + ['02/11','02/15'] ; energy/yaw scan @ 1keV, anode 12.
;trange = '2017 03 ' + ['02/15','02/17'] ; nothing going on.
trange = '2017 03 ' + ['02/17','02/20'] ; rotations @ 1keV with and without attenuator @ two different yaw positions.
trange = '2017 03 ' + ['02/19','02/22'] ; energy/angle scan @ 1keV. small rotation errors occasionally. Otherwise identicaly to 26/03
trange = '2017 03 ' + ['02/23','03/00']; miscellaneous tests with mini e gun.
;trange = '2017 03 ' + ['03/00','03/04'] ; all modes sweeping & yawing - tables are wrong because weird ailiasing is seen.
;trange = '2017 03 ' + ['03/04','03/08'] ; nothing going on.
trange = '2017 03 ' + ['03/08','03/11'] ; energy/angle scan @5keV, anode 6 missing.
;trange = '2017 03 ' + ['03/11','03/18'] ; nothing going on
trange = '2017 03 ' + ['03/18','03/24'] ; MCP threshold test @ 5keV
;trange = '2017 03 ' + ['03/24','04/01'] ; nothing going on
;trange = '2017 03 ' + ['04/01','04/06'] ; some odd linear scans going on here at 4800eV. Hemisphere Sweeping.
;trange = '2017 03 ' + ['04/09','04/13'] ; more odd linear scans going on, but at 1keV.Hemisphere sweeping.
;trange = '2017 03 ' + ['04/13','05/24'] ; nothing going on.
;trange = '2017 03 ' + ['06/00','06/03'] ; more odd linear scans.
;trange = '2017 03 ' + ['06/03','06/19'] ; nothing going on. ramp down/turn off.

;;----SPAN-Ae/B-SPACECRAFT-TVAC----;;

files = spp_file_retrieve('spp/data/sci/sweap/sao/level_zero_telemetry/2018/065/sweap_spp_2018065_01.ptp.gz') ; contains spc data and span-i housekeeping

files = spp_file_retrieve('spp/data/sci/sweap/sao/level_zero_telemetry/2018/065/sweap_spp_2018065_02.ptp.gz') ; first HV ramped, good stuff starts @ 2020 07 17 1800, file ends @ 07 18 ~0500

files = spp_file_retrieve('spp/data/sci/sweap/sao/level_zero_telemetry/2018/065/sweap_spp_2018065_03.ptp.gz') ; first HV ramped, good stuff starts @ 2020 07 17 1800, file ends @ 07 18 ~0500, seems to be the same file as the 02 above.

files = spp_file_retrieve('spp/data/sci/sweap/sao/level_zero_telemetry/2018/066/sweap_spp_2018066_03.ptp.gz') ; Looks like this is hot CPT? Threshold test @ 2020-07-19/09:43
;also odd counts appear on all anodes @ 2020-07-19/06:11:00 on Ae with no known cause. Gun?? Also - two time jumps @ 2020-07-18/10:07 and @ 2020-07-18/21:40 . Data missing in other places.

files = spp_file_retrieve('spp/data/sci/sweap/sao/level_zero_telemetry/2018/067/sweap_spp_2018067_01.ptp.gz') ; contains all the good stuff : rotations back + forth, spoiler tests, and gun tests. 
; for gun test, the values are: 


;;-----EXTRAS-----;;

 trange =  '2016 10 '+ ['18/04','19/22']   ; SPANE - A flght in Cal chamber:  MCP test; NOT PREENV CAL
 
 ; SPANAe Pre Env Cal datat;
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
 ; At some point before Feb 25th @ noon local time, maja quit recording.

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


pro spane_threshold_scan_phd,tranges=trange,lim=lim, xvar = xvar , yvar = yvar, anode = anode

  if ~keyword_set(trange) then ctime,trange,npo=2
  swap_interp=0
  xlim,lim,0,550
  ylim,lim,10,5000,1
  options,lim,psym=4
  wi, 1, wsize = [800,1000]
;  scat_plot,swap_interp=swap_interp,'spp_spa_hkp_MRAM_WR_ADDR','spp_spa_AF0_CNTS',trange=trange,lim=lim,xvalue=dac,yvalue=cnts,ydimen= 4;,color=4
;  scat_plot,swap_interp = swap_interp, 'spp_spa_hkp_MRAM_WR_ADDR','spp_spa_AF0_CNTS',trange=trange,lim=lim,xvalue=dac,yvalue=cnts,color=4;,ydimen= 4
  scat_plot,swap_interp = swap_interp, xvar, yvar, trange=trange, lim=lim, xvalue=dac, yvalue=cnts, color=4, ydimen = anode
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
  print, 'done'
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



if 0  then begin  ;;  time test 
   sf = tsample(times=tf)
   w1 = where(total(sf,2))
   w1=w1[0]
   w2=where(sf[w1,*])
   w2=w2[0]
   t=tf[w1]
   dt =  0.43690658  /2
   print,w2
   ncts = sf[w1,w2]
   mx = max(sf)
   ddt = dt/256 * float(mx-ncts)/mx
   dt = dt+ddt
   
   print,time_string(t+dt*w2/256. - dt*2,prec=3)  ; targeted on
   
   print,time_string(t+dt*w2/256. - dt,prec=3)  ; targeted off

   print,time_string(t+dt*w2/256.,prec=4)  ; span-I
   dt = dt+ddt
   print,time_string(t+dt*w2/256.,prec=5)  ; span-I

   print,reform(sf[w1,*])
   
   

endif

pro spe_kludge, dataNum
  nrg = dgen(32, range = [500,5], /log)
  get_data, dataNum, data = d
  str_element, d, 'v', nrg, /add
  store_data, dataNum, data = d
end


end

