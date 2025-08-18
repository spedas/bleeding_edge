;;

PRO esc_iesa_fm1_evt, events


   ;; FM1 Flight Calibrations
   ;;--------------------------------
   ;; POWER ON - 2023-05-16

   ;;------------------
   ;; Characterize Beam
   ;;c_beam_1 = ;;

   ;; TOF Offset Test
   ;; Pre-Adjustment
   tof1 = ['2023-05-16/17:59:10','2023-05-16/18:04:44']
   tof2 = ['2023-05-16/18:25:10','2023-05-16/18:30:22']
   tof3 = ['2023-05-16/18:50:50','2023-05-16/18:55:52']
   tof4 = ['2023-05-16/19:16:26','2023-05-16/19:21:32']
   tof5 = ['2023-05-16/19:42:02','2023-05-16/19:47:12']
   tof6 = ['2023-05-16/20:07:28','2023-05-16/20:12:46']
   tof7 = ['2023-05-16/20:33:02','2023-05-16/20:38:22']
   
   
   ;;tof8
   ;;2023-05-16/20:48:50 2023-05-16/20:54:04 2023-05-16/21:03:40 2023-05-16/21:13:24

   ;;tof9   

   ;;#############################################################
   ;;#########             Threshold Scan               ##########
   ;;#############################################################
   thresh_scan_1 = {$
                   ano_0x1F:['2023-05-16/18:04:44','2023-05-16/18:14:22'],$
                   ano_0xF: ['2023-05-16/18:14:22','2023-05-16/18:23:44'],$
                   ano_0x1E:['2023-05-16/18:30:22','2023-05-16/18:40:12'],$
                   ano_0xE: ['2023-05-16/18:40:12','2023-05-16/18:49:36'],$
                   ano_0x1D:['2023-05-16/18:55:52','2023-05-16/19:05:30'],$
                   ano_0xD: ['2023-05-16/19:05:30','2023-05-16/19:15:12'],$
                   ano_0x1C:['2023-05-16/19:21:32','2023-05-16/19:31:18'],$ 
                   ano_0xC: ['2023-05-16/19:31:18','2023-05-16/19:40:48'],$
                   ano_0x1B:['2023-05-16/19:47:12','2023-05-16/19:56:58'],$
                   ano_0xB: ['2023-05-16/19:56:58','2023-05-16/20:06:24'],$
                   ano_0x1A:['2023-05-16/20:12:46','2023-05-16/20:22:28'],$
                   ano_0xA: ['2023-05-16/20:22:28','2023-05-16/20:31:56'],$
                   ano_0x19:['2023-05-16/20:38:22','2023-05-16/20:47:42'],$
                   ano_0x18:0,$
                   ano_0x8: 0,$
                   ano_0x17:0,$
                   ano_0x16:0,$
                   ano_0x6: 0,$
                   ano_0x15:0,$
                   ano_0x14:0,$
                   ano_0x4: 0,$
                   ano_0x13:0,$
                   ano_0x12:0,$
                   ano_0x2: 0,$
                   ano_0x11:0,$
                   ano_0x10:0,$
                   ano_0x0: 0$
   }


   ;; YAW-LIN-DEF2-SCAN
   yld2 = ['2023-05-17/18:08:00','2023-05-17/23:22:00']





   

   ;;#############################################################
   ;;#########                 Mass Scans               ##########
   ;;#############################################################
   ;;
   ;;   File1: 20230618_141824/eesa.cmb
   ;;   File2: 20230618_201824/eesa.cmb
   ;;
   ;;   TOF Corrections:
   ;;     [ 3, 1, 3, 0, 1, 4, 6, 6, 4, 6, 5, 5, 6, 5, 5, 5]
   ;;     This was set mistakenly and should have been reversed.
   ;;
   ;;   Scan 1:
   ;;      Colutron Beam Energy - 1keV
   ;;      Einzel Lens Focus - 66V
   ;;      Wien Filter E-Field: 50V / 1.72cm ;; Double Check
   ;;      Wien Filter B-Field: Sweep electromagnet from 0.1A to 1.8A
   ;;      Deflection: 18V
   ;;      Fixed Hemisphere DAC: 0x2EE0
   ;;      Deflector DACs: 0x0
   mscan_full_1kev=['2023-06-18/22:51:30','2023-06-19/00:56:00']

   ;;   Scan 2:
   ;;      Colutron Beam Energy - 2keV
   ;;      Einzel Lens Focus - 120V
   ;;      Wien Filter E-Field: 75V / 1.72cm ;; Double Check
   ;;      Wien Filter B-Field: Sweep electromagnet from 0.1A to 1.8A
   ;;      Deflection: 18V
   ;;      Fixed Hemisphere DAC at 0x4120
   ;;      Deflector DACs at 0x0
   mscan_full_2kev=['2023-06-19/01:36:30','2023-06-19/01:59:10']
   mscan_part_2kev=['2023-06-19/02:06:50','2023-06-19/03:15:10']

   ;;   Scan 3:
   ;;      Colutron Beam Energy - 5keV
   ;;      Einzel Lens Focus - 310V
   ;;      Wien Filter E-Field: 160V / 1.72cm ;; Double Check
   ;;      Wien Filter B-Field: Sweep electromagnet from 0.175A to 2.0A
   ;;      Deflection: 22.5V
   ;;      Fixed Hemisphere DAC at 0x6720
   ;;      Deflector DACs at 0x0
   mscan_full_5kev=['2023-06-19/03:53:00','2023-06-19/04:56:40']
   
   ;; Hemisphere Sweep
   ;;   Colutron Beam Energy - 2keV - He+
   hemi_scan_2kev_he=['2023-06-19/01:09:06','2023-06-19/01:13:06']


   
   ;;#############################################################
   ;;#########             Energy Angle Scan            ##########
   ;;#############################################################
   ;; 
   ;;   File: 20230622_100829/eesa.cmb
   ;;
   ;;   Scan 1:
   ;;      Beam Energy: 480eV
   ;;      Table: 400eV - 600eV, +-15 Degrees
   eascan_1=['2023-06-22/17:39:08','2023-06-22/17:48:42']

   ;;   Scan 2:
   ;;      Beam Energy: 495eV
   ;;      Table: 400eV - 600eV, +-15 Degrees
   eascan_2=['2023-06-22/17:56:50','2023-06-22/18:06:26']

   ;;   Scan 3:
   ;;      Beam Energy: 450eV
   ;;      Table: 400eV - 600eV, +-15 Degrees
   ;;      Spoiler Engaged: Ratio of 0.25 to Hemisphere
   eascan_3=['2023-06-22/18:31:59','2023-06-22/18:41:40']

   ;;   Scan 4:
   ;;      Beam Energy: 495eV
   ;;      Table: 400eV - 600eV, +-15 Degrees
   ;;      Mechanical Attenuator Engaged
   eascan_4=['2023-06-22/18:47:09','2023-06-22/18:56:48']

   ;;   Scan 5:
   ;;      Beam Energy: 450eV
   ;;      Table: 400eV - 600eV, +-15 Degrees
   ;;      Mechanical Attenuator + Spoiler (0.25 Ratio) Engaged
   eascan_5=['2023-06-22/19:00:55,''2023-06-22/19:10:30']
    
    
   ;; Rotation Scan
   ;;   File: 20230623_100831/eesa.cmb
   ;;
   
   
   ;; Deflector - Yaw Scan
   ;;   File: 20230622_160830/eesa.cmb
   ;;   Beam Energy: 495eV
   ;;   Table: 400eV - 600eV, +-15 Degrees
   ;;   Yaw Steps: 5 Degrees
   ;;   Yaw Range: -45 to +43
   defyawscan_1=['2023-06-23/00:56:40','2023-06-23/01:52:05']


   ;; Rotation Scan
   ;; File: 20230621_070019/eesa.cmb
   ;; Beam between 19-20eV
   ;; Table: 0.5 - 60eV
   ;; Only Hemisphere sweeping
   rotscan_x=['2023-06-21/18:45:25','2023-06-21/19:04:45']

   ;; Rotation Scan
   ;; File: 20230621_070019/eesa.cmb
   ;; Beam between 19-20eV
   ;; Table: 0.5 - 60eV
   ;; Hemisphere + DEF1 + DEF2 
   rotscan_x=['2023-06-21/19:14:55','2023-06-21/19:34:50']

   ;; Rotation Scan
   ;; File: 20230621_070019/eesa.cmb
   ;; Beam between 19-20eV
   ;; Table: 0.5 - 60eV
   ;; Hemisphere + DEF1 + DEF2 
   rotscan_x=['2023-06-21/19:14:55','2023-06-21/19:34:50']
   
   ;; Rotation Scan
   ;; File: 
   ;; Spoiler On
   ;; Beam at 495eV
   
   rotscan_x=['2023-06-22/00:02:00','2023-06-22/00:25:00']

   ;; Deflector - Yaw Scan
   ;; File: 20230623_100831/eesa.cmb
   ;; Beam: 1keV
   ;; Hemisphere Sweep Only
   defyawscan_2=['2023-06-23/17:17:56','2023-06-23/17:41:54']

   ;; Deflector - Yaw Scan
   ;; File: 20230623_100831/eesa.cmb
   ;; Beam: 1keV
   ;; Hemisphere + Spoiler Sweep   
   defyawscan_3=['2023-06-23/17:57:06','2023-06-23/18:15:54']

   ;; Yaw Scan
   ;; File: 20230623_100831/eesa.cmb
   ;; Full -45 to 45 Degrees
   ;; Beam 495eV
   yawscan_x=['2023-06-23/18:31:16','2023-06-23/18:34:26']


   ;; Rearrange Array
   events = {yawscan_x:yawscan_x}

END

