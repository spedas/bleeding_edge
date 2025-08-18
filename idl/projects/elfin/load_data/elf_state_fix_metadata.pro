;+
; PROCEDURE:
;         elf_state_fix_metadata
;
; PURPOSE:
;         Helper routine for setting metadata of ELFIN state variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-05-01 13:00:22 -0700 (Mon, 01 May 2017) $
;$LastChangedRevision: 23255 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_fix_metadata.pro $
;-

pro elf_state_fix_metadata, tplotnames, suffix = suffix

  if undefined(suffix) then suffix = ''
  colors=[2,4,6]
  poslabels = ['X', 'Y', 'Z']
  vellabels = ['VX', 'VY', 'VZ']
  
  for i = 0, n_elements(tplotnames)-1 do begin

    ; handle vectors
    get_data, tplotnames[i], data=d, dlimits=dl, limits=l
    if size(dl, /type) EQ 8 then begin
      coloridx=where(tag_names(dl) EQ 'COLORS', ccnt)
      if ccnt EQ 0 then dl = create_struct(dl, 'colors', [2, 4, 6])
      labelidx=where(tag_names(dl) EQ 'LABELS', lcnt)
      if strpos(tplotnames[i],'vel') NE -1 then labels=vellabels else labels=poslabels
      if lcnt EQ 0 then dl = create_struct(dl, 'labels', labels)
    endif else begin
      if strpos(tplotnames[i],'vel') NE -1 then labels=vellabels else labels=poslabels
      dl={colors:[2,4,6], labels:labels}
    endelse
    store_data, tplotnames[i]+suffix, data=d, dlimits=dl, limits=l

    ; handle time 
    if strpos(tplotnames[i], 'solution_date') GE 0 then begin
       get_data, tplotnames[i], data=d, dlimits=dl, limits=l
       if size(d, /type) EQ 8 then begin
        newy=time_double(LONG64(d.y), /tt2000)
        store_data, tplotnames[i], data={x:d.x, y:newy}, dlimits=dl, limits=l
      endif
    endif

  endfor

end