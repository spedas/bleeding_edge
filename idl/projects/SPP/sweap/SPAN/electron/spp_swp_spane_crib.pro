;--------------------------------------------------------------------
; PSP SPAN-E Crib
; 
; Currently this holds all the scrap pieces from calibration / instrument development, which will get moved
; Also includes a log of the calibration files and instructions for processing them
; 
; In the future this will include instructions for looking at flight data:  IN PROG 
; 
; $LastChangedBy: phyllisw3 $
; $LastChangedDate: 2024-03-25 15:00:30 -0700 (Mon, 25 Mar 2024) $
; $LastChangedRevision: 32503 $
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
;;------- PSP Encounter Timestamps -------;;
;;----- (SPAN-E Encounter Mode Only) -----;;
trange = '2018 ' + ['10 31/00:13:17', '11 12/03:29:35']   ;;-- ENCOUNTER 1 --;;
trange = '2019 ' + ['03 29/23:45:23', '04 10/15:18:55']   ;;-- ENCOUNTER 2 --;;
trange = '2019 ' + ['08 22/02:11:30', '09 09/21:14:39']   ;;-- ENCOUNTER 3 --;;
trange = '2020 ' + ['01 23/14:00:18', '02 04/05:09:45']   ;;-- ENCOUNTER 4 --;;
trange = '2020 ' + ['05 20/04:42:52', '06 15/14:00:47']   ;;-- ENCOUNTER 5 --;;
trange = '2020 ' + ['09 12/01:11:53', '10 03/13:03:54']   ;;-- ENCOUNTER 6 --;;
trange = '2021 ' + ['01 09/14:48:06', '01 28/02:13:59']   ;;-- ENCOUNTER 7 --;;
trange = '2021 ' + ['04 20/05:48:37', '05 05/05:05:06']   ;;-- ENCOUNTER 8 --;;
trange = '2021 ' + ['08 02/00:21:18', '08 15/14:19:09']   ;;-- ENCOUNTER 9 --;;

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




pro garbage
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
end

pro timetest
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
end

pro spe_kludge, dataNum
  nrg = dgen(32, range = [2000,2], /log)
  get_data, dataNum, data = d
  str_element, d, 'v', nrg, /add
  store_data, dataNum, data = d
end

;feed this a get_data from a fullspec.y
pro kludge_3d, fullspec
  sizeVar = size(fullspec.x)
  full3d = reform(fullspec.y, sizeVar[1], 16,8,32)
  full3d = {x: fullspec.x, y: full3d}
  store_data, 'psp_swp_spa_L2_sf0_PDATA_3D', data = full3d
end


pro spe_limit_hist, datavar, trange = trange
  if ~keyword_set(trange) then trange = ['2018 10 01/00', 'now']
  if ~keyword_set(datavar) then begin
    ;;----Define limits for use later----;;
    ;;---p8i---;;
    spa_p8i_rul = 37.21
    spa_p8i_yul = 32.7
    spa_p8i_yll = 8.4
    spa_p8i_rll = 0.
    spb_p8i_rul = 60.
    spb_p8i_yul = 43.
    spb_p8i_yll = 8.4
    spb_p8i_rll = 0.
    ;;---p8va---;;
    spa_p8va_rul = 12.29
    spa_p8va_yul = 10.81
    spa_p8va_yll = 7.75
    spa_p8va_rll = 7.5
    spb_p8va_rul = 10.5
    spb_p8va_yul = 10.
    spb_p8va_yll = 7.75
    spb_p8va_rll = 7.5
    ;;---n8i---;;
    spa_n8i_rul = 26.58
    spa_n8i_yul = 23.4
    spa_n8i_yll = 4.2
    spa_n8i_rll = 0.0
    spb_n8i_rul = 68.1
    spb_n8i_yul = 43.0
    spb_n8i_yll = 4.2
    spb_n8i_rll = 0.0
    ;;---n8va---;;
    spa_n8va_rul = 12.33
    spa_n8va_yul = 10.85
    spa_n8va_yll = 8.5
    spa_n8va_rll = 8.2
    spb_n8va_rul = 10.5
    spb_n8va_yul = 10.0
    spb_n8va_yll = 7.75
    spb_n8va_rll = 7.5
    ;;---rawi---;;
    spa_rawi_rul = 45.01
    spa_rawi_yul = 39.61
    spa_rawi_yll = !values.f_nan ; so the plotting structure continues to work, use f_nan
    spa_rawi_rll = !values.f_nan
    spb_rawi_rul = 30.00
    spb_rawi_yul = 25.00
    spb_rawi_yll = !values.f_nan
    spb_rawi_rll = !values.f_nan
    ;;---p5i---;;
    spa_p5i_rul = 30.43
    spa_p5i_yul = 26.77
    spa_p5i_yll = 10.0
    spa_p5i_rll = 8.0
    spb_p5i_rul = 33.0
    spb_p5i_yul = 28.0
    spb_p5i_yll = 10.0
    spb_p5i_rll = 8.0
    ;;---p5va---;;
    spa_p5va_rul = 6.89
    spa_p5va_yul = 6.06
    spa_p5va_yll = 5.0
    spa_p5va_rll = 4.75
    spb_p5va_rul = 5.6
    spb_p5va_yul = 5.4
    spb_p5va_yll = 5.0
    spb_p5va_rll = 4.75
    ;;---n5i---;;
    spa_n5i_rul = 36.51
    spa_n5i_yul = 32.13
    spa_n5i_yll = 15.0
    spa_n5i_rll = 13.0
    spb_n5i_rul = 35.0
    spb_n5i_yul = 31.0
    spb_n5i_yll = 15.0
    spb_n5i_rll = 13.0
    ;;---n5va---;;
    spa_n5va_rul = 6.79
    spa_n5va_yul = 5.98
    spa_n5va_yll = 5.0
    spa_n5va_rll = 4.75
    spb_n5va_rul = 5.6
    spb_n5va_yul = 5.4
    spb_n5va_yll = 5.0
    spb_n5va_rll = 4.75
    ;;---mcpi---;;
    spa_mcpi_rul = 21.31
    spa_mcpi_yul = 18.75
    spa_mcpi_yll = !values.f_nan
    spa_mcpi_rll = !values.f_nan
    spb_mcpi_rul = 50.0
    spb_mcpi_yul = 40.0
    spb_mcpi_yll = !values.f_nan
    spb_mcpi_rll = !values.f_nan
    ;;---22i---;;
    spa_22i_rul = 32.85
    spa_22i_yul = 28.90
    spa_22i_yll = 22.0
    spa_22i_rll = 20.0
    spb_22i_rul = 28.0
    spb_22i_yul = 26.5
    spb_22i_yll = 22.0
    spb_22i_rll = 20.0
    ;;---1p5i---;;
    spa_1p5i_rul = 16.93
    spa_1p5i_yul = 14.9
    spa_1p5i_yll = 9.0
    spa_1p5i_rll = 7.0
    spb_1p5i_rul = 24.0
    spb_1p5i_yul = 20.0
    spb_1p5i_yll = 9.0
    spb_1p5i_rll = 7.0
    ;;---3p3i---;;
    spa_3p3i_rul = 61.49
    spa_3p3i_yul = 54.11
    spa_3p3i_yll = 35.0
    spa_3p3i_rll = 30.0
    spb_3p3i_rul = 57.6
    spb_3p3i_yul = 48.0
    spb_3p3i_yll = 35.0
    spb_3p3i_rll = 30.0
    ;;---3p3vd---;;
    spa_3p3vd_rul = 4.16
    spa_3p3vd_yul = 3.66
    spa_3p3vd_yll = 3.18
    spa_3p3vd_rll = 3.10
    spb_3p3vd_rul = 3.5
    spb_3p3vd_yul = 3.4
    spb_3p3vd_yll = 3.18
    spb_3p3vd_rll = 3.1
    ;;---3p3va---;;
    spa_3p3va_rul = 4.16
    spa_3p3va_yul = 3.66
    spa_3p3va_yll = 3.18
    spa_3p3va_rll = 3.10
    spb_3p3va_rul = 3.5
    spb_3p3va_yul = 3.4
    spb_3p3va_yll = 3.18
    spb_3p3va_rll = 3.1
    ;;----Get all variables to plot----;;
    get_data, "psp_swp_spa_hkp_L1_RIO_P8I", data = spa_p8i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_P8I", data = spb_p8i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_P8VA", data = spa_p8va, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_P8VA", data = spb_p8va, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_N8I", data = spa_n8i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_N8I", data = spb_n8i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_M8VA", data = spa_n8va, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_M8VA", data = spb_n8va, trange = trange
    get_data, "psp_swp_spa_hkp_L1_ADC_IMON_RAW", data = spa_rawi, trange = trange
    get_data, "psp_swp_spb_hkp_L1_ADC_IMON_RAW", data = spb_rawi, trange = trange
    ;;----New Plot Row----;;
    get_data, "psp_swp_spa_hkp_L1_RIO_P5IA", data = spa_p5i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_P5IA", data = spb_p5i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_P5VA", data = spa_p5va, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_P5VA", data = spb_p5va, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_M5IA", data = spa_n5i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_M5IA", data = spb_n5i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_M5VA", data = spa_n5va, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_M5VA", data = spb_n5va, trange = trange
    get_data, "psp_swp_spa_hkp_L1_ADC_IMON_MCP", data = spa_mcpi, trange = trange
    get_data, "psp_swp_spb_hkp_L1_ADC_IMON_MCP", data = spb_mcpi, trange = trange
    ;;----New Plot Row----;;
    get_data, "psp_swp_spa_hkp_L1_RIO_22VA", data = spa_22i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_22VA", data = spb_22i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_1P5I", data = spa_1p5i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_1P5I", data = spb_1p5i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_3P3I", data = spa_3p3i, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_3P3I", data = spb_3p3i, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_3P3VD", data = spa_3p3vd, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_3P3VD", data = spb_3p3vd, trange = trange
    get_data, "psp_swp_spa_hkp_L1_RIO_3P3VDA", data = spa_3p3va, trange = trange
    get_data, "psp_swp_spb_hkp_L1_RIO_3P3VDA", data = spb_3p3va, trange = trange
    ;;----Generate histograms----;;
    daty_spa_p8i = histogram(spa_p8i.y, loc = datx_spa_p8i)
    daty_spb_p8i = histogram(spb_p8i.y, loc = datx_spb_p8i)
    daty_spa_p8va = histogram(spa_p8va.y, loc = datx_spa_p8va)
    daty_spb_p8va = histogram(spb_p8va.y, loc = datx_spb_p8va)
    daty_spa_n8i = histogram(spa_n8i.y, loc = datx_spa_n8i)
    daty_spb_n8i = histogram(spb_n8i.y, loc = datx_spb_n8i)
    daty_spa_n8va = histogram(spa_n8va.y, loc = datx_spa_n8va)
    daty_spb_n8va = histogram(spb_n8va.y, loc = datx_spb_n8va)
    daty_spa_rawi = histogram(spa_rawi.y, loc = datx_spa_rawi)
    daty_spb_rawi = histogram(spb_rawi.y, loc = datx_spb_rawi)
    ;;----New Plot Row----;;
    daty_spa_p5i = histogram(spa_p5i.y, loc = datx_spa_p5i)
    daty_spb_p5i = histogram(spb_p5i.y, loc = datx_spb_p5i)
    daty_spa_p5va = histogram(spa_p5va.y, loc = datx_spa_p5va)
    daty_spb_p5va = histogram(spb_p5va.y, loc = datx_spb_p5va)
    daty_spa_n5i = histogram(spa_n5i.y, loc = datx_spa_n5i)
    daty_spb_n5i = histogram(spb_n5i.y, loc = datx_spb_n5i)
    daty_spa_n5va = histogram(spa_n5va.y, loc = datx_spa_n5va)
    daty_spb_n5va = histogram(spb_n5va.y, loc = datx_spb_n5va)
    daty_spa_mcpi = histogram(spa_mcpi.y, loc = datx_spa_mcpi)
    daty_spb_mcpi = histogram(spb_mcpi.y, loc = datx_spb_mcpi)
    ;;----New Plot Row----;;
    daty_spa_22i = histogram(spa_22i.y, loc = datx_spa_22i)
    daty_spb_22i = histogram(spb_22i.y, loc = datx_spb_22i)
    daty_spa_1p5i = histogram(spa_1p5i.y, loc = datx_spa_1p5i)
    daty_spb_1p5i = histogram(spb_1p5i.y, loc = datx_spb_1p5i)
    daty_spa_3p3i = histogram(spa_3p3i.y, loc = datx_spa_3p3i)
    daty_spb_3p3i = histogram(spb_3p3i.y, loc = datx_spb_3p3i)
    daty_spa_3p3vd = histogram(spa_3p3vd.y, loc = datx_spa_3p3vd)
    daty_spb_3p3vd = histogram(spb_3p3vd.y, loc = datx_spb_3p3vd)
    daty_spa_3p3va = histogram(spa_3p3va.y, loc = datx_spa_3p3va)
    daty_spb_3p3va = histogram(spb_3p3va.y, loc = datx_spb_3p3va)
    ;;----Plot Plots!----;;
    wi, 1
    popen, 'spanae_limit_monitors_20210217', /landscape
    !p.multi = [0, 5, 3]
    plot, datx_spa_p8i, daty_spa_p8i, psym = 10, title = 'Ae: +8 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_p8i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_p8i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_p8i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_p8i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_p8va, daty_spa_p8va, psym = 10, title = 'Ae: +8 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_p8va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_p8va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_p8va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_p8va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_n8i, daty_spa_n8i, psym = 10, title = 'Ae: -8 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_n8i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_n8i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_n8i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_n8i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_n8va, daty_spa_n8va, psym = -6, title = 'Ae: -8 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_n8va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_n8va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_n8va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_n8va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_rawi, daty_spa_rawi, psym = 10, title = 'Ae: Raw Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_rawi_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_rawi_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_rawi_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_rawi_rll
    oplot, rllx, limy, color = 6
    ;;----New Plot Row----;;
    plot, datx_spa_p5i, daty_spa_p5i, psym = 10, title = 'Ae: +5 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_p5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_p5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_p5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_p5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_p5va, daty_spa_p5va, psym = -6, title = 'Ae: +5 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_p5va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_p5va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_p5va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_p5va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_n5i, daty_spa_n5i, psym = 10, title = 'Ae: -5 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_n5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_n5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_n5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_n5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_n5va, daty_spa_n5va, psym = -6, title = 'Ae: -5 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spa_n5va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_n5va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_n5va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_n5va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_mcpi, daty_spa_mcpi, psym = 10, title = 'Ae: MCP Current'
    rulx = fltarr(2) + spa_mcpi_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_mcpi_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_mcpi_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_mcpi_rll
    oplot, rllx, limy, color = 6
    ;;----New Plot Row----;;
    plot, datx_spa_22i, daty_spa_22i, psym = 10, title = 'Ae: 22 Voltage'
    rulx = fltarr(2) + spa_22i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_22i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_22i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_22i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_1p5i, daty_spa_1p5i, psym = 10, title = 'Ae: 1.5 Current'
    rulx = fltarr(2) + spa_1p5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_1p5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_1p5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_1p5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_3p3i, daty_spa_3p3i, psym = 10, title = 'Ae: 3.3 Current'
    rulx = fltarr(2) + spa_3p3i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_3p3i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_3p3i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_3p3i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_3p3vd, daty_spa_3p3vd, psym = -6, title = 'Ae: 3.3V Digital'
    rulx = fltarr(2) + spa_3p3vd_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_3p3vd_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_3p3vd_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_3p3vd_rll
    oplot, rllx, limy, color = 6
    plot, datx_spa_3p3va, daty_spa_3p3va, psym = -6, title = 'Ae: 3.3V Analog'
    rulx = fltarr(2) + spa_3p3va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spa_3p3va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spa_3p3va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spa_3p3va_rll
    oplot, rllx, limy, color = 6
    pclose
    ;;----------SPAN-B----------;;
    wi, 2
    popen, 'spanb_limit_monitors_20210217', /landscape
    !p.multi = [0, 5, 3]
    plot, datx_spb_p8i, daty_spb_p8i, psym = 10, title = 'B: +8 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_p8i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_p8i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_p8i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_p8i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_p8va, daty_spb_p8va, psym = 10, title = 'B: +8 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_p8va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_p8va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_p8va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_p8va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_n8i, daty_spb_n8i, psym = 10, title = 'B: -8 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_n8i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_n8i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_n8i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_n8i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_n8va, daty_spb_n8va, psym = 10, title = 'B: -8 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_n8va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_n8va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_n8va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_n8va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_rawi, daty_spb_rawi, psym = 10, title = 'B: Raw Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_rawi_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_rawi_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_rawi_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_rawi_rll
    oplot, rllx, limy, color = 6
    ;;----New Plot Row----;;
    plot, datx_spb_p5i, daty_spb_p5i, psym = 10, title = 'B: +5 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_p5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_p5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_p5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_p5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_p5va, daty_spb_p5va, psym = -6, title = 'B: +5 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_p5va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_p5va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_p5va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_p5va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_n5i, daty_spb_n5i, psym = 10, title = 'B: -5 Current'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_n5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_n5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_n5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_n5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_n5va, daty_spb_n5va, psym = -6, title = 'B: -5 Voltage'
    limy = [0.,100000000.]
    rulx = fltarr(2) + spb_n5va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_n5va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_n5va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_n5va_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_mcpi, daty_spb_mcpi, psym = 10, title = 'B: MCP Current'
    rulx = fltarr(2) + spb_mcpi_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_mcpi_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_mcpi_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_mcpi_rll
    oplot, rllx, limy, color = 6
    ;;----New Plot Row----;;
    plot, datx_spb_22i, daty_spb_22i, psym = 10, title = 'B: 22 Voltage'
    rulx = fltarr(2) + spb_22i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_22i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_22i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_22i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_1p5i, daty_spb_1p5i, psym = 10, title = 'B: 1.5 Current'
    rulx = fltarr(2) + spb_1p5i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_1p5i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_1p5i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_1p5i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_3p3i, daty_spb_3p3i, psym = 10, title = 'B: 3.3 Current'
    rulx = fltarr(2) + spb_3p3i_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_3p3i_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_3p3i_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_3p3i_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_3p3vd, daty_spb_3p3vd, psym = -6, title = 'B: 3.3V Digital'
    rulx = fltarr(2) + spb_3p3vd_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_3p3vd_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_3p3vd_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_3p3vd_rll
    oplot, rllx, limy, color = 6
    plot, datx_spb_3p3va, daty_spb_3p3va, psym = -6, title = '3.3V Analog B'
    rulx = fltarr(2) + spb_3p3va_rul
    oplot, rulx, limy, color = 6
    yulx = fltarr(2) + spb_3p3va_yul
    oplot, yulx, limy, color = 4
    yllx = fltarr(2) + spb_3p3va_yll
    oplot, yllx, limy, color = 4
    rllx = fltarr(2) + spb_3p3va_rll
    oplot, rllx, limy, color = 6
    pclose
  endif else begin
    wi, 1
    get_data, datavar, data = gotdata
    daty = histogram(gotdata.y, loc = datx)
    plot, datx, daty, psym = 10
  endelse
end
  
  
pro spplot_plw,trange,cursor=cursor,zero=zero,lim=lim,ebins=ebins; borrowed from Davin crib 'spp_swp_span_crib'

  if ~isa(lim) then begin
    ylim,lim,10,1e6,1
  endif
  
  if ~keyword_set(ebins) then ebins = [4,8,7,16] ; 

  d3d1 = spp_swp_3dstruct('spa_sf0_L2', trange = trange, cursor = cursor, sortname = 'deflsort3d')
  wi,1
  wshow,1
  spec3d,d3d1,lim=lim, /phi

  wi,2
  wshow,2
  plot3d_new,d3d1,zero=zero, ebins = ebins

  d3d2 = spp_swp_3dstruct('spb_sf0_L2', trange = trange, sortname = 'deflsort3d')
  wi,3,/wshow
  spec3d,d3d2,lim=lim,/phi
  wi,4,/wshow
  plot3d_new,d3d2,zero=zero, ebins = ebins, magf = d3d2.magf_sc
  timebar,trange

  wshow,2
  wshow,4
  wshow,1
  wshow,3
  ;wshow,4


end

pro spp_swp_spe_plot_all, trange = trange, ql = ql
  if ~keyword_set(trange) then trange = ['2018 10 01/00', 'now']
  spp_swp_spice, trange = trange, /pos, /load, /venus
  spp_swp_spe_load, trange = trange, /allvars, level = 'L2', types = ['af1', 'sf1', 'sf0']
  spp_swp_spe_load, trange = trange, /allvars, level = 'L1', types = ['hkp']
  spp_swp_spe_load, trange = trange, level = 'L3'
  spp_fld_load, trange = trange, type = 'f1_100bps'
  ;spp_swp_spe_load, trange = trange, /allvars, level = 'L3', spxs = ['spa', 'spb']
  if keyword_set(ql) then begin
    tplot, '*ql'
    tplot, /a, 'psp_swp_spe_sf0_L3_EFLUX_VS_PA_E8'
    tplot, /a, '*SPP*POS*_mag'
    options, '*SPP*POS*_mag', panel_size = 0.5
    tplot, /a, 'spp_fld_f1_100bps_B_PEAK'
  endif
  ;spp_swp_spice, trange = trange, /pos, /load
end