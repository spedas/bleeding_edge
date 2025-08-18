;***************************************************************************** 
;+
;*NAME:
;
;	mvn_mag_pkts_read
;
;*PURPOSE:
;
;	Read the MAVEN MAG data.  Formats handled are from instrument,
;	engineering packet from University of California at Berkeley
;	(UCB) DPU, or science packets (multiple formats) from UCB DPU.
;
;*CALLING SEQUENCE:
;
;	mvn_mag_pkts_read,filename,data,input_path=input_path,verbose=verbose
;
;*PARAMETERS:
;
;	filename (required) (input) (string) (scalar)
;	   Input filename - without path.
;
;	data (required) (output) (structure) (array)
;	   Data in a array of structures.  One array entry per packet.
;
;	input_path (keyword) (input) (string) (scalar)
;	   Path to input file.
;
;	verbose (keyword) (input) (integer) (scalar) 
;	   Set to have additional output to screen.
;
;*EXAMPLES:
;
;	ucb_input_path = '/data4/maven/data/ucb/'
;	file26 = 'APID_26.dat' 
;	mvn_mag_pkts_read,file26,data26,input_path=ucb_input_path,/verbose 
;
;	file40 = 'APID_40.dat' 
;	mvn_mag_pkts_read,file40,data40,input_path=ucb_input_path,/verbose 
;
;	file40avg = 'APID_40_avg2.dat' 
;	mvn_mag_pkts_read,file40avg,data40avg,input_path=ucb_input_path
;
;*SYSTEM VARIABLES USED:
;
;	none
;
;*INTERACTIVE INPUT:
;
;	none
;
;*SUBROUTINES CALLED:
;
;       parsestr
;	marker_search
;	bitlis
;       decom_2s_complement
;
;*FILES USED:
;
;	File given in input parameters.
;
;*SIDE EFFECTS:
;
;	none
;
;*RESTRICTIONS:
;
;	assumes data in input files is all from the instrument, or all 
;	engineering via UCB DPU (ApIds 26 and 27), or all science via UCB 
;       DPU (ApIds 40, 41, 42, and 43).  If that is not how it is going to 
;       be delivered, then data sample as will be delivered is required to 
;       be supplied
;
;       ApId 30 not coded for
;
;       Maximum of 550,000 packets per file currently permitted.
;
;*NOTES:
;
;  need to 
;  - test bit sections
;  - calculate and check checksum
;  - add rms fields (2's complement?) - not in UCB CTM - clarification required
;  - engr b field
;  - work error cases (out of data, not in sync)
;  - work difference word between header and checksum
;  - work UCB header field names (JEPC will not care about these)
;  - rework for UCB message ids being incorrect (mostly done)
;  - increment engr & science packet numbers
;  - test with ApID 30 (no data in that format)
;  - test with mixed message ids (no data in that format)
;  - clean up two arrays
;  - think about ib vs ob packets
;  - test resync section
;
;  testing (special attention to)
;  - bit sections
;
;  Problems
;  - message ids not as expected for UCB packets
;  - decom id not as expected for engr pkt 9set to 0 not expected 1)
;
;*PROCEDURE:
;
;
;*MODIFICATION HISTORY:
;
;	30 Mar 2012    started writing
;       26 Apr 2012   continued
;       27 Apr 2012    continued
;        8 May 2012    determined that message ids in UCB supplied data 
;        and              not as expected;  change code to check second
;        9 May 2012       byte to determine type - perfer to use message id -
;                         will need to rework after data is corrected
;       18 May 2012    might be able to handle muplitple UCB ApIds in
;                         one file now - not tested
;          Feb 2013    added CCSDC header;  more of UCB header
;       24 May 2013    add code to skip bytes if PFP, but not MAG pkt
;       13 Mar 2013    add check for if marker_search found additional data;
;                         before each readu, check that there are enough bytes 
;                         remaining
;       24 May 2013    skip data thta is not MAG data
;       29 May 2013    corrected data subseting at end (0.4.1)
;
;-
;******************************************************************************
pro mvn_mag_pkts_read,filename,data,input_path=input_path,verbose=verbose

 if (n_params(0) ne 2) then begin
    print,'MAVEN_MAG_PKTS_READ,FILENAME,DATA,input_path=input_path,/verbose'
    print,' '
    print,'   FILENAME   - input filename'
    print,'   DATA       - output with data from the telemetry file'
    print,'   input_path - override DAT environment variable'
    print,'   verbose    - display information as reading file'
    print,' '
    retall
 endif  ; n_params(0) ne 2

 sw_version = 'maven_mag_pkts_read.pro Version 0.4.1 test'

;  path for filename

;  print,'filename=',filename
  parsestr,filename,parts,delimiter='/'
  num_parts = n_elements(parts)
;  print,num_parts,input_path
  case (num_parts) of 
     0:  ;  invalid

;  no path included

     1: begin
           if (not (keyword_set(input_path))) then begin
              if (getenv('DAT') eq '') then begin
                 print,'DAT enviroment variable not set - assuming ' +   $
                    'current directory'
                 input_path = file_expand_path('./')
              endif else input_path = getenv('DAT')
           endif else begin
              if ( (input_path eq '.') or (input_path eq './') ) then   $
                 input_path = file_expand_path('./')
           endelse  ; (not (keyword_set(input_path))`
           input_file = input_path + '/' + filename
        end  ; num_parts eq 1
     2: begin
           if (parts[0] eq '.') then begin
              input_path = file_expand_path('./')
              filename = parts[1]
              input_file = input_path + '/' + filename
           endif else begin
              input_path = parts[0]
              input_file = filename
              filename = parts[1]
           endelse  ; parts[0] eq '.'
        end  ; num_parts eq 2
     else:  begin
               input_file = filename
               filename = parts[num_parts-1]
               input_path = ''
               for i=0,num_parts-2 do input_path = input_path + '/' + parts[i]
            end  ; else
  endcase  ;  num_parts

  print,'input_file = ', input_file

;  make sure file exists

 temp = findfile(input_file,count=tmp_count)
 if (tmp_count eq 0) then begin
    data = -1
    print,'Can not find ' + input_file
    print,'maven_mag_pkts_read: Action:  Return'
    return
 endif  ; tmp_count eq 0

 if (keyword_set(verbose)) then verbose = 1 else verbose = 0

;  the 2 values for multiplying bit arrays by

 two_array_2 = [1L, 2L]
 two_array_3 = [1L, 2L, 4L]
 two_array_4 = [1L, 2L, 4L, 8L]
 two_array_6 = [1L, 2L, 4L, 8L, 16L, 32L]
 two_array_8 = [1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L]
 two_array_16 = [256L, 512L, 1024L, 2048L, 4096L, 8192L, 16384L, 32768L,   $
                 1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L]
 two_array_32 =  [16777216d, 33554432d, 67108864d, 134217728d,   $
                    268435456d, 536870912d, 1073741824d, 2147483648d,   $
                 65536d, 131072d, 262144d, 524288d, 1048576d,   $
                    2097152d, 4194304d, 8388608d,               $
                 256d, 512d, 1024d, 2048d, 4096d, 8192d, 16384d, 32768d,   $
                 1d, 2d, 4d, 8d, 16d, 32d, 64d, 128d]
 two_array_64 =  [two_array_32*2147483648.d*2.d, two_array_32]
 two_array_16_2 = [ 1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L,   $
                    256L, 512L, 1024L, 2048L, 4096L, 8192L, 16384L, 32768L ]

;  MAVEN spacecraft number

 maven_sc = 202

; sync pattern

 sync_pattern = 'FE6B2840'

;  create structures  - CORRECTION since apid overlaps byte 0

 ccsds_header = { byte0: '',   $
                  apid:  '',   $
                  bytes23: '',   $
                  length:  -1L,   $
                  time_hex: '',   $
                  second:  -1.0D ,   $
                  subsecond:  -1,   $
                  checksum: ''  }

 ucb_header = { byte0: '',      $
                apid: '',       $
                hex_string: '', $
;               grouping:
;               source_seq_ct:
                length: 0L,     $
                second: -1.0D   }
; ucb_header = ''
 ucb_extra_engr = ''

;  header (same for all packet types) and checksum

 header = { pkt_id: -1,          $
            pkt_len: -1,         $
            sync_h: -1L,         $
            sync_l: -1L,         $
            sync_hex: '',        $
            tlfmt: -1,         $
            spare_3_15: -1,      $
            nrng: -1,          $
            avg_n: -1,         $
            eng_n: -1,         $
            diff: -1,          $
            pkt_type: -1,        $
            cmd_cnt: -1,         $
            pkt_seq: -1L,        $
            time_f0: -1L,        $
            time_h: -1L,         $
            time_l: -1L,         $
            pkt_time: -1D,       $
            time_mod: -1L,       $
            fpga: -1,            $
            sn: -1,              $
            drive: -1,           $
            cal: -1,           $
            mnl: -1,           $
            rng: -1,           $
            cksum: -1,           $
            cksum_hex: ''        }

;  engineering section of packet from instrument or engineering packet - 
;  analog and digitial

 xyz_rng = { X: 0L, Y: 0L, Z: 0L, rng: 0L }

 engr = { an_x: -1L,           $
          an_y: -1L,           $
          an_z: -1L,           $
          anrz: -1L,           $
          vcal: -1L,           $
          z8p2vp: -1L,          $
          z8p2vn: -1L,          $
          temp: -1L,           $
          pctmp: -1L,          $
          z13vp: -1L,           $
          z13vn: -1L,           $
          z11p4v: -1L,          $
          z2p5vp: -1L,          $
          z3p3vp: -1L,          $
          ad5vp: -1L,          $
          ad5vn: -1L,          $
          word_26_08_11: -1,     $
          word_26_12_15: -1,     $
          nrng: -1,            $
          pps: -1,             $
          trx_h: -1,           $
          trx_m: -1,           $
          trx_l: -1,           $
          crx: -1,             $
          p_err: -1,           $
          s_err: -1,           $
          cmd: -1L,            $
          cmd_r: -1L,          $
          cmd_o: -1L,          $
          r0_h: -1L,           $
          r1_l : -1L,          $
          r1_h : -1L,          $
          r3_l : -1L,          $
          lle_n: -1L,          $
          ule_n: -1L,          $
          npkts: -1L,          $
          cpkts: -1L,          $
          ule: -1L,            $
          lle: -1L,            $
          cnts: xyz_rng         }

;  science data section of packet from instrument or science packet

 cnts =  replicate(xyz_rng, 64)

 science = { crms: xyz_rng,    $
             cnts: cnts         }

;  open input file

 print,'Opening file ' + input_file
 openr,lun,input_file,/get_lun

;  determine size of file

 file_info = fstat(lun)
 if (verbose) then print,'file_info: ',file_info
 track_number_bytes = file_info.size

;  maximum number of packets (this helps with memory and run time)
           
 memory_max = 550000L

;  initialize counters

 number_engr_pkts = 0L
 number_science_pkts = 0L

 sets = -1L           ;  the number of "kept" packets (minus 1;  starts at 0)
 packet_count = 0L    ;  the number of the packet in the file (starts at 1)
 mag_packet_count = 0L  ; the number of the mag packet in the file (starts at 1)
 last_pkt_start_byte = 0L  ; keep at 0, not -1 for 1st pkt problems
 pkt_start_byte = 0L  ; keep at 0, not -1 for 1st pkt problems
 ccsds_buff_num = 0L
 ucb_buff_num = 0L
 ucb_buff_num_max = 12L

;  work through the file

 while not(eof(lun)) do begin

   next:                    ;  if had to search to find marker

    if (verbose) then print,'track_number_bytes = ', track_number_bytes

;  work around to incorrect message ids from UCB
;  assuming all data is the same source
;  once UCB message id values are fixed, find first sync pattern, 
;  work backwards to determine source

    if (packet_count eq 0) then begin
       buff_num = 2L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)
       case (strupcase(hex[1])) of
          '81': begin
                   source = 'instrument'
                   source2 = 'instrument'
                   ucb_buff_num = 0L
                   ucb_buff_num_max = 0L
                end  ; strupcase(hex[1]) eq '81'
          '26': begin
                   source = 'engr'
                   source2 = 'ucb'
                   ucb_buff_num = 10L
                end  ; strupcase(hex[1]) eq '26'
          '27': begin
                   source = 'engr'
                   ucb_buff_num = 10L
                   source2 = 'ucb'
                end  ; strupcase(hex[1]) eq '27'
          '30': begin
                   source = 'passthru'
                   ucb_buff_num = 12L
                   source2 = 'ucb'
                   print,'Warning: ApId 30 never tested'
                end  ; strupcase(hex[1]) eq '30'
          '40': begin
                   source = 'science'
                   source2 = 'ucb'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '40'
          '41': begin
                   source = 'science'
                   source2 = 'ucb'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '40'
          '42': begin
                   source = 'science'
                   source2 = 'ucb'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '40'
          '43': begin
                   source = 'science'
                   source2 = 'ucb'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '40'
          '50': begin
                   source = 'engr'
                   source2 = 'ccsds'
                   ucb_buff_num = 11L
                   ccsds_buff_num = 11L
                end  ; strupcase(hex[1]) eq '50'
          '51': begin
                   source = 'science'
                   source2 = 'ccsds'
                   ucb_buff_num = 11L
                   ccsds_buff_num = 11L
                end  ; strupcase(hex[1]) eq '51'
          '52': begin
                   source = 'unknown'
                   source2 = 'ccsds'
                   ucb_buff_num = 11L
                   ccsds_buff_num = 11L
                end  ; strupcase(hex[1]) eq '52'
          else: begin
                   print,'Hex value of the second byte is ' + hex[1]
;;                   print,'Not an expected value (81, 26, 40)'
stop
                   free_lun,lun
                   print,'ACTION: close file, retall'
                   retall
                end  ; else
       endcase ;  strupcase(hex[1])


;; source = 'science'
;; ucb_buff_num = 12L

;  set pointer back to beginning of the file

       point_lun,lun,0

;  check the packet length value - using hex values - and
;  setup data output structure

;;       if ( (source  eq 'engr') or (source eq 'science') ) then begin
       if (ucb_buff_num gt 0) then begin
          if (verbose) then print,'data via UCB SW'

          max_number_of_pkts = (file_info.size/72L) + 1L
          if (verbose) then print,'max_number_of_pkts = ',max_number_of_pkts

;  check against maximum number of packets

          if (max_number_of_pkts gt memory_max) then begin
             print,'WARNING:  only read first ' + strtrim(memory_max,2) +   $
                ' packets'
             max_number_of_pkts = memory_max
          endif  ; (max_number_of_pkts gt memory_max)

;  create data structure - designed for intermixed engr and science 
;  packets, but message ids need fixed first

          if (source2 eq 'ccsds') then begin
             data = replicate( { filename: filename,             $
                path: input_path,                                $
                sc: maven_sc,                                    $
                failed_flag: 0L,                                 $
                total_number_pkts: packet_count,                 $
                total_number_engr_pkts: number_engr_pkts,        $
                total_number_science_pkts: number_science_pkts,  $
                packet_number: 0L,                               $
                engr_packet_number: 0L,                          $
                science_packet_number: 0L,                       $
                data_type: 0,                                    $
                pkt_type: 0,                                     $
                sw_version:sw_version,                           $
                ccsds: ccsds_header,                             $
                ucb_header: ucb_header,                          $
                header: header,                                  $
                engr: engr,                                      $
                ucb_extra_engr: '',                               $
                science: science }, max_number_of_pkts)
          endif else begin 
             data = replicate( { filename: filename,             $
                path: input_path,                                $
                sc: maven_sc,                                    $
                failed_flag: 0L,                                 $
                total_number_pkts: packet_count,                 $
                total_number_engr_pkts: number_engr_pkts,        $
                total_number_science_pkts: number_science_pkts,  $
                packet_number: 0L,                               $
                engr_packet_number: 0L,                          $
                science_packet_number: 0L,                       $
                data_type: 0,                                    $
                pkt_type: 0,                                     $
                sw_version:sw_version,                           $
                ucb_header: ucb_header,                          $
                header: header,                                  $
                engr: engr,                                      $
                ucb_extra_engr: '',                               $
                science: science }, max_number_of_pkts)
          endelse  ; source2 eq 'ccsds'
       endif else begin

          if (source  eq 'instrument') then begin
             if (verbose) then print,'data from instrument'

             max_number_of_pkts = (file_info.size/262L) + 1L
             if (verbose) then print,'max_number_of_pkts = ',max_number_of_pkts

; max_number_of_pkts = 500L

;  check against maximum number of packets

             if (max_number_of_pkts gt memory_max) then begin
                print,'WARNING:  only read first ' + strtrim(memory_max,2) +   $
                   ' packets'
                max_number_of_pkts = memory_max
             endif  ; (max_number_of_pkts gt memory_max)

;  create data structure

             data = replicate( { filename: filename,   $
                path: input_path,                      $
                sc: maven_sc,                          $
                failed_flag: 0L,                       $
                total_number_pkts: packet_count,       $
                packet_number: 0L,                     $
                sw_version:sw_version,                 $
                header: header,                        $
                engr: engr,                            $
                science: science }, max_number_of_pkts)

          endif else begin
             print,'Error: unknown packet length - not coded for yet'
             print,hex[1]
             print,'Action: retall'
             retall
          endelse  ; source eq 'instrument'
       endelse  ; (source  eq 'engr') or (source eq 'science')
    endif  ; packet_count eq 0

;  increment counters and reset failed_flag

    failed_flag = 0
    sets = sets + 1L
    packet_count = packet_count + 1L
    mag_packet_count = mag_packet_count + 1L
    data[sets].packet_number = packet_count

    if (source2 eq 'ccsds') then begin
       buff_num = 11L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)

;  byte 0

       data[sets].ccsds.byte0 = strupcase(hex[0])
       if (verbose) then print,'ccsds.byte0 = ',data[sets].ccsds.byte0

;  ApId

       data[sets].ccsds.apid = strupcase(hex[1])
       if (verbose) then print,'ccsds.apid = ',data[sets].ccsds.apid

; CCSDS bytes 2 and 3

       data[sets].ccsds.bytes23 = hex[2] + hex[3]
       if (verbose) then print,'ccsds.bytes23 = ',data[sets].ccsds.bytes23

; CCSDS length (excludes primary header but includes seondary header 
; time;  bytes minus one)

       bitlis,buff[4:5],bit_array
       data[sets].ccsds.length = long(total(bit_array * two_array_16))
       if (verbose) then print,'ccsds.length = ',data[sets].ccsds.length

;  CCSDS time

       data[sets].ccsds.time_hex = hex[6] + hex[7] + hex[8] + hex[9] + hex[10]
       if (verbose) then print,'ccsds.time_hex = ',data[sets].ccsds.time_hex

       bitlis,buff[6:9],bit_array
       data[sets].ccsds.second = total(double(bit_array) * two_array_32)
       if (verbose) then   $
          print,format='(a,f20.0)','ccsds.second = ',data[sets].ccsds.second

       bitlis,buff[10],bit_array
       data[sets].ccsds.subsecond = total(bit_array * two_array_8)
       if (verbose) then   $
          print,'ccsds.subsecond = ',data[sets].ccsds.subsecond
    endif  ; source 2 eq 'ccsds'

; stop
;  read UCB header - for now, just a hex string

    if ( (source eq 'engr') or (source eq 'science') ) then begin
       buff_num = 2L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)

       case (strupcase(hex[1])) of
          '81': begin
                   source = 'instrument'
                   ucb_buff_num = 0L
                end  ; strupcase(hex[1]) eq '81'
          '26': begin
                   source = 'engr'
                   ucb_buff_num = 10L
                end  ; strupcase(hex[1]) eq '26'
          '27': begin
                   source = 'engr'
                   ucb_buff_num = 10L
                end  ; strupcase(hex[1]) eq '27'
          '30': begin
                   source = 'instrument'
                   ucb_buff_num = 12L
                   print,'Warning: ApId 30 never tested'
                end  ; strupcase(hex[1]) eq '30'
          '40': begin
                   source = 'science'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '40'
          '41': begin
                   source = 'science'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '41'
          '42': begin
                   source = 'science'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '42'
          '43': begin
                   source = 'science'
                   ucb_buff_num = 12L
                end  ; strupcase(hex[1]) eq '43'
          else: begin
                   print,' '
                   print,'Hex value of the second byte is ' + hex[1]
;                   print,'Not an expected value ' +   $
;                      '(81, 26, 27, 30, 40, 41, 42, 43)'

;  determine length of packet that is not mag data - skip that packet

                   buff_num = data[sets].ccsds.length + 1L - 7L
                   print,'Assume not a MAG packet - skipping ' +  $
                      strtrim(buff_num,2) + ' bytes'
                   if (track_number_bytes lt buff_num) then begin
                      print,'Remaining bytes less than next buffer'
                      print,'ACTION: finish'
                      goto, finish
                   endif  ; track_number_bytes lt buff_num
; print,hex
                   buff = bytarr(buff_num)
                   readu,lun,buff
                   track_number_bytes = track_number_bytes - buff_num

;  reset values for data structure index

                   data[sets].ccsds.byte0 = ''
                   data[sets].ccsds.apid = ''
                   data[sets].ccsds.bytes23 = ''
                   data[sets].ccsds.length = -1L
                   data[sets].ccsds.time_hex = ''
                   data[sets].ccsds.second = -1.0D
                   data[sets].ccsds.subsecond = -1

                   sets = sets - 1L
                   mag_packet_count = mag_packet_count - 1L
                   goto, next_packet

;                   print,'Does sync pattern match?'
;stop
                end  ; else
       endcase ;  strupcase(hex[1])

; print,'source = ',source,'  source2 = ',source2
;  byte 0

       data[sets].ucb_header.byte0 = strupcase(hex[0])
       if (verbose) then   $
          print,'ucb_header.byte0 = ',data[sets].ucb_header.byte0

;  ApId

       data[sets].ucb_header.apid = strupcase(hex[1])
       if (verbose) then   $
          print,'ucb_header.apid = ',data[sets].ucb_header.apid

;  rest of the header

       if (ucb_buff_num gt 2) then begin
          buff_num = ucb_buff_num - 2L
          if (track_number_bytes lt buff_num) then begin
             print,'Remaining bytes less than next buffer'
             print,'ACTION: finish'
             goto, finish
          endif  ; track_number_bytes lt buff_num

          buff = bytarr(buff_num)
          readu,lun,buff
          track_number_bytes = track_number_bytes - buff_num

          hex = buff
          hex = byte(string(hex,'(z)'))
          hex = strtrim(hex(5:6,*),2)
          temp = where(strlen(hex) ne 2,temp_count)
          if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

;       if (verbose) then print,hex

          num_hex = n_elements(hex)
          for i=0,num_hex-1 do data[sets].ucb_header.hex_string =   $
             data[sets].ucb_header.hex_string + hex[i]
          if (verbose) then   $
             print,'ubc_header.hex_string = ',data[sets].ucb_header.hex_string

;  grouping flags - NEED TO CODE

;  Source Sequence Count  - NEED TO CODE

;  Packet Length

          bitlis,buff[2:3],bit_array
          data[sets].ucb_header.length = long(total(bit_array * two_array_16))
          if (verbose) then   $
             print,'ucb_header.length = ',data[sets].ucb_header.length

;  Packet Time (UCB PFP, not MAG - not to be used for processing)

          bitlis,buff[4:7],bit_array
          data[sets].ucb_header.second = total(bit_array * two_array_32)
          if (verbose) then   $
             print,'ucb_header.seconds = ',data[sets].ucb_header.seconds

       endif ;  ucb_buff_num gt 2
    endif ;  (source eq 'engr') or (source eq 'science')

;  read MAG header section - all packet types

    buff_num = 20L
    if (track_number_bytes lt buff_num) then begin
       print,'Remaining bytes less than next buffer'
       print,'ACTION: finish'
       goto, finish
    endif  ; track_number_bytes lt buff_num

    buff = bytarr(buff_num)
    readu,lun,buff
    track_number_bytes = track_number_bytes - buff_num

    hex = buff[0:5]
    hex = byte(string(hex,'(z)'))
    hex = strtrim(hex(5:6,*),2)
    temp = where(strlen(hex) ne 2,temp_count)
    if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

    if (verbose) then print,hex

;  check sync pattern

    hex_string = hex[2] + hex[3] + hex[4] + hex[5]
; stop
    if (strupcase(hex_string) ne sync_pattern) then begin

;  try to find sync pattern

       track_number_bytes = track_number_bytes + buff_num
       after_byte = file_info.size - track_number_bytes 
       if (after_byte le last_pkt_start_byte) then   $
           after_byte = last_pkt_start_byte + 1L

       marker_search,lun,sync_pattern,after_byte,pkt_start_byte
print,after_byte,pkt_start_byte

;  step back 2 bytes for the message id and currently needed for the UCB header

       if (ucb_buff_num gt 0) then print,'WARNING: assuming same type of ' +   $
          'packet as last valid packet - will be fixed when message ids fixed.'
       pkt_start_byte = pkt_start_byte - 2L - ucb_buff_num_max - ccsds_buff_num

       if (ucb_buff_num_max gt 0) then begin
          point_lun,lun,0
          point_lun,lun,pkt_start_byte
          buff = bytarr(4L)
          readu,lun,buff
          hex = buff
          hex = byte(string(hex,'(z)'))
          hex = strtrim(hex(5:6,*),2)
; print, pkt_start_byte
; print,hex
          for i=0L,3L do begin
             if (hex[i] eq '8') then begin
                pkt_start_byte = pkt_start_byte + i
                i = 5L          ;type error (IDL 8 perhaps?), jmm-2013-06-04
             endif  ; hex[i] = '8'
          endfor  ; i
          if (i eq 4) then begin
             print,'Not at beginning of packet'
             print,'Not coded for'
             print,'ACTION: stop'
             stop
          endif  ; i eq 4
       endif  ; ucb_buff_num_max gt 0

; print, pkt_start_byte
       print,'Skipping ' +   $
          strtrim((pkt_start_byte - after_byte),2) +  $
          ' bytes [' + strtrim(after_byte,2) + ':' +    $
          strtrim(pkt_start_byte-1L,2) + ']'

       last_pkt_start_byte = pkt_start_byte
       track_number_bytes = file_info.size - pkt_start_byte

; stop
       if (pkt_start_byte ge 0) then begin
          point_lun,lun,0
          point_lun,lun,pkt_start_byte
          data[sets].failed_flag = 1
          goto, next
       endif else begin
          free_lun,lun
          print,'Unable to find valid sync pattern to detemine ' +   $
             'start of packet.' 
;          print,'ACTION: stop'
;          stop
          data[sets].failed_flag = 1
          goto,finish
       endelse  ; pkt_start_byte ge 0

    endif  ; strupcase(hex_string) ne 'FE6B2840'

;           data.header.pkt_id

    data[sets].header.pkt_id = fix(buff[0])
    if (verbose) then print,'header.pkt_id = ',data[sets].header.pkt_id

;           data.header.pkt_len

    data[sets].header.pkt_len = fix(buff[1])
    if (verbose) then print,'header.pkt_len = ',data[sets].header.pkt_len
  
;           data.header.sync_h

    bitlis,buff[2:3],bit_array
    data[sets].header.sync_h = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.sync_h = ',data[sets].header.sync_h

;           data.header.sync_l

    bitlis,buff[4:5],bit_array
    data[sets].header.sync_l = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.sync_l = ',data[sets].header.sync_l

;           data.header.sync_hex

    data[sets].header.sync_hex = strupcase(hex_string)
    if (verbose) then print,'header.sync_hex = ',data[sets].header.sync_hex

;           data.header.tlfmt - and split out

    data[sets].header.tlfmt = fix(buff[6])
    if (verbose) then print,'header.tlfmt = ',data[sets].header.tlfmt

    bitlis,buff[6],bit_array

;           data.header.pkt_type

    data[sets].header.pkt_type = fix(total(bit_array[0:1] * two_array_2))
    if (verbose) then print,'header.pkt_type = ',data[sets].header.pkt_type

;           data.header.diff

    data[sets].header.diff = bit_array[2]
    if (verbose) then print,'header.diff = ',data[sets].header.diff

;           data.header.avg_n or
;           data.header.eng_n

;;;    if (data[sets].header.pkt_type eq 1) then   $
    if (source eq 'engr') then   $
       data[sets].header.eng_n = fix(total(bit_array[3:5] * two_array_3)) $
    else    $    ;  instrument or science 
       data[sets].header.avg_n = fix(total(bit_array[3:5] * two_array_3))
    if (verbose) then begin
       print,'header.eng_n = ',data[sets].header.eng_n
       print,'header.avg_n = ',data[sets].header.avg_n
    endif  ; verbose

;           data.header.nrng

    data[sets].header.nrng = bit_array[6]
    if (verbose) then print,'header.nrng = ',data[sets].header.nrng

;           data.header.spare_3_15

    data[sets].header.spare_3_15 = bit_array[6]
    if (verbose) then print,'header.spare_3_15 = ',data[sets].header.spare_3_15

;           data.header.cmd_cnt

    data[sets].header.cmd_cnt = fix(buff[7])
    if (verbose) then print,'header.cmd_cnt = ',data[sets].header.cmd_cnt

;           data.header.pkt_seq

    bitlis,buff[8:9],bit_array
    data[sets].header.pkt_seq = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.pkt_seq = ',data[sets].header.pkt_seq

;           data.header.time_f0

    bitlis,buff[10:11],bit_array
    data[sets].header.time_f0 = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.time_f0 = ',data[sets].header.time_f0

;           data.header.time_h

    bitlis,buff[12:13],bit_array
    data[sets].header.time_h = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.time_h = ',data[sets].header.time_h

;           data.header.time_l

    bitlis,buff[14:15],bit_array
    data[sets].header.time_l = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.time_l = ',data[sets].header.time_l

;           data.header.pkt_time

    bitlis,buff[12:15],bit_array
    data[sets].header.pkt_time = total(bit_array * two_array_32)
    if (verbose) then   $
       print,format='(a,f20.2)','header.pkt_time = ',data[sets].header.pkt_time

;           data.header.time_mod

    bitlis,buff[16:17],bit_array
    data[sets].header.time_mod = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.time_mod = ',data[sets].header.time_mod

;  Header Word 9

    temp = reverse(buff[18:19])
    bitlis,temp,bit_array

;           data.header.rng

    data[sets].header.rng = fix(total(bit_array[0:1] * two_array_2))
    if (verbose) then print,'header.rng = ',data[sets].header.rng

;           data.header.mnl

    data[sets].header.mnl = bit_array[2]
    if (verbose) then print,'header.mnl = ',data[sets].header.mnl

;           data.header.cal

    data[sets].header.cal = bit_array[3]
    if (verbose) then print,'header.cal = ',data[sets].header.cal

;           data.header.drive

    data[sets].header.drive = fix(total(bit_array[4:5] * two_array_2))
    if (verbose) then print,'header.drive = ',data[sets].header.drive

;           data.header.sn

    data[sets].header.sn = fix(total(bit_array[6:9] * two_array_4))
    if (verbose) then print,'header.sn = ',data[sets].header.sn

;           data.header.fpga

    data[sets].header.fpga = fix(total(bit_array[10:15] * two_array_6))
    if (verbose) then print,'header.fpga = ',data[sets].header.fpga


;  header done, now it depends on what type of packet this is

;  pkt_type = 0, instrument packet, 129 words
;  pkt_type = 1, engr packet, 36 words?
;  pkt_type = 2, science packet - averaged, ? words
;  pkt_type = 3, science packet - differenced, ? words

   if (verbose) then begin
      print,'pkt_type = ',data[sets].header.pkt_type
      print,'pkt_len = ',data[sets].header.pkt_len
      print,'source = ',source
   endif  ; verbose
;stop

;  analog and digital housekeeping (instrument or engr packets)
;  need to confirm being set correctly in UCB outout !!

    if ( (source eq 'instrument') or   $
         (source eq 'engr') ) then begin
;;    if ( (data[sets].header.pkt_type eq 0) or   $
;;         (data[sets].header.pkt_type eq 1) ) then begin
;    if ( (data[sets].header.pkt_len eq 129) or   $
;         (data[sets].header.pkt_len eq 36) ) then begin

       buff_num = 48L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

;         data.engr.an_x

       decom_2s_complement,buff[0:1],value
       data[sets].engr.an_x = value
       if (verbose) then print,'engr.an_x = ',data[sets].engr.an_x

;         data.engr.an_y

       decom_2s_complement,buff[2:3],value
       data[sets].engr.an_y = value
       if (verbose) then print,'engr.an_y = ',data[sets].engr.an_y

;         data.engr.an_z

       decom_2s_complement,buff[4:5],value
       data[sets].engr.an_z = value
       if (verbose) then print,'engr.an_z = ',data[sets].engr.an_z

;         data.engr.anrz

       decom_2s_complement,buff[6:7],value
       data[sets].engr.anrz = value
       if (verbose) then print,'engr.anrz = ',data[sets].engr.anrz

;         data.engr.vcal

       decom_2s_complement,buff[8:9],value
       data[sets].engr.vcal = value
       if (verbose) then print,'engr.vcal = ',data[sets].engr.vcal

;         data.engr.z8p2vp

       decom_2s_complement,buff[10:11],value
       data[sets].engr.z8p2vp = value
       if (verbose) then print,'engr.z8p2vp = ',data[sets].engr.z8p2vp

;         data.engr.z8p2vn

       decom_2s_complement,buff[12:13],value
       data[sets].engr.z8p2vn = value
       if (verbose) then print,'engr.z8p2vn = ',data[sets].engr.z8p2vn

;         data.engr.temp

       decom_2s_complement,buff[14:15],value
       data[sets].engr.temp = value
       if (verbose) then print,'engr.temp = ',data[sets].engr.temp

;         data.engr.pctmp

       decom_2s_complement,buff[16:17],value
       data[sets].engr.pctmp = value
       if (verbose) then print,'engr.pctmp = ',data[sets].engr.pctmp

;         data.engr.z13vp

       decom_2s_complement,buff[18:19],value
       data[sets].engr.z13vp = value
       if (verbose) then print,'engr.z13vp = ',data[sets].engr.z13vp

;         data.engr._13vn

       decom_2s_complement,buff[20:21],value
       data[sets].engr.z13vn = value
       if (verbose) then print,'engr.z13vn = ',data[sets].engr.z13vn

;         data.engr.z11p4v

       decom_2s_complement,buff[22:23],value
       data[sets].engr.z11p4v = value
       if (verbose) then print,'engr.z11p4v = ',data[sets].engr.z11p4v

;         data.engr.z2p5vp

       decom_2s_complement,buff[24:25],value
       data[sets].engr.z2p5vp = value
       if (verbose) then print,'engr.z2p5vp = ',data[sets].engr.z2p5vp

;         data.engr.z3p3vp

       decom_2s_complement,buff[26:27],value
       data[sets].engr.z3p3vp = value
       if (verbose) then print,'engr.z3p3vp = ',data[sets].engr.z3p3vp

;         data.engr.ad5vp

       decom_2s_complement,buff[28:29],value
       data[sets].engr.ad5vp = value
       if (verbose) then print,'engr.ad5vp = ',data[sets].engr.ad5vp

;         data.engr.ad5vn

       decom_2s_complement,buff[30:31],value
       data[sets].engr.ad5vn = value
       if (verbose) then print,'engr.ad5vn = ',data[sets].engr.ad5vn

;  now digital housekeeping

;  Word 26, MAG_DIG_HK_00 (based on instrument packet format)

       temp = reverse(buff[32:33])
       bitlis,temp,bit_array

;         data.engr.s_err

       data[sets].engr.s_err = bit_array[0]
       if (verbose) then print,'engr.s_err = ',data[sets].engr.s_err

;         data.engr.p_err

       data[sets].engr.p_err = bit_array[1]
       if (verbose) then print,'engr.p_err = ',data[sets].engr.p_err

;         data.engr.crx

       data[sets].engr.crx = bit_array[2]
       if (verbose) then print,'engr.crx = ',data[sets].engr.crx

;         data.engr.trx_l

       data[sets].engr.trx_l = bit_array[3]
       if (verbose) then print,'engr.trx_l = ',data[sets].engr.trx_l

;         data.engr.trx_m

       data[sets].engr.trx_m = bit_array[4]
       if (verbose) then print,'engr.trx_m = ',data[sets].engr.trx_m

;         data.engr.trx_h

       data[sets].engr.trx_h = bit_array[5]
       if (verbose) then print,'engr.trx_h = ',data[sets].engr.trx_h

;         data.engr.pps

       data[sets].engr.pps = bit_array[6]
       if (verbose) then print,'engr.pps = ',data[sets].engr.pps

;         data.engr.nrng

       data[sets].engr.nrng = bit_array[7]
       if (verbose) then print,'engr.nrng = ',data[sets].engr.nrng

;         data.engr.word_26_08_11

       data[sets].engr.word_26_08_11 =   $
          fix(total(bit_array[8:11] * two_array_4))
       if (verbose) then   $
          print,'engr.word_26_08_11 = ',data[sets].engr.word_26_08_11
       if (data[sets].engr.word_26_08_11 ne 0) then   $
         print,'WARNING: engr.word_26_08_11 equals ' +   $
           strtrim(data[sets].engr.word_26_08_11,2) + ' when it should equal 0'

;         data.engr.word_26_12_15

       data[sets].engr.word_26_12_15 =   $
          fix(total(bit_array[12:15] * two_array_4))
       if (verbose) then   $
          print,'engr.word_26_12_15 = ',data[sets].engr.word_26_12_15

;         data.engr.cmd

       bitlis,buff[34:35],bit_array
       data[sets].engr.cmd = long(total(bit_array * two_array_16))
       if (verbose) then print,'engr.cmd = ',data[sets].engr.cmd

;         data.engr.cmd_r

       data[sets].engr.cmd_r = fix(buff[36])
       if (verbose) then print,'engr.cmd_r = ',data[sets].engr.cmd_r

;         data.engr.cmd_o

       data[sets].engr.cmd_o = fix(buff[37])
       if (verbose) then print,'engr.cmd_o = ',data[sets].engr.cmd_o

;         data.engr.r0_h

       data[sets].engr.r0_h = fix(buff[38])
       if (verbose) then print,'engr.r0_h = ',data[sets].engr.r0_h

;         data.engr.r1_l

       data[sets].engr.r1_l = fix(buff[39])
       if (verbose) then print,'engr.r1_l = ',data[sets].engr.r1_l

;         data.engr.r1_h

       data[sets].engr.r1_h = fix(buff[40])
       if (verbose) then print,'engr.r1_h = ',data[sets].engr.r1_h

;         data.engr.r3_l

       data[sets].engr.r3_l = fix(buff[41])
       if (verbose) then print,'engr.r3_l = ',data[sets].engr.r3_l

;         data.engr.lle_n

       data[sets].engr.lle_n = fix(buff[42])
       if (verbose) then print,'engr.lle_n = ',data[sets].engr.lle_n

;         data.engr.ule_n

       data[sets].engr.ule_n = fix(buff[43])
       if (verbose) then print,'engr.ule_n = ',data[sets].engr.ule_n

;         data.engr.npkts

       data[sets].engr.npkts = fix(buff[44])
       if (verbose) then print,'engr.npkts = ',data[sets].engr.npkts

;         data.engr.cpkts

       data[sets].engr.cpkts = fix(buff[45])
       if (verbose) then print,'engr.cpkts = ',data[sets].engr.cpkts

;         data.engr.ule

       data[sets].engr.ule = fix(buff[46])
       if (verbose) then print,'engr.ule = ',data[sets].engr.ule

;         data.engr.lle

       data[sets].engr.lle = fix(buff[47])
       if (verbose) then print,'engr.lle = ',data[sets].engr.lle

    endif  ;  data[sets].header.pkt_type eq 0 or 1
;    endif ; data[sets].header.pkt_len eq 129 or 36

;  for engineering packet, next would be B componets from sample 0

    if (source eq 'engr') then begin
;;;    if (data[sets].header.pkt_type eq 1) then begin

       buff_num = 6L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

;         data.engr.cnts.x

       decom_2s_complement,buff[0:1],value
       data[sets].engr.cnts.x = value
       if (verbose) then print,'engr.cnts.x = ',data[sets].engr.cnts.x

;         data.engr.cnts.y

       decom_2s_complement,buff[2:3],value
       data[sets].engr.cnts.y = value
       if (verbose) then print,'engr.cnts.y = ',data[sets].engr.cnts.y

;         data.engr.cnts.z

       decom_2s_complement,buff[4:5],value
       data[sets].engr.cnts.z = value
       if (verbose) then print,'engr.cnts.z = ',data[sets].engr.cnts.z

;         data.engr.cnts.rng

       data[sets].engr.cnts.rng = data[sets].header.rng
       if (verbose) then print,'engr.cnts.rng = ',data[sets].engr.cnts.rng

    endif ;  data[sets].header.pkt_type eq 1


;  for science packet (pkt_type = 2), next would be B rms values
;  from MAVEN_PF_FSW_021_CTM.xls, looks like this may have been dropped
;  So, do this for pkt_type = 2 and see if the values match X, Y, Z of sample 0
;  CHECK THIS

    if (data[sets].header.pkt_type eq 2) then begin
;    if (data[sets].header.pkt_len eq 108) then begin

;         data.science.crms

       buff_num = 6L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

;  two's complement?????

;         data.science.crms.x

       decom_2s_complement,buff[0:1],value
       data[sets].science.crms.x = value
       if (verbose) then   $
          print,'science.crms.x = ',data[sets].science.crms.x

;         data.science.crms.y

       decom_2s_complement,buff[2:3],value
       data[sets].science.crms.y = value
       if (verbose) then    $
          print,'science.crms.y = ',data[sets].science.crms.y

;         data.science.crms.z

       decom_2s_complement,buff[4:5],value
       data[sets].science.crms.z = value
       if (verbose) then   $
          print,'science.crms.z = ',data[sets].science.crms.z

;         data.science.crms.rng

       data[sets].science.crms.rng = data[sets].header.rng
       if (verbose) then   $
          print,'science.crms.rng = ',data[sets].science.crms.rng

       print,'CHECK the RMS values'

    endif ;  data[sets].header.pkt_type eq 2
;    endif ; data[sets].header.pkt_len eq 108

;  for instrument packet (pky_type = 0, pkt_len = 129 words) or science packet
;  (pkt_type = 2, pkt_len = ??? words), science data is next

    if ( (source eq 'instrument') or    $
         (data[sets].header.pkt_type eq 2) ) then begin
;;    if ( (data[sets].header.pkt_type eq 0) or    $
;;         (data[sets].header.pkt_type eq 2) ) then begin
;    if ( (data[sets].header.pkt_len eq 129) or   $
;         (data[sets].header.pkt_len eq 108) ) then begin

;             science.cnts

       buff_size = 192L
       if (track_number_bytes lt buff_size) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_size

       buff = bytarr(buff_size)
       readu,lun,buff
; print,buff
       track_number_bytes = track_number_bytes - buff_size

;  step through samples
       
       for i=0,31 do begin

;  x component (science.cnts.x)

          decom_2s_complement,buff[i*6:i*6+1],value
          data[sets].science.cnts[i].x = value

;  y component (science.cnts.y)

          decom_2s_complement,buff[i*6+2:i*6+3],value
          data[sets].science.cnts[i].y = value

;  z component (science.cnts.z)

          decom_2s_complement,buff[i*6+4:i*6+5],value
          data[sets].science.cnts[i].z = value

;  range (science.cnts.rng)

          data[sets].science.cnts[i].rng = data[sets].header.rng

          if (verbose) then print,'science.cnts[' + strtrim(i,2) + '] = ',  $
             strtrim(data[sets].science.cnts[i].x,2),', ',   $
             strtrim(data[sets].science.cnts[i].y,2),', ',   $
             strtrim(data[sets].science.cnts[i].z,2),', ',   $
             strtrim(data[sets].science.cnts[i].rng,2)

       endfor  ; i
    endif ;  data[sets].header.pkt_type eq 0 or 2
;    endif ; data[sets].header.pkt_len eq 129 or 108

;  for science packet (pkt_type = 3, pkt_len = ??? words), science data is next

    if (data[sets].header.pkt_type eq 3) then begin

;             science.cnts[0]

       buff_size = 6L
       if (track_number_bytes lt buff_size) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_size

       buff = bytarr(buff_size)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_size

       decom_2s_complement,buff[0:1],value
       data[sets].science.cnts[0].x = value

       decom_2s_complement,buff[2:3],value
       data[sets].science.cnts[0].y = value

       decom_2s_complement,buff[4:5],value
       data[sets].science.cnts[0].z = value

       data[sets].science.cnts[0].rng = data[sets].header.rng

       if (verbose) then print,'science.cnts[0] = ',   $
          strtrim(data[sets].science.cnts[0].x,2),', ',   $
          strtrim(data[sets].science.cnts[0].y,2),', ',   $
          strtrim(data[sets].science.cnts[0].z,2),', ',   $
          strtrim(data[sets].science.cnts[0].rng,2)

;             science.cnts[1:63]

       buff_size = 192L
       if (track_number_bytes lt buff_size) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_size

       buff = bytarr(buff_size)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_size

;  step through samples
       
       for i=0,62 do begin

;  x component (science.cnts.x)

          bitlis,buff[i*3],bit_array
          value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
            ( long(total(bit_array[0:6] * two_array_8[0:6])) )
          data[sets].science.cnts[i+1].x = value

;  y component (science.cnts.y)

          bitlis,buff[i*3+1],bit_array
          value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
            ( long(total(bit_array[0:6] * two_array_8[0:6])) )
          data[sets].science.cnts[i+1].y = value

;  z component (science.cnts.z)

          bitlis,buff[i*3+2],bit_array
          value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
            ( long(total(bit_array[0:6] * two_array_8[0:6])) )
          data[sets].science.cnts[i+1].z = value

;  range (science.cnts.rng)

          data[sets].science.cnts[i+1].rng = -1

          if (verbose) then   $
             print,'science.cnts[' + strtrim(i+1,2) + '] = ',   $
             strtrim(data[sets].science.cnts[i].x,2),', ',   $
             strtrim(data[sets].science.cnts[i].y,2),', ',   $
             strtrim(data[sets].science.cnts[i].z,2),', ',   $
             strtrim(data[sets].science.cnts[i].rng,2)
       endfor ;  i

;  if the rms is not included, what are the 3 last bytes?

       bitlis,buff[189],bit_array
       value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
         ( long(total(bit_array[0:6] * two_array_8[0:6])) )
       data[sets].science.crms.x = value

       bitlis,buff[190],bit_array
       value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
         ( long(total(bit_array[0:6] * two_array_8[0:6])) )
       data[sets].science.crms.y = value

       bitlis,buff[191],bit_array
       value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
         ( long(total(bit_array[0:6] * two_array_8[0:6])) )
       data[sets].science.crms.z = value

       if (verbose) then print,'science.crms = ',   $
          strtrim(data[sets].science.crms.x,2),', ',   $
          strtrim(data[sets].science.crms.y,2),', ',   $
          strtrim(data[sets].science.crms.z,2),', ',   $
          strtrim(data[sets].science.crms.rng,2)

    endif ;  data[sets].header.pkt_type eq 3

;  for all packet types, last work (2 bytes) are checksum
;  note - for instrument packet, last bit is always 0

    buff_size = 2L
    if (track_number_bytes lt buff_size) then begin
       print,'Remaining bytes less than next buffer'
       print,'ACTION: finish'
       goto, finish
    endif  ; track_number_bytes lt buff_size

    buff = bytarr(buff_size)
    readu,lun,buff
    track_number_bytes = track_number_bytes - buff_size

;           data.header.cksum

    bitlis,buff[0:1],bit_array
    data[sets].header.cksum = long(total(bit_array * two_array_16))
    if (verbose) then print,'header.cksum = ',data[sets].header.cksum

;           data.header.cksum_hex: ''        }

    hex = buff[0:1]
    hex = byte(string(hex,'(z)'))
    hex = strtrim(hex(5:6,*),2)
    temp = where(strlen(hex) ne 2,temp_count)
    if (temp_count gt 0) then hex(temp) = '0' + hex(temp)
    data[sets].header.cksum_hex = strupcase(hex[0] + hex[1])
    if (verbose) then print,'header.cksum_hex = ',data[sets].header.cksum_hex

;  NEED TO CALCULATE CHECKSUM and set failed flag is necessary

    print,'Check sum not being validated yet'

;  UCB eng packet may have extra bytes after the checksum - CHECK THIS

    if (source eq 'engr') then begin
;;    if (data[sets].header.pkt_type eq 1) then begin

       print,'extra bytes after checksum in UCB engr packet ApIds'

       buff_num = 22L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)
       temp = where(strlen(hex) ne 2,temp_count)
       if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

;       if (verbose) then print,hex

       num_hex = n_elements(hex)
       for i=0,num_hex-1 do data[sets].ucb_extra_engr =   $
          data[sets].ucb_extra_engr + hex[i]
       if (verbose) then print,'ubc_extra_engr = ',data[sets].ucb_extra_engr
    endif ;  data[sets].header.pkt_type eq 1
 
    if (source2 eq 'ccsds') then begin
       buff_num = 2
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)
       temp = where(strlen(hex) ne 2,temp_count)
       if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

       data[sets].ccsds.checksum = hex[0] + hex[1]
       if (verbose) then print,'ccsds.checksum = ',data[sets].ccsds.checksum
    endif ;  source2 eq 'ccsds'

    next_packet:

;  update markers

    last_pkt_start_byte = pkt_start_byte
    pkt_start_byte = file_info.size - track_number_bytes 
; stop

 endwhile  ;  not(eof(lun))

 finish:         ;  if reach point where no more data to process

 print,'file_info.size = ',strtrim(file_info.size,2)
 print,'track_number_bytes = ',strtrim(track_number_bytes,2)

 data.total_number_pkts = packet_count
 print,'Number of packets: ' + strtrim(packet_count,2)
 print,'Number of mag packets: ' + strtrim(mag_packet_count,2)

;  only save actual data

; data = data[0:packet_count-1]
 data = data[0:mag_packet_count-1]

;  close input file

 free_lun,lun

 return
 end  ; mvn_mag_pkts_read
