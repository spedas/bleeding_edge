;+
; PROCEEDURE: MMS_BURST_SEGMENT, MINSEGMENTSIZE, MAXSEGMENTSIZE, 
;                                START=START, STOP=STOP
;
; PURPOSE: A UTILITY to enforce a minimum/maxim segemnt size. No input/error
;          checking is in the routine. MAKE SURE INPUTS ARE VALID!
; 
; INPUT:
;
;   MinSegmentSize   - REQUIRED. (Long) The minimum size of a burst segment.  
;                      Number of 10s buffers. 
;                      NOTE: Input MinSegmentSize-2*Pad if Pad is set.
;
;   MaxSegmentSize   - REQUIRED. (Long) The maximum size of a burst segment.  
;                      Number of 10s buffers. If not set, no maximum is used.
;                      NOTE: Can cause larger segments to be broken up.
;                      CAUTION: To avoid strange behavior, set 
;                      MaxSegmentSize > 2*MinSegmentSize
;
; KEYWORDS:
;
;   Start            - REQUIRED. (FP) The starting index of a burst segment.  
;
;   Stop             - REQUIRED. (FP) The ending index of a burst segment.  
;
;
; OUTPUT: Start and Stop are altered.
;
; INITIAL VERSION: REE 2010-10-26
; MODIFICATION HISTORY:
; LASP, University of Colorado
;
;-

pro mms_burst_segment, MinSegmentSize, MaxSegmentSize, Start=Start, Stop=Stop

; CALCULATE SEGMENT LENGTHS
SegLengths  = Stop - Start + 1
NSegs       = n_elements(Start)



; ENFORCE MINIMUM SIZE
IndSmall     = where(SegLengths LT MinSegmentSize, NSmall)
FOR i = 0, NSmall-1 DO BEGIN
  Start(IndSmall(i)) = Start(IndSmall(i)) - $
    floor((MinSegmentSize - float(SegLengths(IndSmall(i))))/2)
  Stop(IndSmall(i)) = Stop(IndSmall(i)) + $
    ceil((MinSegmentSize - float(SegLengths(IndSmall(i))))/2)
ENDFOR
SegLengths  = Stop - Start + 1
NSegs       = n_elements(Start)



; MERGE OVERLAPPING SEGMENTS
IndOverlap  = where( (Start(1:*) - Stop(0:*)) LE 0, N_OverLap)
IF (N_OverLap GT 0) THEN BEGIN
  Start(IndOverlap + 1) = -1
  Stop(IndOverlap) = -1
  Ind = where(Start GE 0)
  Start = Start(Ind) 
  Ind = where(Stop GE 0)
  Stop = Stop(Ind) 
ENDIF
SegLengths  = Stop - Start + 1
NSegs       = n_elements(Start)



; MERGE CONTACTING SEGMENTS IF MAXSEGMENTSIZE IS NOT EXCEEDED.
IndContact  = where( (Start(1:*) - Stop(0:*)) EQ 1, NContact) 
IF (NContact GT 0) THEN BEGIN
  FOR i=0L, Ncontact-1 DO BEGIN
    IF (SegLengths(i) + SegLengths(i+1)) LE MaxSegmentSize THEN BEGIN
      Start(IndContact(i) + 1) = -1
      Stop(IndContact(i)) = -1
    ENDIF  
  ENDFOR 
  Ind = where(Start GE 0)
  Start = Start(Ind) 
  Ind = where(Stop GE 0)
  Stop = Stop(Ind) 
ENDIF
SegLengths  = Stop - Start + 1
NSegs       = n_elements(Start)



; BREAKUP LARGE SEGMENTS (EXCEED MAXSEGMENTSIZE)
IndLarge    = where(Seglengths GT MaxSegmentSize, NLarge) 
IF (NLarge GT 0) AND (MaxSegmentSize GT 0) THEN BEGIN
  FOR i=0L, Nlarge-1 DO BEGIN
    MinBreakUp = Seglengths(IndLarge(i)) / MaxSegmentSize + 1
    MaxBreakUp = Seglengths(IndLarge(i)) / MinSegmentSize
    NewSegSize = Seglengths(IndLarge(i)) / (MinBreakup < MaxBreakup)
    NewSegSize = (NewSegSize > MinSegmentSize) < MaxSegmentSize
    N_NewSegs  = (MinBreakup < MaxBreakup)
    Remainder  = Seglengths(IndLarge(i)) - N_NewSegs*NewSegSize
        
    ; ADD NEW SEGMENTS
    Start(IndLarge(i)) = Start(IndLarge(i)) + ceil(Remainder/2)
    Stop(IndLarge(i))  = Stop(IndLarge(i))  - floor(Remainder/2)
    FOR j=1L, N_NewSegs-1 DO BEGIN
      Ind   = Start(IndLarge(i)) + j*NewSegSize 
      Start = [Start, Ind]
      Ind   = (Start(IndLarge(i)) + (j+1)*NewSegSize)-1 < Stop(IndLarge(i))       
      Stop  = [Stop, Ind]
    ENDFOR
    Stop(IndLarge(i)) = Start(IndLarge(i)) + NewSegSize - 1
  ENDFOR   
ENDIF

; RESORT START AND STOP
Start = Start(sort(Start))
Stop  = Stop(sort(Stop))


END

