;***************************************************************************** 
;+
;*NAME:
;
;	maven_mag_pkts_read
;
;*PURPOSE:
;
;	Read the MAVEN MAG data.  Formats handled are from 
;       - instrument,
;	- engineering packet from University of California at Berkeley
;	  Particle and Fields Package (PFP) DPU, 
;	- science packets (multiple formats) from PFP DPU, and 
;       - CCSDS format from spacecraft (available via LASP SDC).
;
;*CALLING SEQUENCE:
;
;	maven_mag_pkts_read,filename,data,data_source,   $
;          input_path=input_path,verbose=verbose
;
;*PARAMETERS:
;
;	filename (required) (input) (string) (scalar)
;	   Input filename - without path.
;
;	data (required) (output) (structure) (array)
;	   Data in a array of structures.  One array entry per packet.
;
;	data_source (required) (input) (scalar) (string)
;	   Describes the source os the data file.
;	   'instrument' - from the instrument, no PFP or spacecraft in path
;	   'pfp_eng' - engineering data via the PFP DPU which includes 
;		       the PFP header
;	   'pfp_sci' - science data via the PFP DPU which includes the 
;		       PFP header
;	   'ccsds' - data from the spacecraft which includes the CCSDS 
;		     and PFP headers
;
;	input_path (keyword) (input) (string) (scalar)
;	   Path to input file.
;
;	verbose (keyword) (input) (integer) (scalar) 
;	   Set to have additional output to screen.
;
;*EXAMPLES:
;
;	pfp_input_path = '/data4/maven/data/ucb/'
;	file26 = 'APID_26.dat' 
;	maven_mag_pkts_read,file26,data26,'pfp_eng',   $
;          input_path=pfp_input_path,/verbose 
;
;	file40 = 'APID_40.dat' 
;	maven_mag_pkts_read,file40,data40,'pfp_sci',   $
;	   input_path=pfp_input_path,/verbose 
;
;	file40avg = 'APID_40_avg2.dat' 
;	maven_mag_pkts_read,file40avg,data40avg,'pfp_sci',   $
;	   input_path=pfp_input_path
;
;       input_path = '/home/magdata/maven/data/flight/telemetry/sci/mag/l0/'
;       file = 'mvn_mag_svy_l0_20131205_v2.dat'
;	maven_mag_pkts_read,file,data,'ccsds',input_path=input_path
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
;	checksum_16bits
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
;	assumes data in input files is 
;	- all from the instrument, or 
;	- all engineering via PFP DPU (ApIds 26 and 27), or 
;	- all science via PFP DPU (ApIds 40, 41, 42, and 43), or
;	- from the spacecraft with CCSDS and PFP headers.
;
;       ApId 30 (passthru) not coded for
;
;       Maximum of 550,000 packets per file currently permitted.
;
;*NOTES:
;
;  PFP MAG engineering checksum only uses MAG portion
;  PFP MAG science checksum uses PFP header and MAG portion
;
;  Which MAG sensor is which:
;  
;    OB is FM1; on +Y; SSN #5; PFP APID 26 (engr), 40, 42; Drive select 0
;    IB is FM2; on -Y; SSN #6; PFP APID 27 (engr), 41, 43; Drive select 3
;    PFP test setup at SSL is EM;  SSN #1
;
;  Message ID not modified by PFP FSW - not to be used to determine packet type

;  Problems
;  - message ids not as expected for PFP packets
;  - decom id not as expected for engr pkt (set to 0 not expected 1)
;  - no PFP ApID 30 data (passthru)
;
;*PROCEDURE:
;
;	- determine input path to use
;	- make sure input file exists
;	- setup useful values and structures
;	- read until end of file - or not enough bytes left
;	- for the first (index 0) packet, calculate estimated number of packets
;	- if CCSDS source, decome that header
;	- if data via PFP DPU, decom the PFP header
;	  - if not a MAG packet, skip
;	  - if a MAG science packet, include the PFP header in the MAG 
;	    checksum calculation
;	- decom the MAG data header
;	  - failed_flag set to 1 if values are not as expected
;	- decom the MAG engineering data (if not a science data packet)
;	- decom MAG science data (if not an engineering packet)
;	- decom MAG checksum and verify value
;	  - for instrument packet, last bit will always be 0
;	- if engineering data via PFP DPU, decom extra bytes
;	- if CCSDS packet, decom CCSDS checksum (not being checked)
;	- if falied_flag is set, find next packet
;	- after file is read, save only entries that have data
;
;*MODIFICATION HISTORY:
;
;	30 Mar 2012  PJL  started writing
;       26 Apr 2012  PJL  continued
;       27 Apr 2012  PJL  continued
;        8 May 2012  PJL  determined that message ids in UCB supplied data 
;        and              not as expected;  change code to check second
;        9 May 2012       byte to determine type - perfer to use message id -
;                         will need to rework after data is corrected
;       18 May 2012  PJL  might be able to handle muplitple UCB ApIds in
;                         one file now - not tested
;          Feb 2013  PJL  added CCSDC header;  more of UCB header
;       24 May 2013  PJL  add code to skip bytes if PFP, but not MAG pkt
;       13 Mar 2013  PJL  add check for if marker_search found additional data;
;                         before each readu, check that there are enough bytes 
;                         remaining
;       24 May 2013  PJL  skip data that is not MAG data
;       29 May 2013  PJL  corrected data subseting at end (0.4.1)
;       19 Jun 2013  PJL  handle headers with no or only time data
;       19 Jul 2013  PJL  added check of source 2 if hex to determine source 
;	                  is an 'else' (still need to code marker_search)
;       22 Jul 2013  PJL  rearranged failed flag code;  handle sync pattern
;                         not found
;       15 Oct 2013  PJL  handle CCSDS length of 0 bytes;  set the marker_search
;                         after_byte based on expected packet type (0.4.5)
;       27 Nov 2013  PJL  data_source as input instead of trying to determine
;       29 Nov 2013  PJL  adding MAG data checksum check (works for engineering
;                         data, but not for science data);  engineering tags
;                         renamed 'z' replaced with 'e' for 8p2vp, 8p2vn,
;                         13vp, 13vn, 11p4v, 2p5vp, and 3p3vp
;       02 Dec 2013  PJL  reformat help print
;       04 Dec 2013  PJL  finally understand PFP MAG science packet checksum
;       06 Dec 2013  PJL  ucb_ changed to pfp_;  rename pfp_extra_engr to
;                         pfp_engr;  decom pfp_engr;  data_type (unused) 
;                         replaced with source;  replaced apid with apid_hex;
;                         added apid (decimal);  clean up;  additional notes;
;                         additional checks for failed cases (0.4.7)
;       11 Dec 2013  PJL  messaage ids will not be fixed - remove messages
;                         that assumes they will;  cross check serial number,
;			  drive value, and PFP apid; passthru (PFP Apid 0x30) 
;                         code commented out (no data to test;  handle 
;                         direct from instrument (last bit always zero) 
;                         checksum verification correctly; updated prolog (0.5)
;       20 Dec 2013  PJL  compare pkt_type and difference flags - if not
;                         correct match, set failed flag
;	11 Mar 2014  PJL  changed MAVEN spacecraft number from 202 to -202
;	18 Mar 2014  PJL  correct difference words (skip first difference
;			  since all zeros and use next 63)
;
;-
;******************************************************************************
 pro maven_mag_pkts_read,filename,data,data_source,   $
       input_path=input_path,verbose=verbose

; !except = 2
 if (n_params(0) ne 3) then begin
    print,'MAVEN_MAG_PKTS_READ,FILENAME,DATA,DATA_SOURCE,' +   $
       'input_path=input_path,/verbose'
    print,' '
    print,'   FILENAME    - input filename'
    print,'   DATA        - output with data from the telemetry file'
    print,'   DATA_SOURCE - Allowed values are '
    print,'                 instrument, pfp_eng, pfp_sci, ccsds'
;    print,'                 instrument, pfp_eng, pfp_sci, passthru, ccsds'
    print,'   input_path  - override DAT environment variable'
    print,'   verbose     - display information as reading file'
    print,' '
    retall
 endif  ; n_params(0) ne 2

 sw_version = 'maven_mag_pkts_read.pro Version 0.5 test'


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
; two_array_64 =  [two_array_32*2147483648.d*2.d, two_array_32]
; two_array_16_2 = [ 1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L,   $
;                    256L, 512L, 1024L, 2048L, 4096L, 8192L, 16384L, 32768L ]

;  MAVEN spacecraft number

 maven_sc = -202

; sync pattern

 sync_pattern = 'FE6B2840'

;  create structures  - CORRECTION since apid overlaps byte 0

 ccsds_header = { byte0: '',        $
                  apid_hex:  '',    $
                  apid: 0L,         $
                  bytes23: '',      $
                  length:  -1L,     $
                  time_hex: '',     $
                  second:  -1.0D,   $
                  subsecond:  -1,   $
                  checksum: ''  }

 pfp_header = { byte0: '',      $
                apid_hex:  '',  $
                apid:  0L,      $
                hex_string: '', $
;               grouping:
;               source_seq_ct:
                length: 0L,     $
                second: -1.0D  }

 pfp_engr = { opt: 0L,     $
              rstlmt: 0,   $
              rstsec: 0,   $
              xoff0: 0L,   $
              yoff0: 0L,   $
              zoff0: 0L,   $
              xoff1: 0L,   $
              yoff1: 0L,   $
              zoff1: 0L,   $
              xoff3: 0L,   $
              yoff3: 0L,   $
              zoff3: 0L   }

;  header (same for all packet types) and checksum

 header = { pkt_id: -1,          $
            pkt_len: -1,         $
            sync_h: -1L,         $
            sync_l: -1L,         $
            sync_hex: '',        $
;            sync: -1L,           $
            tlfmt: -1,           $
            spare_3_15: -1,      $
            nrng: -1,            $
            avg_n: -1,           $    ; science only
            eng_n: -1,           $    ; engineering only
            diff: -1,            $
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
            cal: -1,             $
            mnl: -1,             $
            rng: -1,             $
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
          e8p2vp: -1L,         $
          e8p2vn: -1L,         $
          temp: -1L,           $
          pctmp: -1L,          $
          e13vp: -1L,          $
          e13vn: -1L,          $
          e11p4v: -1L,         $
          e2p5vp: -1L,         $
          e3p3vp: -1L,         $
          ad5vp: -1L,          $
          ad5vn: -1L,          $
          word_26_08_11: -1,   $
          word_26_12_15: -1,   $
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

; number_engr_pkts = 0L
; number_science_pkts = 0L

 sets = -1L           ;  the number of "kept" packets (minus 1;  starts at 0)
 packet_count = 0L    ;  the number of the packet in the file (starts at 1)
 mag_packet_count = 0L  ; the number of the mag packet in the file (starts at 1)
 last_pkt_start_byte = 0L  ; keep at 0, not -1 for 1st pkt problems
 pkt_start_byte = 0L  ; keep at 0, not -1 for 1st pkt problems
 ccsds_buff_num = 0L
 pfp_buff_num = 0L
 pfp_buff_num_max = 12L

;  work through the file

 while not(eof(lun)) do begin

   next:                    ;  if had to search to find marker

    if (verbose) then print,'track_number_bytes = ', track_number_bytes

;  assuming all data is the same source

    if (packet_count eq 0) then begin
       case (strtrim(data_source)) of
          'instrument':  begin
                            source = 'instrument'
                            source2 = 'instrument'
                            pfp_buff_num = 0L
                            pfp_buff_num_max = 0L
                         end  ; strtrim(data_source) eq 'instrument'
          'pfp_eng':  begin
                         source = 'engr'
                         source2 = 'pfp'
                         pfp_buff_num = 10L
                      end  ; strtrim(data_source) eq 'pfp_eng'
;          'passthru': begin             

;  'passthru' NEVER TESTED
;                         source = 'passthru'
;                         pfp_buff_num = 12L
;                         source2 = 'pfp'
;                         print,'Warning: ApId 30 never tested'
;                      end  ; strtrim(data_source) eq 'passthru'
          'pfp_sci':  begin
                         source = 'science'
                         source2 = 'pfp'
                         pfp_buff_num = 12L
                      end  ; strtrim(data_source) eq 'pfp_sci'
          'ccsds':  begin

;  if ccsds define as science to start with;  code will determine by packet

                       source = 'science'
                       source2 = 'ccsds'
                       pfp_buff_num = 12L
                       ccsds_buff_num = 11L
                    end  ; strtrim(data_source) eq 'ccsds'
          else:  begin
                    print,'Supplied data_source is not an expected value'
                    print,'Allowed values are instrument, pfp_eng, ' +   $
                       'pfp_sci, ccsds'
;                       'pfp_sci, passthru, ccsds'
                    print,'ACTION: retall'
                    retall
                 end  ; else 
       endcase  ; strlowcase(data_source)


       if (pfp_buff_num gt 0) then begin
          if (verbose) then print,'data via PFP FSW'

          max_number_of_pkts = (file_info.size/72L) + 1L
          if (verbose) then print,'max_number_of_pkts = ',max_number_of_pkts

;  check against maximum number of packets

          if (max_number_of_pkts gt memory_max) then begin
             print,'WARNING:  only read first ' + strtrim(memory_max,2) +   $
                ' packets'
             max_number_of_pkts = memory_max
          endif  ; (max_number_of_pkts gt memory_max)

;  create data structure - designed for intermixed engr and science packets

          if (source2 eq 'ccsds') then begin
             data = replicate( { filename: filename,             $
                path: input_path,                                $
                sc: maven_sc,                                    $
                failed_flag: 0L,                                 $
                total_number_pkts: packet_count,                 $
;                total_number_engr_pkts: number_engr_pkts,        $
;                total_number_science_pkts: number_science_pkts,  $
                packet_number: 0L,                               $
                engr_packet_number: 0L,                          $
                science_packet_number: 0L,                       $
                source: data_source,                             $
                pkt_type: 0,                                     $
                sw_version:sw_version,                           $
                ccsds: ccsds_header,                             $
                pfp_header: pfp_header,                          $
                header: header,                                  $
                engr: engr,                                      $
                pfp_engr: pfp_engr,                              $
                science: science }, max_number_of_pkts)
          endif else begin 
             data = replicate( { filename: filename,             $
                path: input_path,                                $
                sc: maven_sc,                                    $
                failed_flag: 0L,                                 $
                total_number_pkts: packet_count,                 $
;                total_number_engr_pkts: number_engr_pkts,        $
;                total_number_science_pkts: number_science_pkts,  $
                packet_number: 0L,                               $
                engr_packet_number: 0L,                          $
                science_packet_number: 0L,                       $
                source: data_source,                             $
                pkt_type: 0,                                     $
                sw_version:sw_version,                           $
                pfp_header: pfp_header,                          $
                header: header,                                  $
                engr: engr,                                      $
                pfp_engr: pfp_engr,                               $
                science: science }, max_number_of_pkts)
          endelse  ; source2 eq 'ccsds'
       endif else begin

          if (source eq 'instrument') then begin
             if (verbose) then print,'data from instrument'

             max_number_of_pkts = (file_info.size/262L) + 1L
             if (verbose) then print,'max_number_of_pkts = ',max_number_of_pkts

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
                source: data_source,                   $
                packet_number: 0L,                     $
                sw_version:sw_version,                 $
                header: header,                        $
                engr: engr,                            $
                science: science }, max_number_of_pkts)

          endif else begin
             print,'Error (maven_mag_pkts_read): source, ' +   $
                strtrim(source,2) + ' - not coded for'
             data = 0
             print,'Action: return'
             retall
          endelse  ; source eq 'instrument'
       endelse  ; (pfp_buff_num gt 0)
    endif  ; packet_count eq 0

;  increment counters and reset failed_flag

    failed_flag = 0
    sets = sets + 1L
    packet_count = packet_count + 1L
    mag_packet_count = mag_packet_count + 1L
    data[sets].packet_number = packet_count

    if (source2 eq 'ccsds') then begin

;  note:  CCSDS Apids related to MAG data changed during developmet,
;         so use of the values was removed to prevent unnecessary errors

       buff_num = 11L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num
       if (verbose) then print,'track_number_bytes = ', track_number_bytes

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)

;  byte 0

       data[sets].ccsds.byte0 = strupcase(hex[0])
       if (verbose) then print,'ccsds.byte0 = ',data[sets].ccsds.byte0

;  ApId

       data[sets].ccsds.apid_hex = strupcase(hex[1])
       if (verbose) then print,'ccsds.apid_hex = ',data[sets].ccsds.apid_hex

       data[sets].ccsds.apid = fix(buff[1])
       if (verbose) then print,'ccsds.apid = ',data[sets].ccsds.apid

; CCSDS bytes 2 and 3

       data[sets].ccsds.bytes23 = hex[2] + hex[3]
       if (verbose) then print,'ccsds.bytes23 = ',data[sets].ccsds.bytes23

; CCSDS length (excludes primary header but includes seondary header 
; time;  bytes minus one)

       bitlis,buff[4:5],bit_array
       data[sets].ccsds.length = long(total(bit_array * two_array_16))
       if (verbose) then print,'ccsds.length = ',data[sets].ccsds.length

       if ( (data[sets].ccsds.length eq 0) or   $
            (data[sets].ccsds.length eq 5) ) then begin

;  remove that packet since it is empty

          if (data[sets].ccsds.length eq 0) then begin
             neglun = (-1) * lun
             point_lun,neglun,position
             point_lun,lun,position-5L
             track_number_bytes = track_number_bytes + 5L
             if (verbose) then print,'track_number_bytes = ', track_number_bytes
          endif ; data[sets].ccsds.length eq 0
          
          data[sets].ccsds.byte0 = ''
          data[sets].ccsds.apid_hex = ''
          data[sets].ccsds.apid = 0L
          data[sets].ccsds.bytes23 = ''
          data[sets].ccsds.length = -1L
          data[sets].ccsds.time_hex = ''
          data[sets].ccsds.second = -1.0D
          data[sets].ccsds.subsecond = -1

          sets = sets - 1L
          mag_packet_count = mag_packet_count - 1L
          goto, next_packet
       endif  ; data[sets].ccsds.length eq 0 or 5

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

    checksum_buff_start = 0L

;  read PFP header - for now, just a hex string

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
       if (verbose) then print,'track_number_bytes = ', track_number_bytes

       hex = buff
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)

       if (verbose) then print,'apid_hex: ',hex[1]
       case (strupcase(hex[1])) of
;          '81': begin
;                   source = 'instrument'
;                   pfp_buff_num = 0L
;                   checksum_buff = bytarr(264)
;                   expect_pfp_length = 0
;                end  ; strupcase(hex[1]) eq '81'
          '26': begin
                   source = 'engr'
                   pfp_buff_num = 10L
                   checksum_buff = bytarr(196)
                   expect_pfp_length = 101
                end  ; strupcase(hex[1]) eq '26'
          '27': begin
                   source = 'engr'
                   pfp_buff_num = 10L
                   checksum_buff = bytarr(196)
                   expect_pfp_length = 101
                end  ; strupcase(hex[1]) eq '27'
;          '30': begin
;                   source = 'instrument'
;                   pfp_buff_num = 12L
;                   checksum_buff = bytarr(264)
;                   expect_pfp_length = 269
;                   print,'Warning: ApId 30 never tested'
;                end  ; strupcase(hex[1]) eq '30'
          '40': begin
                   source = 'science'
                   pfp_buff_num = 12L
                   checksum_buff = bytarr(232)
                   expect_pfp_length = 225
                end  ; strupcase(hex[1]) eq '40'
          '41': begin
                   source = 'science'
                   pfp_buff_num = 12L
                   checksum_buff = bytarr(232)
                   expect_pfp_length = 225
                end  ; strupcase(hex[1]) eq '41'
          '42': begin
                   source = 'science'
                   pfp_buff_num = 12L
                   checksum_buff = bytarr(232)
                   expect_pfp_length = 225
                end  ; strupcase(hex[1]) eq '42'
          '43': begin
                   source = 'science'
                   pfp_buff_num = 12L
                   checksum_buff = bytarr(232)
                   expect_pfp_length = 225
                end  ; strupcase(hex[1]) eq '43'
          else: begin
             If(verbose) Then Begin
                print,' '
                print,'Hex value of the second byte is ' + hex[1]
                print,source,' ',source2
                print,'Not an expected value ' +   $
                      '(26, 27, 40, 41, 42, 43)'
             Endif
;                      '(81, 26, 27, 30, 40, 41, 42, 43)'

;  determine length of packet that is not mag data - skip that packet

                   if (source2 eq 'ccsds') then begin
                      buff_num = data[sets].ccsds.length + 1L - 7L
                      if(verbose) then print,'Assume not a MAG packet - skipping ' +  $
                         strtrim(buff_num,2) + ' bytes'
;if (buff_num eq 0) then stop
                      if (track_number_bytes lt buff_num) then begin
                         print,'Remaining bytes less than next buffer'
                         print,'ACTION: finish'
                         goto, finish
                      endif  ; track_number_bytes lt buff_num
; print,hex
                      if (buff_num gt 0) then begin
                         buff = bytarr(buff_num)
                         readu,lun,buff
                         track_number_bytes = track_number_bytes - buff_num
                         if (verbose) then print,'track_number_bytes = ',    $
                            track_number_bytes
                      endif  ;  buff_num gt 0

;  reset values for data structure index

                      data[sets].ccsds.byte0 = ''
                      data[sets].ccsds.apid_hex = ''
                      data[sets].ccsds.apid = 0L
                      data[sets].ccsds.bytes23 = ''
                      data[sets].ccsds.length = -1L
                      data[sets].ccsds.time_hex = ''
                      data[sets].ccsds.second = -1.0D
                      data[sets].ccsds.subsecond = -1

                      sets = sets - 1L
                      mag_packet_count = mag_packet_count - 1L
                      goto, next_packet
                   endif else begin
;  not ccsds

;stop
                      failed_flag = buff_num
                      data[sets].failed_flag = failed_flag

                   endelse  ; source2 eq 'ccsds'
                end  ; else
       endcase ;  strupcase(hex[1])

; print,'source = ',source,'  source2 = ',source2

;  byte 0

       if (failed_flag eq 0) then begin

          if (source eq 'science') then begin

;  for PFP FSW modified science (not engineering) packets, the 
;  PFP header is included in the checksum calculation

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:  $
                checksum_buff_start+buff_num-1] = buff
             checksum_buff_start = checksum_buff_start + buff_num
             if (verbose) then print,checksum_buff_start
          endif  ; source eq 'science'

          data[sets].pfp_header.byte0 = strupcase(hex[0])
          if (verbose) then   $
             print,'pfp_header.byte0 = ',data[sets].pfp_header.byte0

;  ApId

          data[sets].pfp_header.apid_hex = strupcase(hex[1])
          if (verbose) then   $
             print,'pfp_header.apid_hex = ',data[sets].pfp_header.apid_hex

          data[sets].pfp_header.apid = fix(buff[1])
          if (verbose) then   $
             print,'pfp_header.apid = ',data[sets].pfp_header.apid

;  rest of the header

          if (pfp_buff_num gt 2) then begin
             buff_num = pfp_buff_num - 2L
             if (track_number_bytes lt buff_num) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_num

             buff = bytarr(buff_num)
             readu,lun,buff

             track_number_bytes = track_number_bytes - buff_num
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (source eq 'science') then begin

;  for PFP FSW modified science (not engineering) packets, the 
;  PFP header is included in the checksum calculation

                if (verbose) then print,checksum_buff_start
                checksum_buff[checksum_buff_start:   $
                   checksum_buff_start+buff_num-1] = buff
                checksum_buff_start = checksum_buff_start + buff_num
                if (verbose) then print,checksum_buff_start
             endif  ; source eq 'science'

             hex = buff
             hex = byte(string(hex,'(z)'))
             hex = strtrim(hex(5:6,*),2)
             temp = where(strlen(hex) ne 2,temp_count)
             if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

;       if (verbose) then print,hex

             num_hex = n_elements(hex)
             for i=0,num_hex-1 do data[sets].pfp_header.hex_string =   $s
                data[sets].pfp_header.hex_string + hex[i]
             if (verbose) then   $
                print,'ubc_header.hex_string = ',  $
                   data[sets].pfp_header.hex_string

;  grouping flags - NEED TO CODE

;  Source Sequence Count  - NEED TO CODE

;  Packet Length

             bitlis,buff[2:3],bit_array
             data[sets].pfp_header.length =   $
                long(total(bit_array * two_array_16))
             if (verbose) then   $
                print,'pfp_header.length = ',data[sets].pfp_header.length
             if (data[sets].pfp_header.length ne expect_pfp_length) then begin
                print,'WARNING: Set ' + strtrim(sets,2) + ' PFP length of ' +  $
                   strtrim(data[sets].pfp_header.length,2) +   $
                   ' not expected value of ' + strtrim(expect_pfp_length,2) + $
                   ' for PFPF Apid 0x' + data[sets].pfp_header.apid_hex
                failed_flag = buff_num
                data[sets].failed_flag = failed_flag
             endif  ; data[sets].pfp_header.length ne expect_pfp_length

;  Packet Time (PFP, not MAG - not to be used for processing)

             bitlis,buff[4:7],bit_array
             data[sets].pfp_header.second = total(bit_array * two_array_32)
             if (verbose) then   $
                print,'pfp_header.second = ',data[sets].pfp_header.second

          endif ;  pfp_buff_num gt 2
       endif  ; failed_flag eq 0
    endif else begin 
       if (source eq 'instrument') then begin
          checksum_buff = bytarr(264)
          expect_pfp_length = 0
       endif   ; source eq 'instrument'
    endelse ;  (source eq 'engr') or (source eq 'science')

;  read MAG header section - all packet types

    if (failed_flag eq 0) then begin
       buff_num = 20L
       if (track_number_bytes lt buff_num) then begin
          print,'Remaining bytes less than next buffer'
          print,'ACTION: finish'
          goto, finish
       endif  ; track_number_bytes lt buff_num

       buff = bytarr(buff_num)
       readu,lun,buff
       track_number_bytes = track_number_bytes - buff_num
       if (verbose) then print,'track_number_bytes = ',track_number_bytes

       if (verbose) then print,checksum_buff_start
       checksum_buff[checksum_buff_start:checksum_buff_start+buff_num-1] = buff
       checksum_buff_start = checksum_buff_start + buff_num
       if (verbose) then print,checksum_buff_start

       hex = buff[0:5]
       hex = byte(string(hex,'(z)'))
       hex = strtrim(hex(5:6,*),2)
       temp = where(strlen(hex) ne 2,temp_count)
       if (temp_count gt 0) then hex(temp) = '0' + hex(temp)

       if (verbose) then print,hex

;  check sync pattern

       hex_string = hex[2] + hex[3] + hex[4] + hex[5]

       if (strupcase(hex_string) eq sync_pattern) then begin

;  data.header.pkt_id
   
          data[sets].header.pkt_id = fix(buff[0])
          if (verbose) then print,'header.pkt_id = ',data[sets].header.pkt_id
          if (data[sets].header.pkt_id ne 64) then begin
             print,'WARNING" set ' + strtrim(sets,2) + ' PKT_ID value is ' +  $
                strtrim(data[sets].header.pkt_id,2) +   $
                ', not expected value of 64'
             failed_flag = buff_num
             data[sets].failed_flag = failed_flag
          endif  ; data[sets].header.pkt_id ne 64

;           data.header.pkt_len
   
          data[sets].header.pkt_len = fix(buff[1])
          if (verbose) then print,'header.pkt_len = ',data[sets].header.pkt_len

;  note:  129 is the correct (131 words - 2 words) value for the instrument
;         packets;  The PFP FSW did _not_ modify this value, therefore it
;         is the incorrect value for a packet that has been modified by 
;         the PFP FSW, but it is always 129

          if (data[sets].header.pkt_len ne 129) then begin
             print,'WARNING" set ' + strtrim(sets,2) + ' PKT_LEN value is ' +  $
                strtrim(data[sets].header.pkt_id,2) +   $
                ', not expected value of 129'
             failed_flag = buff_num
             data[sets].failed_flag = failed_flag
          endif  ; data[sets].header.pkt_id ne 129
  
;  data.header.sync_h

          bitlis,buff[2:3],bit_array
          data[sets].header.sync_h = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.sync_h = ',data[sets].header.sync_h

;  data.header.sync_l

          bitlis,buff[4:5],bit_array
          data[sets].header.sync_l = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.sync_l = ',data[sets].header.sync_l

;  data.header.sync_hex

          data[sets].header.sync_hex = strupcase(hex_string)
          if (verbose) then print,'header.sync_hex = ',   $
             data[sets].header.sync_hex
   
;  data.header.sync

;          bitlis,buff[2:5],bit_array
;          data[sets].header.sync = long(total(bit_array * two_array_32))
;          if (verbose) then print,'header.sync = ',data[sets].header.sync

;  data.header.tlfmt - and split out
;  note:  for data from the instrument, this value is 0
;         for data via the PFP FSW, this value includes PKT_TYPE (0,2,3),
;         DIFF (0,1), AVG_N (0-5) or ENG_N (0-7), NRNG (0,1)

          data[sets].header.tlfmt = fix(buff[6])
          if (verbose) then print,'header.tlfmt = ',data[sets].header.tlfmt
   
          bitlis,buff[6],bit_array

;  data.header.pkt_type

;  expected values
;    0 is engineering via PFP FSW or instrument
;    2 (averaged) and 3 (averaged and differenced) are science via PFP FSW

          data[sets].header.pkt_type = fix(total(bit_array[0:1] * two_array_2))
          if (verbose) then print,'header.pkt_type = ',   $
             data[sets].header.pkt_type
          if ( (data[sets].header.pkt_type ne 0) and   $
               (data[sets].header.pkt_type ne 2) and   $
               (data[sets].header.pkt_type ne 3) ) then begin
             print,'WARNING: set ' + strtrim(sets,2) +   $
                ' has invalid PKT_TYPE of ' +   $
                strtrim(data[sets].header.pkt_type,2)
             failed_flag = buff_num
             data[sets].failed_flag = failed_flag
          endif  ; data[sets].header.pkt_type ne 

;  data.header.diff (differencing not enabled = 0; enabled = 1)

          data[sets].header.diff = bit_array[2]
          if (verbose) then print,'header.diff = ',data[sets].header.diff

;  data.header.avg_n (science; number of samples averaged) or
;  data.header.eng_n (engineering; engineering rate)

          if (source eq 'engr') then begin
             data[sets].header.eng_n = fix(total(bit_array[3:5] * two_array_3))
          endif else    $    ;  instrument or science 
             data[sets].header.avg_n = fix(total(bit_array[3:5] * two_array_3))
          if (verbose) then begin
             print,'header.eng_n = ',data[sets].header.eng_n
             print,'header.avg_n = ',data[sets].header.avg_n
          endif  ; verbose

;  data.header.nrng 
;  if eq 1, a range change was detected in any MAG_TLM pkt that contributed 
;     data to this MAG_SCI pkt;  eq 0, otherwise

          data[sets].header.nrng = bit_array[6]
          if (verbose) then print,'header.nrng = ',data[sets].header.nrng
   
;  data.header.spare_3_15

          data[sets].header.spare_3_15 = bit_array[6]
          if (verbose) then   $
             print,'header.spare_3_15 = ',data[sets].header.spare_3_15
   
;  data.header.cmd_cnt (command count)
   
          data[sets].header.cmd_cnt = fix(buff[7])
          if (verbose) then print,'header.cmd_cnt = ',data[sets].header.cmd_cnt

;  data.header.pkt_seq (packet sequence)

          bitlis,buff[8:9],bit_array
          data[sets].header.pkt_seq = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.pkt_seq = ',data[sets].header.pkt_seq

;  data.header.time_f0

          bitlis,buff[10:11],bit_array
          data[sets].header.time_f0 = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.time_f0 = ',data[sets].header.time_f0

;  data.header.time_h

          bitlis,buff[12:13],bit_array
          data[sets].header.time_h = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.time_h = ',data[sets].header.time_h

;  data.header.time_l

          bitlis,buff[14:15],bit_array
          data[sets].header.time_l = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.time_l = ',data[sets].header.time_l

;  data.header.pkt_time (packet time)

          bitlis,buff[12:15],bit_array
          data[sets].header.pkt_time = total(bit_array * two_array_32)
          if (verbose) then   $
             print,format='(a,f20.2)','header.pkt_time = ',   $
                data[sets].header.pkt_time

;  data.header.time_mod

          bitlis,buff[16:17],bit_array
          data[sets].header.time_mod = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.time_mod = ',   $
             data[sets].header.time_mod

;  Header Word 9 (MAG_STATUS)

          temp = reverse(buff[18:19])
          bitlis,temp,bit_array

;  data.header.rng (range = 0, 1, or 3)

          data[sets].header.rng = fix(total(bit_array[0:1] * two_array_2))
          if (verbose) then print,'header.rng = ',data[sets].header.rng
          if ( (data[sets].header.rng ne 0) and   $
               (data[sets].header.rng ne 1) and   $
               (data[sets].header.rng ne 3) ) then begin
             print,'WARNING: set ' + strtrim(sets,2) +   $
                ' has invalid RNG of ' + strtrim(data[sets].header.rng,2)
             failed_flag = buff_num
             data[sets].failed_flag = failed_flag
          endif  ; data[sets].header.rng ne 0, 1, or 3

;  data.header.mnl (0 = auto ranging;  1 = manual ranging)

          data[sets].header.mnl = bit_array[2]
          if (verbose) then print,'header.mnl = ',data[sets].header.mnl

;  data.header.cal (0 = cal off; 1 = cal on)

          data[sets].header.cal = bit_array[3]
          if (verbose) then print,'header.cal = ',data[sets].header.cal

;  data.header.drive (drive select status)

          data[sets].header.drive = fix(total(bit_array[4:5] * two_array_2))
          if (verbose) then print,'header.drive = ',data[sets].header.drive

;  data.header.sn (serial number)

          data[sets].header.sn = fix(total(bit_array[6:9] * two_array_4))
          if (verbose) then print,'header.sn = ',data[sets].header.sn
          if (data_source ne 'instrument') then begin
             case (data[sets].header.sn) of 
                5: begin
                      if (data[sets].header.drive ne 0) then   $
                         print,'WARNING: Set ' + strtrim(sets,2) +   $
                         ' serial number 5, not drive 0'
                      if ( (data[sets].pfp_header.apid ne 38) and   $
                           (data[sets].pfp_header.apid ne 64) and   $
                           (data[sets].pfp_header.apid ne 66) ) then   $
                         print,'WARNING: Set ' + strtrim(sets,2) +   $
                         ' serial number 5, not PFP Apid 38, 64, or 66'
                   end  ; data[sets].header.sn eq 5
                6: begin
                      if (data[sets].header.drive ne 3) then   $
                         print,'WARNING: Set ' + strtrim(sets,2) +   $
                         ' serial number 6, not drive 3'
                      if ( (data[sets].pfp_header.apid ne 39) and   $
                           (data[sets].pfp_header.apid ne 65) and   $
                           (data[sets].pfp_header.apid ne 67) ) then   $
                         print,'WARNING: Set ' + strtrim(sets,2) +   $
                         ' serial number 6, not PFP Apid 39, 65, or 67'
                   end  ; data[sets].header.sn eq 5
                else:  print,'WARNING: Set ' + strtrim(sets,2) + ' value ' +   $
                          strtrim(data[sets].header.sn,2) +    $
                          ' not serial number 5 or 6'
             endcase  ; data[sets].header.sn
          endif  ;  data_source ne 'instrument'

;  data.header.fpga (FPGA version number)

          data[sets].header.fpga = fix(total(bit_array[10:15] * two_array_6))
          if (verbose) then print,'header.fpga = ',data[sets].header.fpga

;  header done, now it depends on what type of packet this is

;  pkt_type = 0, instrument packet, 131 words
;  pkt_type = 0, engr packet via PFP FSW, MAG portion 38 words + 11 words
;  pkt_type = 2, science packet - averaged, MAG portion 110 words
;  pkt_type = 3, science packet - differenced, MAG portion 110 words

         if (verbose) then begin
            print,'pkt_type = ',data[sets].header.pkt_type
            print,'pkt_len = ',data[sets].header.pkt_len
            print,'source = ',source
         endif  ; verbose

;  analog and digital housekeeping (instrument or engr packets)
;  need to confirm being set correctly in PFP outout !!

;  engineering packet - or section in instrument packet

          if ( (source eq 'instrument') or   $
               (source eq 'engr') ) then begin

             buff_num = 48L
             if (track_number_bytes lt buff_num) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_num

             buff = bytarr(buff_num)
             readu,lun,buff
             track_number_bytes = track_number_bytes - buff_num
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_num-1] = buff
             checksum_buff_start = checksum_buff_start + buff_num
             if (verbose) then print,checksum_buff_start

;  data.engr.an_x

             decom_2s_complement,buff[0:1],value
             data[sets].engr.an_x = value
             if (verbose) then print,'engr.an_x = ',data[sets].engr.an_x

;  data.engr.an_y

             decom_2s_complement,buff[2:3],value
             data[sets].engr.an_y = value
             if (verbose) then print,'engr.an_y = ',data[sets].engr.an_y

;  data.engr.an_z

             decom_2s_complement,buff[4:5],value
             data[sets].engr.an_z = value
             if (verbose) then print,'engr.an_z = ',data[sets].engr.an_z

;  data.engr.anrz

             decom_2s_complement,buff[6:7],value
             data[sets].engr.anrz = value
             if (verbose) then print,'engr.anrz = ',data[sets].engr.anrz

;  data.engr.vcal

             decom_2s_complement,buff[8:9],value
             data[sets].engr.vcal = value
             if (verbose) then print,'engr.vcal = ',data[sets].engr.vcal

;  data.engr.e8p2vp (+8.2V)

             decom_2s_complement,buff[10:11],value
             data[sets].engr.e8p2vp = value
             if (verbose) then print,'engr.e8p2vp = ',data[sets].engr.e8p2vp

;  data.engr.e8p2vn (-8.2V)

             decom_2s_complement,buff[12:13],value
             data[sets].engr.e8p2vn = value
             if (verbose) then print,'engr.e8p2vn = ',data[sets].engr.e8p2vn

;  data.engr.temp (sensor temperature)

             decom_2s_complement,buff[14:15],value
             data[sets].engr.temp = value
             if (verbose) then print,'engr.temp = ',data[sets].engr.temp

;  data.engr.pctmp (PCB temperature)

             decom_2s_complement,buff[16:17],value
             data[sets].engr.pctmp = value
             if (verbose) then print,'engr.pctmp = ',data[sets].engr.pctmp

;  data.engr.e13vp (+13V)

             decom_2s_complement,buff[18:19],value
             data[sets].engr.e13vp = value
             if (verbose) then print,'engr.e13vp = ',data[sets].engr.e13vp

;  data.engr.e13vn (-13V)

             decom_2s_complement,buff[20:21],value
             data[sets].engr.e13vn = value
             if (verbose) then print,'engr.e13vn = ',data[sets].engr.e13vn

;  data.engr.e11p4v (+11.4V)

             decom_2s_complement,buff[22:23],value
             data[sets].engr.e11p4v = value
             if (verbose) then print,'engr.e11p4v = ',data[sets].engr.e11p4v

;  data.engr.e2p5vp (+2.5V)

             decom_2s_complement,buff[24:25],value
             data[sets].engr.e2p5vp = value
             if (verbose) then print,'engr.e2p5vp = ',data[sets].engr.e2p5vp

;  data.engr.e3p3vp (+3.3V)

             decom_2s_complement,buff[26:27],value
             data[sets].engr.e3p3vp = value
             if (verbose) then print,'engr.e3p3vp = ',data[sets].engr.e3p3vp

;  data.engr.ad5vp (ADC +5V)

             decom_2s_complement,buff[28:29],value
             data[sets].engr.ad5vp = value
             if (verbose) then print,'engr.ad5vp = ',data[sets].engr.ad5vp

;  data.engr.ad5vn (ADC -5V)

             decom_2s_complement,buff[30:31],value
             data[sets].engr.ad5vn = value
             if (verbose) then print,'engr.ad5vn = ',data[sets].engr.ad5vn

;  now digital housekeeping

;  Word 26, MAG_DIG_HK_00 (based on instrument packet format)

             temp = reverse(buff[32:33])
             bitlis,temp,bit_array

;  data.engr.s_err (stop bit error)

             data[sets].engr.s_err = bit_array[0]
             if (verbose) then print,'engr.s_err = ',data[sets].engr.s_err
             if (data[sets].engr.s_err eq 1) then begin
                print,'NOTICE:  Set ' + strtrim(sets,2) + ' stop bit error set'
             endif  ; data[sets].engr.s_err eq 1

;         data.engr.p_err (parity error)

             data[sets].engr.p_err = bit_array[1]
             if (verbose) then print,'engr.p_err = ',data[sets].engr.p_err
             if (data[sets].engr.p_err eq 1) then begin
                print,'NOTICE:  Set ' + strtrim(sets,2) + ' parity error set'
             endif  ; data[sets].engr.p_err eq 1

;         data.engr.crx (command received)

             data[sets].engr.crx = bit_array[2]
             if (verbose) then print,'engr.crx = ',data[sets].engr.crx

;         data.engr.trx_l

             data[sets].engr.trx_l = bit_array[3]
             if (verbose) then print,'engr.trx_l = ',data[sets].engr.trx_l
             if (data[sets].engr.trx_l eq 0) then begin
                print,'NOTICE:  Set ' + strtrim(sets,2) +   $
                   ' time update Lo word not recieved'
             endif  ; data[sets].engr.trx_l eq 0

;         data.engr.trx_m

             data[sets].engr.trx_m = bit_array[4]
             if (verbose) then print,'engr.trx_m = ',data[sets].engr.trx_m
             if (data[sets].engr.trx_m eq 0) then begin
                print,'NOTICE:  Set ' + strtrim(sets,2) +   $
                   ' time update Mid word not recieved'
             endif  ; data[sets].engr.trx_m eq 0

;         data.engr.trx_h

             data[sets].engr.trx_h = bit_array[5]
             if (verbose) then print,'engr.trx_h = ',data[sets].engr.trx_h
             if (data[sets].engr.trx_h eq 0) then begin
                print,'NOTICE:  Set ' + strtrim(sets,2) +   $
                   ' time update Hi word not recieved'
             endif  ; data[sets].engr.trx_h eq 0

;         data.engr.pps (PPS type;  0 = external; 1 = internal)

             data[sets].engr.pps = bit_array[6]
             if (verbose) then print,'engr.pps = ',data[sets].engr.pps

;         data.engr.nrng (MAG range update flag)

             data[sets].engr.nrng = bit_array[7]
             if (verbose) then print,'engr.nrng = ',data[sets].engr.nrng

;         data.engr.word_26_08_11

             data[sets].engr.word_26_08_11 =   $
                fix(total(bit_array[8:11] * two_array_4))
             if (verbose) then   $
                print,'engr.word_26_08_11 = ',data[sets].engr.word_26_08_11
             if (data[sets].engr.word_26_08_11 ne 0) then   $
               print,'WARNING: engr.word_26_08_11 equals ' +   $
                 strtrim(data[sets].engr.word_26_08_11,2) +   $
                    ' when it should equal 0'

;         data.engr.word_26_12_15

             data[sets].engr.word_26_12_15 =   $
                fix(total(bit_array[12:15] * two_array_4))
             if (verbose) then   $
                print,'engr.word_26_12_15 = ',data[sets].engr.word_26_12_15

;         data.engr.cmd (last command data excluding time messages)

             bitlis,buff[34:35],bit_array
             data[sets].engr.cmd = long(total(bit_array * two_array_16))
             if (verbose) then print,'engr.cmd = ',data[sets].engr.cmd

;         data.engr.cmd_r (command reject counter)

             data[sets].engr.cmd_r = fix(buff[36])
             if (verbose) then print,'engr.cmd_r = ',data[sets].engr.cmd_r

;         data.engr.cmd_o (last command op code)

             data[sets].engr.cmd_o = fix(buff[37])
             if (verbose) then print,'engr.cmd_o = ',data[sets].engr.cmd_o

;         data.engr.r0_h (range 0 high threshold)

             data[sets].engr.r0_h = fix(buff[38])
             if (verbose) then print,'engr.r0_h = ',data[sets].engr.r0_h

;         data.engr.r1_l (range 1 lo threshold)

             data[sets].engr.r1_l = fix(buff[39])
             if (verbose) then print,'engr.r1_l = ',data[sets].engr.r1_l

;         data.engr.r1_h (range 1 high threshold)

             data[sets].engr.r1_h = fix(buff[40])
             if (verbose) then print,'engr.r1_h = ',data[sets].engr.r1_h

;         data.engr.r3_l (range 3 lo threshold)

             data[sets].engr.r3_l = fix(buff[41])
             if (verbose) then print,'engr.r3_l = ',data[sets].engr.r3_l

;         data.engr.lle_n (LLE threshold)

             data[sets].engr.lle_n = fix(buff[42])
             if (verbose) then print,'engr.lle_n = ',data[sets].engr.lle_n

;         data.engr.ule_n (ULE threshold)

             data[sets].engr.ule_n = fix(buff[43])
             if (verbose) then print,'engr.ule_n = ',data[sets].engr.ule_n

;         data.engr.npkts (number of packets for algorithm interval)

             data[sets].engr.npkts = fix(buff[44])
             if (verbose) then print,'engr.npkts = ',data[sets].engr.npkts

;         data.engr.cpkts (integration packet count through last 1 PPS.  
;         If this equals npkts, then represents last second of integration)

             data[sets].engr.cpkts = fix(buff[45])
             if (verbose) then print,'engr.cpkts = ',data[sets].engr.cpkts

;         data.engr.ule (number of ULE threshold {X,Y,Z} crossings through 
;	  last 1 PPS)

             data[sets].engr.ule = fix(buff[46])
             if (verbose) then print,'engr.ule = ',data[sets].engr.ule

;         data.engr.lle (number of LLE threshold {X,Y,Z} crossings through 
;	  last 1 PPS)

             data[sets].engr.lle = fix(buff[47])
             if (verbose) then print,'engr.lle = ',data[sets].engr.lle

          endif  ;  data[sets].header.pkt_type eq 0 or 1

;  for engineering packet, next would be B componets from sample 0

          if (source eq 'engr') then begin

             buff_num = 6L
             if (track_number_bytes lt buff_num) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_num

             buff = bytarr(buff_num)
             readu,lun,buff
             track_number_bytes = track_number_bytes - buff_num
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_num-1] = buff
             checksum_buff_start = checksum_buff_start + buff_num
             if (verbose) then print,checksum_buff_start

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

          endif ; ource eq 'engr'


;  for science packet (pkt_type = 2), next would be B rms values
;  from MAVEN_PF_FSW_021_CTM.xls, looks like this may have been dropped
;  So, do this for pkt_type = 2 and see if the values match X, Y, Z of 
;  sample 0 - yes they do

          if (data[sets].header.pkt_type eq 2) then begin

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
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_num-1] = buff
             checksum_buff_start = checksum_buff_start + buff_num
             if (verbose) then print,checksum_buff_start

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
   
             print,'NOTICE:  RMS values actually first sample values when ' + $
                'PKT_TYPE = 2'

          endif ;  data[sets].header.pkt_type eq 2

;  for instrument packet (data_source = 'instrument', pkt_type = 0) or 
;  science packet (pkt_type = 2), science data is next

          if ( (source eq 'instrument') or    $
            (data[sets].header.pkt_type eq 2) ) then begin

;             science.cnts

             buff_size = 192L
             if (track_number_bytes lt buff_size) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_size

             buff = bytarr(buff_size)
             readu,lun,buff

             track_number_bytes = track_number_bytes - buff_size
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_size-1] = buff
             checksum_buff_start = checksum_buff_start + buff_size
             if (verbose) then print,checksum_buff_start

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
   
                if (verbose) then   $
                   print,'science.cnts[' + strtrim(i,2) + '] = ',  $
                      strtrim(data[sets].science.cnts[i].x,2),', ',   $
                      strtrim(data[sets].science.cnts[i].y,2),', ',   $
                      strtrim(data[sets].science.cnts[i].z,2),', ',   $
                      strtrim(data[sets].science.cnts[i].rng,2)
   
             endfor  ; i
          endif ; (source eq 'instrument') or (data[sets].header.pkt_type eq 2)

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
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_size-1] = buff
             checksum_buff_start = checksum_buff_start + buff_size
             if (verbose) then print,checksum_buff_start

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

;   science.cnts[1:63] - difference words

             buff_size = 192L
             if (track_number_bytes lt buff_size) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_size

             buff = bytarr(buff_size)
             readu,lun,buff
             track_number_bytes = track_number_bytes - buff_size
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             if (verbose) then print,checksum_buff_start
             checksum_buff[checksum_buff_start:   $
                checksum_buff_start+buff_size-1] = buff
             checksum_buff_start = checksum_buff_start + buff_size
             if (verbose) then print,checksum_buff_start

;  step through samples
       
;             for i=0,62 do begin
             for i=0,63 do begin

;  x component (science.cnts.x)

                bitlis,buff[i*3],bit_array
                value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
                  ( long(total(bit_array[0:6] * two_array_8[0:6])) )
;                data[sets].science.cnts[i+1].x = value
                if (i ne 0) then data[sets].science.cnts[i].x = value

;  y component (science.cnts.y)

                bitlis,buff[i*3+1],bit_array
                value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
                  ( long(total(bit_array[0:6] * two_array_8[0:6])) )
;                data[sets].science.cnts[i+1].y = value
                if (i ne 0) then data[sets].science.cnts[i].y = value

;  z component (science.cnts.z)

                bitlis,buff[i*3+2],bit_array
                value = ( -1L *  two_array_8[7] * bit_array[7] ) +   $
                  ( long(total(bit_array[0:6] * two_array_8[0:6])) )
;                data[sets].science.cnts[i+1].z = value
                if (i ne 0) then data[sets].science.cnts[i].z = value

;  range (science.cnts.rng)

;               data[sets].science.cnts[i+1].rng = -1
                if (i ne 0) then data[sets].science.cnts[i].rng = -1

                if (verbose and (i ne 0) ) then   $
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

;  for all packet types, last word (2 bytes) are checksum
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
          if (verbose) then print,'track_number_bytes = ',track_number_bytes
   
;  always 0 for calculation

          checksum_buff[checksum_buff_start:   $
             checksum_buff_start+buff_size-1] = [0,0]
          checksum_buff_start = checksum_buff_start + buff_size

;  data.header.cksum

          bitlis,buff[0:1],bit_array
          data[sets].header.cksum = long(total(bit_array * two_array_16))
          if (verbose) then print,'header.cksum = ',data[sets].header.cksum

;  data.header.cksum_hex

          hex = buff[0:1]
          hex = byte(string(hex,'(z)'))
          hex = strtrim(hex(5:6,*),2)
          temp = where(strlen(hex) ne 2,temp_count)
          if (temp_count gt 0) then hex(temp) = '0' + hex(temp)
          data[sets].header.cksum_hex = strupcase(hex[0] + hex[1])
          if (verbose) then print,'header.cksum_hex = ',   $
             data[sets].header.cksum_hex

;  check the checksum

          if (source eq 'instrument') then   $
             checksum_16bits,checksum_buff,cal_chksum,/lastbitzero   $
          else checksum_16bits,checksum_buff,cal_chksum
          if (verbose) then begin
             print,'header.cksum_hex = ', data[sets].header.cksum_hex
             print,'cal_chksum = ',cal_chksum
          endif  ; verbose
          if (data[sets].header.cksum_hex ne cal_chksum) then begin
             print,'Set: ' + strtrim(sets,2) + ' checksum NOT matched, ' +   $
                'expected: ' + data[sets].header.cksum_hex +   $
                ', calculated: ' + cal_chksum
             failed_flag = buff_num
             data[sets].failed_flag = failed_flag
          endif else begin
             if (verbose) then    $
                print,'Set: ' + strtrim(sets,2) + ' checksum matched'
          endelse  ; data[sets].header.cksum_hex ne cal_chksum

;  PFP eng after MAG checksum in engineering packet (pfp_engr) 

          if (source eq 'engr') then begin

;             print,'extra bytes after checksum in PFP engr packet ApIds'
   
             buff_num = 22L
             if (track_number_bytes lt buff_num) then begin
                print,'Remaining bytes less than next buffer'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt buff_num
   
             buff = bytarr(buff_num)
             readu,lun,buff
             track_number_bytes = track_number_bytes - buff_num
             if (verbose) then print,'track_number_bytes = ',track_number_bytes
      
;  opt (options)

             decom_2s_complement,buff[0:1],value
             data[sets].pfp_engr.opt = value
             if (verbose) then print,'pfp_engr.opt = ',data[sets].pfp_engr.opt

;  rstlmt (reset if no messages in seconds)

             data[sets].pfp_engr.rstlmt = fix(buff[2])
             if (verbose) then print,'pfp_engr.rstlmt = ',   $
                data[sets].pfp_engr.rstlmt

;  rstsec (reset seconds since last message)

             data[sets].pfp_engr.rstsec = fix(buff[3])
             if (verbose) then print,'pfp_engr.rstsec = ',   $
                data[sets].pfp_engr.rstsec

;  xoff0 (x offset range 0)

             decom_2s_complement,buff[4:5],value
             data[sets].pfp_engr.xoff0 = value
             if (verbose) then print,'pfp_engr.xoff0 = ',   $
                data[sets].pfp_engr.xoff0

;  yoff0 (y offset range 0)

             decom_2s_complement,buff[6:7],value
             data[sets].pfp_engr.yoff0 = value
             if (verbose) then print,'pfp_engr.yoff0 = ',   $
                data[sets].pfp_engr.yoff0

;  zoff0 (z offset range 0)

             decom_2s_complement,buff[8:9],value
             data[sets].pfp_engr.zoff0 = value
             if (verbose) then print,'pfp_engr.zoff0 = ',   $
                data[sets].pfp_engr.zoff0

;  xoff1 (x offset range 1)

             decom_2s_complement,buff[10:11],value
             data[sets].pfp_engr.xoff1 = value
             if (verbose) then print,'pfp_engr.xoff1 = ',   $
                data[sets].pfp_engr.xoff1

;  yoff1 (y offset range 1)

             decom_2s_complement,buff[12:13],value
             data[sets].pfp_engr.yoff1 = value
             if (verbose) then print,'pfp_engr.yoff1 = ',   $
                data[sets].pfp_engr.yoff1

;  zoff1 (z offset range 1)

             decom_2s_complement,buff[14:15],value
             data[sets].pfp_engr.zoff1 = value
             if (verbose) then print,'pfp_engr.zoff1 = ',   $
                data[sets].pfp_engr.zoff1

;  xoff3 (x offset range 3)

             decom_2s_complement,buff[16:17],value
             data[sets].pfp_engr.xoff3 = value
             if (verbose) then print,'pfp_engr.xoff3 = ',   $
                data[sets].pfp_engr.xoff3

;  yoff3 (y offset range 3)

             decom_2s_complement,buff[18:19],value
             data[sets].pfp_engr.yoff3 = value
             if (verbose) then print,'pfp_engr.yoff3 = ',   $
                data[sets].pfp_engr.yoff3

;  zoff3 (z offset range 3)

             decom_2s_complement,buff[20:21],value
             data[sets].pfp_engr.zoff3 = value
             if (verbose) then print,'pfp_engr.zoff3 = ',   $
                data[sets].pfp_engr.zoff3

          endif  ;  source eq 'engr'

;  in CCSDS source, checksum (not being checked)

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
             if (verbose) then print,'track_number_bytes = ',track_number_bytes

             hex = buff
             hex = byte(string(hex,'(z)'))
             hex = strtrim(hex(5:6,*),2)
             temp = where(strlen(hex) ne 2,temp_count)
             if (temp_count gt 0) then hex(temp) = '0' + hex(temp)
   
             data[sets].ccsds.checksum = hex[0] + hex[1]
             if (verbose) then print,'ccsds.checksum = ',   $
                data[sets].ccsds.checksum
          endif ;  source2 eq 'ccsds'
       endif else begin

;  sync pattern not match

          print,'WARNING: set '+ strtrim(sets,2) +   $
             ' sync pattern does not match'
          failed_flag = buff_num
          data[sets].failed_flag = failed_flag
       endelse  ; strupcase(hex_string) eq sync_pattern
    endif  ; failed_flag eq 0

;  continue to next packet after handling any failures

    next_packet:

;  failed flag is set

    if (failed_flag gt 0) then begin

       track_number_bytes = track_number_bytes + buff_num
       after_byte = file_info.size - track_number_bytes 
       if (after_byte le last_pkt_start_byte) then   $
           after_byte = last_pkt_start_byte + 1L
       after_byte = after_byte + pfp_buff_num_max + ccsds_buff_num

       marker_search,lun,sync_pattern,after_byte,pkt_start_byte
print,'after_byte = ',after_byte,'   pkt_start_byte = ',pkt_start_byte

       if (pkt_start_byte ge 0) then begin

;  step back 2 bytes for the message id and currently needed for the PFP header

          if (pfp_buff_num gt 0) then   $
             print,'WARNING: assuming same type of packet as last ' +   $
                'valid packet.'
;                'valid packet - will be fixed when message ids fixed.'
          pkt_start_byte = pkt_start_byte - 2L - pfp_buff_num_max -   $
             ccsds_buff_num

          if (pfp_buff_num_max gt 0) then begin
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
                   i = 5
                endif  ; hex[i] = '8'
             endfor  ; i
             if (i eq 4) then begin
                print,'Not at beginning of packet'
                print,'Not coded for'
                print,'ACTION: stop'
                stop
             endif  ; i eq 4
          endif  ; pfp_buff_num_max gt 0

; print, pkt_start_byte
          print,'Skipping ' +   $
             strtrim((pkt_start_byte - after_byte),2) +  $
             ' bytes [' + strtrim(after_byte,2) + ':' +    $
             strtrim(pkt_start_byte-1L,2) + ']'

          if ((pkt_start_byte - after_byte) le 0) then stop
          last_pkt_start_byte = pkt_start_byte
          track_number_bytes = file_info.size - pkt_start_byte
          if (verbose) then print,'track_number_bytes = ',track_number_bytes

; stop
          if (pkt_start_byte ge 0) then begin
             point_lun,lun,0
             point_lun,lun,pkt_start_byte
             data[sets].failed_flag = 1
;          goto, next
          endif else begin
             free_lun,lun
             print,'Unable to find valid sync pattern to detemine ' +   $
                'start of packet.' 
;          print,'ACTION: stop'
;          stop
             data[sets].failed_flag = 1
             goto,finish
          endelse  ; pkt_start_byte ge 0
       endif else goto, finish   ;  pkt_start_byte ge 0
    endif  ; failed_flag gt 0

;  update markers

    last_pkt_start_byte = pkt_start_byte
    pkt_start_byte = file_info.size - track_number_bytes 

;  confirm that pkt_type and diff values make sense together
; if pkt_type is 2 (averaged) then difference flag should be 0

    if (min(sets) ge 0L) then begin

      if ( (data[sets].header.pkt_type eq 2) and   $
           (data[sets].header.diff ne 0) ) then begin
         failed_flag = buff_num
         data[sets].failed_flag = failed_flag
      endif  ; (data[sets].header.pkt_type eq 2) and   $
             ;    (data[sets].header.diff ne 0)

; if pkt_type is 3 (averaged and differenced) then difference flag should be 1

      if ( (data[sets].header.pkt_type eq 3) and   $
           (data[sets].header.diff ne 1) ) then begin
         failed_flag = buff_num
         data[sets].failed_flag = failed_flag
      endif  ; (data[sets].header.pkt_type eq 3) and   $
             ;    (data[sets].header.diff ne 1)

    endif

 endwhile  ;  not(eof(lun))

 finish:         ;  if reach point where no more data to process

 print,'file_info.size = ',strtrim(file_info.size,2)
 print,'track_number_bytes = ',strtrim(track_number_bytes,2)

 data.total_number_pkts = packet_count
 print,'Number of packets: ' + strtrim(packet_count,2)
 print,'Number of mag packets: ' + strtrim(mag_packet_count,2)

 failed_index = where(data.failed_flag gt 0,failedct)
 print,'Number of failed packets: ' + strtrim(failedct,2)

;  only save actual data

 data = data[0:mag_packet_count-1]

;  close input file

 free_lun,lun

 return
 end  ; maven_mag_pkts_read
