;+
;NAME:
; mvn_gen_multipng_plot
;PURPOSE:
; Creates full day, and single orbit plots 
; Note that the data must have already been plotted for this
; routine to work properly. It calls tplot without arguments.
;CALLING SEQUENCE:
; mvn_gen_multipng_plot, filename_proto, date, directory=directory
;INPUT:
; filename_in = the first part of the eventual filename, e.g.,
;               'mvn_pfp_ql_yyyymmdd'
;OUTPUT:
; png files, with names directory+filename_proto+yyddmm_hshf.png,
; where hshf refers to start and end hours for the plot.
;KEYWORDS:
; directory = the output directory, remember the trailing slash....
; no_fdb = if set, the program will not create a .fdb file; the .fdb
;          file for each day contains the start and end times and
;          start and end orbits for each filename.
;HISTORY:
; Hacked from thm_gen_multipngplot, 15-oct-2014, jmm,
; jimm@ssl.berkeley.edu
; Switched to plot single orbit plots, 24-apr-2015, jmm
; Plots from apoapsis to apoapsis, suggested by Takuya Hara,
; 2015-05-13
; Added date to filenames, 14-jul-2015, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-14 11:11:42 -0700 (Tue, 14 Jul 2015) $
; $LastChangedRevision: 18122 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_gen_multipngplot.pro $
;-
Pro mvn_gen_multipngplot, filename_in, directory = directory, $
                          no_fdb = no_fdb, _extra = _extra

;Extract the date
  f0 = strsplit(file_basename(filename_in), '_', /extract)
  nf0 = n_elements(f0)
  date0 = f0[nf0-1]
  date = time_string(date0)
  year = strmid(date, 0, 4)
  month = strmid(date, 5, 2)
  day = strmid(date, 8, 2)
  ymd = year+month+day

  filename_proto = strjoin(f0[0:nf0-2], '_')

  date_double = time_double(date[0])
  if keyword_set(directory) then begin
    dir = directory[0]
    dir = strtrim(dir, 2)
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Ne '/' And ll Ne '\') Then dir = dir+'/'
  endif else dir = './'
;Full day plot
  tplot
;  makepng,dir+filename_proto+'_'+ymd+'_0024',/no_expose,_extra =
;  _extra
  makepng,dir+filename_proto+'_'+ymd, /no_expose, _extra = _extra

;Orbit plots, filename_proto+'_'+orbit_number+'_'+yymmddhhmmss

; Get all orbits for this day
  get_data, 'mvn_orbnum1', data = dorb
  If(~is_struct(dorb)) Then Begin
     orbdata = mvn_orbit_num()
     store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
                 dlimit={ytitle:'Orbit'}
     store_data, 'mvn_orbnum1', orbdata.apo_time, orbdata.num, $
                 dlimit={ytitle:'Orbit-APO'}
     get_data, 'mvn_orbnum1', data = dorb
  Endif
  norbits = n_elements(dorb.x)
  tr0 = date_double+[0.0d0, 86400.0d0]

  If(tr0[0] Ge dorb.x[0] And $
     tr0[1] Le dorb.x[norbits-1]) Then Begin
     o1 = max(where(dorb.x Le tr0[0]))
     o2 = min(where(dorb.x ge tr0[1]))
     tbins = dorb.x[o1:o2]
     onums = dorb.y[o1:o2-1]
     norb = n_elements(tbins)-1
;Output a textfile fdbyyyymmdd
     If(~keyword_set(no_fdb)) Then Begin
        fdbfile = dir+'.fdb'+ymd
        openw, unit, fdbfile, /get_lun
     Endif
     For j = 0, norb-1 Do Begin
        trj = tbins[j:j+1]
        orbno = string(onums[j], format = '(i6.6)')
        orbno0 = strcompress(onums[j], /remove_all)
        orbno1 = strcompress(onums[j]+1, /remove_all)
        tplot, trange = trj, title = 'MAVEN PFP L2: Orbit '+$
               orbno0+'-'+orbno1, var_label = 'mvn_orbnum'
        trjstr0 = time_string(trj[0], format=6)
        trjstr1 = time_string(trj[1], format=6)
        fileid = filename_proto+'_'+ymd+'_'+orbno
        makepng, dir+fileid, /no_expose, _extra = _extra
        If(~keyword_set(no_fdb)) Then Begin
;use commas for delimiters, since jsp object ignores new lines when
;reading the file, then put a comma at the end of each line except for
;the last
           If(j Lt norb-1) Then Begin
              printf, unit, fileid,',',trjstr0,',',trjstr1,','
           Endif Else printf, unit, fileid,',',trjstr0,',',trjstr1
        Endif
     Endfor
;close file
     If(~keyword_set(no_fdb)) Then free_lun, unit
  Endif

  Return
End
