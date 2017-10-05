;+
; PROCEEDURE: MMS_BURST_FOM 
;
; PURPOSE: Primarily an input/output for MMS_BURST_FOM_CALC. Selects segemnts
;          of burst data for downlink. 
;
; INPUT:
;   MDQ              - REQUIRED. (FP) An array of MDQ values. Must be  
;                      continuous. Set unknown values to zero! No NaNs!
; 
;   TargetBuffs      - REQUIRED. (Long) The target number of 10s buffers to be
;                      selected. 
;                      EXAMPLE: TargetBuffs = 360 (Tail) 120 (SubSolar)
;
; KEYWORDS:
;
;   FOMAve           - OPTIONAL. (FP) The current average FOM off-line.  
;                      Setting FOMAve will allow program to decide to exceed or
;                      lower the number of selected buffers from TargetBuffs.
;                      DEFAULT: 0
;                      RECOMMEND: Recommend that it is set.
;                      RANGE: >0 to 255 allowed. 0 - Closest to TargetBuffs.
;
;   TargetRatio      - OPTIONAL. (FP) Only used if FOMAve is set. The ratio  
;                      that TargetBuffs can change. Allows selection as
;                      few as TargetBuffs/TargetRatio and as many as  
;                      TargetBuffs*TargetRatio buffers. 
;                      DEFAULT: 2 (If FOMAve is set.)
;                      RANGE: 1 to 100 allowed.
;
;   MinSegmentSize   - OPTIONAL. (Long) The minimum size of a burst segment.  
;                      Number of 10s buffers.
;                      DEFAULT:  12 (Tail)
;                      RECOMMEND: 6 (SubSolar)
;                      RANGE: 1 to TargetBuffs allowed.
;
;   MaxSegmentSize   - OPTIONAL. (Long) The maximum size of a burst segment.  
;                      Number of 10s buffers. If not set, no maximum is used.
;                      DEFAULT:   60 (Tail)
;                      RECOMMEND: 30 (SubSolar)
;                      RANGE: 0 to >TargetBuffs allowed.
;                      NOTE: Can cause larger segments to be broken up.
;                      CAUTION: To avoid strange behavior, set 
;                      MaxSegmentSize > 2*MinSegmentSize
;
;   Pad              - OPTIONAL. (Long) Will add <Pad> buffers to begining 
;                      and end of a segment so that the surrounding data can 
;                      be kept.
;                      DEFAULT:   1 (Tail)
;                      RECOMMEND: 0 (SubSolar)
;                      RANGE: 1 to TargetBuffs/2 allowed.
;              
;   SearchRatio      - OPTIONAL. (FP) The ratio of TargetBuffs in the initial
;                      search. SearchBuffs = SearchRatio*TargetBuffs
;                      DEFAULT: 1 (Or TargetRatio if set)
;                      RANGE: 0.5 to 2.0 allowed.
;                      RECOMMEND: No not set SearchRatio is TargetRatio is set.
;                      NOTE: Making larger will favor large segment sizes.
;
;   FOMWindowSize    - OPTIONAL. (Long) The size, in number of 10 s buffers, of
;                      the FOM calculation window. 
;                      DEFAULT: FOMWindowSize = MinSegemntSize-2*Pad
;                      RANGE: 1 to TargetBuffs allowed.
;                      NOTE: Making larger will favor large segment sizes.
;
;   FOMSlope         - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
;                      over a segment, 100 to weigh peaks higher.
;                      DEFAULT: 20 
;                      RANGE: 0-100
;
;   FOMSkew          - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
;                      over a segment, 1 to weigh peaks higher.
;                      DEFAULT: 0 (Tail; See note)
;                      RECOMMEND: 0.5 (SubSolar)
;                      RANGE: 0-1
;                      NOTE: Set skew to low emphasize FOMBias  
;
;   FOMBias          - OPTIONAL. (FP) Used in calculating FOM. 0 for favoring
;                      small segment, 1 for favoring large segemnts, 
;                      DEFAULT: 1 (Tail; See note)
;                      RECOMMEND: 0.5 (SubSolar)
;                      RANGE: 0-1
;                      NOTE: FOMBias sets skew depending on segemnt size.
;
;
; OUTPUT: A structure, FOM_STR which contains all input and results.
;
; INITIAL VERSION: REE 2010-10-26
; MODIFICATION HISTORY:
; 
; LASP, University of Colorado
;-

pro MMS_BURST_FOM, MDQ, TargetBuffs, FOMAve=FOMAve, TargetRatio=TargetRatio, $
                   MinSegmentSize=MinSegmentSize, $
                   MaxSegmentSize=MaxSegmentSize, Pad=Pad, $
                   SearchRatio=SearchRatio, FOMWindowSize=FOMWindowSize, $
                   FOMSlope=FOMSlope, FOMSkew=FOMSkew, FOMBias=FOMBias, $
                   FOMStr=FOMStr
    

; MAKE OUTPUT STRUCTURE
FOMStr = {Valid:      0L, $
          Error:      ''}

; CHECK REQUIRED INPUTS
if n_elements(MDQ) LT 1 then $
  FOMStr.Error = FOMStr.Error + '(1) Valid MDQ values must be given. '
if n_elements(TargetBuffs) NE 1 then $
  FOMStr.Error = FOMStr.Error + '(2) TargetBuffs must be set. '
if (FOMStr.Error NE '') then return

; FORCE TO PROPER TYPE
MDQ         = float(MDQ)
TargetBuffs = long(TargetBuffs)

; CHECK OPTIONAL INPUTS 
if n_elements(FOMAve)         NE 1 then FOMAve         =  0.0
if n_elements(TargetRatio)    NE 1 then TargetRatio    =  2.0
if FOMAve                     EQ 0 then TargetRatio    =  1.0
if n_elements(MinSegmentSize) NE 1 then MinSegmentSize = 12L
if n_elements(MaxSegmentSize) NE 1 then MaxSegmentSize =  0L
if n_elements(Pad)            NE 1 then Pad            =  1L
if n_elements(SearchRatio)    NE 1 then SearchRatio    =  TargetRatio
if n_elements(FOMWindowSize)  NE 1 then FOMWindowSize  =  MinSegmentSize-2*Pad
if n_elements(FOMSlope)       NE 1 then FOMSlope       = 20.0
if n_elements(FOMSkew)        NE 1 then FOMSkew        =  0.0
if n_elements(FOMBias)        NE 1 then FOMBias        =  1.0

; RESET TARGET RATIO AND SEARCHRATIO


; ENFORCE RANGES
FOMAve         = (float(FOMAve)         > 0.0)  < 255.0
TargetRatio    = (float(TargetRatio)    > 1.0)  < 100.0
MinSegmentSize = (long(MinSegmentSize)  > 1L )  < TargetBuffs
MaxSegmentSize = (long(MaxSegmentSize)  > 0L )
Pad            = (long(Pad )            > 0L )  < (TargetBuffs/2)
SearchRatio    = (float(SearchRatio)    > 0.5)  <   2.0
FOMWindowSize  = (long(FOMWindowSize)   > 1L )  < TargetBuffs
FOMSlope       = (float(FOMSlope)       > 0.0)  < 100.0
FOMSkew        = (float(FOMSkew)        > 0.0)  <   1.0
FOMBias        = (float(FOMBias)        > 0.0)  <   1.0


; EXPAND MDQ TO PREVENT OVERFLOW/UNDERFLOW ERROR
Zeros = fltarr(TargetBuffs)
MDQEx = [Zeros, float(MDQ), Zeros]
Npts  = n_elements(MDQEx)


; FIND PRELIMINARY FOMS (SMALLEST SEGMENTS)
FOMWindow    = mms_burst_fom_window(FOMWindowSize, FOMSlope, FOMSkew, FOMBias)
FOMX         = mms_burst_sort_convol(MDQEx, FOMWindow)


; SELECT THE ELIGIBLE BUFFERS
IndSortR     = reverse(sort(FOMX))      ; DECENDING ORDER
IndBest      = IndSortR(0:SearchRatio*TargetBuffs-1)     
IndBest      = IndBest(sort(IndBest))


; FIND SEGMENTS
IndSegments  = where( (IndBest(1:*) - IndBest(0:*)) GT 1, NSegs)
Start        = [IndBest(0), IndBest(IndSegments + 1)]
Stop         = [IndBest(IndSegments), max(IndBest)]
NSegs        = NSegs + 1
SegLengths   = Stop - Start + 1

; ADD PAD
Start = (Start - Pad) > 0 
Stop  = (Stop  + Pad) < (n_elements(MDQEx) - 1)


; ENFORCE MINIMUM SEGEMNT SIZE - REMOVE OVERLAP
mms_burst_segment, MinSegmentSize, MaxSegmentSize, $
                    Start=Start, Stop=Stop


; REMOVE OUT-OF-RANGE BUFFERS
Ind = where( (Start GE (TargetBuffs+Pad) ) AND $
             (Stop  LT (Npts - TargetBuffs - Pad)), Nind)

; EXIT SYSTEM - NO BUFFERS FOUND
IF Nind EQ 0 then BEGIN  
  FOMStr.Error = FOM.Error + '(3) No valid buffers can be found. '
  return
ENDIF

Start = Start(ind)
Stop  = Stop(ind)
SegLengths   = Stop - Start + 1
NSegs        = n_elements(Start)



; CALCULATE FOM
RealFOM = fltarr(NSegs)
MaxFOM  = fltarr(NSegs)
FOR i=0L, NSegs-1 DO BEGIN
  MaxFOM(i)  = max(FOMX[Start(i):Stop(i)])
  Data       = MDQEx[Start(i):Stop(i)]
  FOMWindow  = mms_burst_fom_window(Seglengths(i), FOMSlope, FOMSkew, FOMBias)
  RealFOM(i) = total(Data(sort(Data))*FOMWindow)
ENDFOR
FOM = (MaxFOM > RealFOM)


; SELECT BUFFERS
TargetMin = TargetBuffs/TargetRatio
TargetMax = TargetBuffs*TargetRatio
IndS   = reverse(sort(FOM))

; FIRST DO CASE WHERE FOMAve IS SET
IF (keyword_set(FOMAve)) THEN BEGIN
  IndKeep = IndS(0)      
  FOR i=1L, Nsegs-1 DO BEGIN
    NBuffs = total(SegLengths(IndS(0:i-1)))
    if (NBuffs GE TargetMin) AND (FOM(IndS(i)) LT FOMAve) then BREAK 
    if (NBuffs GT TargetMax) then BREAK
    IndKeep = [IndKeep, IndS(i)]
  ENDFOR
ENDIF ELSE BEGIN ; CASE FOMAve=0
  NBuffs = lonarr(NSegs)
  for i=0L, NSegs-1 do NBuffs(i) = total(SegLengths(IndS(0:i)))
  dum = min(abs(NBuffs-TargetBuffs), Indmin)   
  IndKeep = IndS(0:Indmin) 
ENDELSE


; REVALUE FROM MDQEx TO MDQ
IndKeep = IndKeep(sort(IndKeep))
Start = ((Start(IndKeep) - TargetBuffs) > 0) < (n_elements(MDQ) - 1)
Stop  = ((Stop(IndKeep)  - TargetBuffs) > 0) < (n_elements(MDQ) - 1)
FOM   = FOM(IndKeep)
SegLengths   = Stop - Start + 1
NSegs        = n_elements(Start)


; MAKE STRUCTURE AND RETURN
FOMStr = {Valid:           1L, $
          Error:           FOMStr.Error, $
          NSegs:           NSegs, $
          Start:           Start, $
          Stop:            Stop, $
          SegLengths:      SegLengths, $
          FOM:             FOM, $
          NBuffs:          long(total(SegLengths)), $
          MDQ:             MDQ, $
          TargetBuffs:     TargetBuffs, $ 
          FOMAve:          FOMAve, $ 
          TargetRatio:     TargetRatio, $ 
          MinSegmentSize:  MinSegmentSize, $ 
          MaxSegmentSize:  MaxSegmentSize, $ 
          Pad:             Pad, $ 
          SearchRatio:     SearchRatio, $ 
          FOMWindowSize:   FOMWindowSize, $ 
          FOMSlope:        FOMSlope, $ 
          FOMSkew:         FOMSkew, $ 
          FOMBias:         FOMBias}
return
end

