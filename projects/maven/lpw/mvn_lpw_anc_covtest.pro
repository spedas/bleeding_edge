function mvn_lpw_anc_covtest, unix_in, kernels_to_check, object

;+
;Program written by CF on April 29th 2014 to check if give unix_times lie within the coverage of an SPK file. Multiple SPK files can be loaded 
;and combined together to create larger coverage ranges.
;
;USAGE:
;coverage = mvn_lpw_anc_covtest(unix_in, kernels_to_check)
;
;INPUTS:
;unix_in: dblarr of unix times to check. ### ET times would be more accurate - check with Davin
;
;kernels_to_check: string or strarr containing the full paths to the spk kernels you want to look at.
;
;SPICE kernel files must already be loaded into IDL memory.
;
;object: for now, the NAIF ID code of the object to check; -202 is MAVEN, 1003228 is CSS.
;
;OUTPUTS:
;result: an array n_elements(unix_in) long. 1 means time is within coverage, 0 means it is outside of the kernel coverage.
;
;
; Version 1.0
;
;MODIFICATIONS:
;
; ;140718 clean up for check out L. Andersson
; 20141208: modified by CF to check coverage for different objects - not just MAVEN. New input parameter 'object' allows this.
;-

if size(unix_in, /type) ne 5. then begin
    print, "#######################"
    print, "WARNING: unix_in must be a double array of UNIX times."
    print, "#######################"
    retall
endif

if size(kernels_to_check, /type) ne 7 then begin
    print, "#######################"
    print, "WARNING: kernels_to_check must be a string array of SPICE SPK kernels."
    print, "#######################"
    return, 1
endif


;kernel_dir='/Users/chfo8135/LASP/MAVEN/data/misc/spice/naif/MAVEN/kernels/'
;file0=kernel_dir+'spk/trj_c_od005a_131121-141002_131125_tcm1final.bsp'
;file1 = kernel_dir+'spk/trj_c_od015a_140215-141012_moiprelim_v1.bsp'
;file2 = kernel_dir+'lsk/naif0010.tls'

;unix_in = [1395273611.000021d, 1395273612.000015d, 1395273613.000010d, 1395273614.000005d, 1395273614.999999d, 1395273615.999994d] ;test numbers

nele = long(n_elements(unix_in))  ;number of time stamps
nele_kernels = n_elements(kernels_to_check)

;Parameters for SPICE windows / cells
      MAXIV  = 1000  
      WINSIZ = 2 * MAXIV   ;max size of window
      TIMLEN = 51
      MAXOBJ = 1000  ;max number of objects allowed in an spk file

      cover = cspice_celld( WINSIZ )  ;make a double prec window
      ids   = cspice_celli( MAXOBJ )  ;make an integar prec window

;cspice_furnsh, file1  ;load kernel
;cspice_furnsh, file2

;=========
;--Times--
;=========

;Convert from UNIX times to ET time to UTC to ET(TDB):
utc_time = time_string(unix_in, precision=5)  ;UTC time
;utc_time = ['2014-02-15/23:55:00.00002','2014-02-15/23:59:59.5','2014-02-16/00:00:00.50002']  ;utc times must be of this format
for aa = 0, nele-1 do utc_time[aa] = utc_time[aa]+' TDB'  ;add on to end of string for next line
cspice_str2et, utc_time, ET_TDB_time  ;convert to ET(TDB) time


;cspice_spkobj, file1, ids  ;objects in file

obj = object  ;ids.base[ ids.data + i ]  ;get next object ID
cspice_scard, 0L, cover  ;discard previous object entry so it doesn't combine it
    
for zz = 0, nele_kernels-1 do cspice_spkcov, kernels_to_check[zz], obj, cover  ;look for MAVEN position info, load all kernels in order
    
niv = cspice_wncard( cover )  ;number of coverage intervals

     ;Check if a time lies within interval: Make array here so that it's not overwritten in the for loop
     result = fltarr(nele)
   
     for j=0, niv-1 do begin
         
         
            print, "========================================"
            print, "SPK coverage for loaded kernels, object # ", object
        
            cspice_wnfetd, cover, j, b, e   ;b, e are ET TDB time, start and endpoints of coverage
            
            cspice_timout, [b,e], $ 
            "YYYY MON DD HR:MN:SC.###",  $     ;"YYYY MON DD HR:MN:SC.### (TDB) ::TDB",  $
            TIMLEN ,$
            timstr 

            print, "Interval: ", j
            print, "Start (UTC)  : ", timstr[0]
            print, "Stop (UTC)   : ", timstr[1]
            print
                        
            for aa = 0, nele-1 do result[aa] += cspice_wnelmd(et_tdb_time[aa], cover)    ;add +! if covered. Time may be covered in multiple kernels, so result[] can be greater than 1.       
     endfor  ;over j
     
     indsTMP = where(result ge 1., nindsTMP)
     if nindsTMP gt 0. then result[indsTMP] = 1.  ;replace any numbers greater than 1 with 1.
     
return, result  ;1 if covered, 0 if outside of coverage

;stop
end














