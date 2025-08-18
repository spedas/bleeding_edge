          ;+
          ; NAME:
          ;    THM_GMAG_STATIONS.PRO
          ;
          ; PURPOSE:
          ;    define quantities for GMAG stations
          ;
          ; CATEGORY:
          ;    None
          ;
          ; CALLING SEQUENCE:
          ;    thm_gmag_stations,labels,location
          ;
          ; INPUTS:
          ;    None
          ;
          ; OPTIONAL INPUTS:
          ;    None
          ;
          ; KEYWORD PARAMETERS:
          ;    conjugate	conjugate locations
          ;    magnetic	geomagnetic coordinates
          ;    midnight	local magnetic midnight
          ;    names	full names of sites
          ;    verbose    some debug printing
          ;
          ; OUTPUTS:
          ;    labels	Names of GBO stations
          ;    location	Geographic location of stations
          ;
          ; OPTIONAL OUTPUTS:
          ;    None
          ;
          ; COMMON BLOCKS:
          ;    None
          ;
          ; SIDE EFFECTS:
          ;    None
          ;
          ; RESTRICTIONS:
          ;    None
          ;
          ; EXAMPLE:
          ;
          ;
          ; MODIFICATION HISTORY:
          ;    Written by: Harald Frey
          ;                Version 1.0 August, 16, 2011
          ;
          ; VERSION:
          ;   $LastChangedBy: jwl $
          ;   $LastChangedDate: 2023-12-30 17:48:10 -0800 (Sat, 30 Dec 2023) $
          ;   $LastChangedRevision: 32328 $
          ;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_gmag_stations.pro $
          ;
          ;-
          
pro thm_gmag_stations,labels,location,conjugate=conjugate,magnetic=magnetic,$
  midnight=midnight,names=names,verbose=verbose
  
  ; find and read file
  ;relpath = 'themis/ground/'
  relpath = ''
  ending = '.txt'
  prefix = 'GMAG-Station-Code-'
  
  relpathnames = file_dailynames(relpath,prefix,ending,$
    trange=['1970-01-01/00:00:00','1970-01-01/00:00:00'])
    
  ;files = '$IDL_BASE_DIR'+'/' + relpathnames
  rt_info = routine_info('thm_gmag_stations',/source)
  files = file_dirname(rt_info.path) + path_sep() + relpathnames
  
  
  if keyword_set(verbose) then  dprint, files
  
  dummy=' '
  labels=strarr(150)
  location=fltarr(2,150)
  mag=fltarr(2,150)
  mid=strarr(150)
  con=fltarr(2,150)
  nam=strarr(150)
  
  openr,unit,files[0],/get_lun
  readf,unit,dummy,format='(a0)'	; header
  i=0
  while not eof(unit) do begin
    readf,unit,dummy,format='(a0)'
    res=strsplit(strcompress(dummy),' ',/extract)
    labels[i]=res[0]
    location[*,i]=float([res[1],res[2]])
    parts=n_elements(res)
    case parts of
      10: begin
        nam[i]=res[3]+' '+res[4]
        mag[*,i]=float([res[5],res[6]])
        mid[i]=res[7]
        con[*,i]=float([res[8],res[9]])
      end
      11: begin
        nam[i]=res[3]+' '+res[4]+' '+res[5]
        mag[*,i]=float([res[6],res[7]])
        mid[i]=res[8]
        con[*,i]=float([res[9],res[10]])
      end
      else:begin
      
    end
  endcase
  i=i+1
endwhile

; return values
labels=labels[0:i-1]
location=location[*,0:i-1]
magnetic =mag[*,0:i-1]
midnight =mid[0:i-1]
conjugate=con[*,0:i-1]
names    =nam[0:i-1]

end
