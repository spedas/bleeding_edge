;+
;
; SPP_SWP_SPI_FLIGHT_MEM
;
; :Params:
;    tables : in, optional, type=structure
;       PSP SWEAP SPAN-Ai Flight MRAM Memory Map.
;    config : in, optional, type=structure
;       PSP SWEAP SPAN-Ai Flight Instrument Configuration       
;
; SVN Properties
; --------------
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2020-02-18 15:49:13 -0800 (Tue, 18 Feb 2020) $
; $LastChangedRevision: 28313 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_mem.pro $
;-

PRO spp_swp_spi_flight_mem, tbl

   tbl = { $
         
         ;;##################
         ;;# SRAM Addresses #
         ;;##################

         ;; Sweep Tables
         slut_sram_addr:     '2000'x,$
         fslut_sram_addr:    '1800'x,$
         tslut_sram_addr:    '8000'x,$
         psum_sram_addr:     '4000'x,$
         mrlut_sram_addr:    '4020'x,$
         allut_sram_addr:    '4040'x,$
         edlut_sram_addr:    '4060'x,$
         pmbins_sram_addr:   '4080'x,$

         ;; Product Index Tables
         fs_p0_m0_sram_addr: '10000'x,$
         fs_p0_m1_sram_addr: '10800'x,$
         fs_p0_m2_sram_addr: '11000'x,$
         fs_p0_m3_sram_addr: '11800'x,$
         ts_p0_m0_sram_addr: '12000'x,$
         ts_p0_m1_sram_addr: '12800'x,$
         ts_p0_m2_sram_addr: '13000'x,$
         ts_p0_m3_sram_addr: '13800'x,$
         fs_p1_m0_sram_addr: '14000'x,$
         fs_p1_m1_sram_addr: '14800'x,$
         fs_p1_m2_sram_addr: '15000'x,$
         fs_p1_m3_sram_addr: '15800'x,$
         ts_p1_m0_sram_addr: '16000'x,$
         ts_p1_m1_sram_addr: '16800'x,$
         ts_p1_m2_sram_addr: '17000'x,$
         ts_p1_m3_sram_addr: '17800'x,$
         fs_p2_m0_sram_addr: '18000'x,$
         fs_p2_m1_sram_addr: '18800'x,$
         fs_p2_m2_sram_addr: '19000'x,$
         fs_p2_m3_sram_addr: '19800'x,$
         ts_p2_m0_sram_addr: '1a000'x,$
         ts_p2_m1_sram_addr: '1a800'x,$
         ts_p2_m2_sram_addr: '1b000'x,$
         ts_p2_m3_sram_addr: '1b800'x,$
         mlut_sram_addr:     '1c000'x,$

         ;;#################################################
         ;;#                MRAM Addresses                 #
         ;;#################################################
         
         ;; Description: Calibration
         slut_mram_addr:             '0000'x, $
         fslut_mram_addr:            '8000'x, $
         tslut_mram_addr:            '9000'x, $
         psum_mram_addr:             '8800'x, $
         mrlut_mram_addr:            '8880'x, $
         allut_mram_addr:            '8900'x, $
         edlut_mram_addr:            '8980'x, $
         pmbins_mram_addr:           '8A00'x, $
         spsum_mram_addr:            '8A80'x, $
         mlut_mram_addr:             '29000'x,$
         prod_16A_mram_addr: 	     '69000'x,$
         prod_32E_mram_addr: 	     '6b000'x,$
         prod_08D_mram_addr: 	     '6d000'x,$
         prod_32Ex16A_mram_addr:     '6f000'x,$
         prod_08Dx16A_mram_addr:     '71000'x,$
         prod_08Dx32E_mram_addr:     '73000'x,$
         prod_08Dx32Ex16A_mram_addr: '75000'x,$
         prod_1D_mram_addr:          '77000'x,$

         ;; Description: MODE 1
         mode1_psum_mram_addr:  '79000'x,$
         mode1_mrlut_mram_addr: '79080'x,$
         mode1_allut_mram_addr: '79100'x,$
         mode1_edlut_mram_addr: '79180'x,$
         mode1_pmbins_mram_addr:'79200'x,$

         ;; Description: MODE 2
         mode2_psum_mram_addr:  '79800'x,$
         mode2_mrlut_mram_addr: '79880'x,$
         mode2_allut_mram_addr: '79900'x,$
         mode2_edlut_mram_addr: '79980'x,$
         mode2_pmbins_mram_addr:'79A00'x,$

         ;; Description: MODE 3
         mode3_psum_mram_addr:  '7A000'x,$
         mode3_mrlut_mram_addr: '7A080'x,$
         mode3_allut_mram_addr: '7A100'x,$
         mode3_edlut_mram_addr: '7A180'x,$
         mode3_pmbins_mram_addr:'7A200'x,$

         ;; Description: MODE 4
         mode4_psum_mram_addr:  '7A800'x,$
         mode4_mrlut_mram_addr: '7A880'x,$
         mode4_allut_mram_addr: '7A900'x,$
         mode4_edlut_mram_addr: '7A980'x,$
         mode4_pmbins_mram_addr:'7AA00'x,$

         ;; Description: MODE 5
         mode5_psum_mram_addr:  '7B000'x,$
         mode5_mrlut_mram_addr: '7B080'x,$
         mode5_allut_mram_addr: '7B100'x,$
         mode5_edlut_mram_addr: '7B180'x,$
         mode5_pmbins_mram_addr:'7B200'x,$

         ;; Description: MODE 6
         mode6_psum_mram_addr:  '7B800'x,$
         mode6_mrlut_mram_addr: '7B880'x,$
         mode6_allut_mram_addr: '7B900'x,$
         mode6_edlut_mram_addr: '7B980'x,$
         mode6_pmbins_mram_addr:'7BA00'x,$

         ;; Description: MODE 7
         mode7_psum_mram_addr:  '10E800'x,$
         mode7_mrlut_mram_addr: '10E880'x,$
         mode7_allut_mram_addr: '10E900'x,$
         mode7_edlut_mram_addr: '10E980'x,$
         mode7_pmbins_mram_addr:'10EA00'x,$

         ;; Description: MODE 8
         mode8_psum_mram_addr:  '10F000'x,$
         mode8_mrlut_mram_addr: '10F080'x,$
         mode8_allut_mram_addr: '10F100'x,$
         mode8_edlut_mram_addr: '10F180'x,$
         mode8_pmbins_mram_addr:'10F200'x,$

         ;; Description: MODE 9
         mode9_psum_mram_addr:  '123800'x,$
         mode9_mrlut_mram_addr: '123880'x,$
         mode9_allut_mram_addr: '123900'x,$
         mode9_edlut_mram_addr: '123980'x,$
         mode9_pmbins_mram_addr:'123A00'x,$

         ;; Description: MODE 10
         mode10_psum_mram_addr:  '124000'x,$
         mode10_mrlut_mram_addr: '124080'x,$
         mode10_allut_mram_addr: '124100'x,$
         mode10_edlut_mram_addr: '124180'x,$
         mode10_pmbins_mram_addr:'124200'x,$

         ;; Description: MODE X (Flight Calibration)
         ;;modex_psum_mram_addr:  '324000'x,$
         ;;modex_mrlut_mram_addr: '324080'x,$
         ;;modex_allut_mram_addr: '324100'x,$
         ;;modex_edlut_mram_addr: '324180'x,$
         ;;modex_pmbins_mram_addr:'324200'x,$
         
         ;; Description: Evenly Space FSLUT
         es_fslut_mram_addr:'7C000'x,$
         
         ;; Description: Evenly Space TSLUT  
         es_tslut_mram_addr:'7C800'x,$

         ;; Description: Science Table 1    
         sci_1a_mram_addr:'9C800'x,$
         sci_1b_mram_addr:'A4800'x,$
         
         ;; Description: Science Table 2    
         sci_2a_mram_addr:'AC800'x,$
         sci_2b_mram_addr:'B4800'x,$

         ;; Description: Science Table 3    
         sci_3a_mram_addr:'BC800'x,$
         sci_3b_mram_addr:'C4800'x,$

         ;; Description: Science Table 4    
         sci_4a_mram_addr:'CC800'x,$
         sci_4b_mram_addr:'D4800'x,$

         ;; Description: Calibrated Mass Table
         mlut_sci_mram_addr:'DC800'x,$

         ;; Moments Product
         prod_08Dx32Ex08A_mram_addr:'EC800'x,$

         ;; Description: Science Table 5    
         sci_5a_mram_addr:'EE800'x,$
         sci_5b_mram_addr:'F6800'x,$
         
         ;; Description: Science Table 6    
         sci_6a_mram_addr:'FE800'x,$
         sci_6b_mram_addr:'106800'x,$

         ;; Description: Science Table 7
         sci_7a_mram_addr:'10F800'x,$
         sci_7b_mram_addr:'117800'x,$

         ;; Science Sweep Table 1 (Flight Clibration)
         ;;sci_1x_mram_addr:'39C800'x,$

         ;; Science Sweep Table 2 (Flight Clibration)
         ;;sci_2x_mram_addr:'3A4800'x,$

         ;; Product Sum Full MRAM Addresses
         ;;'sng_psum_mram_addr':

         ;;##############################
         ;;#   Size of table in SRAM.   #
         ;;##############################

         ;; SWEAP Tables
         slut_sram_size:   '2000'x,$
         fslut_sram_size:  '0200'x,$
         tslut_sram_size:  '8000'x,$
         prod_sram_size:   '0800'x,$
         psum_sram_size:   '001c'x,$
         mrlut_sram_size:  '0010'x,$
         allut_sram_size:  '001c'x,$
         edlut_sram_size:  '001c'x,$
         pmbins_sram_size: '001c'x,$
         spsum_sram_size:  '001c'x,$
         mlut_sram_size:   '4000'x,$

         ;; Special Tables
         sng_psum_sram_size: '01'x,$

         ;; DPP packet size and commands
         prod_1D_dpp_size: 		'0002'x,$
         prod_08D_dpp_size: 		'0008'x,$
         prod_32E_dpp_size: 		'0020'x,$
         prod_16A_dpp_size: 		'0010'x,$
         prod_08DX32E_dpp_size: 	'0100'x,$
         prod_32EX16A_dpp_size: 	'0200'x,$
         prod_08DX16A_dpp_size: 	'0080'x,$
         prod_08DX32EX16A_dpp_size: 	'1000'x,$
         prod_08DX32EX08A_dpp_size:     '0800'x,$

         prod_order_sram: [$
         'fs_p0_m0','fs_p0_m1','fs_p0_m2','fs_p0_m3',$
         'ts_p0_m0','ts_p0_m1','ts_p0_m2','ts_p0_m3',$
         'fs_p1_m0','fs_p1_m1','fs_p1_m2','fs_p1_m3',$
         'ts_p1_m0','ts_p1_m1','ts_p1_m2','ts_p1_m3',$
         'fs_p2_m0','fs_p2_m1','fs_p2_m2','fs_p2_m3',$
         'ts_p2_m0','ts_p2_m1','ts_p2_m2','ts_p2_m3'] $

   }


END
