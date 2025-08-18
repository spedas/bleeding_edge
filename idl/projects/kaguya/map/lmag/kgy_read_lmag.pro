;+
; PROCEDURE:
;     kgy_read_lmag
; PURPOSE:
;     reads in Kaguya MAP/LMAG files 
;     and stores data in a common block (kgy_lmag_com)
; CALLING SEQUENCE:
;     kgy_read_lmag, files, trange=trange
; INPUTS:
;     files: full paths to the LMAG files (gziped or decompressed)
;            e.g., [ 'dir/mag20080101.7.all.1sec.gz', $
;                    'dir/mag20080101.7.sat.1sec.gz', $
;                    'dir/mag20080101_00.7.sat.32hz.gz', ... ]
; KEYWORDS:
;     trange: time range (optional, Def. all),
;             ['yyyy-mm-dd/hh:mm:ss','yyyy-mm-dd/hh:mm:ss']
;             Any format compatible with 'time_double' is acceptable.
; NOTES:
;     Invalid data elements = 999.99 -> NaNs
; CREATED BY:
;     Yuki Harada on 2014-06-30
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-09 11:33:47 -0700 (Fri, 09 Sep 2016) $
; $LastChangedRevision: 21810 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/lmag/kgy_read_lmag.pro $
;-

pro kgy_read_lmag, files, trange=trange, verbose=verbose

@kgy_lmag_com

for i_file=0,n_elements(files)-1 do begin

fname = files[i_file]

;- file info check
finfo = file_info(fname)
if finfo.exists eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'FILE DOES NOT EXIST: '+fname+' --> skipped'
   CONTINUE
endif else dprint,dlevel=0,verbose=verbose,'open file: '+fname

if strmatch(fname,'*MAG_TS*.dat') eq 1 then datatype = 'pub'
if strmatch(fname,'*all.1sec*') eq 1 then datatype = 'all'
if strmatch(fname,'*sat.1sec*') eq 1 then datatype = 'sat'
if strmatch(fname,'*all.32hz*') eq 1 then datatype = 'all32hz'
if strmatch(fname,'*sat.32hz*') eq 1 then datatype = 'sat32hz'
if strmatch(fname,'*.gz') eq 1 then compress = 1 else compress = 0

tr = timerange(trange)


syst0 = systime(/sec)
secnow = 0.

case datatype of
   'pub': begin
      xread = strarr(14)
      Ndata = 86400l/4
      lmag_pub_line $
         = {time:0.d, $
            Rme:dblarr(3), Bme:fltarr(3), $
            Rgse:dblarr(3), Bgse:fltarr(3) }
      lmag_pub_file = replicate( lmag_pub_line, Ndata )

      i_data = 0l
      openr,1,fname,compress=compress
      while (NOT EOF(1)) do begin
         readf,1,xread, $
               format='(a10,1x,a8,1x,a8,1x,a8,1x,a8,1x,' + $
               'a7,1x,a7,1x,a7,1x,a10,1x,a10,1x,a10,1x,' + $
               'a7,1x,a7,1x,a7)'
         now = time_double(xread[0]+'/'+xread[1])
         if now ge tr[0] and now lt tr[1] then begin

            if systime(/sec)-syst0 gt secnow+1 then begin
               secnow = secnow + 1
               dprint,'Reading '+fname+': '+time_string(now)
            endif

            lmag_pub_file[i_data].time = now
            lmag_pub_file[i_data].Rme = double(xread[2:4])
            lmag_pub_file[i_data].Bme = float(xread[5:7])
            lmag_pub_file[i_data].Rgse = double(xread[8:10])
            lmag_pub_file[i_data].Bgse = float(xread[11:13])
            i_data = i_data + 1
         endif
      endwhile
      close,1
      free_lun,1

      w = where( lmag_pub_file.Bme eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_pub_file.Bme
         bb[w] = !values.f_nan
         lmag_pub_file.Bme = bb
      endif
      w = where( lmag_pub_file.Bgse eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_pub_file.Bgse
         bb[w] = !values.f_nan
         lmag_pub_file.Bgse = bb
      endif

      if i_data ge 1 then begin
         if size(lmag_pub,/tname) ne 'STRUCT' then $
            lmag_pub = lmag_pub_file[0:i_data-1] $
         else lmag_pub = [ lmag_pub, lmag_pub_file[0:i_data-1] ]
      endif
   end
   'all': begin
      xread = strarr(21)
      Ndata = 86400l
      lmag_all_line $
         = {time:0.d, $
            Rme:dblarr(3), Bme:fltarr(3), $
            Rgse:dblarr(3), Bgse:fltarr(3), $
            Rsse:dblarr(3), Bsse:fltarr(3), $
            Temp:0. }
      lmag_all_file = replicate( lmag_all_line, Ndata )

      i_data = 0l
      openr,1,fname,compress=compress
      while (NOT EOF(1)) do begin
         readf,1,xread, $
               format='(a10,1x,a8,1x,a10,1x,a10,1x,a10,1x,' + $
               'a10,1x,a10,1x,a10,1x,a12,1x,a12,1x,a12,1x,' + $
               'a10,1x,a10,1x,a10,1x,a12,1x,a12,1x,a12,1x,' + $
               'a10,1x,a10,1x,a10,1x,a10)'
         now = time_double(xread[0]+'/'+xread[1])
         if now ge tr[0] and now lt tr[1] then begin

            if systime(/sec)-syst0 gt secnow+1 then begin
               secnow = secnow + 1
               dprint,'Reading '+fname+': '+time_string(now)
            endif

            lmag_all_file[i_data].time = now
            lmag_all_file[i_data].Rme = double(xread[2:4])
            lmag_all_file[i_data].Bme = float(xread[5:7])
            lmag_all_file[i_data].Rgse = double(xread[8:10])
            lmag_all_file[i_data].Bgse = float(xread[11:13])
            lmag_all_file[i_data].Rsse = double(xread[14:16])
            lmag_all_file[i_data].Bsse = float(xread[17:19])
            lmag_all_file[i_data].Temp = float(xread[20])
            i_data = i_data + 1
         endif
      endwhile
      close,1
      free_lun,1

      w = where( lmag_all_file.Bme eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all_file.Bme
         bb[w] = !values.f_nan
         lmag_all_file.Bme = bb
      endif
      w = where( lmag_all_file.Bgse eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all_file.Bgse
         bb[w] = !values.f_nan
         lmag_all_file.Bgse = bb
      endif
      w = where( lmag_all_file.Bsse eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all_file.Bsse
         bb[w] = !values.f_nan
         lmag_all_file.Bsse = bb
      endif

      if i_data ge 1 then begin
         if size(lmag_all,/tname) ne 'STRUCT' then $
            lmag_all = lmag_all_file[0:i_data-1] $
         else lmag_all = [ lmag_all, lmag_all_file[0:i_data-1] ]
      endif
   end
   'sat': begin
      xread = strarr(8)
      Ndata = 86400l
      lmag_sat_line $
         = {time:0.d, alt:0., lat:0., lon:0., Bsat:fltarr(3)}
      lmag_sat_file = replicate( lmag_sat_line, Ndata )

      i_data = 0l
      openr,1,fname,compress=compress
      while (NOT EOF(1)) do begin
         readf,1,xread, $
               format='(a10,1x,a8,1x,a10,1x,a10,1x,a10,1x,' + $
               'a10,1x,a10,1x,a10)'
         now = time_double(xread[0]+'/'+xread[1])
         if now ge tr[0] and now lt tr[1] then begin

            if systime(/sec)-syst0 gt secnow+1 then begin
               secnow = secnow + 1
               dprint,'Reading '+fname+': '+time_string(now)
            endif

            lmag_sat_file[i_data].time = now
            lmag_sat_file[i_data].alt = float(xread[2]) - 1738.
            lmag_sat_file[i_data].lat = float(xread[3])
            lmag_sat_file[i_data].lon = float(xread[4])
            lmag_sat_file[i_data].Bsat = float(xread[5:7])
            i_data = i_data + 1
         endif
      endwhile
      close,1
      free_lun,1

      w = where( lmag_sat_file.Bsat eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_sat_file.Bsat
         bb[w] = !values.f_nan
         lmag_sat_file.Bsat = bb
      endif

      if i_data ge 1 then begin
         if size(lmag_sat,/tname) ne 'STRUCT' then $
            lmag_sat = lmag_sat_file[0:i_data-1] $
         else lmag_sat = [ lmag_sat, lmag_sat_file[0:i_data-1] ]
      endif
   end
   'all32hz': begin
      xread = strarr(21)
      Ndata = 32*60*60l
      lmag_all32hz_line $
         = {time:0.d, $
            Rme:dblarr(3), Bme:fltarr(3), $
            Rgse:dblarr(3), Bgse:fltarr(3), $
            Rsse:dblarr(3), Bsse:fltarr(3), $
            Temp:0. }
      lmag_all32hz_file = replicate( lmag_all32hz_line, Ndata )

      i_data = 0l
      openr,1,fname,compress=compress
      while (NOT EOF(1)) do begin
         readf,1,xread, $
               format='(a10,1x,a13,1x,a10,1x,a10,1x,a10,1x,' + $
               'a10,1x,a10,1x,a10,1x,a12,1x,a12,1x,a12,1x,' + $
               'a10,1x,a10,1x,a10,1x,a12,1x,a12,1x,a12,1x,' + $
               'a10,1x,a10,1x,a10,1x,a10)'
         now = time_double(xread[0]+'/'+xread[1])
         if now ge tr[0] and now lt tr[1] then begin

            if systime(/sec)-syst0 gt secnow+1 then begin
               secnow = secnow + 1
               dprint,'Reading '+fname+': '+time_string(now)
            endif

            lmag_all32hz_file[i_data].time = now
            lmag_all32hz_file[i_data].Rme = double(xread[2:4])
            lmag_all32hz_file[i_data].Bme = float(xread[5:7])
            lmag_all32hz_file[i_data].Rgse = double(xread[8:10])
            lmag_all32hz_file[i_data].Bgse = float(xread[11:13])
            lmag_all32hz_file[i_data].Rsse = double(xread[14:16])
            lmag_all32hz_file[i_data].Bsse = float(xread[17:19])
            lmag_all32hz_file[i_data].Temp = float(xread[20])
            i_data = i_data + 1
         endif
      endwhile
      close,1
      free_lun,1

      w = where( lmag_all32hz_file.Bme eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all32hz_file.Bme
         bb[w] = !values.f_nan
         lmag_all32hz_file.Bme = bb
      endif
      w = where( lmag_all32hz_file.Bgse eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all32hz_file.Bgse
         bb[w] = !values.f_nan
         lmag_all32hz_file.Bgse = bb
      endif
      w = where( lmag_all32hz_file.Bsse eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_all32hz_file.Bsse
         bb[w] = !values.f_nan
         lmag_all32hz_file.Bsse = bb
      endif

      if i_data ge 1 then begin
         if size(lmag_all32hz,/tname) ne 'STRUCT' then $
            lmag_all32hz = lmag_all32hz_file[0:i_data-1] $
         else lmag_all32hz = [ lmag_all32hz, lmag_all32hz_file[0:i_data-1] ]
      endif
   end
   'sat32hz': begin
      xread = strarr(8)
      Ndata = 32*60*60l
      lmag_sat32hz_line $
         = {time:0.d, alt:0., lat:0., lon:0., Bsat:fltarr(3)}
      lmag_sat32hz_file = replicate( lmag_sat32hz_line, Ndata )

      i_data = 0l
      openr,1,fname,compress=compress
      while (NOT EOF(1)) do begin
         readf,1,xread, $
               format='(a10,1x,a13,1x,a10,1x,a10,1x,a10,1x,' + $
               'a10,1x,a10,1x,a10)'
         now = time_double(xread[0]+'/'+xread[1])
         if now ge tr[0] and now lt tr[1] then begin

            if systime(/sec)-syst0 gt secnow+1 then begin
               secnow = secnow + 1
               dprint,'Reading '+fname+': '+time_string(now)
            endif

            lmag_sat32hz_file[i_data].time = now
            lmag_sat32hz_file[i_data].alt = float(xread[2]) - 1738.
            lmag_sat32hz_file[i_data].lat = float(xread[3])
            lmag_sat32hz_file[i_data].lon = float(xread[4])
            lmag_sat32hz_file[i_data].Bsat = float(xread[5:7])
            i_data = i_data + 1
         endif
      endwhile
      close,1
      free_lun,1

      w = where( lmag_sat32hz_file.Bsat eq 999.99 , nw )
      if nw gt 0 then begin
         bb = lmag_sat32hz_file.Bsat
         bb[w] = !values.f_nan
         lmag_sat32hz_file.Bsat = bb
      endif

      if i_data ge 1 then begin
         if size(lmag_sat32hz,/tname) ne 'STRUCT' then $
            lmag_sat32hz = lmag_sat32hz_file[0:i_data-1] $
         else lmag_sat32hz = [ lmag_sat32hz, lmag_sat32hz_file[0:i_data-1] ]
      endif
   end
endcase

endfor                          ;- i_file loop

end
