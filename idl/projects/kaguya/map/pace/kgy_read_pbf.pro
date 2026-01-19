;+
; PROCEDURE:
;     kgy_read_pbf
; PURPOSE:
;     reads in Kaguya MAP/PACE PBF format files
;     and stores data in a common block (kgy_pace_com)
; CALLING SEQUENCE:
;     kgy_load_pbf, files, trange=trange
; INPUTS:
;     files: full paths to the data files (gziped or decompressed)
;            e.g., [ 'dir/PBF1_C_20080101_ESA1_V001_I.DAT.gz', $
;                    'dir/PBF1_C_20080101_IEA_V001_I.DAT' ]
; KEYWORDS:
;     trange: 2-element array specifying time range (optional, Def. 1day), 
;             e.g., ['yyyy-mm-dd/hh:mm:ss','yyyy-mm-dd/hh:mm:ss']
;             Can be in any format accepted by time_double.
; NOTES:
;     65535 = uint(-1) and 4294967295 = ulong(-1) mean NaN.
; CREATED BY:
;     Yuki Harada on 2014-06-30
;     Modified from 'read_pbf_v2.c' and 'paceql_outputdata_090805.h'
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2026-01-14 19:58:43 -0800 (Wed, 14 Jan 2026) $
; $LastChangedRevision: 34017 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_read_pbf.pro $
;-

pro kgy_read_pbf, files, trange=trange, verbose=verbose

@kgy_pace_com

for i_file=0,n_elements(files)-1 do begin

fname = files[i_file]

;- file info check
finfo = file_info(fname)
if finfo.exists eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'FILE DOES NOT EXIST: '+fname+' --> skipped'
   CONTINUE
endif else if finfo.size lt 1024 then begin
   dprint,dlevel=0,verbose=verbose,'INVALID FILE: '+fname+' --> skipped'
   CONTINUE
endif

if strmatch(fname,'*ESA1*') eq 1 then fsensor = 0
if strmatch(fname,'*ESA2*') eq 1 then fsensor = 1
if strmatch(fname,'*IMA*') eq 1 then fsensor = 2
if strmatch(fname,'*IEA*') eq 1 then fsensor = 3
if strmatch(fname,'*.gz') eq 1 then compress = 1 else compress = 0

if keyword_set(trange) then tr = minmax(time_double(trange)) else begin
   bname = file_basename(fname) ;;; from file_extract_time_from_name.pro
   map = replicate(0b,256)      ;- remove any thing that is not a number or '_'
   keep = byte('01234567890_-')
   map[keep] = keep
   bbn = map[  byte(bname) ]
   w = where(bbn,n)
   segments = strsplit(string(bbn[w]),'_',/extract)
   l = strlen(segments)
   w = where( l eq 8 , nw )
   if nw eq 1 then $
      tr = time_double(segments[w[0]],tf='YYYYMMDD')+[0d,86400d] $
   else begin
      w = where( l eq 6 , nw )
      if nw eq 1 then $
         tr = time_double(segments[w[0]],tf='yyMMDD')+[0d,86400d]
   endelse
endelse
if size(tr,/type) eq 0 then tr = timerange(trange)
trll = long64(time_string(tr,format=6))

;- set sequence number
if n_elements(index_next) eq 1 then index = index_next else index = 0l


;===== set header and data structures =====
;- see 'paceql_outputdata_090805.h' for detail
;=== header ===
s_pace_header = $
   {sensor:ulong(0) ,$           ; /* 0 ESA-S1  1 ESA-S2  2 IMA  3 IEA 4 ALL */
    mode:ulong(0) ,$             ; /* data mode = data mode command in hex  */
    mode2:ulong(0)  ,$           ; /* sub-data mode */
    type:ulong(0) ,$             ; /* data type */
    size:ulong(0) ,$             ; /* data size */
    time_resolution:ulong(0) ,$  ; /* time resolution (msec) */
    sampl_time:ulong(0) ,$       ; /* sampling time (16000/*** msec)*/
    ver:ulong(0) ,$              ; /* data version */
    tbl_ver:ulong(0) ,$          ; /* onboard table version */
    obs_ver:ulong(0) ,$          ; /* onboard software version */
    timeH:ulong(0) ,$            ; /* 1pps TI High Word */  
    timeM:ulong(0) ,$            ; /* 1pps TI Medium Word */        
    timeL:ulong(0) ,$            ; /* 1pps TI Low Word */   
    bc:ulong(0) ,$               ; /* base clock */    
    ic:ulong(0) ,$               ; /* increment counter */     
    sc:ulong(0) ,$               ; /* base counter */  
    sc_step0:ulong(0) ,$         ; /* sc @ energy sweep 0 */
    t_date:ulong(0) ,$           ; /* total date */
    time_ms:ulong(0) ,$          ; /* msec of day @ energy sweep 0 */
    yyyymmdd:ulong(0) ,$         ;
    hhmmss:ulong(0) , $          ; hhmmss @ energy sweep 0
    tof_tbl:ulong(0) ,$          ; /* IMA */
    pd_pha:ulong(0) ,$           ; 
    svg_tbl:ulong(0) ,$          ; SVG (Sweep high Voltage for Geometrical factor control)
    sva_tbl:ulong(0) ,$          ; SVA (Sweep high Voltage for Angular scanning deflector)
    svs_tbl:ulong(0) ,$          ; SVS (Sweep high Voltage for Spherical deflector)
    obs_tbl:ulong(0) ,$          ; 
    obs_ctr:ulong(0) ,$          ;        
    nv_high:ulong(0) ,$          ;        
    nv_low:ulong(0) ,$           ; 
    data_quality:ulong(0) ,$     ; /* data quality */        
    pol_step:ulong(0) ,$         ; /* polar angle step number */
    az_step:ulong(0) ,$          ; /* azimuthal angle step number */
    ene_step:ulong(0) ,$         ; /* energy step number */
    mass_step:ulong(0) ,$        ; /* mass step number */
    pitch_step:ulong(0) ,$       ; /* pitch angle step number */
    tof_step:ulong(0) ,$         ; /* tof step number */
    solwnd_step:ulong(0) ,$      ; /* solar wind  number */
    exb_step:ulong(0) ,$         ; /* ExB  number */
    event_step:ulong(0) ,$       ; /* event counter number */
    trash_step:ulong(0) ,$       ; /* trash counter number */
    tof_disc_start:ulong(0) ,$   ; /* TOF DISCRI SCAN h'73 MODE IMA IEA ONLY */
    tof_disc_stop:ulong(0) ,$   ; /* TOF DISCRI SCAN h'73 MODE IMA IEA ONLY */ 
    hv_scan_level:ulong(0), $   ; /* 1Byte HV SCAN h'72 MODE ONLY */
;    spare:ulonarr(20) $ ; /* total header 256bytes = 64 long */ no need 
    index:ulong(-1) $           ; sequence number included in both
                                ; header and data structure arrays
   }
xread_header = ulonarr(64)      ; for readu


;/*===================== ESA DATA TYPE =====================*/
if fsensor eq 0 or fsensor eq 1 then begin
;/* ------- TYPE 00 ------- */
   s_esa_type00 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,16,64), $ ;- (ene, pol, az)
       trash:uintarr(32,16,2) , index:ulong(-1)}
   xread_00e = ulonarr(16)
   xread_00c = transpose(uintarr(32,16,64))
   xread_00t = transpose(uintarr(32,16,2))
   ; A[3][2] -> A[0][0] A[0][1] A[1][0] A[1][1] A[2][0] A[2][1] in C
   ; A[3,2] -> A[0,0]  A[1,0]  A[2,0]  A[0,1]  A[1,1]  A[2,1] in IDL
;/* ------- TYPE 01 ------- */
   s_esa_type01 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,4,16), $  ;- (ene, pol, az)
       trash:uintarr(32,4,2) , index:ulong(-1)}
   xread_01e = ulonarr(16)
   xread_01c = transpose(uintarr(32,4,16))
   xread_01t = transpose(uintarr(32,4,2))
;/* ------- TYPE 02 ------- */
   s_esa_type02 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,32) , index:ulong(-1)}     ;- (ene, pa)
   xread_02e = ulonarr(16)
   xread_02c = transpose(uintarr(32,32))
;/* ------- TYPE 03 ------- */
   s_esa_type03 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,8,64), $  ;- unused
       trash:uintarr(32,8,2) , index:ulong(-1)}
   xread_03e = ulonarr(16)
   xread_03c = transpose(uintarr(32,8,64))
   xread_03t = transpose(uintarr(32,8,2))
endif
;/*===================== IMA DATA TYPE =====================*/
if fsensor eq 2 then begin
;/* ------- TYPE 40 ------- */
   s_ima_type40 = $
      {event:ulonarr(4,16), $
       cnt:uintarr(4,32,1024) , index:ulong(-1)} ;- (pol, ene, mass)
   xread_40e = transpose(ulonarr(4,16))
   xread_40c = transpose(uintarr(4,32,1024))
;/* ------- TYPE 41 ------- */
   s_ima_type41 = $
      {event:ulonarr(4,16), $
       cnt:uintarr(32,16,64), $ ;- (ene, pol, az)
       trash:uintarr(32,16,2) , index:ulong(-1)}
   xread_41e = transpose(ulonarr(4,16))
   xread_41c = transpose(uintarr(32,16,64))
   xread_41t = transpose(uintarr(32,16,2))
;/* ------- TYPE 42 ------- */
   s_ima_type42 = $
      {event:ulonarr(4,16), $
       cnt:uintarr(32,4,16), $  ;- (ene, pol, az)
       trash:uintarr(32,4,2) , index:ulong(-1)}
   xread_42e = transpose(ulonarr(4,16))
   xread_42c = transpose(uintarr(32,4,16))
   xread_42t = transpose(uintarr(32,4,2))
;/* ------- TYPE 43 ------- */
   s_ima_type43 = $
      {event:ulonarr(4,16), $
       cnt:uintarr(8,32,4,16), $ ;- (mass, ene, pol, az)
       trash:uintarr(8,32,4,2) , index:ulong(-1)}
   xread_43e = transpose(ulonarr(4,16))
   xread_43c = transpose(uintarr(8,32,4,16))
   xread_43t = transpose(uintarr(8,32,4,2))
;/* ------- TYPE 44 ------- */
   s_ima_type44 = $
      {event:ulonarr(4,16), $
       s_cnt:uintarr(16,32,64), $ ;- unused
       cnt:uintarr(16,32,16,64) , index:ulong(-1)}
   xread_44e = transpose(ulonarr(4,16))
   xread_44sc = transpose(uintarr(16,32,64))
   xread_44c = transpose(uintarr(16,32,16,64))
;/* ------- TYPE 45 ------- */
   s_ima_type45 = $
      {event:ulonarr(4,16), $
       cnt:uintarr(16,32,4,16), $ ;- unused
       trash:uintarr(16,32,4,2) , index:ulong(-1)}
   xread_45e = transpose(ulonarr(4,16))
   xread_45c = transpose(uintarr(16,32,4,16))
   xread_45t = transpose(uintarr(16,32,4,2))
endif
;/*===================== IEA DATA TYPE =====================*/
if fsensor eq 3 then begin
;/* ------- TYPE 80 ------- */
   s_iea_type80 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,4,16), $  ;- (ene, pol, az)
       trash:uintarr(32,4,2) , index:ulong(-1)}
   xread_80e = ulonarr(16)
   xread_80c = transpose(uintarr(32,4,16))
   xread_80t = transpose(uintarr(32,4,2))
;/* ------- TYPE 81 ------- */
   s_iea_type81 = $
      {event:ulonarr(16), $
       cnt:uintarr(32,16,64), $ ;- (ene, pol, az)
       trash:uintarr(32,16,2) , index:ulong(-1)}
   xread_81e = ulonarr(16)
   xread_81c = transpose(uintarr(32,16,64))
   xread_81t = transpose(uintarr(32,16,2))
;/* ------- TYPE 82 ------- */
   s_iea_type82 = $
      {event:ulonarr(16), $
       s_cnt:uintarr(32,128), $ ;- 128 bins centered at the SW direction
       cnt:uintarr(32,16,64) , index:ulong(-1)}
   xread_82e = ulonarr(16)
   xread_82sc = transpose(uintarr(32,128))
   xread_82c = transpose(uintarr(32,16,64))
endif
;==========================================


;===== scan data and count up Ndata for each type ======
openr,1,fname,compress=compress ;- open data file

;- read file header description (1024 byte)
c_in_head = bytarr(1024)
readu,1,c_in_head

;- file binary type check (need to add '#ifdef PC ...'???)
if c_in_head[1023] eq 'EE'XB or c_in_head[1023] eq 'DD'XB then begin
   dprint,dlevel=0,verbose=verbose,'scan file: '+fname
endif else begin
   dprint,dlevel=0,verbose=verbose,'FILE_TYPE_ERROR: '+fname+' --> skipped'
   CONTINUE
endelse

N00 = 0l & N01 = 0l & N02 = 0l & N03 = 0l
N40 = 0l & N41 = 0l & N42 = 0l & N43 = 0l & N44 = 0l & N45 = 0l
N80 = 0l & N81 = 0l & N82 = 0l
while not EOF(1) do begin

;- read data header
   readu,1,xread_header
   for i_tag=0,43 do s_pace_header.(i_tag) = xread_header[i_tag]
   now = s_pace_header.yyyymmdd * 1000000ll + s_pace_header.hhmmss

;- data mode
   case s_pace_header.type of
      '00'XB: begin
         readu,1,xread_00e,xread_00c,xread_00t
         if now ge trll[0] and now lt trll[1] then begin
            N00 = N00 + 1
         endif
      end
      '01'XB:begin
         readu,1,xread_01e,xread_01c,xread_01t
         if now ge trll[0] and now lt trll[1] then begin
            N01 = N01 + 1
         endif
      end
      '02'XB:begin
         readu,1,xread_02e,xread_02c
         if now ge trll[0] and now lt trll[1] then begin
            N02 = N02 + 1
         endif
      end
      '03'XB:begin              ;- unused
         readu,1,xread_03e,xread_03c,xread_03t
         if now ge trll[0] and now lt trll[1] then begin
            N03 = N03 + 1
         endif
      end
      '40'XB:begin
         readu,1,xread_40e,xread_40c
         if now ge trll[0] and now lt trll[1] then begin
            N40 = N40 + 1
         endif
      end
      '41'XB:begin
         readu,1,xread_41e,xread_41c,xread_41t
         if now ge trll[0] and now lt trll[1] then begin
            N41 = N41 + 1
         endif
      end
      '42'XB:begin
         readu,1,xread_42e,xread_42c,xread_42t
         if now ge trll[0] and now lt trll[1] then begin
            N42 = N42 + 1
         endif
      end
      '43'XB:begin
         readu,1,xread_43e,xread_43c,xread_43t
         if now ge trll[0] and now lt trll[1] then begin
            N43 = N43 + 1
         endif
      end
      '44'XB:begin              ;- unused
         readu,1,xread_44e,xread_44c,xread_44t
         if now ge trll[0] and now lt trll[1] then begin
            N44 = N44 + 1
         endif
      end
      '45'XB:begin              ;- unused
         readu,1,xread_45e,xread_45c,xread_45t
         if now ge trll[0] and now lt trll[1] then begin
            N45 = N45 + 1
         endif
      end
      '80'XB:begin
         readu,1,xread_80e,xread_80c,xread_80t
         if now ge trll[0] and now lt trll[1] then begin
            N80 = N80 + 1
         endif
      end
      '81'XB:begin
         readu,1,xread_81e,xread_81c,xread_81t
         if now ge trll[0] and now lt trll[1] then begin
            N81 = N81 + 1
         endif
      end
      '82'XB:begin
         readu,1,xread_82e,xread_82sc,xread_82c
         if now ge trll[0] and now lt trll[1] then begin
            N82 = N82 + 1
         endif
      end
   endcase
endwhile
close,1                         ;- close file
free_lun,1
if fsensor eq 0 or fsensor eq 1 then $
   dprint,dlevel=1,verbose=verbose,'# type00, 01, 02, 03: ',N00,N01,N02,N03
if fsensor eq 2 then $
   dprint,dlevel=1,verbose=verbose,'# type40, 41, 42, 43, 44, 45: ',N40,N41,N42,N43,N44,N45
if fsensor eq 3 then $
   dprint,dlevel=1,verbose=verbose,'# type80, 81, 82: ',N80,N81,N82

Nsum = N00+N01+N02+N03+N40+N41+N42+N43+N44+N45+N80+N81+N82
if Nsum eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'No data points in that time range: '+fname+' --> skipped'
   CONTINUE
endif
;==========================================


;===== set up temporary str arrays ========
s_pace_header_arr = replicate(s_pace_header,Nsum)

if fsensor eq 0 or fsensor eq 1 then begin
   if N00 gt 0 then $
      s_esa_type00_arr = replicate(s_esa_type00,N00)
   if N01 gt 0 then $
      s_esa_type01_arr = replicate(s_esa_type01,N01)
   if N02 gt 0 then $
      s_esa_type02_arr = replicate(s_esa_type02,N02)
   if N03 gt 0 then $
      s_esa_type03_arr = replicate(s_esa_type03,N03)
endif
if fsensor eq 2 then begin
   if N40 gt 0 then $
      s_ima_type40_arr = replicate(s_ima_type40,N40)
   if N41 gt 0 then $
      s_ima_type41_arr = replicate(s_ima_type41,N41)
   if N42 gt 0 then $
      s_ima_type42_arr = replicate(s_ima_type42,N42)
   if N43 gt 0 then $
      s_ima_type43_arr = replicate(s_ima_type43,N43)
   if N44 gt 0 then $
      s_ima_type44_arr = replicate(s_ima_type44,N44)
   if N45 gt 0 then $
      s_ima_type45_arr = replicate(s_ima_type45,N45)
endif
if fsensor eq 3 then begin
   if N80 gt 0 then $
      s_iea_type80_arr = replicate(s_iea_type80,N80)
   if N81 gt 0 then $
      s_iea_type81_arr = replicate(s_iea_type81,N81)
   if N82 gt 0 then $
      s_iea_type82_arr = replicate(s_iea_type82,N82)
endif
;==========================================


;===== read data ==========================
openr,1,fname,compress=compress ;- open data file

;- read file header description (1024 byte)
c_in_head = bytarr(1024)
readu,1,c_in_head

i_data = 0l
i_00 = 0l & i_01 = 0l & i_02 = 0l & i_03 = 0l
i_40 = 0l & i_41 = 0l & i_42 = 0l & i_43 = 0l & i_44 = 0l & i_45 = 0l
i_80 = 0l & i_81 = 0l & i_82 = 0l
while not EOF(1) do begin

;- read data header
   readu,1,xread_header
   for i_tag=0,43 do s_pace_header.(i_tag) = xread_header[i_tag]
   now = s_pace_header.yyyymmdd * 1000000ll + s_pace_header.hhmmss
   if now ge trll[0] and now lt trll[1] then begin
      s_pace_header_arr[i_data] = s_pace_header
      s_pace_header_arr[i_data].index = index
      if index mod 1000 eq 1 then dprint,dlevel=1,verbose=verbose,'sensor:',fsensor,', index:',index,now
   endif

;- data mode
   case s_pace_header.type of
      '00'XB: begin
         readu,1,xread_00e,xread_00c,xread_00t
         if now ge trll[0] and now lt trll[1] then begin
            s_esa_type00_arr[i_00].event = xread_00e
            s_esa_type00_arr[i_00].cnt = transpose(xread_00c)
            s_esa_type00_arr[i_00].trash = transpose(xread_00t)
            s_esa_type00_arr[i_00].index = index
            index = index + 1
            i_00 = i_00 + 1
            i_data = i_data + 1
         endif
      end
      '01'XB:begin
         readu,1,xread_01e,xread_01c,xread_01t
         if now ge trll[0] and now lt trll[1] then begin
            s_esa_type01_arr[i_01].event = xread_01e
            s_esa_type01_arr[i_01].cnt = transpose(xread_01c)
            s_esa_type01_arr[i_01].trash = transpose(xread_01t)
            s_esa_type01_arr[i_01].index = index
            index = index + 1
            i_01 = i_01 + 1
            i_data = i_data + 1
         endif
      end
      '02'XB:begin
         readu,1,xread_02e,xread_02c
         if now ge trll[0] and now lt trll[1] then begin
            s_esa_type02_arr[i_02].event = xread_02e
            s_esa_type02_arr[i_02].cnt = transpose(xread_02c)
            s_esa_type02_arr[i_02].index = index
            index = index + 1
            i_02 = i_02 + 1
            i_data = i_data + 1
         endif
      end
      '03'XB:begin              ;- unused
         readu,1,xread_03e,xread_03c,xread_03t
         if now ge trll[0] and now lt trll[1] then begin
            index = index + 1
            i_03 = i_03 + 1
            i_data = i_data + 1
         endif
      end
      '40'XB:begin
         readu,1,xread_40e,xread_40c
         if now ge trll[0] and now lt trll[1] then begin
            s_ima_type40_arr[i_40].event = transpose(xread_40e)
            s_ima_type40_arr[i_40].cnt = transpose(xread_40c)
            s_ima_type40_arr[i_40].index = index
            index = index + 1
            i_40 = i_40 + 1
            i_data = i_data + 1
         endif
      end
      '41'XB:begin
         readu,1,xread_41e,xread_41c,xread_41t
         if now ge trll[0] and now lt trll[1] then begin
            s_ima_type41_arr[i_41].event = transpose(xread_41e)
            s_ima_type41_arr[i_41].cnt = transpose(xread_41c)
            s_ima_type41_arr[i_41].trash = transpose(xread_41t)
            s_ima_type41_arr[i_41].index = index
            index = index + 1
            i_41 = i_41 + 1
            i_data = i_data + 1
         endif
      end
      '42'XB:begin
         readu,1,xread_42e,xread_42c,xread_42t
         if now ge trll[0] and now lt trll[1] then begin
            s_ima_type42_arr[i_42].event = transpose(xread_42e)
            s_ima_type42_arr[i_42].cnt = transpose(xread_42c)
            s_ima_type42_arr[i_42].trash = transpose(xread_42t)
            s_ima_type42_arr[i_42].index = index
            index = index + 1
            i_42 = i_42 + 1
            i_data = i_data + 1
         endif
      end
      '43'XB:begin
         readu,1,xread_43e,xread_43c,xread_43t
         if now ge trll[0] and now lt trll[1] then begin
            s_ima_type43_arr[i_43].event = transpose(xread_43e)
            s_ima_type43_arr[i_43].cnt = transpose(xread_43c)
            s_ima_type43_arr[i_43].trash = transpose(xread_43t)
            s_ima_type43_arr[i_43].index = index
            index = index + 1
            i_43 = i_43 + 1
            i_data = i_data + 1
         endif
      end
      '44'XB:begin              ;- unused
         readu,1,xread_44e,xread_44c,xread_44t
         if now ge trll[0] and now lt trll[1] then begin
            index = index + 1
            i_44 = i_44 + 1
            i_data = i_data + 1
         endif
      end
      '45'XB:begin              ;- unused
         readu,1,xread_45e,xread_45c,xread_45t
         if now ge trll[0] and now lt trll[1] then begin
            index = index + 1
            i_45 = i_45 + 1
            i_data = i_data + 1
         endif
      end
      '80'XB:begin
         readu,1,xread_80e,xread_80c,xread_80t
         if now ge trll[0] and now lt trll[1] then begin
            s_iea_type80_arr[i_80].event = xread_80e
            s_iea_type80_arr[i_80].cnt = transpose(xread_80c)
            s_iea_type80_arr[i_80].trash = transpose(xread_80t)
            s_iea_type80_arr[i_80].index = index
            index = index + 1
            i_80 = i_80 + 1
            i_data = i_data + 1
         endif
      end
      '81'XB:begin
         readu,1,xread_81e,xread_81c,xread_81t
         if now ge trll[0] and now lt trll[1] then begin
            s_iea_type81_arr[i_81].event = xread_81e
            s_iea_type81_arr[i_81].cnt = transpose(xread_81c)
            s_iea_type81_arr[i_81].trash = transpose(xread_81t)
            s_iea_type81_arr[i_81].index = index
            index = index + 1
            i_81 = i_81 + 1
            i_data = i_data + 1
         endif
      end
      '82'XB:begin
         readu,1,xread_82e,xread_82sc,xread_82c
         if now ge trll[0] and now lt trll[1] then begin
            s_iea_type82_arr[i_82].event = xread_82e
            s_iea_type82_arr[i_82].s_cnt = transpose(xread_82sc)
            s_iea_type82_arr[i_82].cnt = transpose(xread_82c)
            s_iea_type82_arr[i_82].index = index
            index = index + 1
            i_82 = i_82 + 1
            i_data = i_data + 1
         endif
      end
   endcase
endwhile
close,1                         ;- close file
free_lun,1
;==========================================


;===== store data in common blocks ========
if fsensor eq 0 then begin
   if size(esa1_header_arr,/tname) ne 'STRUCT' then $
      esa1_header_arr = s_pace_header_arr $
   else esa1_header_arr = [ esa1_header_arr, s_pace_header_arr ]
   if N00 gt 0 then begin
      if size(esa1_type00_arr,/tname) ne 'STRUCT' then $
         esa1_type00_arr = s_esa_type00_arr $
      else esa1_type00_arr = [ esa1_type00_arr, s_esa_type00_arr ]
   endif
   if N01 gt 0 then begin
      if size(esa1_type01_arr,/tname) ne 'STRUCT' then $
         esa1_type01_arr = s_esa_type01_arr $
      else esa1_type01_arr = [ esa1_type01_arr, s_esa_type01_arr ]
   endif
   if N02 gt 0 then begin
      if size(esa1_type02_arr,/tname) ne 'STRUCT' then $
         esa1_type02_arr = s_esa_type02_arr $
      else esa1_type02_arr = [ esa1_type02_arr, s_esa_type02_arr ]
   endif
endif
if fsensor eq 1 then begin
   if size(esa2_header_arr,/tname) ne 'STRUCT' then $
      esa2_header_arr = s_pace_header_arr $
   else esa2_header_arr = [ esa2_header_arr, s_pace_header_arr ]
   if N00 gt 0 then begin
      if size(esa2_type00_arr,/tname) ne 'STRUCT' then $
         esa2_type00_arr = s_esa_type00_arr $
      else esa2_type00_arr = [ esa2_type00_arr, s_esa_type00_arr ]
   endif
   if N01 gt 0 then begin
      if size(esa2_type01_arr,/tname) ne 'STRUCT' then $
         esa2_type01_arr = s_esa_type01_arr $
      else esa2_type01_arr = [ esa2_type01_arr, s_esa_type01_arr ]
   endif
   if N02 gt 0 then begin
      if size(esa2_type02_arr,/tname) ne 'STRUCT' then $
         esa2_type02_arr = s_esa_type02_arr $
      else esa2_type02_arr = [ esa2_type02_arr, s_esa_type02_arr ]
   endif
endif
if fsensor eq 2 then begin
   if size(ima_header_arr,/tname) ne 'STRUCT' then $
      ima_header_arr = s_pace_header_arr $
   else ima_header_arr = [ ima_header_arr, s_pace_header_arr ]
   if N40 gt 0 then begin
      if size(ima_type40_arr,/tname) ne 'STRUCT' then $
         ima_type40_arr = s_ima_type40_arr $
      else ima_type40_arr = [ ima_type40_arr, s_ima_type40_arr ]
   endif
   if N41 gt 0 then begin
      if size(ima_type41_arr,/tname) ne 'STRUCT' then $
         ima_type41_arr = s_ima_type41_arr $
      else ima_type41_arr = [ ima_type41_arr, s_ima_type41_arr ]
   endif
   if N42 gt 0 then begin
      if size(ima_type42_arr,/tname) ne 'STRUCT' then $
         ima_type42_arr = s_ima_type42_arr $
      else ima_type42_arr = [ ima_type42_arr, s_ima_type42_arr ]
   endif
   if N43 gt 0 then begin
      if size(ima_type43_arr,/tname) ne 'STRUCT' then $
         ima_type43_arr = s_ima_type43_arr $
      else ima_type43_arr = [ ima_type43_arr, s_ima_type43_arr ]
   endif
endif

if fsensor eq 3 then begin
   if size(iea_header_arr,/tname) ne 'STRUCT' then $
      iea_header_arr = s_pace_header_arr $
   else iea_header_arr = [ iea_header_arr, s_pace_header_arr ]
   if N80 gt 0 then begin
      if size(iea_type80_arr,/tname) ne 'STRUCT' then $
         iea_type80_arr = s_iea_type80_arr $
      else iea_type80_arr = [ iea_type80_arr, s_iea_type80_arr ]
   endif
   if N81 gt 0 then begin
      if size(iea_type81_arr,/tname) ne 'STRUCT' then $
         iea_type81_arr = s_iea_type81_arr $
      else iea_type81_arr = [ iea_type81_arr, s_iea_type81_arr ]
   endif
   if N82 gt 0 then begin
      if size(iea_type82_arr,/tname) ne 'STRUCT' then $
         iea_type82_arr = s_iea_type82_arr $
      else iea_type82_arr = [ iea_type82_arr, s_iea_type82_arr ]
   endif
endif

index_next = index            ;- store next index in kgy_pace_com
;==========================================

endfor ;- i_file loop

end

