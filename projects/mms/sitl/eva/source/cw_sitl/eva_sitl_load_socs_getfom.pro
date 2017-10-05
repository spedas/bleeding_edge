;+
; NAME:
;   eva_sitl_load_socs_getfom
;
; PURPOSE:
;   To 'forge' an FOMstr using MMS survey data.
; 
; INPUT:
;   tfom: a 2-element double array indicaing the time period of forging
;
;-

;define IIR4 filter
;------------------
function eva_IIR4, X, F
  result=long(3.*long(F/4) + long(X/4))
  return,result
end

function eva_IIR2, X, F
  result=long(long(F/2) + long(X/2))
  return,result
end

function eva_top12, X
  bitarray=bytarr(32)
  for i=0,31 do begin
    if 2.^(31-i) le X then begin
      bitarray(i)=1
      X=X mod 2.^(31-i)
    endif else bitarray(i)=0
  endfor
  array=bitarray*reverse(findgen(32))
  index=where(array eq max(array))
  if index(0) ge 20 then begin
    a1=bitarray(index(0):*)
    a2=array(index(0):*)
  endif else begin
    a1=bitarray(index(0):index(0)+11)
    a2=array(index(0):index(0)+11)
  endelse
  ;delibrate error
  index=where(a1 ne 0)
  a3=reverse(findgen(n_elements(a1)))
  if index(0) ne -1 then top12num=long(total(2.^(a3(index)))) else top12num=long(0)

  return,top12num
end

function eva_top8, X
  bitarray=bytarr(32)
  for i=0,31 do begin
    if 2.^(31-i) le X then begin
      bitarray(i)=1
      X=X mod 2.^(31-i)
    endif else bitarray(i)=0
  endfor
  clippedarray=bitarray(20:27)
  index=where(clippedarray ne 0)
  a1=reverse(findgen(8))
  if index(0) eq -1 then top8num=0 else top8num=total(2.^(a1(index)))

  return,top8num
end

FUNCTION eva_sitl_load_socs_getfom, tfom,$
  cdq_table = cdq_table, mdq_table = mdq_table, fom_table = fom_table, $
  filename=filename
  
  compile_opt idl2

  if n_elements(filename) eq 0 then filename = 'FOMstr_socs.sav'
  
  ;---------------------
  ; 1. LOAD TABLES
  ;---------------------
  ts = tfom[0]
  te = tfom[1]
  timespan,time_string(ts),te-ts,/SECONDS
  Npts = floor((te-ts)/10.d0)
  Ntdq = 32L
  
  if (n_elements(cdq_table) eq 0) then begin
    weight = fltarr(Ntdq)
    offset = fltarr(Ntdq)
    weight[0] = 1.0
    cdq_table = {weight:weight, offset:offset}
  endif
  
  if (n_elements(mdq_table) eq 0) then begin
    ; window array is multiplied to the four, sorted (in ascending order) data.
    ;win = [0.25,0.25,0.25,0.25]; average of the four spacecraft
    win = [0.10,0.20,0.30,0.40]; enhances the larger CDQ
    ;win = [0.00,0.00,0.00,1.00]; enhances the largest CDQ
    win /= total(win); normalize
    mdq_table = {window:win}
  endif

  if (n_elements(fom_table) eq 0) then begin
    TargetBuffs = 700L; REQUIRED. (Long) The target number of 10s buffers to be selected.
    FOMAve      = 0   ; (FP) The current average FOM off-line.
    TargetRatio = 2   ; (FP) Only used if FOMAve is set. Allows selection as few as TargetBuffs/TargetRatio and as many as TargetBuffs*TargetRatio buffers.
    MinSegmentSize = 12 ; (Long) Default: 12 (Tail), Recommend:  6 (subsolar); Range: 1 to TargetBuffs allowed
    MaxSegmentSize = 60 ; (Long) Default: 60 (Tail), Recommend: 30 (subsolar); Range: 0 to >TargetBuffs allowed
    Pad            = 1  ; (Long) Default:  1 (Tail), Recommend:  0 (subsolar); Will add <Pad> buffers to begining and end of a segment so that the surrounding data can be kept.
    SearchRatio    = 2  ; (FP)   Default:  1 (Or TargetRatio if set); Range: 0.5 - 2.0; The ratio of TargetBuffs in the initial search. SearchBuffs = SearchRatio*TargetBuffs

    ;   FOMWindowSize    - OPTIONAL. (Long) The size, in number of 10 s buffers, of
    ;                      the FOM calculation window.
    ;                      DEFAULT: FOMWindowSize = MinSegemntSize-2*Pad
    ;                      RANGE: 1 to TargetBuffs allowed.
    ;                      NOTE: Making larger will favor large segment sizes.
    FOMWindowSize  = MinSegmentSize-2*Pad

    ;   FOMSlope         - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
    ;                      over a segment, 100 to weigh peaks higher.
    ;                      DEFAULT: 20
    ;                      RANGE: 0-100
    FOMSlope       = 20

    ;   FOMSkew          - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
    ;                      over a segment, 1 to weigh peaks higher.
    ;                      DEFAULT: 0 (Tail; See note)
    ;                      RECOMMEND: 0.5 (SubSolar)
    ;                      RANGE: 0-1
    ;                      NOTE: Set skew to low emphasize FOMBias
    FOMSkew        =  0.5

    ;   FOMBias          - OPTIONAL. (FP) Used in calculating FOM. 0 for favoring
    ;                      small segment, 1 for favoring large segemnts,
    ;                      DEFAULT: 1 (Tail; See note)
    ;                      RECOMMEND: 0.5 (SubSolar)
    ;                      RANGE: 0-1
    ;                      NOTE: FOMBias sets skew depending on segemnt size.
    FOMBias        =  0.5

    fom_table = {TargetBuffs:TargetBuffs, FOMAve:FOMAve, TargetRatio:TargetRatio, $
      MinSegmentSize:MinSegmentSize, MaxSegmentSize:MaxSegmentSize, Pad:Pad, SearchRatio:SearchRatio, $
      FOMWindowSize:FOMWindowSize, FOMSlope:FOMSlope, FOMSkew:FOMSkew, FOMBias:FOMBias}

  endif
  
  ;---------------------
  ; 2. TDN
  ;---------------------
  
  ; PREPARE tdn
  probes = [1,2,3,4]
  pmax = n_elements(probes)
  tdn_t   = 10.d*findgen(Npts) + ts; tdn timestamps
  tdn_p   = fltarr(Npts, Ntdq, pmax); tdn from all probes combined
  tdn_v   = findgen(Ntdq)
  fake    = randomu(seed, Npts); this is used to fake TDN data
  
  ; Brms/|B|
  Mtdq  = 0
  for p=0, pmax-1 do begin; for each probe
    
    strp = 'mms'+strtrim(string(probes[p]),2)
    print,'EVA:------------'
    print,'EVA: TDN for '+strp
    print,'EVA:------------'
    tpv = strp+'_dfg_srvy_gsm_dmpa'
    tn = tnames(tpv,c)
    if c ne 1 then begin; if magnetic field data not yet loaded
      mms_sitl_get_dcb, afg_status, dfg_status, sc_id=strp;, no_update = no_update, reload = reload
      tn2 = tnames(tpv,c2)
      if c2 eq 1 then begin; if successfully downloaded
        eva_cap, tpv
        options, tpv, labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
        options, tpv, 'ytitle', strp+'!CDFG_srvy'
        options, tpv, 'ysubtitle', '[nT]'
        options, tpv, 'colors',[2,4,6]
      endif else begin
        print,'EVA: magnetic field not loaded for socs'
        return, 0
      endelse
    endif
    get_data, tpv, data=D
    if n_tags(D) lt 2 then begin
      print,'EVA: magnetic field not loaded for socs'
      return, 0
    endif else begin
      BX     = D.y[*,0]
      BY     = D.y[*,1]
      BZ     = D.y[*,2]

      ;---------- Bob Ergun's sample program ----------
      dBx    = BX[1:*] - BX[0:*]
      dBy    = BY[1:*] - BY[0:*]
      dBz    = BZ[1:*] - BZ[0:*]
      db2    = dBx*dBx + dBy*dBy + dBz*dBz
      B2     = BX*BX + BY*BY + BZ*BZ
      trigR  = sqrt(dB2/B2)*100.d
      ;---------- THEMIS BZ Trigger ------------------
;      scale_bz=30. ; (can play with different scale factor)
;      q=eva_top12((scale_bz)*BZ[0])  ;set first q value
;      F=q       ;set IIR4 initial value
;      NI=bytarr(n_elements(D.x)) ;initalize trigger value array
;      NI[0]=0       ;set first trigger value
;      for i=1,n_elements(D.x)-1 do begin
;        q=eva_top12((scale_Bz)*BZ[i])
;        F=eva_IIR4(q,F)
;        NI[i]=eva_top8(abs(q-F))
;      endfor
;      trigR = 10.0*NI
      ;------------------------------------------------------
      
      t      = D.x - ts
      Nbuf   = floor(t/10.d); determine which cycle (each cycle is 10s long) to add the value in
      for N=0,Npts-1 do begin; for each 10s cycle....
        temp = trigR[where(Nbuf eq N, count)]; extract 10s of data; if count=0, temp will be the last element of the data array
        csum = total(temp[reverse(sort(temp))],/cumulative); cumulative sum of the data in descending order
        if count ge 8 then begin
          tdn_p[N,Mtdq  ,p] = csum[7]/8.d; take 8 highest peaks and average (ignore if count < 8)
;          tdn_p[N,Mtdq+1,p] = 1*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;          tdn_p[N,Mtdq+2,p] = 2*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;          tdn_p[N,Mtdq+3,p] = fake[N]*1.5*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;          tdn_p[N,Mtdq+4,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;          tdn_p[N,Mtdq+5,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;          tdn_p[N,Mtdq+6,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;          tdn_p[N,Mtdq+7,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
        endif else begin
          if (count gt 0 and count lt 8) then begin
;            tdn_p[N,Mtdq  ,p] = csum[count-1]/count; take all and average
;            tdn_p[N,Mtdq+1,p] = 1*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;            tdn_p[N,Mtdq+2,p] = 2*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;            tdn_p[N,Mtdq+3,p] = fake[N]*1.5*tdn_p[N,Mtdq,p]; fake (to be deleted later)
;            tdn_p[N,Mtdq+4,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;            tdn_p[N,Mtdq+5,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;            tdn_p[N,Mtdq+6,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
;            tdn_p[N,Mtdq+7,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
          endif
        endelse
      endfor; for N=0, Npts-1
    endelse; if n_tags
  endfor; for p=0,pmax-1

  ; Nrms/|N| (To be coded)

  ; Epara (To be coded)

  ; STORE tdn
  for p=0,pmax-1 do begin
    strp = 'mms'+strtrim(string(probes[p]),2)
    store_data, strp+'_socs_tdn',data={x:tdn_t, y:tdn_p[*,*,p], v:tdn_v}
  endfor

  ;---------------------
  ; 3. CDQ
  ;---------------------
  for p=0,pmax-1 do begin
    strp = 'mms'+strtrim(string(probes[p]),2)
    get_data,strp+'_socs_tdn',data=D
    cdq = mms_burst_cdq(D.y, cdq_table.weight, cdq_table.offset)
    store_data,strp+'_socs_cdq',data={x:D.x, y:cdq};, psym_hist:1} (see mplot)
  endfor
  
  ;---------------------
  ; 3. MDQ
  ;---------------------
  t1 = tnames('mms1_socs_cdq',c1)
  t2 = tnames('mms2_socs_cdq',c2)
  t3 = tnames('mms3_socs_cdq',c3)
  t4 = tnames('mms4_socs_cdq',c4)
  if c1 and c2 and c3 and c4 then begin
    get_data,t1, data=D1
    get_data,t2, data=D2
    get_data,t3, data=D3
    get_data,t4, data=D4
    mdq = mms_burst_mdq(D1.y, D2.y, D3.y, D4.y, window=mdq_table.window)
    store_data,'mms_socs_mdq',data={x:D1.x, y:mdq}
  endif else begin
    return, 0
  endelse

  ;---------------------
  ; 4. FOM
  ;---------------------
  tn = tnames('mms_socs_mdq', exist)
  if exist then begin
    print, 'EVA: creating FOM .... '
    get_data, 'mms_socs_mdq',data=D

    ;generate FOMStr
    mms_burst_fom, D.y, TargetBuffs, FOMAve=fom_table.FOMAve, TargetRatio=fom_table.TargetRatio, $
      MinSegmentSize=fom_table.MinSegmentSize, $
      MaxSegmentSize=fom_table.MaxSegmentSize, Pad=fom_table.Pad, $
      SearchRatio=fom_table.SearchRatio, FOMWindowSize=fom_table.FOMWindowSize, $
      FOMSlope=fom_table.FOMSlope, FOMSkew=fom_table.FOMSkew, FOMBias=fom_table.FOMBias, $
      FOMStr=FOMStr
    unix_FOMStr = FOMStr
    nmax = unix_FOMStr.NSEGS
    numcycles=n_elements(D.x)
    sourceid = strarr(nmax)
    sourceid[0:nmax-1] = 'socs (EVA)'
    discussion = strarr(nmax)
    discussion[0:nmax-1] = ' '
    str_element,/add,unix_FOMStr,'NumCycles',numcycles
    str_element,/add,unix_FOMStr,'TimeStamps',D.X; UNIX TIME
    str_element,/add,unix_FOMStr,'CycleStart',D.X[0]
    str_element,/add,unix_FOMStr,'AlgVersion','$Revision:1.5$'
    str_element,/add,unix_FOMStr,'SourceID',sourceid
    str_element,/add,unix_FOMStr,'metadataevaltime',systime(/utc)
    str_element,/add,unix_FOMStr,'discussion',discussion
    mms_convert_fom_unix2tai, unix_FOMStr, FOMStr
    save, FOMStr, filename=filename

    ;------------------------
    ; 'mms_socs_fomstr'
    ;------------------------
    store_data,'mms_socs_fomstr',data=eva_sitl_strct_read(unix_FOMStr,D.x[0])
    options,'mms_socs_fomstr','ytitle','FOM'
    options,'mms_socs_fomstr','ysubtitle','(Simulated ABS)'
    options,'mms_socs_fomstr','unix_FOMStr_org',unix_FOMStr
    return, 1
  endif else begin 
    return, 0
  endelse
END
