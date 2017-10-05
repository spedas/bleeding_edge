

function mav_misg_status_decom,pkt,rec_time = rec_time,last_status=last_status
   if not keyword_set(rec_time) then rec_time =  systime(1)
   buffer_uint = pkt.data
   utc_time = buffer_uint[1] * 2ul^16 + buffer_uint[2] + buffer_uint[3]/2d^16
;   if utc_time lt 323308800L then utc_time -= 7L*3600  ; long(time_double('2011-4-1') - time_double('2001-1-1') )
   time = utc_time + 978307200   ;  ulong( time_double('2001-1-1') )
;   time = utc_time + 946771200   ;  ulong( time_double('2000-1-2') )
   seqcntr = buffer_uint[0]
   seqdcntr  =  0 > (seqcntr - (keyword_set(last_status) ?  last_status.seq_cntr : seqcntr)) < 10u

   last_act_flags2 = (keyword_set(last_status) ?  last_status.act_flags2 : 0u)
   act_flags = buffer_uint[6]
   act_n = ishft(act_flags and 'f0'x ,-4)
;   armed = (act_flags and '2'x) ne 0
;   test  = (act_flags and '200'x) ne 0
   nsense = (act_flags and '100'x) ne 0
   act_flags2 =  (act_flags and '3ff'xu)  or (last_act_flags2 and 'f000'xu)
   valid = (act_flags and '203'x) eq '203'x
;   shiftval= ([5,0,2,5,1,5,3,5, 5,5,5,5,5,5,5,5])[act_n] +10

    if valid then begin
;        nsense = 1u
        if act_n eq 1 then begin
            bit = ishft(1u,10)
            act_flags2 = act_flags2 or (bit * nsense)
            bit = ishft(1u,12)
            act_flags2 = (act_flags2 and not bit) or (bit * nsense)
        endif
        if act_n eq 4 then begin
            bit = ishft(1u,11)
            act_flags2 = act_flags2 or (bit * nsense)
            bit = ishft(1u,13)
            act_flags2 = (act_flags2 and not bit) or (bit * nsense)
        endif
   endif


   status = {time       :   time,               $
             seq_cntr    :   seqcntr        ,$
             seq_dcntr  :    seqdcntr ,    $
             time_delay :   rec_time - time   ,$
 ;            utc_time   :   utc_time         ,  $
             fpga_rev   :   byte(ishft( buffer_uint[4],-8) ) ,  $
             mode_flags :   byte( buffer_uint[4] and 'FF'x )   ,  $
             fifo_cntr  :   byte(ishft(buffer_uint[5],-8))   ,   $
             fifo_flags :   byte(buffer_uint[5] and 'FF'x)    , $
             act_flags  :   act_flags,  $
             act_flags2 :   act_flags2,  $
             act_time   :   buffer_uint[7],  $
             xtr1_flags :   buffer_uint[8],  $
             xtr2_flags :   buffer_uint[9]  }
   return,status
end

