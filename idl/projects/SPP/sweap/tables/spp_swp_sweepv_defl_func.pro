;+
;
;
;
; SPP_SWP_SWEEPV_DEFL_FUNC
;
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2020-04-08 09:45:22 -0700 (Wed, 08 Apr 2020) $
; $LastChangedRevision: 28525 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_defl_func.pro $
;
;-

FUNCTION spp_swp_sweepv_defl_func, spe = spe, defl_angle

   ;; SPAN-Ion 5th Degree Polynomial Values
   pi = [ -6.6967358589, 1118.9683837891, 0.5826185942, -0.0928234607, 0.0000374681, 0.0000016514]

   ;; SPAN-Electron 5th Degree Polynomial Values (WRONG)
   ;pe = [ -6.6967358589, 1118.9683837891, 0.5826185942, -0.0928234607, 0.0000374681, 0.0000016514]
   pe = [-1396.73, 539.083, 0.802293, -0.0462400, -0.000163369, 0.00000319759]

   ;; Switch to defaults
   p = pi
   if keyword_set(spe) then p = pe
   xparam = defl_angle

   ;; Generate DACS
   defl_dac = p[0]+p[1]*xparam+p[2]*xparam^2+p[3]*xparam^3+p[4]*xparam^4+p[5]*xparam^5

   ;; Return values
   return, defl_dac

END
