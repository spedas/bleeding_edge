;Commented out.  Function unused.  Common block undefined. pcruce 2013-04-23
;function sst_calib_params,time=time,probe=probe,instrument=inst
;
;sst_calib_params_com,cal_a,cal_b,cal_c,cal_d,cal_e
;
;f = !values.d_nan
;
;detcal0={detcal,geom0:.1d,   geom_1:0d,scale:1.6d,offset:5.d}
;detcal1=detcal0   & detcal1.geom0 /= 64
;sst_fmt = {time:0l,probe:-1,detn:0,cal:[detcal0,detcal1]}
;if not keyword_set(param) then begin
;
;
;endif
;eflux = 0
;
;
;return,eflux
;end

pro thm_sst_energy_cal,inst=inst,time=time,probe=probe,energy=energy,denergy=denergy


proben = size(/type,probe) eq 7 ? (byte(probe)-byte('a'))[0] : probe[0]

;if inst eq 1 then begin
  dap_borders = [12,19,26,34,44,69,103,150,215,306,506,906,2000,3000,4000,5000,60000]  ; last 4 are fill!

;dprint,'inst=',inst
 ;              electrons                     ions
 ;                                        red    black   orange   blue
  scale =  [[1.6 , 1.6  , 1.6  , 1.6  ] ,  [ 1.6 , 1.6  , 1.6  , 1.6 ]]
  offset = [ $
       [[5.0 , 5.0  , 5.0,   5.0  ] , [[ 3.0 , 8.0  , 12.0,   10.0 ]+1]]  ,$  ; themis x
       [[5.0 , 5.0  , 5.0,   5.0  ] , [[ 5.0 , 5.0  ,  5.0,    5.0 ]+1]]  ,$  ; themis B
       [[[5.0 , 5.0  , 5.0,   5.0  ]+0] , [[ 5.0 , 5.0  ,  5.0,    5.0 ]+1]]  ,$  ; themis C
       [[5.0 , 5.0  , 5.0,   5.0  ] , [[ 3.0 , 8.0  , 12.0,   10.0 ]+1]]  ,$  ; themis D
       [[5.0 , 5.0  , 5.0,   5.0  ] , [[ 5.0 , 5.0  ,  5.0,    5.0 ]+2]]  ,$  ; themis E
       [[5.0 , 5.0  , 5.0,   5.0  ] , [[ 5.0 , 5.0  , 5.0,   5.0 ]+1]]  ]  ; themis x
;  scale =  1.6
;  offset = 8.

  one = replicate(1.,16)
  e_start =  ((dap_borders[0:15] # scale[*,inst])  + (one # offset[*,inst,proben])) * 1000.
  e_end   =  ((dap_borders[1:16] # scale[*,inst])  + (one # offset[*,inst,proben])) * 1000.
  denergy    = e_end - e_start
  energy   = (e_end + e_start)/2

;endif

end
