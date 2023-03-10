;+
;
; SPP_SWP_SPI_FLIGHT_EVT
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31605 $
; $LastChangedDate: 2023-03-09 13:12:04 -0800 (Thu, 09 Mar 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_evt.pro $
;
;-

PRO spp_swp_spi_flight_evt, table

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;  Pre-Vibe and Pre-Environmental SPAN-Ai Flight Calibration   ;;;
   ;;;                       CAL Facility                           ;;;
   ;;;                        2017-01-01                            ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Threshold Scan
   tt_threshscan_1 = ['2017-01-04/19:50:00', '2017-01-05/03:35:30']


   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;          SPAN-Ai Flight Calibration Experiments              ;;;
   ;;;                       CAL Facility                           ;;;
   ;;;                        2017-03-07                            ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;------------------------------------------------------------------
   ;; Gun Map
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   tt_gunmap_1 = ['2017-03-09/04:12:00','2017-03-09/22:36:00']
   ;; First Half
   tt_gunmap_11 = ['2017-03-09/04:25:10','2017-03-09/06:22:10']
   ;; Second Half
   tt_gunmap_12 = ['2017-03-09/20:25:20','2017-03-09/22:15:00']
   ;; Rotation Scan before TOF correction
   tt_rotscan_1 = ['2017-03-10/07:28:20','2017-03-10/08:44:40']
   ;; Rotation Scan after TOF correction
   ;rotscan2 = [
   
   ;;------------------------------------------------------------------
   ;; Threshold Scan
   ;;
   ;; INFO
   ;;   - CFD Threshold scan of all START and STOP channels.
   ;; CONFIG
   ;;   - AZ  = [0,1,2,3]
   ;;   - RAW = [0xD000]
   ;;   - MCP = [0xD000]
   ;;   - ACC = [0xFF00]
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_threshscan_2 = ['2017-03-12/05:47:00','2017-03-12/19:00:00']
   
   ;;------------------------------------------------------------------   
   ;; Rotation Scan
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_rotscan_2 = ['2017-03-13/07:12:35','2017-03-13/08:32:45']
   
   ;;------------------------------------------------------------------   
   ;; Energy Angle Scan
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_eascan_1 = ['2017-03-13/18:21:00','2017-03-13/23:47:00']
   
   ;;------------------------------------------------------------------   
   ;; Constant YAW, Sweeping Deflector - HIGH DETAIL - ANODE 0x0
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_def_sweep_fine_0 = ['2017-03-14/06:31:50','2017-03-14/10:04:30']
   tt_def_sweep_fine_1 = ['2017-03-14/10:35:00','2017-03-14/13:50:30']

   ;;------------------------------------------------------------------   
   ;; Constant YAW, Sweeping Deflector - COARSE - ALL ANODES
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   ;; Anode 0x0
   tt_def_sweep_coarse_0 = ['2017-03-14/18:28:00','2017-03-14/22:30:00']
   ;; Anode 0x1
   tt_def_sweep_coarse_1 = ['2017-03-14/18:28:00','2017-03-14/22:30:00']
   ;; Anode 0x2
   tt_def_sweep_coarse_2 = ['2017-03-15/05:22:00','2017-03-15/06:18:00']
   ;; Anode 0x3
   tt_def_sweep_coarse_3 = ['2017-03-15/06:49:35','2017-03-15/07:45:10']
   ;; Anode 0x4
   tt_def_sweep_coarse_4 = ['2017-03-15/08:17:15','2017-03-15/09:13:30']
   ;; Anode 0x5
   tt_def_sweep_coarse_5 = ['2017-03-15/09:45:40','2017-03-15/10:41:25']
   ;; Anode 0x6
   tt_def_sweep_coarse_6 = ['2017-03-15/11:13:25','2017-03-15/12:09:00']
   ;; Anode 0x7
   tt_def_sweep_coarse_7 = ['2017-03-15/12:40:50','2017-03-15/13:35:05']
   ;; Anode 0x8
   tt_def_sweep_coarse_8 = ['2017-03-15/14:06:50','2017-03-15/15:01:35']
   ;; Anode 0x9
   tt_def_sweep_coarse_9 = ['2017-03-15/15:32:55','2017-03-15/16:26:40']
   ;; Anode 0xB
   tt_def_sweep_coarse_B = ['2017-03-15/17:48:00','2017-03-15/18:33:30']
   ;; Anode 0xC
   tt_def_sweep_coarse_C = ['2017-03-15/18:45:00','2017-03-15/19:25:00']
   ;; Anode 0xD
   tt_def_sweep_coarse_D = ['2017-03-15/19:36:50','2017-03-15/20:05:20']

   ;;------------------------------------------------------------------
   ;; Very High Flux (~50K / 1/4NYS) on Anode 14 for ~5 hours
   tt_high_flux_14 = ['2017-03-16/18:02:20','2017-03-16/23:33:00']

   ;;------------------------------------------------------------------   
   ;; Constant YAW, Sweeping Deflector - Fine - anodes 9,10,11,12,13
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   ;; Anode 0x9
   tt_def_sweep_fine_9=['2017-03-21/07:36:50','2017-03-21/09:16:05']
   ;; Anode 0xA
   tt_def_sweep_fine_A=['2017-03-21/09:41:50','2017-03-21/11:21:50']
   ;; Anode 0xB
   tt_def_sweep_fine_B=['2017-03-21/11:47:00','2017-03-21/13:30:00']
   ;; Anode 0xC
   tt_def_sweep_fine_C=['2017-03-21/13:51:30','2017-03-21/15:33:30']
   ;; Anode 0xD
   tt_def_sweep_fine_D=['2017-03-21/15:57:00','2017-03-21/17:33:50']
   ;; Anode 0xE
   tt_def_sweep_fine_E=['2017-03-21/18:03:10','2017-03-21/19:16:00']

   str_def_sweep = {$
                   coarse:$
                   [{anode:'0'x, trange:tt_def_sweep_coarse_0},$
                    {anode:'1'x, trange:tt_def_sweep_coarse_1},$
                    {anode:'2'x, trange:tt_def_sweep_coarse_2},$
                    {anode:'3'x, trange:tt_def_sweep_coarse_3},$
                    {anode:'4'x, trange:tt_def_sweep_coarse_4},$
                    {anode:'5'x, trange:tt_def_sweep_coarse_5},$
                    {anode:'6'x, trange:tt_def_sweep_coarse_6},$
                    {anode:'7'x, trange:tt_def_sweep_coarse_7},$
                    {anode:'8'x, trange:tt_def_sweep_coarse_8},$
                    {anode:'9'x, trange:tt_def_sweep_coarse_9},$
                    ;;{anode:'A'x, trange:tt_def_sweep_coarse_a},$
                    {anode:'B'x, trange:tt_def_sweep_coarse_b}],$
                    ;;{anode:'C'x, trange:tt_def_sweep_coarse_c},$
                    ;;{anode:'D'x, trange:tt_def_sweep_coarse_d}],$
                   fine:$
                   [{anode:'0'x, trange:tt_def_sweep_fine_0},$
                    {anode:'1'x, trange:tt_def_sweep_fine_1},$
                    {anode:'9'x, trange:tt_def_sweep_fine_9},$
                    {anode:'A'x, trange:tt_def_sweep_fine_a},$
                    {anode:'B'x, trange:tt_def_sweep_fine_b},$
                    {anode:'C'x, trange:tt_def_sweep_fine_c},$
                    {anode:'D'x, trange:tt_def_sweep_fine_d},$
                    {anode:'E'x, trange:tt_def_sweep_fine_e}]}

   ;;------------------------------------------------------------------   
   ;; Turned back on 05:55
   ;; Quick Rotation scan to get beam back to anode 0
   tt_rot_scan_xx = ['2017-03-22/06:00:00', '2017-03-22/06:15:00']

   ;;------------------------------------------------------------------   
   ;; Sweep YAW with constant deflector
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   ;; Anode 0x0 and partially Anode 0x1
   tt_yaw_sweep_0 = ['2017-03-22/06:16:20', '2017-03-22/11:49:40']
   ;; Anode 0x4 and partially Anode 0x5
   tt_yaw_sweep_4 = ['2017-03-22/11:49:30', '2017-03-22/17:46:00']
   ;; Anode 0xA
   tt_yaw_sweep_a = ['2017-03-22/17:46:00', '2017-03-22/23:05:30']

   str_yaw_sweep = [$
                   {anode:'0'x, trange:tt_yaw_sweep_0},$
                   {anode:'4'x, trange:tt_yaw_sweep_4},$
                   {anode:'A'x, trange:tt_yaw_sweep_a}]
   
   ;;------------------------------------------------------------------   
   ;; Energy Scan (k-Factor and Mass Table)
   tt_e_scan_kfac_masstbl = ['2017-03-23/06:30:10', '2017-03-23/09:17:50']

   ;;------------------------------------------------------------------
   ;; K Factor Sweep
   ;;
   ;; INFO
   ;;   -
   ;; CONFIG
   ;;   - Disregard MRAM pointers for this test
   ;;   - Energies -> 5 - 20,000 eV
   ;;   - Oddly spaced Full/Targeted LUTs
   tt_ksweep_1 = ['2017-03-23/06:30:00', '2017-03-23/09:30:00']
   
   ;;------------------------------------------------------------------   
   ;; Colutron
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Nitrogen Gas Gun
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_mass_scan_nitrogen = ['2017-03-22/02:00:00','2017-03-22/03:00:00']
   
   ;;------------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Gas mixture of H2, He, Ne, Ar
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet   
   tt_mass_scan_gas_mix = ['2017-03-24/17:00:00','2017-03-24/22:00:00']
   tt_mass_scan_h   = ['2017-03-24/21:03:30','2017-03-24/21:17:25']
   tt_mass_scan_h2  = ['2017-03-24/20:57:05','2017-03-24/21:02:40']
   tt_mass_scan_he  = ['2017-03-24/18:36:05','2017-03-24/18:48:45']
   tt_mass_scan_m4  = ['2017-03-24/19:01:15','2017-03-24/19:07:00']
   tt_mass_scan_m5  = ['2017-03-24/19:09:40','2017-03-24/19:13:20']
   tt_mass_scan_m6  = ['2017-03-24/19:22:20','2017-03-24/19:28:30']
   tt_mass_scan_m7  = ['2017-03-24/19:31:35','2017-03-24/19:36:20']
   tt_mass_scan_m8  = ['2017-03-24/19:39:00','2017-03-24/19:42:55']
   tt_mass_scan_m9  = ['2017-03-24/19:43:40','2017-03-24/19:50:25']
   tt_mass_scan_m10 = ['2017-03-24/19:52:40','2017-03-24/20:01:05']
   tt_mass_scan_m11 = ['2017-03-24/20:04:50','2017-03-24/20:12:35']
   tt_mass_scan_m12 = ['2017-03-24/20:15:15','2017-03-24/20:21:10']
   tt_mass_scan_m13 = ['2017-03-24/20:25:10','2017-03-24/20:39:25']     

   str_mass_scan_1 = [{name:'full', tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N+',   tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N2+',  tt_mass_scan:tt_mass_scan_nitrogen}]
   str_mass_scan_2 = [{name:'full', tt_mass_scan:tt_mass_scan_gas_mix},  $
                      {name:'H+',   tt_mass_scan:tt_mass_scan_h},   $
                      {name:'H2+',  tt_mass_scan:tt_mass_scan_h2},  $
                      {name:'He+',  tt_mass_scan:tt_mass_scan_he},  $
                      {name:'m4',   tt_mass_scan:tt_mass_scan_m4},  $
                      {name:'m5',   tt_mass_scan:tt_mass_scan_m5},  $
                      {name:'m6',   tt_mass_scan:tt_mass_scan_m6},  $
                      {name:'m7',   tt_mass_scan:tt_mass_scan_m7},  $
                      {name:'m8',   tt_mass_scan:tt_mass_scan_m8},  $
                      {name:'m9',   tt_mass_scan:tt_mass_scan_m9},  $
                      {name:'m10',  tt_mass_scan:tt_mass_scan_m10}, $
                      {name:'m11',  tt_mass_scan:tt_mass_scan_m11}, $
                      {name:'m12',  tt_mass_scan:tt_mass_scan_m12}, $
                      {name:'m13',  tt_mass_scan:tt_mass_scan_m13}]

   ;;------------------------------------------------------------------   
   ;; Colutron
   ;;
   ;; INFO
   ;;   - ACC Scan
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Gas Mix
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_acc_scan_init = ['2017-03-24/22:00:00', '2017-03-25/01:00:00']

   tt_acc_scan_co2_1 = ['2017-03-24/22:22:29', '2017-03-24/22:41:19']
   tt_acc_scan_co2_2 = ['2017-03-24/23:32:10', '2017-03-24/23:47:19'] 

   tt_acc_scan_h_1 = ['2017-03-25/00:09:20', '2017-03-25/00:25:50']
   tt_acc_scan_h_2 = ['2017-03-25/00:25:50', '2017-03-25/00:45:40']

   tt_acc_scan = { $
                 tt_acc_scan_init:tt_acc_scan_init,$
                 tt_acc_scan_co2_1:tt_acc_scan_co2_1,$
                 tt_acc_scan_co2_2:tt_acc_scan_co2_2,$
                 tt_acc_scan_h_1:tt_acc_scan_h_1,$
                 tt_acc_scan_h_2:tt_acc_scan_h_2}
                 
   
   ;;------------------------------------------------------------------
   ;; Long term anode 11 with 2kV beam
   tt_long_term_2kV = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']

   ;;------------------------------------------------------------------
   ;; Energy Scan using Davin's tables
   tt_e_scan_full  = ['2017-03-26/01:30:00', '2017-03-26/11:00:00']
   tt_e_scan_full1 = ['2017-03-26/01:30:00', '2017-03-26/05:59:00']
   tt_e_scan_full2 = ['2017-03-26/08:00:00', '2017-03-26/11:00:00']
   
   tt_e_scan_d1 = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']
   tt_e_scan_d2 = ['2017-03-26/02:34:25', '2017-03-26/02:43:30']
   tt_e_scan_d3 = ['2017-03-26/03:13:20', '2017-03-26/03:23:00']
   tt_e_scan_d4 = ['2017-03-26/04:21:55', '2017-03-26/04:30:45']

   tt_e_scan_d_anodes = ['2017-03-26/08:41:10', '2017-03-26/10:36:20']

   tt_e_scan_d_an15 = ['2017-03-26/08:39:20', '2017-03-26/08:48:30']
   tt_e_scan_d_an14 = ['2017-03-26/08:48:30', '2017-03-26/08:55:50']
   tt_e_scan_d_an13 = ['2017-03-26/08:55:50', '2017-03-26/09:02:40']
   tt_e_scan_d_an12 = ['2017-03-26/09:02:40', '2017-03-26/09:10:10']
   tt_e_scan_d_an11 = ['2017-03-26/09:10:10', '2017-03-26/09:17:10']
   tt_e_scan_d_an10 = ['2017-03-26/09:17:10', '2017-03-26/09:24:10']
   tt_e_Scan_d_an09 = ['2017-03-26/09:24:10', '2017-03-26/09:31:20']
   tt_e_scan_d_an08 = ['2017-03-26/09:31:20', '2017-03-26/09:38:20']
   tt_e_scan_d_an07 = ['2017-03-26/09:38:20', '2017-03-26/09:45:20']
   tt_e_scan_d_an06 = ['2017-03-26/09:45:20', '2017-03-26/09:52:10']
   tt_e_scan_d_an05 = ['2017-03-26/09:52:10', '2017-03-26/09:59:10']
   tt_e_scan_d_an04 = ['2017-03-26/09:59:10', '2017-03-26/10:06:10']
   tt_e_scan_d_an03 = ['2017-03-26/10:06:10', '2017-03-26/10:13:20']
   tt_e_scan_d_an02 = ['2017-03-26/10:13:20', '2017-03-26/10:20:20']
   tt_e_scan_d_an01 = ['2017-03-26/10:20:20', '2017-03-26/10:27:10']
   tt_e_scan_d_an00 = ['2017-03-26/10:27:34', '2017-03-26/10:34:50']

   str_e_scan_davin_1 = [{name:'full', tt_mass_scan:tt_e_scan_full1},  $
                         {name:'d1',  tt_mass_scan:tt_e_scan_d1},  $
                         {name:'d2',  tt_mass_scan:tt_e_scan_d2},  $
                         {name:'d3',  tt_mass_scan:tt_e_scan_d3},  $
                         {name:'d4',  tt_mass_scan:tt_e_scan_d4}]


   str_e_scan_davin_2 = [{name:'full', tt_mass_scan:tt_e_scan_full2},  $
                         {name:'anode_00', tt_e_scan:tt_e_scan_d_an00}, $
                         {name:'anode_01', tt_e_scan:tt_e_scan_d_an01}, $
                         {name:'anode_02', tt_e_scan:tt_e_scan_d_an02}, $
                         {name:'anode_03', tt_e_scan:tt_e_scan_d_an03}, $
                         {name:'anode_04', tt_e_scan:tt_e_scan_d_an04}, $
                         {name:'anode_05', tt_e_scan:tt_e_scan_d_an05}, $
                         {name:'anode_06', tt_e_scan:tt_e_scan_d_an06}, $
                         {name:'anode_07', tt_e_scan:tt_e_scan_d_an07}, $
                         {name:'anode_08', tt_e_scan:tt_e_scan_d_an08}, $
                         {name:'anode_09', tt_e_scan:tt_e_scan_d_an09}, $
                         {name:'anode_10', tt_e_scan:tt_e_scan_d_an10}, $
                         {name:'anode_11', tt_e_scan:tt_e_scan_d_an11}, $
                         {name:'anode_12', tt_e_scan:tt_e_scan_d_an12}, $
                         {name:'anode_13', tt_e_scan:tt_e_scan_d_an13}, $
                         {name:'anode_14', tt_e_scan:tt_e_scan_d_an14}, $
                         {name:'anode_15', tt_e_scan:tt_e_scan_d_an15}]
   
   
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight CPT                      ;;;
   ;;;                       APL EMC Facility                       ;;;
   ;;;                          2017-06-29                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2017-06-29/18:25:00']
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight LPT                      ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-01-22                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-01-23/02:00:00']

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight Cover                    ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-01-22                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-02-24/07:23:56']

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                  SPAN-Ai Flight Hot/Cold CPT                 ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-03-06                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-03-06/00:00:00','2018-03-09/00:00:00'] 

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight MSIM-4                   ;;;
   ;;;                          Astro-Tech                          ;;;
   ;;;                          2018-05-15                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-05-15']

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight Aliveness                ;;;
   ;;;                        SLC-39 Cape Canaveral                 ;;;
   ;;;                          2018-08-11                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-08-11']

   

   str_mass_scan_1 = [{name:'full', tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N+',   tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N2+',  tt_mass_scan:tt_mass_scan_nitrogen}]
   str_mass_scan_2 = [{name:'full', tt_mass_scan:tt_mass_scan_gas_mix},  $
                      {name:'H+',   tt_mass_scan:tt_mass_scan_h},   $
                      {name:'H2+',  tt_mass_scan:tt_mass_scan_h2},  $
                      {name:'He+',  tt_mass_scan:tt_mass_scan_he},  $
                      {name:'m4',   tt_mass_scan:tt_mass_scan_m4},  $
                      {name:'m5',   tt_mass_scan:tt_mass_scan_m5},  $
                      {name:'m6',   tt_mass_scan:tt_mass_scan_m6},  $
                      {name:'m7',   tt_mass_scan:tt_mass_scan_m7},  $
                      {name:'m8',   tt_mass_scan:tt_mass_scan_m8},  $
                      {name:'m9',   tt_mass_scan:tt_mass_scan_m9},  $
                      {name:'m10',  tt_mass_scan:tt_mass_scan_m10}, $
                      {name:'m11',  tt_mass_scan:tt_mass_scan_m11}, $
                      {name:'m12',  tt_mass_scan:tt_mass_scan_m12}, $
                      {name:'m13',  tt_mass_scan:tt_mass_scan_m13}]



   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;                                                                ;;
   ;;               __    ___   __  ___   __________  __             ;; 
   ;;              / /   /   | / / / / | / / ____/ / / /             ;;
   ;;             / /   / /| |/ / / /  |/ / /   / /_/ /              ;;
   ;;            / /___/ ___ / /_/ / /|  / /___/ __  /               ;;
   ;;           /_____/_/  |_\____/_/ |_/\____/_/ /_/                ;;
   ;;                                                                ;;
   ;;                                                                ;;
   ;;                  Kennedy Space Center                          ;;
   ;;                       2018-08-13                               ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




   

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                       Second Turn On                         ;;;
   ;;;                 Sept 3, 2018 (Mission Day 23)                ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                    First High Voltage Ramp                   ;;;
   ;;;                 Sept 3, 2018 (Mission Day 23)                ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ;; !!!  First Turn On, Cover Open and Acutation  !!! 
   ;; !!!             2018-0?-0? - APL              !!!
   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   ;; First Turn on
   ;; tt_on_1 = ['','']
   
   ;; Cover Open
   ;; tt_flight_cvr_open = ['','']

   ;; 1st Actuation
   ;; tt_act_1 = ['','']

   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ;; !!!!!     Second Turn On, First HV Ramp     !!!!! 
   ;; !!!!!           2018-09-05 - APL            !!!!!
   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   ;; Second Turn on
   tt_on_2 = ['2018-09-05/22:36:40','2018-09-05/23:05:00']
   
   ;; 1st High Voltage Ramp up and 15kV Conditioning
   tt_hv_on_1 = ['2018-09-05/22:55:00','2018-09-06/05:58:00']

   ;; 1st Background Measurement
   tt_bkg_1 = ['2018-09-06/05:47:00','2018-09-06/09:35:40']
   
   ;; 1st CPT
   tt_cpt_1 = ['2018-09-06/09:37:05','2018-09-06/10:48:25']

   ;; 1st Ramp Down
   tt_hv_off_1 = ['2018-09-06/17:13:26','2018-09-06/17:15:00']
   
   ;; 2nd High Voltage Ramp up
   tt_hv_on_2 = ['2018-09-08/01:40:22','2018-09-08/01:47:32']

   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ;; !!!!!!!          TRANSIENT SLEW           !!!!!!!
   ;; !!!!!!!         2018-09-08 - APL          !!!!!!!
   ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   ;; Transient Slew
   tt_transient_slew = ['2018-09-08/04:47:00','2018-09-08/05:27:40']

   ;; 2nd Background Measurement
   tt_bkg_2 = ['2018-09-08/05:39:30','2018-09-08/09:11:30']

   ;; 1st MCP Gain Test (Sequence 77?)
   tt_mcp_gain_1 = ['2018-09-08/07:53:50','2018-09-08/08:30:45']
   
   ;; 2nd Ramp Down
   tt_hv_off_2 = ['2018-09-08/09:18:30','2018-09-08/09:30:00']

   full = ['2018-09-05/22:36:40','2018-09-08/09:30:00']
   

   table = {$

           ;; CALIBRATION EVENTS
           calibration:{$
           tt_gunmap_1:tt_gunmap_1,$
           tt_gunmap_11:tt_gunmap_11,$
           tt_gunmap_12:tt_gunmap_12,$
           tt_rotscan_1:tt_rotscan_1,$
           tt_rotscan_2:tt_rotscan_2,$
           tt_threshscan_1:tt_threshscan_1,$
           tt_threshscan_2:tt_threshscan_2,$
           tt_eascan_1:tt_eascan_1,$
           tt_ksweep_1:tt_ksweep_1,$
           str_def_sweep:str_def_sweep,$
           str_yaw_sweep:str_yaw_sweep,$
           str_mass_scan_1:str_mass_scan_1,$
           str_mass_scan_2:str_mass_scan_2,$
           str_e_scan_davin_1:str_e_scan_davin_1,$
           str_e_scan_davin_2:str_e_scan_davin_2},$
           
           ;; FLIGHT EVENTS
           flight:{$
           tt_on_2:tt_on_2,$
           tt_hv_on_1:tt_hv_on_1,$
           tt_bkg_1:tt_bkg_1,$
           tt_cpt_1:tt_cpt_1,$
           tt_hv_off_1:tt_hv_off_1,$
           tt_hv_on_2:tt_hv_on_2,$
           tt_transient_slew:tt_transient_slew,$
           tt_bkg_2:tt_bkg_2,$
           tt_mcp_gain_1:tt_mcp_gain_1,$
           tt_hv_off_2:tt_hv_off_2,$
           full:full}}

END
