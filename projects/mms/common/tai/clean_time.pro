;+
;NAME:        
;             clean_time
;CALL:        clean_time,datanames [,SORT=SORT]
;PURPOSE:     
;             Check and fix the time arrays of the input variables.
;             If the time array cannot be fixed, remove the corresponding
;             time and data values.
;WARNING:     This program is not an artificial intelligence.  It will not
;             work on all problems.  Particularly if there are lots of errors
;             piled up together or seperated by only a few time intervals.
;             It should be able to handle up to 40 consecuous time errors if
;             there is a bit of clean time (~40 points) before the next errors.
;INPUTS:      Array of strings.  Each string should be associated with a data
;             quantity.  (see the store_data and get_data routines)
;             alternately, datanames could be one data structure.
;             eg:  get_data,'Ve_3dp',dat=dat & clean_time,dat
;OPTIONAL INPUTS: seed:  an input to the filter routine. Default is 5.
;             seed is a filtering width factor.  If the default fails, choose
;             another seed that is not a multiple of 5.  Seed will affect
;             run time.
;KEYWORDS: 
;             SORT: this is a kludge. assume all the time data is good.
;                   this will sort the data monotonically.
;             PLOT: plot the new time array to see if it is acceptable.
;                   this is mostly a debugging tool
;             LOUD:  Print lots of messages as the program chugs along.
;OUTPUTS:     Prints a strange report:  eg:  no errors found, data
;             cleaned, xx% data loss, data unrecoverable, too many errors.
;SIDE EFFECTS:If sucessful in finding errors, will alter the data array
;             and time array.  
;LAST MODIFICATION:     @(#)clean_time.pro	1.5 95/12/04
;AUTHOR: Frank V. Marcoline
;-

FUNCTION nglitches,array        ;find places where array is not monotonic
  l = n_elements(array)
  delta = where( (array(1:l-1l)-array(0:l-2l)) LT 0, count )
  return,count
END 

FUNCTION rm_ele,arr,ele         ;remove element ele from array arr
  n = n_elements(arr)
  IF ((ele GE n) OR (ele LT 0)) THEN BEGIN
    print,'Element ',strcompress(ele),$
      ' out of range: 0 < # < ',strcompress(n-1)
    return,-1
  ENDIF 
  IF      ele EQ 0   THEN arr = arr(1:n-1) $
  ELSE IF ele EQ n-1 THEN arr = arr(0:n-2) $
  ELSE arr = [arr(0:ele-1),arr(ele+1:n-1)]
  return,arr
END 
  
PRO clean_time,datanames,seed,PLOT=PLOT,LOUD=LOUD,SORT=SORT
on_error,0
  IF n_params() NE 2 THEN seed = 5 ELSE seed =  long(seed)

  type = data_type(datanames)
  CASE type OF
    8: nparams = 1
    7: nparams = (reverse(size(datanames)))(0)
    0: BEGIN
      print,'No defined parameters entered'
      return
    ENDCASE 
    ELSE: nparams = 1
  ENDCASE 

  IF NOT keyword_set(PLOT) THEN PLOT = 0
  IF NOT keyword_set(LOUD) THEN LOUD = 0
  IF NOT keyword_set(SORT) THEN SORT = 0

  FOR i=0l,nparams-1l DO BEGIN
    CASE type OF
      8: time = datanames.x
      7: begin
        print,'Dataname: ',datanames(i)
        get_data,datanames(i),dat=data,index=index
        IF index EQ 0 THEN BEGIN 
          print,'Unsuccessful attempt to get_data: ',datanames(i)
          return
        ENDIF ELSE time = data.x
      ENDCASE
      ELSE: time = datanames
    ENDCASE 

    IF PLOT THEN plot,time MOD time(0),title='Time arary.' 

    length = n_elements(time) 
    ;;the median is more likely to be representive of the average time step
    ;;than the average is, because time spikes are often large shifts
    IF length GT 1 THEN delta_t = median(-ts_diff(time,1)) $
    ELSE BEGIN
      print,'Time array contains only one data point'
      return
    ENDELSE 

    IF LOUD THEN print,'Median time step:',delta_t
    
    IF NOT SORT THEN BEGIN 
      ;;simplest test, is the time array monotonic and increasing?
      glitches = nglitches(time)
      IF glitches EQ 0 THEN BEGIN 
        IF LOUD THEN print,'Time array monotonically increasing.'
      ENDIF ELSE BEGIN 
        IF LOUD THEN print,'Time array not monotonically increasing'
        print,'Number of faults in time array: ',glitches
        
        dt = -ts_diff(time,1)
        dt = dt(0:length-2)
        spike = where((dt GT 5*delta_t) OR (dt LT -5*delta_t),spikes)+1
        IF LOUD THEN print,'Spikes and gaps: ',strcompress(spikes)
        IF LOUD THEN print,spike
        IF spikes GT 1 THEN gaps = lonarr(spikes) ELSE gaps = 0
        FOR j=0l,spikes-2 DO BEGIN
          IF time(spike(j)) GT time(spike(j)-1) THEN BEGIN
            ;;test1:see if a time jump has no dips within the next 40 points
            test1 = where(time(spike(j)+1:((spike(j)+41)<(length-1))) $
                          LT time(spike(j)),n1)
            ;;test2:see if a time jump has no jumps within the previous 40 points
            test2 = where(time(((spike(j)-41)>0):(spike(j)-1)) $
                          GT time(spike(j)-1),n2)
;          print,test1,test2
            IF n1+n2 EQ 0 THEN BEGIN ;this is a gap, not a spike
              gaps(j) = 1
;            print,j,spike(j)
            ENDIF 
          ENDIF
        ENDFOR
        
        spike = spike(where(gaps eq 0,spikes)) ;remove gaps, leave just spikes
        IF LOUD THEN print,'Spikes:',strcompress(spikes),' Gaps: ',strcompress(total(gaps))
;      IF LOUD THEN print,'Spike:',spike
        ;;try to get rid of spikes
        k = 0
        FOR j=0l,spikes-1 DO BEGIN
          IF k EQ 0 THEN BEGIN 
            IF dt(spike(j)-1) GT 0 THEN $ ;spike, not a dip
              REPEAT k = k+1 $  ;find return
              UNTIL ((dt(spike(j+k)-1) LT 0) OR (k+j GE spikes-1)) $ 
            ELSE $              ;this is a dip
              REPEAT k = k+1 $
              UNTIL ((dt(spike(j+k)-1) GT 0) OR (k+j GE spikes-1)) ;find return
;this statement represents a failure of accounting, please fix me
            IF (k+j) LT spikes THEN BEGIN 
              span = spike(j+k)-(spike(j)-1)
              tspan = time(spike(j+k))-time(spike(j)-1)
              avg = tspan/span
            ENDIF 
            FOR l=1l,span-1 DO time(spike(j)+l-1) = time(spike(j)-1)+(l*avg)
          ENDIF ELSE k = k-1
        ENDFOR
      ENDELSE   
      glitches = nglitches(time)
      print,'Number of glitches left: ',glitches
;      med = median(time,70)     ;construct a replacement time series
;                                ;70 wil handle up to 32 contiguous time errors
;      trouble = where(ts_diff(med,1) eq 0,spots)+1
;      IF spots GT 1 THEN BEGIN
;        trouble = trouble(0:spots-2)
;        spots = spots-1
;      ENDIF
;      inarow = lonarr(spots)+1
;      k = 0
;      FOR j=0,spots-2 DO BEGIN
;        IF trouble(j+1)-trouble(j) EQ 1 THEN inarow(k) = inarow(k)+1 $
;        ELSE k = k+1
;      ENDFOR 
;      inarow = inarow(where(inarow GT 1),spikes)
      

;      FOR j=seed,length/seed,seed DO $
;        IF nglitches(med) GT 0 THEN med = median(med,j*seed)
;      print,'glitches after median filtering:',nglitches(med)
;      ;;we knocked out the salt and pepper noise.  now replace the points
;      ;;with reasonable values.
;
;      span = 0
;      print,'spots',spots
;      FOR j=0,spots-1 DO BEGIN
;        k = 0
;        REPEAT BEGIN 
;          k = k+1
;          IF trouble(j)+k LT length THEN $
;            span = time(trouble(j)+k)-time(trouble(j)-1) 
;        ENDREP UNTIL ((k GE 34) OR (span GT 0.5*moments(0))) 
;        print,k
;        IF span GT 0 THEN BEGIN ;fix the time elements 
;          FOR l=0,k-1 DO BEGIN
;            time(trouble(j)+l) = time(trouble(j)-1)+span*(l+1.0)/(k+1)
;          ENDFOR                ;loop variable l
;        ENDIF ELSE BEGIN 
;          ;;throw out a bunch of junk...
;        ENDELSE
;      ENDFOR                    ;loop variable j

    ENDIF                       ;end of: if not sort
  
    IF PLOT THEN plot,time MOD time(0),title='Repaired time array.'
                                ;prepair for departure...
    IF SORT THEN BEGIN 
      time_index = sort(time)
      time = time(time_index)
    ENDIF 

    CASE type OF
      8: BEGIN 
        IF SORT THEN BEGIN
          datanames.y = datanames.y(time_index,*)
        ENDIF 
        datanames.x = time
      ENDCASE 
      7: BEGIN
        data.x = time
        IF SORT THEN BEGIN
          data.y = data.y(time_index,*)
        ENDIF 
        store_data,datanames(i),dat=data
      ENDCASE
      ELSE: datanames = time
    ENDCASE 
    
  ENDFOR                        ;loop variable i
  RETURN  
END  



