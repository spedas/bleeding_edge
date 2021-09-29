;+
;
;              MODE 6
;
; SWEM State Configuration for SPAN-Ai
;
; User must define the following tables
; -------------------------------------
; Product i | Full     | Mass j
; Product i | Targeted | Mass j
; 0 <= i <= 2
; 0 <= j <= 3
; Total: 24 Products
;
; Table Options
; -------------
; 1D - '16A' , '32E' , '08D' 
; 2D - '08Dx32E' , '08Dx16A'
; 3D - '08Dx32Ex16A'
; D - Deflector
; E - Energy
; A - Anode
;
; Special Case: '1D'
; ------------------
; This simply sums over all steps
; and anodes but leaves the mass
; variable.
;
; Summing Options
; ---------------
; Define exponent n of 2**n for
; Archive and Survey Products.
; ar - Archive
; sr - Survey
; Value range: 0 <= n <= 16
;
; SVN Properties
; --------------
; $LastChangedRevision: 26842 $
; $LastChangedDate: 2019-03-17 22:56:35 -0700 (Sun, 17 Mar 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_config_flight_calibration.pro $
;-


PRO spp_swp_spi_config_flight_calibration, mem, info

   ind16 = replicate(0,16)
   ind32 = replicate(1,16)
   ind48 = replicate(2,16)
   ind64 = replicate(3,16)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;           Product 0               ;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;     Full Sweep     ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   full_p0_m0    = '16A'
   pm_full_p0_m0 = 16
   mr_full_p0_m0 = ind16
   ar_full_p0_m0 = 0
   sr_full_p0_m0 = 3
   
   ;; Mass 1 
   full_p0_m1    = '16A'
   pm_full_p0_m1 = 16 
   mr_full_p0_m1 = ind32
   ar_full_p0_m1 = 0
   sr_full_p0_m1 = 3
   
   ;; Mass 2
   full_p0_m2    = '16A'
   pm_full_p0_m2 = 16
   mr_full_p0_m2 = ind48
   ar_full_p0_m2 = 0
   sr_full_p0_m2 = 3
   
   ;; Mass 3 
   full_p0_m3   = '16A'
   pm_full_p0_m3 = 16
   mr_full_p0_m3 = ind64
   ar_full_p0_m3 = 0
   sr_full_p0_m3 = 3
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;   Targeted Sweep   ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   targ_p0_m0    = '16A'
   pm_targ_p0_m0 = 16
   mr_targ_p0_m0 = ind16
   ar_targ_p0_m0 = 0
   sr_targ_p0_m0 = 3
   
   ;; Mass 1 
   targ_p0_m1    = '16A'
   pm_targ_p0_m1 = 16
   mr_targ_p0_m1 = ind32
   ar_targ_p0_m1 = 0
   sr_targ_p0_m1 = 3

   ;; Mass 2
   targ_p0_m2    = '16A'
   pm_targ_p0_m2 = 16
   mr_targ_p0_m2 = ind48
   ar_targ_p0_m2 = 0
   sr_targ_p0_m2 = 3
   
   ;; Mass 3 
   targ_p0_m3   = '16A'
   pm_targ_p0_m3 = 16
   mr_targ_p0_m3 = ind64
   ar_targ_p0_m3 = 0
   sr_targ_p0_m3 = 3

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;           Product 1               ;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;     Full Sweep     ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   full_p1_m0    = '08Dx32E'
   pm_full_p1_m0 = 1
   mr_full_p1_m0 = ind16
   ar_full_p1_m0 = 0
   sr_full_p1_m0 = 1

   ;; Mass 1 
   full_p1_m1    = '08Dx32E'
   pm_full_p1_m1 = 1
   mr_full_p1_m1 = ind32
   ar_full_p1_m1 = 0
   sr_full_p1_m1 = 1
   
   ;; Mass 2
   full_p1_m2    = '08Dx32E'
   pm_full_p1_m2 = 1
   mr_full_p1_m2 = ind48
   ar_full_p1_m2 = 0
   sr_full_p1_m2 = 1
   
   ;; Mass 3 
   full_p1_m3   = '08Dx32E'
   pm_full_p1_m3 = 1
   mr_full_p1_m3 = ind64
   ar_full_p1_m3 = 0
   sr_full_p1_m3 = 1
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;   Targeted Sweep   ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   targ_p1_m0    = '08Dx32E'
   pm_targ_p1_m0 = 1
   mr_targ_p1_m0 = ind16
   ar_targ_p1_m0 = 0
   sr_targ_p1_m0 = 1
   
   ;; Mass 1 
   targ_p1_m1    = '08Dx32E'
   pm_targ_p1_m1 = 1
   mr_targ_p1_m1 = ind32
   ar_targ_p1_m1 = 0
   sr_targ_p1_m1 = 1
   
   ;; Mass 2
   targ_p1_m2    = '08Dx32E'
   pm_targ_p1_m2 = 1
   mr_targ_p1_m2 = ind48
   ar_targ_p1_m2 = 0
   sr_targ_p1_m2 = 1
   
   ;; Mass 3 
   targ_p1_m3   = '08Dx32E'
   pm_targ_p1_m3 = 1
   mr_targ_p1_m3 = ind64
   ar_targ_p1_m3 = 0
   sr_targ_p1_m3 = 1

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;           Product 2               ;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;     Full Sweep     ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   full_p2_m0    = '32E'
   pm_full_p2_m0 = 16
   mr_full_p2_m0 = ind16
   ar_full_p2_m0 = 0
   sr_full_p2_m0 = 3
   
   ;; Mass 1 
   full_p2_m1    = '32E'
   pm_full_p2_m1 = 16
   mr_full_p2_m1 = ind32
   ar_full_p2_m1 = 0
   sr_full_p2_m1 = 3
   
   ;; Mass 2
   full_p2_m2    = '32E'
   pm_full_p2_m2 = 16
   mr_full_p2_m2 = ind48
   ar_full_p2_m2 = 0
   sr_full_p2_m2 = 3
   
   ;; Mass 3 
   full_p2_m3   = '32E'
   pm_full_p2_m3 = 16
   mr_full_p2_m3 = ind64
   ar_full_p2_m3 = 0
   sr_full_p2_m3 = 3
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;   Targeted Sweep   ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Mass 0
   targ_p2_m0    = '32E'
   pm_targ_p2_m0 = 16
   mr_targ_p2_m0 = ind16
   ar_targ_p2_m0 = 0
   sr_targ_p2_m0 = 3
   
   ;; Mass 1 
   targ_p2_m1    = '32E'
   pm_targ_p2_m1 = 16
   mr_targ_p2_m1 = ind32
   ar_targ_p2_m1 = 0
   sr_targ_p2_m1 = 3
   
   ;; Mass 2
   targ_p2_m2    = '32E'
   pm_targ_p2_m2 = 16
   mr_targ_p2_m2 = ind48
   ar_targ_p2_m2 = 0
   sr_targ_p2_m2 = 3
   
   ;; Mass 3 
   targ_p2_m3   = '32E'
   pm_targ_p2_m3 = 16
   mr_targ_p2_m3 = ind64
   ar_targ_p2_m3 = 0
   sr_targ_p2_m3 = 3
   


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;        Assemble Products          ;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ;;; NOTE ;;;
   ;; Assembly is based on sweep sequence (full - targeted - full -...)

   prod_type = [ $
               full_p0_m0 , full_p0_m1 , full_p0_m2 , full_p0_m3 , $
               targ_p0_m0 , targ_p0_m1 , targ_p0_m2 , targ_p0_m3 , $
               full_p1_m0 , full_p1_m1 , full_p1_m2 , full_p1_m3 , $
               targ_p1_m0 , targ_p1_m1 , targ_p1_m2 , targ_p1_m3 , $
               full_p2_m0 , full_p2_m1 , full_p2_m2 , full_p2_m3 , $
               targ_p2_m0 , targ_p2_m1 , targ_p2_m2 , targ_p2_m3]

   pmbins = [ $
            pm_full_p0_m0 , pm_full_p0_m1 , pm_full_p0_m2 , pm_full_p0_m3 , $
            pm_targ_p0_m0 , pm_targ_p0_m1 , pm_targ_p0_m2 , pm_targ_p0_m3 , $
            pm_full_p1_m0 , pm_full_p1_m1 , pm_full_p1_m2 , pm_full_p1_m3 , $
            pm_targ_p1_m0 , pm_targ_p1_m1 , pm_targ_p1_m2 , pm_targ_p1_m3 , $
            pm_full_p2_m0 , pm_full_p2_m1 , pm_full_p2_m2 , pm_full_p2_m3 , $
            pm_targ_p2_m0 , pm_targ_p2_m1 , pm_targ_p2_m2 , pm_targ_p2_m3]

   ar_sum = [ $
            ar_full_p0_m0 , ar_full_p0_m1 , ar_full_p0_m2 , ar_full_p0_m3 , $
            ar_targ_p0_m0 , ar_targ_p0_m1 , ar_targ_p0_m2 , ar_targ_p0_m3 , $
            ar_full_p1_m0 , ar_full_p1_m1 , ar_full_p1_m2 , ar_full_p1_m3 , $
            ar_targ_p1_m0 , ar_targ_p1_m1 , ar_targ_p1_m2 , ar_targ_p1_m3 , $
            ar_full_p2_m0 , ar_full_p2_m1 , ar_full_p2_m2 , ar_full_p2_m3 , $
            ar_targ_p2_m0 , ar_targ_p2_m1 , ar_targ_p2_m2 , ar_targ_p2_m3]
   
   sr_sum = [ $
            sr_full_p0_m0 , sr_full_p0_m1 , sr_full_p0_m2 , sr_full_p0_m3 , $
            sr_targ_p0_m0 , sr_targ_p0_m1 , sr_targ_p0_m2 , sr_targ_p0_m3 , $
            sr_full_p1_m0 , sr_full_p1_m1 , sr_full_p1_m2 , sr_full_p1_m3 , $
            sr_targ_p1_m0 , sr_targ_p1_m1 , sr_targ_p1_m2 , sr_targ_p1_m3 , $
            sr_full_p2_m0 , sr_full_p2_m1 , sr_full_p2_m2 , sr_full_p2_m3 , $
            sr_targ_p2_m0 , sr_targ_p2_m1 , sr_targ_p2_m2 , sr_targ_p2_m3]
   
   mrbins = [ $
            mr_full_p0_m0 , mr_full_p0_m1 , mr_full_p0_m2 , mr_full_p0_m3 , $
            mr_targ_p0_m0 , mr_targ_p0_m1 , mr_targ_p0_m2 , mr_targ_p0_m3 , $
            mr_full_p1_m0 , mr_full_p1_m1 , mr_full_p1_m2 , mr_full_p1_m3 , $
            mr_targ_p1_m0 , mr_targ_p1_m1 , mr_targ_p1_m2 , mr_targ_p1_m3 , $
            mr_full_p2_m0 , mr_full_p2_m1 , mr_full_p2_m2 , mr_full_p2_m3 , $
            mr_targ_p2_m0 , mr_targ_p2_m1 , mr_targ_p2_m2 , mr_targ_p2_m3]

   ed_length  = []
   str_addr = intarr(25)

   FOR i = 0, 23 DO BEGIN 
      CASE prod_type[i] OF
         '08D':BEGIN
            ed_length  = [ed_length, mem.prod_08D_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END 
         '32E':BEGIN
            ed_length  = [ed_length, mem.prod_32E_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         '16A':BEGIN
            ed_length  = [ed_length, mem.prod_16A_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         '08Dx32E':BEGIN
            ed_length  = [ed_length, mem.prod_08Dx32E_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         '08Dx16A':BEGIN
            ed_length  = [ed_length, mem.prod_08Dx16A_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         '32Ex16A':BEGIN		
            ed_length  = [ed_length, mem.prod_32Ex16A_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         ;; NOTE
         ;;  For product 08Dx32Ex08A we are exluding certain
         ;;  anodes from being collected. The size of the packet
         ;;  stays the same at 2048 but the start address is
         ;;  shifted by 2 addresses in order to allow certain
         ;;  anode data to be thrown away.
         '08Dx32Ex08A':BEGIN
            ed_length  = [ed_length, mem.prod_08Dx32Ex08A_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]+2

            ;; DOUBLE CHECK THIS MISTAKE IN MODE %!!!!
            ;;ed_length.append(sat.tables.prod_08x32Ex08A_dpp_size)
            ;;start_addr.append(start_addr[i]+pmbins[i]*ed_length[i]+2)
         END
         '08Dx32Ex16A':BEGIN 
            ed_length  = [ed_length, mem.prod_08Dx32Ex16A_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         '1D':BEGIN
            ed_length  = [ed_length, mem.prod_1D_dpp_size]
            str_addr[i+1] = str_addr[i]+pmbins[i]*ed_length[i]
         END
         ELSE:BEGIN
            print, prod_type[i],' does not exist.'
            print, 'Cancelling product.'
            return
         END
      ENDCASE
   ENDFOR

   ;; Insert values into corresponding arrays
   pr_length = []
   FOR i=0, 23 DO pr_length = $
    [pr_length, str_addr[i+1]-str_addr[i]]      

   ;; Product Sequence
   proseq = ['F00','F01','F02','F03',$
             'T00','T01','T02','T03',$
             'F10','F11','F12','F13',$
             'T10','T11','T12','T13',$
             'F20','F21','F22','F23',$
             'T20','T21','T22','T23']

   ;; Get Energy-Mass LUT
   ;; spp_swp_spi_get_mlut,mlut,mlut_chk
   ;; Get Product Sum LUT
   spp_swp_spi_get_psumlut, ar_sum, sr_sum, psum, psum_chk
   ;; Get Mass Range LUT
   spp_swp_spi_get_mrlut, mrbins, mrlut, mrlut_chk
   ;; Get Address Length LUT
   spp_swp_spi_get_allut, str_addr, pr_length, allut, allut_chk
   ;; Get Energy Deflector LUT
   spp_swp_spi_get_edlut, ed_length, edlut, edlut_chk
   ;; Get Product Index LUT
   spp_swp_spi_get_pilut, mem, prod_type, pilut, pilut_chk
   ;; Get Product Mass Bins
   spp_swp_spi_get_pmbins, mrbins, pmbins, pmbins_chk
   
   info = { $

          ;; Configurations
          produc:prod_type,$
          ar_sum:ar_sum,$
          sr_sum:sr_sum,$
          mrbins:mrbins,$
          ed_len:ed_length,$
          pr_len:pr_length,$
          str_ad:str_addr,$
          proseq:proseq,$

          ;; SPAN-Ion Tables
          psum:psum,$
          mrlut:mrlut,$
          allut:allut,$
          edlut:edlut,$
          pilut:pilut,$
          pmbins:pmbins,$

          ;; Checksums
          psum_chk:psum_chk,$
          mrlut_chk:mrlut_chk,$
          allut_chk:allut_chk,$
          edlut_chk:edlut_chk,$
          pilut_chk:pilut_chk,$
          pmbins_chk:pmbins_chk $

   }

   return
   
END
