;;  @(#)xfastorbcfg.pro	1.3 12/15/94   Fast orbit display program

pro xfastorbcfg
; IDL procedure to configure xfastorb program.  Grabs data from config file
; and fills commons.

@fastorb.cmn
@fastorbdisp.cmn

configdir=getenv('FASTCONFIG')
if (strlen(configdir) eq 0) then begin
  print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  print, 'must set the FASTCONFIG env variable first'
  print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  exit
endif
configfile=configdir + '/xfastorb.cfg'
openr,lun,/get_lun,configfile
dumstr=''
i=0
while(not eof(lun)) do begin
  readf,lun,dumstr
  if(strlen(dumstr) gt 0) then begin
    if(strmid(dumstr,0,1) eq ';') then begin  ; Comment?
       if(strmid(dumstr,1,1) ne ';') then print,strmid(dumstr,1,200)
    endif else begin
      dumstr=strtrim(dumstr,1)
      pos=strpos(dumstr,' ')
      if(pos gt 0) then begin
        option=strtrim(strmid(dumstr,0,pos),2)
        args=strtrim(str_sep(strmid(dumstr,pos,200),','),2)
      endif else begin
        option=strtrim(dumstr,2)
        args=''
      endelse
      case option of
        'TMStation': begin
          fill=n_elements(tmstation)
          if(fill le 0) then $
            tmstation=create_struct('name','','abbr','','desig','', $
                                    'lon',0.0,'lat',0.0,'alt',0.0, $
                                    'elevmin',0.0) $
          else tmstation=[tmstation,tmstation(0)]
          for j=0,n_tags(tmstation)-1 do $
            if(j lt n_elements(args)) then tmstation(fill).(j)=args(j) $
            else tmstation(fill).(j)=''
        end
        else: begin
          print,'Unknown option "'+dumstr+'" in config file.'
        endelse
      endcase
    endelse
  endif
endwhile
close,lun
free_lun,lun

; Add and calculate unit vectors for each station.
scratch=tmstation
tmstation=replicate(create_struct(tmstation(0),'unit',fltarr(3)), $
                    n_elements(tmstation))
for j=0,n_tags(scratch)-1 do tmstation.(j)=scratch.(j)
tmstation.unit(0)=cos(tmstation.lon*!dtor)*cos(tmstation.lat*!dtor)
tmstation.unit(1)=sin(tmstation.lon*!dtor)*cos(tmstation.lat*!dtor)
tmstation.unit(2)=sin(tmstation.lat*!dtor)
w=where(tmstation.abbr eq '',nw)
if(nw gt 0) then tmstation(w).abbr=tmstation(w).name

; For now just hardwire in some printers.
case !version.os of
  'sunos': printque='lwp1'
  else: printque='php4'
endcase

return
end
