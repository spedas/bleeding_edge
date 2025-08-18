

function mav_sep_hkp_decom,msg,last_hkp=last_hkp,memstate=memstate
   if msg.valid eq 0 then return, fill_nan(last_hkp)
   time = msg.time
   dtime =  0d   ; msg.time - last_hkp.time
   data = [msg.hdr,msg.data]
   amonitor = fix(data[1:8])
   mapid    = byte( ishft( data[9],-8 ) )
   fpga_rev = byte( data[9] and 'ff'x  )
   vcmd_cntr = byte(  ishft( data[10],-8) )
   vcmd_rate= 0b
   icmd_cntr =  byte( data[10] and 'ff'x  )
   icmd_rate = 0b
   cmd_dcntr  = byte( keyword_set(memstate) ?  (memstate.ncmds mod 256) - vcmd_cntr : 0 )
   mode_flags    =  data[11]
   noise_flags    =  data[12]
   noise_res     = byte(  ishft(data[12],-8) and '111'b )
   noise_per    =   byte(data[12] and 'ff'x)
   mem_addr     =  data[13]
   mem_checksum =  byte(  ishft( data[14] ,-8) )
   pps_cntr     =  byte(  data[14] and 'ff'x )
   event_cntr   =  data[15]
   rate_cntr    =  data[16:21]
   cntr1 = byte( ishft( data[22],-12 ) and 'f'x )
   cntr2 = byte( ishft( data[22],-8 ) and 'f'x )
   cntr3 = byte( ishft( data[22],-4 ) and 'f'x )
   cntr4 = byte( ishft( data[22],0 ) and 'f'x )
   timeout_cntrs = [cntr1,cntr2,cntr3,cntr4]
   det_timeout   = byte(ishft(data[23],-8) )
   nopeak_cntr   = byte( data[23] and 'ff'x )
   nopeak_rate   = 0b
   reserved      = data[24]
   par_dap = therm_temp2()
   par_dap.r1 = 50000.
   par_dap.rv = 1e9
   par_dap.xmax = 2.5
   par_s1 = par_dap
   par_s2 = par_s1




   sephkp = {time :      time,      $
             dtime :    dtime,  $
             amonitor:  amonitor,   $
             Amon_Bias_voltage: amonitor[0] * (38.57*2.5/2L^15), $
             Amon_Bias_current: amonitor[1] * 2.5/ 2L^15, $
             Amon_TEMP_DAP: func(par=par_dap,amonitor[2] * 2.5/ 2L^15), $
             Amon_P5VD: amonitor[3] * 2.5/ 2L^15 * 5/2., $
             Amon_P5VA: amonitor[4] * 2.5/ 2L^15 * 5/2., $
             Amon_M5VA: amonitor[5] * 2.5/ 2L^15 * 5/2., $
             Amon_TEMP_S1: func(par=par_s1,amonitor[6] * 2.5/ 2L^15), $
             Amon_TEMP_S2: func(par=par_s2,amonitor[7] * 2.5/ 2L^15), $
             mapid:     mapid,  $
             fpga_rev:   fpga_rev,  $
             vcmd_cntr :   vcmd_cntr  ,   $
             vcmd_rate :   vcmd_rate , $
             icmd_cntr :   icmd_cntr, $
             icmd_rate :   icmd_rate,  $
             cmd_dcntr :   cmd_dcntr,  $
             mode_flags   :   mode_flags   ,  $
             noise_flags   :   noise_flags   ,  $
             noise_res   :   noise_res   ,  $
             noise_per   :   noise_per   ,  $
             mem_addr   :   mem_addr   ,  $
             mem_checksum:  mem_checksum,  $
             pps_cntr:  pps_cntr,  $
             event_cntr:  event_cntr,  $
             rate_cntr:  rate_cntr,  $
             timeout_cntrs:  timeout_cntrs,  $
             det_timeout:  det_timeout,  $
             nopeak_cntr:  nopeak_cntr,  $
             nopeak_rate:  nopeak_rate,  $
             reserved_flags:  reserved    }

    if keyword_set(last_hkp) then begin
        sephkp.dtime  = sephkp.time - last_hkp.time
        sephkp.nopeak_rate = sephkp.nopeak_cntr - last_hkp.nopeak_cntr
        sephkp.vcmd_rate = sephkp.vcmd_cntr - last_hkp.vcmd_cntr
        sephkp.icmd_rate = sephkp.icmd_cntr - last_hkp.icmd_cntr
    endif

   return,sephkp
end

