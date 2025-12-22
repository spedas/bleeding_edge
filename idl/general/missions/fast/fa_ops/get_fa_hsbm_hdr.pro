;
;GET_FA_HSBM_HDR
;
;Procedure to extract  FAST High-Speed-Burst-Memory header
;information, including the end time of HSBM data buffers.
;The program requires no inputs. When run in conjunction with SDT it
;returns the following data:
;
;BUFFER_TIMES: an array of double precision numbers representing times
;              in UT of the ENDS of the HSBM buffers in seconds from 1970.
;
;HSBM_HDR: a structure containing various HSBM operating
;          parameters.
;
;CHATTY: set this keyword to generated some informative ASCII text at
;        the IDL command line while the program is running.
;


pro get_fa_hsbm_hdr, burst_times, $
                     hsbm_hdr, $
                     CHATTY = chatty


sat_code = 2001
hdr = get_ts_from_sdt('HSBM_Hdr',sat_code,/all)

hdr_dat = strcompress(string(hdr.comp1(6:35,*)),/remove_all)
sdt_t_packs = where(string(hdr.comp3(0:9,*)) EQ 'TIMEPACKET')
hdr_dat=byte(hdr_dat)
    ;Turn SDT header data into strings of raw 14-byte HSBM headers.
    ;This data is ascii text showing the HEX values of the HSBM data headers.

trans_hex_1 = where(hdr_dat GE 48 AND hdr_dat LE 57)
trans_hex_2 = where(hdr_dat GE 97 AND hdr_dat LE 102)
hdr_dat(trans_hex_1) = hdr_dat(trans_hex_1) - 48
hdr_dat(trans_hex_2) = hdr_dat(trans_hex_2) - 87
    ;Translate byte formatted hexidecimal characters to decimal numbers 0-16

time_packet = ishft((hdr_dat(16,*) and 4),-2)
t_packs = where(time_packet GT 0)
if keyword_set(chatty) then begin
    if n_elements(t_packs) NE n_elements(sdt_t_packs) then begin
        print,'number of SDT time packets and number of type 1'
        print,'header bits do not agree.'
    endif else begin
        t_diffs = where(t_packs NE sdt_t_packs)
        if t_diffs EQ -1 then $
          print,'SDT and type 1 header times agree' else $
          print,'Discrepancy between SDT times and type 1'
        print,'header times'
    endelse
endif
if n_elements(t_packs) LT n_elements(sdt_t_packs) then $
  t_packs = sdt_t_packs
    ;If SDT times and raw type 1 header times disagree, go with
    ;SDT
num_t_packs = strcompress(string(N_elements(t_packs)),/remove_all)
    ;Find out where time packets are using bit 70 of HSBM
    ;Primary HSBM data header. If bit 70 = 1 then it's a time packet.

burst_strings = strcompress(string(hdr.comp1(40:52,t_packs)),/remove_all)
burst_times_secs = timesec(burst_strings)
burst_date =secdate(hdr.time(t_packs(0)))+'/00:00:00.000'
burst_date_sec = time_double(burst_date)
burst_date = secdate(burst_date_sec)
burst_times_str=burst_date+'/'+burst_strings
burst_times = time_double(burst_times_str)

;Determine HSBM configuration from header data. Use median function to
;weed out modes left over from previous orbits and bad packets.

mode_dat=intarr(n_elements(hdr_dat(*,0)))
for i=0,n_elements(hdr_dat(*,0))-1 do $
  mode_dat(i) = fix(median(hdr_dat(i,*)))
sample_speed = 250000.0*2^(mode_dat(1) AND 3)
memsize=fix((ishft(mode_dat(3),-3) AND 1) + 2*(mode_dat(2) AND 1) + $
            4*(ishft(mode_dat(2),-1) AND 1))
buffer_points = (2^(fix(memsize)))*4096.0
acquire = ishft((mode_dat(1) AND 4),-2)
if (mode_dat(1) and 8) EQ 8 then port = 'DSP' else port = 'IDPU'
timebase = (mode_dat(0) AND 1)
output_en = ishft((hdr_dat(0,1) AND 2),-1)
mux = ishft((mode_dat(0) AND 12),-2)
fields_mode = mode_dat(19)+16*mode_dat(18)
channels = strarr(4)
LF_Channels = ['V1-V2','V1-V4','V7-V8','V5-V8','V5-V6','Mag3ac', $
               'V3-V4','V9-V10']
for i =0,3 do begin
    case (ishft(mode_dat(13),-i) AND 1) of
        0:channels(i) = LF_Channels(2*i)
        1:channels(i) = LF_Channels(2*i+1)
    endcase
endfor

if keyword_set(chatty) then begin
    if num_t_packs EQ 1 then print,'There is ',num_t_packs, $
      ' HSBM event during this orbit.' else print,'There are ', $
      num_t_packs,' HSBM events during this orbit.'
    print,'HSBM Header Data'
    print,mode_dat
    print,'Channels Used for HSBM1-4:'
    print,channels
    print,' '
    print,format='("sample speed = ",F10.1," samples/sec")',sample_speed
    print,format='("Memory size = ",I1)',memsize
    print,format='("Each Buffer is ",I7," points long")',buffer_points
endif    
    
hsbm_hdr = {times:dblarr(n_elements(burst_times)), $
       channels:strarr(4),npts:0L,speed:0.0,mode:0}
hsbm_hdr.times = burst_times
hsbm_hdr.channels = channels
hsbm_hdr.npts = long(buffer_points)
hsbm_hdr.speed = float(sample_speed)
hsbm_hdr.mode = fix(fields_mode)

end
