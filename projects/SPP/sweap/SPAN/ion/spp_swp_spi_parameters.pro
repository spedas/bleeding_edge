PRO spp_swp_spi_parameters, vals


   ;;------------------------------------------------------
   ;; Time-of-Flight Bin to Nanoseconds

   ;; Original 2048 array bin size in nanoseconds
   tof_bin = 0.101725 

   ;; TOF Histogram
   ;; Compression 1: Cut off LSB and scheme below
   tof2048 = findgen(2048)*tof_bin
   tof1024 = tof2048[findgen(1024)*2]
   p1 = tof1024[0:255]
   p2 = (tof1024[256:511])[findgen(128)*2]
   p3 = (tof1024[512:1023])[findgen(128)*4]
   tof512 = [p1,p2,p3]
   tof512_factor = [replicate(2,256),$
                    replicate(4,128),$
                    replicate(8,128)]

   ;;------------------------------------------------------
   ;; DAC to Deflection (from deflector scan)
   ;;
   ;; Ion Gun: 0.85[A], 480 [eV]
   ;;
   ;; [0] + [1]*yaw + [2]*yaw^2 + [3]*yaw^3
   ;;
   anode0_poly = [-172.984,1110.45,0.5,-0.08]

   ;;------------------------------------------------------
   ;; DAC to Voltage (DVM from HV Calibration Test)

   ;; Hemisphere 
   hemi_dacs = ['0000'x,'0040'x,'0080'x,'00C0'x,'0100'x,$
                '0280'x,'0500'x,'0800'x,'0C00'x,'1000'x]
   hemi_volt = [0.006,-3.903,-7.8,-11.7,-15.61,$
                -39.04,-78.1,-125,-187.5,-250]

   ;; Deflector 1
   def1_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def1_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Deflector 2
   def2_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def2_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Spoiler 
   splr_dacs = ['0000'x,'0100'x,'0200'x,'0400'x,'1000'x,'4000'x]
   splr_volt = [0.0003,-0.31,-0.62,-1.243,-4.974,-19.9]


   hemi_fitt = linfit(hemi_dacs,hemi_volt)
   def1_fitt = linfit(def1_dacs,def1_volt)
   def2_fitt = linfit(def2_dacs,def2_volt)
   splr_fitt = linfit(splr_dacs,splr_volt)


   vals = {$

          hemi_dacs:hemi_dacs,$
          def1_dacs:def1_dacs,$
          def2_dacs:def2_dacs,$
          splr_dacs:splr_dacs,$
          
          hemi_volt:hemi_volt,$
          def1_volt:def1_volt,$
          def2_volt:def2_volt,$
          splr_volt:splr_volt,$

          hemi_fitt:hemi_fitt,$
          def1_fitt:def1_fitt,$
          def2_fitt:def2_fitt,$
          splr_fitt:splr_fitt,$

          tof2048:tof2048,$
          tof1024:tof1024,$
          tof512:tof512,$

          tof512_factor:tof512_factor $

          }

END
