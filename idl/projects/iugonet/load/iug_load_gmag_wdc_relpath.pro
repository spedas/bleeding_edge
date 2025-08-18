;+
;Function: IUG_LOAD_GMAG_WDC_RELPATH
;function iug_load_gmag_wdc_relpath, sname = sname, $
;                                    trange = trange, $
;                                    resolution = res, $
;                                    level = level, $
;                                    addmaster = addmaster, $
;                                    _extra = _extra
;
;Purpose:
;  create relpath string from abb code
;
;Notes:
;  This procedure is called from load procedures for WDC format data,
;  'iug_load_gmag_wdc*' provided by WDC Kyoto.
;
;
;Written by:  Daiki Yoshida,  Aug 2010
;Updated by:  Daiki Yoshida,  Sep 14, 2010
;
;-

function iug_load_gmag_wdc_relpath, sname = sname, $
                                    trange = trange, $
                                    resolution = res, $
                                    level = level, $
                                    addmaster = addmaster, $
                                    _extra = _extra

  dir = ''
  dirformat = 'YYYY/'
  prefix = ''
  suffix = ''
  fileformat = 'yyMM'

  relpathnames = ''

  if(~keyword_set(level)) then level = 'all'

  if(~keyword_set(res)) then begin
     if strlowcase(sname) eq 'sym' or $
        strlowcase(sname) eq 'asy' then begin
        res = 'min'
     endif else if strlowcase(sname) eq 'dst' then begin
        res = 'hour'
     endif else begin
        res = 'min'
     endelse
  endif


  if strlowcase(sname) eq 'dst' then begin
     if level eq 'all' or level eq 'final' then begin
        append_array, dir, res+'/index/dst/'
        append_array, prefix, sname
        append_array, suffix, ''
     endif
     if level eq 'all' or strmid(level,0,4) eq 'prov' then begin
        append_array, dir, res+'/index/pvdst/'
        append_array, prefix, sname
        append_array, suffix, ''
     endif
  endif else if strlowcase(sname) eq 'ae' then begin 
     if level eq 'all' or level eq 'final' then begin
        append_array, $
           dir, [res+'/index/ae/', res+'/index/au/', $
                 res+'/index/al/', res+'/index/ao/']
        append_array, prefix, ['ae.', 'au.', 'al.', 'ao.']
        append_array, suffix, replicate('',4)
     endif
     if level eq 'all' or strmid(level,0,4) eq 'prov' then begin
        if res eq 'min' then begin
           ; before 1996
           append_array, $
              dir, [res+'/index/a.e/', res+'/index/a.u/', $
                    res+'/index/a.l/', res+'/index/a.o/']
           append_array, prefix, ['ae', 'au', 'al', 'ao']
           append_array, suffix, replicate('',4)
           ; after 1995
           append_array, dir, replicate(res+'/index/pvae/',5)
           append_array, prefix, ['ae', 'au', 'al', 'ao', 'ax']
           append_array, suffix, replicate('',5)
        endif
     endif
  endif else if strlowcase(sname) eq 'sym' or strlowcase(sname) eq 'asy' then begin
     append_array, dir, res+'/index/asy/'
     append_array, prefix, 'asy'
     append_array, suffix, '.wdc'
  endif else begin
     append_array, dir, res+'/'+strlowcase(sname)+'/'
     append_array, prefix, strlowcase(sname)
     if res eq 'min' then append_array, suffix, '.wdc' else append_array, ''
  endelse


  for i = 0l, size(dir,/n_elements) -1 do begin
     append_array, $
        relpathnames, $
        file_dailynames(dir[i], prefix[i], suffix[i], $
                        dir_format=dirformat, $
                        file_format=fileformat, $
                        trange=trange, addmaster=addmaster, /unique)
  endfor


  return, relpathnames
end