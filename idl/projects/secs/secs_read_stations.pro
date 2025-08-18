;+
;Function: secs_read_stations
;
;Purpose:
; This is a routine to read the sec ascii data file that contains the 
; name of the stations used to derive the SECS eics and seca data
;
; The file includes station name (abbreviated) and latitude, longitude in geocoordinates
; Each file is for one day. On any given day all eics and seca 10 second data files refers to this 1 one
;
;INPUT:
;  filename: a
;OUTPUT:
;  trange: array of start and stop times [optional if time is set via timerange)
;
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2012-05-10 14:23:29 -0700 (Thu, 10 May 2012) $
; $LastChangedRevision: 10410 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/thmsoc/fmi_gmag/thm_read_fmi10secfile.pro $
;-
function secs_read_stations, filename

  sec_template = { version: 1.0, $
    datastart: 0L, $
    delimiter: 32b, $
    missingvalue: 0.0, $    ; OR? !values.f_nan
    commentsymbol: ';', $
    fieldcount: 3L, $
    fieldtypes: [7, 4, 4], $
    fieldnames: ['name','lat','long'] ,$
    fieldlocations: [0,6,12], $
    fieldgroups: [0,1,2] }

  ;catch errors from incorrectly formatted files
  catch,err
  if err eq 0 then begin

      dprint, 'Reading filename: ' + filename
      ; get data from file, data is read in as name, Lat, Long
      ; NOTE: read_ascii is not working, should fix
      ;  results = read_ascii(filename,template=sec_template)
      openr, lun, filename, /get_lun
      line=''
      readf,lun, line
      names=[strmid(line,0,4)]
      line1=strtrim(strmid(line,4),1)
      pos=strpos(line1,' ')
      lats=[float(strmid(line1,0,pos))]
      longs=[float(strmid(line1,pos+1))]
      while not EOF(lun) do begin
        readf, lun, line
        names=[names,[strmid(line,0,4)]]
        line1=strtrim(strmid(line,4),1)
        pos=strpos(line1,' ')
        lats=[lats,[float(strmid(line1,0,pos))]]
        longs=[longs,[float(strmid(line1,pos+1))]]
      endwhile
      npts=n_elements(names)
      latlong=make_array(npts,2, /double)
      latlong[*,0]=lats
      latlong[*,1]=longs
      data={names:names, latlongs:latlong}

    return, data

  endif else begin

    dprint,"Error reading: " + filenames[i]
    dprint,"Error: " + !ERROR_STATE.MSG
    return, 'ERR'

  endelse
  catch,/cancel

end
