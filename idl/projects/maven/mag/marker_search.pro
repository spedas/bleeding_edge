;***************************************************************************** 
;+
;*NAME:
;
;	marker_search
;
;*PURPOSE:
;
;	Find the first marker in the data file and 
;	return the byte number of the beginning of that marker.
;
;*CALLING SEQUENCE:
;
;	marker_search,lun,sync_pattern,after_byte,found_byte,/debug
;
;*PARAMETERS:
;
;	lun  (required) (input) (integer) (scalar)
;	   Open file unit
;
;       sync_pattern  (required) (input) (scalar) (string - hex)
;	   The pattern to find.  Hex - include leading zeros.
;
;	after_byte (required) (input) (integer) (scalar)
;	   The byte to start the search after.  If not needed, use 0.
;
;	found_byte (required) (output) (scalar) (long word integer)
;	   The byte number in the file where 
;	      - if no after_byte, the occurance of the pattern starts
;	      - if after_byte set, the next occurance of the pattern starts
;	   If marker not found, equals -1
;
;	debug (keyword) (input) (integer) (scalar)
;	   Set to print out debug information
;
;*EXAMPLES:
;
;	marker_search,lun,'fe6b2840',0,found_byte,/debug
;	marker_search,lun,'fe6b2840',found_byte+1L,found_byte
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
;	none
;
;*FILES USED:
;
;	open input file from parameter list
;
;*SIDE EFFECTS:
;
;	Sets input file read pointer to start of file
;
;*RESTRICTIONS:
;
;*NOTES:
;
;	found_byte equals -1 if marker not found
;
;*PROCEDURE:
;
;       - determine size of file
;       - determine length of sync pattern and separate first byte value
;	- If after_byte not equals 0, skip number of bytes.
;	- Until end-of-file or marker is found,
;	  - read a buffer of bytes
;	  - convert the bytes to hex
;	  - check for the start of the marker
;	  - if start of marker is found,
;	    - obtain additional bytes if needed
;           - add leading zeros if necessary
;	    - combine the hex of the neceaary number of bytes
;	    - if equals the marker, return found byte of the marker
;
;*MODIFICATION HISTORY:
;
;	 7 May 2012  PJL  wrote - based on juno_cip_marker_search and
;                         juno_fgm_pkts_search - generalize
;       13 Mar 2013  PJL  before each readu, make sure there are enough bytes
;                         remaining
;        8 Jul 2013  PJL  subtract bytes read from track number
;
;-
;******************************************************************************
 pro marker_search,lun,sync_pattern,after_byte,found_byte,debug=debug

;  check inputs

 if (n_params(0) ne 4) then begin
    print,'marker_search,lun,sync_pattern,after_byte,found_byte,/debug'
    return
 endif  ; n_params(0) ne 4

;  debug flag

  if (keyword_set(debug)) then debug = 1 else debug = 0

;  set pointer to start of file

 point_lun,lun,0

;  determine size of file

 file_info = fstat(lun)
 if (debug) then print,'file_info: ',file_info
 track_number_bytes = file_info.size
 file_number_bytes = file_info.size

;  sync pattern

 sync_length = strlen(sync_pattern)
 sync_bytes = sync_length/2
 if ( sync_bytes ne (sync_length/2.0) ) then begin
    print,'ERROR:  sync pattern is not an even number of bytes'
    print,'ACTION: stop'
    stop
 endif  ; sync_bytes ne (sync_length/2.0)

 if (sync_length gt 2) then   $
    start_sync_pattern = strupcase(strmid(sync_pattern,0,2))   $
 else start_sync_pattern = strupcase(sync_pattern)
 
;  initialize counters

 found_byte = -1L
 reading_buff_length = 36L
;; reading_buff_length = 700L
 reading_buff = bytarr(reading_buff_length)
 byte_count = 0L

;  if need to skip to later in the file (not first packet)

 if (after_byte gt 0L) then begin
    if (track_number_bytes lt after_byte) then begin
       print,'marker_search: not enough bytes remaining'
       print,'ACTION: finish'
       goto, finish
    endif  ; track_number_bytes lt after_byte

    ignore_buff = bytarr(after_byte)
    readu,lun,ignore_buff
    byte_count = byte_count + long(after_byte)
    track_number_bytes = track_number_bytes - after_byte
 endif  ; after_byte gt 0L

;  until eof or find the marker - step through input file

 while ( not(eof(lun)) and (found_byte lt 0) ) do begin

;  read a buffer

    if (track_number_bytes lt reading_buff_length) then begin
       print,'marker_search: not enough bytes remaining'
       print,'ACTION: finish'
       goto, finish
    endif  ; track_number_bytes lt reading_buff_length

    readu,lun,reading_buff
    additional_bytes = 0L
    track_number_bytes = track_number_bytes - reading_buff_length

;  convert to hex

    hex = byte(string(reading_buff,'(z)'))
    hex = strupcase(strtrim(hex(5:6,*),2))

;  search for start of marker

    sync_index = where(strupcase(hex) eq start_sync_pattern,sync_index_ct)

;  if start of marker is found

    if (sync_index_ct ge 1) then begin
       j = 0

;  for each start byte found ...

       while ( (j lt sync_index_ct) and (found_byte lt 0) ) do begin

;  determine if additional bytes are needed

          additional_bytes =   $
             -1 * (reading_buff_length - sync_index[j] - sync_bytes)

;  if there were additional bytes needed, piece together the bytes

          if (additional_bytes gt 0) then begin
             if (track_number_bytes lt additional_bytes) then begin
                print,'marker_search: not enough bytes remaining'
                print,'ACTION: finish'
                goto, finish
             endif  ; track_number_bytes lt additional_bytes

             temp_buff = bytarr(additional_bytes)
             readu,lun,temp_buff
             track_number_bytes = track_number_bytes - additional_bytes
             temp_hex = byte(string(temp_buff,'(z)'))
             temp_hex = strupcase(strtrim(temp_hex(5:6,*),2))
             new_hex = strarr(reading_buff_length + additional_bytes)
             new_hex[0L:reading_buff_length-1L] = hex[0L:reading_buff_length-1L]
             new_hex[reading_buff_length:reading_buff_length+additional_bytes-1L] = temp_hex
             hex = new_hex
;             byte_count = byte_count + additional_bytes
             if (debug) then begin 
                print,'additional_bytes = ',additional_bytes
                print,j, sync_index[j],hex[sync_index[j]:*]
             endif  ; debug
          endif else additional_bytes = 0L

;  create the hex - based on length of marker string

          working_hex = ''
          for k=0L,sync_bytes-1L do begin
	     temphex = hex[sync_index[j]+k]
             while(strlen(temphex) lt 2) do temphex = '0' + temphex
             working_hex = working_hex + temphex
          endfor  ; k
          if (debug) then begin
             print,'working_hex = ', working_hex
             print,'sync_index[' + strtrim(j,2) + '] = ',sync_index[j]
          endif  ; debug

;  compare hex value with marker

          if (working_hex eq strupcase(sync_pattern)) then   $
             found_byte = byte_count + long(sync_index[j])
          if (debug) then begin
             print,'byte_count = ',byte_count
             print,'found_byte = ', found_byte
          endif  ; debug

          j = j + 1

       endwhile  ; (j le sync_index_ct) and (found_byte lt 0)
    endif  ; sync_index_ct ge 1

;  update location in file

    byte_count = byte_count + reading_buff_length + long(additional_bytes)
    if (debug) then print,'bytes count, buff, additional = ',   $
       byte_count,reading_buff_length,additional_bytes

 endwhile  ; not(eof(lun)) and (found_byte lt 0)

 finish:

;  set pointer to start of file

 point_lun,lun,0

 return
 end  ; marker_search
