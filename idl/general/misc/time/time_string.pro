pro time_substitute,destination,source,pos,next_position=p
   p=-1
   if pos lt 0 then return
   if n_elements(source) eq 1 then strput,destination,source,pos  $
   else begin
      for i=0l,n_elements(destination)-1 do begin
         d=destination[i]
         strput,d,source[i],pos
         destination[i]=d
      endfor
   endelse
   p=pos+strlen(source[0])
end




;+
;FUNCTION: time_string(TIME)
;NAME:
;  time_string
;PURPOSE:
;  Converts time to a date string.
;INPUTs:
;  TIME  input can be a scalar or array of any dimension of type:
;  double(s)      seconds since 1970
;  string(s)      format:  YYYY-MM-DD/hh:mm:ss
;  structure(s)   format:  given in "time_struct"
;  float(s)       not recommended, may result in loss of precision 
;  longs(s)
;                 values outside normal range will be corrected.
;KEYWORDS:
;
;  LOCAL_TIME ;      if set then local time is displayed.
;
;  TFORMAT:   a format string such as:  "YYYY-MM-DD/hh:mm:ss.ff DOW TDIFF"
;               the following tokens are recognized:
;                    YYYY  - 4 digit year
;                    yy    - 2 digit year
;                    MM    - 2 digit month
;                    DD    - 2 digit date
;                    hh    - 2 digit hour
;                    mm    - 2 digit minute
;                    ss    - 2 digit seconds
;                    .fff   - fractional seconds
;                    MTH   - 3 character month
;                    DOW   - 3 character Day of week
;                    DOY   - 3 character Day of Year
;                    TDIFF - 5 character, hours different from UTC    (useful with LOCAL keyword)
;
;        if TFORMAT is defined then the following keywords are ignored.
;
;  FORMAT:         specifies output format.
;    FORMAT=0:  YYYY-MM-DD/hh:mm:ss
;    FORMAT=1:  YYYY Mon dd hhmm:ss
;    FORMAT=2:  YYYYMMDD_hhmmss
;    FORMAT=3:  YYYY MM dd hhmm:ss
;    FORMAT=4:  YYYY-MM-DD/hh:mm:ss
;    FORMAT=5:  YYYY/MM/DD hh:mm:ss
;    FORMAT=6:  YYYYMMDDhhmmss
;  SQL:            produces output format: "YYYY-MM-DD hh:mm:ss.sss"
;                  (quotes included) which convenient for building SQL queries.
;  PRECISION:      specifies precision
;      -5:   Year only
;      -4:   Year, month
;      -3:   Year, month, date
;      -2:   Year, month, date, hour
;      -1:   Year, month, date, hour, minute
;       0:   Year, month, date, hour, minute, sec
;      >0:   fractional seconds
;  AUTOPREC  If set PREC will automatically be set based on the array of times
;  DELTAT:   (float) PREC set based on this precision.
;  DATE_ONLY:   Same as PREC = -3
;  MSEC:        Same as PREC = 3
;
;OUTPUT:
;  string with the following format: YYYY-MM-DD/hh:mm:ss (Unless
;  modified by keywords.)
;
;See Also:  "time_double"  , "time_struct" or "time_ticks"
;
;NOTE:
;  This routine works on vectors and is designed to be fast.
;  Output will have the same dimensions as the input.
;  
;  If you call this function using a float for time0, IDL transforms the float
;  to an exp format, which may result in loss of precision. For example:
;  time_string(1514851198.0D) = 2018-01-01/23:59:58 (Correct!)
;  time_string(1514851198.0) = 2018-01-02/00:00 (Wrong!) float becomes 1.5148512e+009 
;  time_string(1514851198) = 2018-01-01/23:59:58 (Correct!)  
;
;CREATED BY:    Davin Larson  Oct 1996
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-05-24 15:55:33 -0700 (Sat, 24 May 2025) $
; $LastChangedRevision: 33332 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/time_string.pro $
;-
function time_string,time0, $
   format = format,precision=prec,epoch=epoch,date_only=date_only, $
   tformat=tformat, $
   local_time=local_time, $
   MMDDYYYY=MMDDYYYY,  $
   is_local_time=is_local_time, $
   msec = msec, sql=sql, autoprec=autoprec, deltat=dt,timezone=timezone,badstring=badstring,escape_seq=escape_seq

ms=['   ','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
dow = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
;if not keyword_set(badstring) then badstring='NULL'

if keyword_set(msec) then prec=3

if size(/type,time0) eq 0 then begin
   s= ''
   print,'Enter time(s)  (YYYY-MM-DD/hh:mm:ss)  blank line to quit:'
   read,s
   time0 = s
   while keyword_set(s) do begin
     read,s
     if keyword_set(s) then time0=[time0,s]
   endwhile
endif

if size(/type,time0) eq 4 and n_elements(prec) eq 0  then prec=-1

if size(/type,time0) ne 8 then time = time_struct(time0,epoch=epoch,timezone=timezone,local_time=local_time,is_local_time=is_local_time,mmddyyyy=mmddyyyy) $
else time = time0                               ; Force input into a structure

if keyword_set(tformat) then begin
    if size(/n_dimension,time0) eq 0 then res=tformat $
    else res = make_array(value=tformat,dim=size(/dimension,time0))

    pos = 0
    repeat time_substitute,res, dow[time.dow],  strpos(tformat,'DOW',pos), next=pos  until pos lt 0
    repeat time_substitute,res, ms[time.month], strpos(tformat,'MTH',pos), next=pos  until pos lt 0
    repeat time_substitute,res, string(time.year ,format='(i4.4)'), strpos(tformat,'YYYY',pos),next=pos  until pos lt 0
    repeat time_substitute,res, string(time.year mod 100 ,format='(i2.2)'), strpos(tformat,'yy',pos),next=pos  until pos lt 0
    repeat time_substitute,res, string(time.month,format='(i2.2)'), strpos(tformat,'MM',pos)  ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.date ,format='(i2.2)'), strpos(tformat,'DD',pos)  ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.hour, format='(i2.2)'), strpos(tformat,'hh',pos)  ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.min,  format='(i2.2)'), strpos(tformat,'mm',pos)  ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.sec,  format='(i2.2)'), strpos(tformat,'ss',pos)  ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.doy,  format='(i3.3)'), strpos(tformat,'DOY',pos) ,next=pos  until pos lt 0
    repeat time_substitute,res, string(time.tdiff,format='("(",i+3.2,")")'),strpos(tformat,'TDIFF',pos) ,next=pos  until pos lt 0
    token='.'
    repeat begin
        token = token +'f'
        pos = strpos(tformat, token )
    endrep until strpos(tformat,token+'f') lt 0
    time_substitute,res,strmid(string(time.fsec,format='(f10.8)'),1,strlen(token)), pos
    if keyword_set(escape_seq) then res = str_sub(res,escape_seq,'')
    return,res

endif else begin

    if size(/n_dimen,time0) eq 0 then res='' $
    else res = make_array(value='',dim=size(/dimension,time0))

    if not keyword_set(format) then fmt = 0 else fmt = format

    if keyword_set(sql) then begin
;        message,/info,'the SQL keyword is a STUPID keyword!'
        fmt = 4
        prec = 3
    end

    case fmt of
        0:  f = '(i4.4,"-",i2.2,"-",i2.2,"/",i2.2,":",i2.2,":",i2.2)'
        1:  f = '(i4.4," ",a," ",i2.2," ",i2.2,i2.2,":",i2.2)'
        2:  f = '(i4.4,i2.2,i2.2,"_",i2.2,i2.2,i2.2)'
        3:  f = '(i4.4," ",i2.2," ",i2.2," ",i2.2," ",i2.2," ",i2.2)'
        4:  f = '(i4.4,"-",i2.2,"-",i2.2," ",i2.2,":",i2.2,":",i2.2)'
        5:  f = '(i4.4,"/",i2.2,"/",i2.2," ",i2.2,":",i2.2,":",i2.2)'
        6:  f = '(i4.4,i2.2,i2.2,i2.2,i2.2,i2.2)'
    endcase

    if keyword_set(autoprec) or keyword_set(dt) then begin
        if n_elements(time) ge 1 and keyword_set(autoprec) then begin
            td = time_double(time)
            td = td[sort(td)]
            dt = min(abs(td-shift(td,1)))
        endif
        if dt le 0 then dt=1
        prec = -5
        if dt lt 364*86400. then prec= -4  ;months
        if dt lt  60*86400. then prec= -3  ;days
;        if dt lt     86400. then prec= -2  ;hours
        if dt lt  12* 3600. then prec= -1  ;min
        if dt lt        60. then prec= 0   ;sec
        if dt lt         1. then prec =  floor(1-alog10(dt))
    endif

    if keyword_set(date_only) then prec = -3

    if keyword_set(prec) then begin
        posits = [[16,13,10,7,4],[16,14,11,8,4],[13,11,8,6,4],[16,13,10,7,4],[16,13,10,7,4],[16,13,10,7,4],[12,10,8,6,4]]
    if prec gt 0 then  pos = prec else pos= -posits[-prec-1,fmt]
endif

if size(/type,time) eq 8 then begin       ; input is a structure
    for i=0l,n_elements(time)-1 do begin
        t = time[i]
        case fmt of
            0:      s = string(form=f,t.year,t.month,t.date,t.hour,t.min,t.sec)
            1:      s = string(form=f,t.year,ms[t.month],t.date,t.hour,t.min,t.sec)
            else:   s = string(form=f,t.year,t.month,t.date,t.hour,t.min,t.sec)
        endcase
        if keyword_set(pos) then begin
            if pos gt 0 then s = s + strmid(string(t.fsec,format="(f16.14)"),1,pos+1)
            if pos lt 0 then s = strmid(s,0,-pos)
        endif
        res[i] = s
    endfor

    if keyword_set(sql) then begin
        res = '"' + res + '"'
    end
    if  keyword_set(badstring) then begin
        notgood = where(finite(time.sod) eq 0)
        if (notgood[0] ne -1) then res[notgood] = badstring
    endif
    return,res
endif

endelse

message,/info,'Improper time input'

end

