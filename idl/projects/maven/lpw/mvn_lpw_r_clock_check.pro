
;+
;Program written by Chris Fowler on 2014-06-06 to check for clock jitter in the maven s/c clock. 
;
;USAGE: mvn_lpw_r_clock_check, packet_name, packet_arr, SC, sc_clk1, sc_clk2
;
;EXAMPLE: mvn_lpw_r_clock_check, 'PAS_HF', pkt_PAS_HF, SC, sc_clk1, sc_clk2 
;
;INPUTS:
;
; packet_name: a string of the name of the packet you want to check: Acceptable packet names are:
;             'HSK'
;             'EUV'
;             'SWP1'
;             'SWP2'
;             'ACT'
;             'PAS'
;             'ACT_LF'
;             'ACT_MF'
;             'ACT_HF'
;             'PAS_LF'
;             'PAS_MF'
;             'PAS_HF'
;
; packet_arr: the array containing information for the desired packet. Acceptable packets are:
;             pkt_HSK
;             pkt_EUV
;             pkt_SWP1
;             pkt_SWP2
;             pkt_ACT
;             pkt_PAS
;             pkt_ACT_LF
;             pkt_ACT_MF
;             pkt_ACT_HF
;             pkt_PAS_LF
;             pkt_PAS_MF
;             pkt_PAS_HF
;         
; SC: sequence counter: the array containing packet numbers in the order they are loaded, to check for missing packets.
;         
; sc_clk1: MAVEN s/c second ticks
; sc_clk2: MAVEN s/c sub second ticks (note, these are s/c clock ticks, NOT decimal seconds)
; 
; 
;OUTPUTS:
; sc_clk1 and sc_clk2 will be edited to correct for the ~0.5s clock jitter in the MAVEN s/c clock.
; 
; 
;CREATED: Chris Fowler, 2014, June 6th 
; 
; ### routine still under construction - need to add checks
; 
; Version 1.0
; ;140718 clean up for check out L. Andersson
; ;140916: CF: fixed issue where timesteps just over the mod 4 limit (eg 16.000015 for EUV) were triggering false positives. Added in lower limit to correct this.
; ;150119: CF: added common block to store times that the clock jumps, so they can be saved for statistics.
;
;
;-


pro mvn_lpw_r_clock_check, packet_name, packet_arr, SC, sc_clk1, sc_clk2

common clock_check, jump_times_nospice

;Create temporary coarse decimal clock:
tmp_clk = SC_CLK1+SC_CLK2/2l^16

;Use x mod 4 to determine if there's a clock change. x is the length in time of each packet.
;Use shift function to calculate time differences, since it's more robust - DLM.

indx = packet_arr - shift(packet_arr,1)
indx[0] = 0

tdiff1 = tmp_clk[indx] - tmp_clk[indx]  ;time difference between packets in secs

tdiff2 = tdiff1 mod 4  ;time difference off of expected length between packets. Should be close to zero (<0.01) unless there's a clock jump
;tdiff2 should be ~3.999xxx for EUV. When there's a skip, it will be ~0.499xxxx. 

qq = where((tdiff2 lt 0.6) and (tdiff2 gt 0.4), nqq)   ;for a clock jump, we're looking for values of ~0.499xxx. Add 1 so that qq is the "trouble packet" rather than one before it
                                                       ;Some timesteps can be 16.000015 and so we need a lower limit to avoid false positives.

;stop
;qq needs to have 0.49 subtracted to correct for clock jump
;SC is the sequence counter, ie number ID of each packet. When we get a jump, need to check it's not due to a missing packet next to the trouble packet.
;note that SC can only go up to a certain number so may reset to 0 and then carry on at some point: 16383 is the max value (as 0 is possible: 2^14 = 16384).
;SC contains information from all packets, so it jumps around. packet_arr for eg contains indices within SC which correspond to EUV packets.

jump = 0.499939D  ;clock jump is just below 0.5s. Should try and get an exact number as we want to be precise, use this for now.
;Convert 'jump' to maven sub ticks:
s_ticks = round(jump*(2l^16.))  ;round to nearest s/c tick
h_ticks = 0.5*(2l^16.)  ;half a second, in sc clock ticks
f_ticks = h_ticks*2.

if nqq ge 1 then begin  ;if there's a clock jump
      
      for jj = 0, n_elements(qq)-1 do begin
            if SC[packet_arr[qq[jj]]] eq (SC[packet_arr[qq[jj]-1]]+1) then begin  ;no packet is missing so jump is clock jitter
                  ;No packets missing                           
                  ;sc_clk1 and sc_clk2 are the s/c clock times
                  ;65535 is the max value of the maven subsecond tick clock (sc_clk2). 
                  
                  ;"jump" is in subticks, s_ticks:
                  ;If s_ticks is gt sc_clk2[packet_arr[qq]] then we need to reduce sc_clk1 by 1 second, and subtract the remaining sub ticks from sc_clk2                  
                                  
                  ;Determine if packet lost or gained half a second. If tdiff2 is 4., 4., 3.5, 0.5, 4. then packet has lost 0.5; if 4., 4., 0.5, 3.5, 4. then has gained 0.5:
                  if tdiff2[qq[jj]+1] lt 3.6 then begin  ;qq[jj] finishes 0.5 too long
                        print, "mvn_lpw_r_header_l0: ", packet_name, " : clock jump detected for packet # ", qq[jj]+1
                        
                        ;Subtract 0.5 from qq[jj] +1
                        if s_ticks gt sc_clk2[packet_arr[qq[jj]+1]] then begin   ;left over sub seconds, want to subtract 0.499 seconds
                           
                            sc_clk1[packet_arr[qq[jj]+1]] -= 1.D  ;subtract 1 sec
                            sc_clk2[packet_arr[qq[jj]+1]] += s_ticks   
                                                        
                        endif else sc_clk2[packet_arr[qq[jj]+1]] = sc_clk2[packet_arr[qq[jj]+1]] - s_ticks
                        print, "        packet # ", qq[jj]+1, " timestamp corrected."                            
                        
                        ;Add jump times to common block
                        tmp = SC_CLK1[packet_arr[qq[jj]+1]]+SC_CLK2[packet_arr[qq[jj]+1]]/2l^16
                        jump_times_nospice = [jump_times_nospice, tmp]
                        
                  endif
                  
                  
                  if tdiff2[qq[jj]+1] gt 3.6 then begin  ;qq[jj] starts 0.5 to early
                        print, "mvn_lpw_r_header_l0: ", packet_name, " : clock jump detected for packet # ", qq[jj]
                        ;Add 0.5 to qq[jj]
                        if sc_clk2[packet_arr[qq[jj]]] gt (f_ticks-s_ticks) then begin
                              sc_clk1[packet_arr[qq[jj]]] += 1.D  ;add one second
                              sc_clk2[packet_arr[qq[jj]]] -= s_ticks
                         
                        endif else sc_clk2[packet_arr[qq[jj]]] += s_ticks
                        print, "        packet # ", qq[jj], " timestamp corrected."
                       
                        ;Add jump times to common block
                        tmp = SC_CLK1[packet_arr[qq[jj]]]+SC_CLK2[packet_arr[qq[jj]]]/2l^16
                        jump_times_nospice = [jump_times_nospice, tmp]
                        
                  endif           

            endif else begin
                  ;Packet is missing
                  print, "        packet #(s) in between ", qq[jj]-1, " and ", qq[jj], " are missing. No timestamp correction done."
            endelse
            tmp_clk2 = SC_CLK1+SC_CLK2/2l^16  ;new clock based on corrected timestamps
      endfor  ;over jj

endif  

end
