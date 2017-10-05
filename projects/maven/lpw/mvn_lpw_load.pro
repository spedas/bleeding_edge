
;+
;
;PROCEDURE:   mvn_lpw_load
;PURPOSE:
; For a given UTC date, routine will check if the orbit data is present on the local machine. If not, it will download that data from the Berkeley server.
; Routine will then find the kernels required for that orbit on your machine. If they are not present, they will also be downloaded from the Berkeley server. 
; For now, routine grabs all SPICE kernels. 
; Directories of the data file and required SPICe kernels are saved into tplot variables so they can be accessed by other routines.
; Routine can only take one utc date, as our load routines only do one orbit at a time.
; 
; The common block is for storing clock jump times for statistics.
; 
;
;USAGE:
; mvn_lpw_load, '2014-02-02'
; mvn_lpw_load, filetype='GROUND'
; mvn_lpw_load, '2014-02-02', packet=['EUV','HSK'], tplot_var='all'
; 
;INPUTS:
;- utc_in: a string or one element long string array, of the day for which you wish to look at: utc_in = 'yyyy-mm-dd'
;
;OUTPUTS:                                                    
;- Tplot variables: mvn_lpw_anc_data_file: dlimit.Data_file contains the directory to the orbit data for the given utc date.
;                   mvn_lpw_anc_kernel_files: dlimit.Kernel_files is a string array containing the directories to the required
;                                         SPICE kernels on your machine, which will be downloaded if not present.
;                                                      
;KEYWORDS:
; - data_dir:   Set this when you don't have access to your default 'root_data_dir'. For LASPIANS, this is the LASP spg
;               server. The directory tree used by this software mirrors that at Berkeley, and includes L0 data and SPICE kernel
;               files. 
;               
;               You will need to restart IDL if you switch between using data_dir and not, as this overwrites the environment variable
;               root_data_dir as set in an IDL startup file. 
;               
;               An example:
;               To load L0 data from an external HDD called "external" which mounts on your machine at /Volumes/external , you need the following directories:
;               /Volumes/external/maven/data/sci/pfp/l0_all/          ;L0 data
;               /Volumes/external/misc/spice/naif/MAVEN/kernels/      ;SPICE kernels
;               
;               You would then set data_dir='/Volumes/external/' and /notatlasp (see below).
;               
;               
;       filetype:   'cdf' archive files (L2-data), 'l0' (L0 data, binary file with sc header),  
;                    or 'ground'/'ground_dir'a (file from ground testing, binary file without sc header)
;                    Default is L0. Note that when 'ground' is set, you do not need to enter 'utc_in' - this will be set to a default value.
;                    Filetype can be upper or lowercase - it is corrected to upper case in the code.
;                    
;       packet:     Which packets to read into memeory, default all packets ['HSK','EUV','AVG','SPEC','HSBM','WPK'] 
;       
;       board:      board_names=['EM1','EM2','EM3','FM'] 
;       
;       tplot_var  'all' or 'sci' Which tplot variables to produce. 'sci' produces tplot variables which have physical unit 
;                                 associated with them, and is the default. 'all' produces all tplot variables and includes 
;                                 master cycle information etc.  ### NOTE this currently doesn't work and the default is tplot_var='all'
;                                
;       nospice    setting /nospice will force IDL to NOT use the SPICE routines. Clock times will not be SPICE corrected, and spacecraft attitude
;                  information will not be available.
;     
;       noserver   setting /noserver will mean the Berkeley server is not checked for the latest L0 data. If set, the routine will check your local
;                  data directory (set by setenv, 'ROOT_DATA_DIR=/Dir/toyour/data/') only for the required L0 file. If not present, it will not
;                  be downloaded from the Berkeley server. Useful if the Berkeley server is down, as this routine will crash otherwise. This is also
;                  useful if your internet connection is slow, as the L0 files are ~100mb in size.
;                  Setting this will also mean the NAIF website is not checked for updated SPICE kernels - just those stored within root_data_dir. 
;                  
;       notatlasp setting /notatlasp is a quick fix so the software works (hopefully) outside of LASP. Set this if you are NOT connected to the LASP spg 
;                 server. Without this set, the software checks for a LASP server, returning an error if you're not connected. Setting this keyword skips this check.
;                 
;       get_file_info  setting /get_file_info will stop the routine before actually loading any data. This allows user to see which files and SPICE kernels 
;                      are required. Pressing '.c' will continue the load process.
;     
;       The keywords filetype, packet, board and tplot_var are not checked for in this wrapper. This is because mvn_lpw_load checks for them, and
;       sets them to default values if not present. See mvn_lpw_load.pro for more details. 
;       
;            
;      get_clock_jumps: setting /get_clock_jumps will pause the routine right at the end, so that the user can get the array jump_times_nospice. This array contains
;                       UNIX times for when clock jumps are corrected. These times are NOT SPICE corrected. They are derived straight from the s/c clock. Setting the keyword 
;                       as a string will save the array as an IDL .sav file to that array. Using just /get_clock_jumps will not save the array. User must include last '/' in file directory. Filename
;                       itself is created automatically within the routine.
;                       For example: get_clock_jumps='/Users/name/' will create the file /Users/name/yyyy-mm-dd_clk_jumps.sav
; 
;      leavespice: Default is to leave SPICE kernels intact on exit.  Set this keyword to 0 to clear the kernels on exit.
;
;      spiceinit: Force a re-initialization of SPICE for the input date (see utc_in above).  Default = 0 (no).
;      
;      success: Set this to a variable name. The returned value is 0. if the load was not successful for the given date, and 1 if it was successful.
;      
;NOTES: 
; This routine is a wrapper for several of Davin Larons IDL routines: mvn_pfp_file_retrieve, mvn_spice_kernels, and routines within these. See comments in these
; programs for more information. Davin's routines are available from the Berkeley svn/ssh server.
; 
; This routine looks up SPICE kernels and downloads them if necessary once, at the start of the routine, before looping over packets. SPICE kernels are cleared from IDL at the end of this routine.
; Use /nospiceclear to keep them in IDL memory.
; 
; 
;EXAMPLES:
;
;LASPIANS: (your root_data_dir default is set to the LASP spg server. Occasionally, you may want to work offline from LASP from an external HDD for example:)
;   -If you are not connected to the spg server, you must set /notatlasp
;   
;   - Use at LASP, to load all variables, and all data except the HSBM. You are connected to the spg server. You want to download any updates via 
;   Berkeley and NAIF.
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm' 
;
;   - Use at LASP, to load all variables, and all data except the HSBM. You are connected to the spg server. You do not want to download any updates
;   from Berkeley or NAIF.
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /noserver
;
;   - Use outside of LASP, BUT still connected to the spg server via LASP VPN. You want updates:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm'    ;(same as above; set /noserver to ignore updated L0 and SPICE files)
;
;   - Use outside of LASP, with data stored on an external HDD, but you still want to check for updates and download them to the HDD. You
;   are not connected to the spg server:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', data_dir='/Volumes/HDD/', /notatlasp
;
;   - Use outside of LASP, with data stored on an external HDD. You don't want to check for updates or download them. You are not connected
;   to the spg server:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', data_dir='/Volumes/HDD/', /notatlasp, /noserver
;
;
;NON LASPIANS: (your root_data_dir is permanently set to something outside of LASP, for example you're at Berkeley)
;   - If you are never connected to the LASP spg server, you always need to set /notatlasp.
;   
;   - Your root_data_dir is set to it's default (which is not the LASP spg server); you want to check Berkeley and NAIF for updates:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp 
;
;   - Your root_data_dir is set to it's default (which is not the LASP spg server); you don't want to check Berkeley and NAIF for updates:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp, /noserver
;   
;   - You want to work from an external HDD; you want to check Berkeley and NAIF for updates:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp, data_dir='/Volumes/HDD/'
;
;   - You want to work from an external HDD; you don't want to check Berkeley and NAIF for updates:
;   mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp, data_dir='/Volumes/HDD/', /noserver
;  
;
;=============================
;Loading L2 files: an example:
;=============================
;For now, this will grab all L2 products found for the specfied date. To be written: to ability to select certain products (for example waves, EUV, spectra).
;
;ROOT_DATA_DIR is set to it's default:
;mvn_lpw_load, '2014-11-01', filetype='CDF'
;
;ROOT_DATA_DIR is set to an external HDD, for example:
;mvn_lpw_load, '2014-11-01', filetype='CDF', data_dir='/Volumes/HDD/'
;  
;
;CREATED BY:   Chris Fowler April 23rd 2014
;FILE: 
;VERSION:  2.1
;LAST MODIFICATION: 
;30 April 2014 CF: added option to work offline. This is done via keyword kernel_dir, see INPUTS above.
;13 May 2014 CF: changed name to mvn_lpw_load. Fixed bugs for working with fast server and also offline.
;16 May 2014 CF: Fixed bugs involving use of / or \ for windows or linux machines. Added noserver keyword. Fixed bug to allow use of
;                ground data with filetype keyword.
;20 May 2014 CF: Fixed bug with ground keyword.
;27 May 2014 CF: routine now searches for the file /Volumes/spg/maven/data/server_check/lpw_server_check.rtf to check if machine is connected to
;                the LASP server. This should hopefully prevent IDL from getting confused at times and creating a copy of this tree on the user machine
;                even when connected.
;6 Jun 2014 CF: fixed bug with packet='ALL', added keyword /notatlasp as a quick fix so people outside of LASP can use software.
;;140718 clean up for check out L. Andersson
;20140807: CF: filetype must be now be lowercase in mvn-lpw-load-file; uppercase entries here are now changed to lowercase.
;20141010: CF: added keyword get_file_info: setting this stops the routine before loading any data so user can see which SPICE kernels are required without
;              loading any data.
;20141021: CF: no longer delete previous tplot variables when run. Took out spice kernel finding software and put into mvn-lpw-anc-get-spice-kernels. 
;20141106: CF: changed path to look for L0 data to comply with SSL path. 
;20141216: CF: fixed bug when using data_dir= keyword, to be compliant with new SSL directories.                        
;20150107: CF: edited keyword /noserver so that usage means the SSL server is not checked for L0 files and NAIF website is not checked for
;              SPICE kernels. Useful if you have no, or a very slow, internet connection.     
;20150119: CF: added common block to store clock jump times for statistics.     
;20150806: CMF forced tplot_var='all'as keyword  currently doesn't work.   
;2015-10-08: CMF: modified so that we don't spam NAIF with many requests for SPICE kernels. Kernels are looked up and downloaded (if needed) once at start of routine.
;                 SPICE kernels are cleared by default once all processing done, but remain as a tplot variable.
;2015-11-09: CMF: modified SPICE kernel finder routines - they now add 20 minutes to each end to make sure we cover all times within the day; sometimes packets can be outside of the day by a few minutes.
;2015-12-22: CMF added success keyword.    
;2017-02-22: DLM modified behavior regarding loading and clearing of SPICE kernels.  If SPICE has not yet
;                been initialized, this routine will load kernels appropriate for the input date.  Once loaded,
;                the kernels will remain in memory on exit.  If SPICE has already been initialized, this 
;                routine will use the kernels currently in memory, and they will remain in memory on exit.
;                Keywords LEAVESPICE and SPICEINIT can be used to alter this default behavior.
;           
;-

pro mvn_lpw_load, utc_in, data_dir=data_dir, tplot_var=tplot_var, filetype=filetype, packet=packet, board=board, nospice=nospice, noserver=noserver, $
                  notatlasp=notatlasp, get_file_info=get_file_info, get_clock_jumps = get_clock_jumps, leavespice=leavespice, spiceinit=spiceinit, $
                  success=success

common clock_check, jump_times_nospice
jump_times_nospice = dblarr(1)
tplot_var='all'  ;### CMF added this as default as keyword currently doesn't work

if (size(leavespice,/type) eq 0) then leavespice = 1   ;### DLM changed default to NOT clear kernels on exit (2017-02-22).

;Clear all tplot variables. Kernel and data information can be retained in tplot variables. This must be updated for each run, particularly if
;you switch between using and not using SPICE
;store_data, delete='*'  ;no longer delete previous tplot variables
sl=path_sep()  ;/ for linux, \ for Windows 

;jmm, 29-jan-2015, locate mvn_lpw_software directory if not preset
If(getenv('mvn_lpw_software')) Eq '' Then setenv, 'mvn_lpw_software='+file_dirname(routine_filepath('mvn_lpw_load'))+sl

;If the user doesn't want to use SPICE, we can skip a lot of code which checks and finds kernels:
;==========================
;--- Work on or offline ---
;==========================
;Default is to use the online file structure as made out by Davin's routines. This will be on our server, and should be added to your start_up file
;as: setenv,'ROOT_DATA_DIR=//Users/chfo8135/LASP/MAVEN/data/'. Here, if the user sets a keyword, this dir will be chagned here, so the change is 
;temporary until you restart IDL.

if not keyword_set(data_dir) and getenv('ROOT_DATA_DIR') eq '' then begin  ;if no data dir is set
      print, "#### WARNING ####: mvn_lpw_load uses SSL routines to automatically find L0 data and SPICE kernels."
      print, "Use 'setenv, 'ROOT_DATA_DIR=/Dir/to/your/data/' to tell this software where to find your data."
      print, "If you don't have the required data, it will be downloaded for you automatically."
      print, "###NOTE###: the SSL software requires a specific file structure to store L0 and SPICE kernels. Your setenv directory"
      print, "should be a parent directory to where you want the SSL software to setup the required folder tree."
      print, "Set the environment variable ROOT_DATA_DIR before trying again. Returning to terminal."
      success = 0.
      return
endif

if keyword_set(data_dir) then begin
    if size(data_dir, /type) ne 7 then begin
        print, "#### WARNING ####: data_dir must be a string with the path to your Berkeley data tree. Returning."
        success = 0.
        return
    endif else begin
               ;Make sure last symbol is / so that files go from that folder:
               slen = strlen(data_dir)  ;number of characters in the directory
               extract = strmid(data_dir, slen-1,1)  ;extract the last character
               IF extract NE sl THEN data_dir = data_dir+sl  ;add / or \ to end so new folder is not created.  
               extract = strmid(data_dir, 0, 1)  ;extract first symbol
               IF sl eq '/' then begin  ;if on linux, we need '/' at the front of the path
                  IF extract NE '/' THEN data_dir = '/'+data_dir  ;add to front    
               ENDIF
               
        print, "#### WARNING ####: By specifying the keyword data_dir you are choosing to work offline."
        print, "Your offline kernel and orbit data directory must contain the following Berkeley determined"
        print, "directories: /data/misc/spice/naif/MAVEN/kernels/ for SPICE use, and 
        print, "/data/maven/pfp/l0 to find and load MAVEN orbit data (with '\' on Windows machine). If it does not, this routine will create them"
        print, "for you and download required orbit data and SPICE kernels here. You can work offline without using SPICE;"
        print, "this directory tree must still be present so that the software can locate orbit data."
        print, "-----------------"
        print, "Are your data stored / to be stored in the directories:"
        print, strtrim(data_dir,2), "misc"+sl+"spice"+sl+"naif"+sl+"MAVEN"+sl+"kernels"      
        print, strtrim(data_dir,2), "maven"+sl+"data"+sl+'sci'+sl+"pfp"+sl+"l0_all             on your machine?"    
        print, "-----------------"
        print, "Enter 'yes' and return if this is correct; enter 'no' and return if this is incorrect and be returned to the IDL terminal..."
        response = ''
        read, response, prompt = "'Yes' or 'no', followed by return key: "   ;wait for user confirmation to work offline
        
        if (response ne 'yes') and (response ne 'no') then begin
            print, "### ERROR ###: You must respond either 'yes' or 'no'. Returning to IDL terminal."
            success = 0.
            return
        endif
        if response eq 'no' then begin
            print, "Response = no. Returning to IDL terminal."
            success = 0.
            return
        endif
        if response eq 'yes' then begin
            print, "-----------------"
            print, "Response = yes. Working offline using the data directory ", strtrim(data_dir,2)+"maven"+sl+"data"+sl+"sci"+sl+"pfp"+sl+"l0_all"
            print, "                Working offline with or without SPICE using the directory ", strtrim(data_dir,2)+"misc"+sl+"spice"+sl+"naif"+sl+"MAVEN"+sl+"kernels"+sl
                                   
            ;Check this file tree exists, warn user it will be created if it doesn't:
            fulldir = data_dir;+'maven'+sl+'pfp'+sl+'l0'  ;full path to data, as Davin's software can create these folders if not present 
            res = file_search(fulldir)
            if res eq '' then begin                
                print, "-----------------"
                print, "#### WARNING ####: The directory ", fulldir, " doesn't exist. Do you want this directory to be created? You will"
                print, "need internet access to download orbit and kernel files to the correct directories, unless you can copy and paste them there yourself."
                response2=''
                read, response2, prompt="Do you want to  continue? 'Yes' or 'no', followed by the return key..."
                
                if (response2 ne 'yes') and (response2 ne 'no') then begin
                    print, "### ERROR ###: You must respond either 'yes' or 'no'. Returning to IDL terminal."
                    success = 0.
                    return
                endif
                if (response2 eq 'no') then begin
                    print, "Response = no. Returning to IDL terminal."
                    success = 0.
                    return
                endif
                if (response2 eq 'yes') then begin
                    print, "Response = yes. Continuing, and creating required directories."
                endif
            endif
              
            IF sl eq '/' THEN rootdir = 'ROOT_DATA_DIR=/'+data_dir   ;need '//' after '=' sign here, only for unix though
            IF sl eq '\' THEN rootdir = 'ROOT_DATA_DIR='+data_dir   ;windows
                 
            setenv, rootdir  ;reset root dir to find offline source
            print, "-----------------"
            print, "Kernel directory set to: ", getenv('ROOT_DATA_DIR')
            print, "-----------------"
            print, "-----------------"
            print, "REMEMBER: You will need to restart IDL to start working online and using the LASP server for kernels and data."
            print, "Make sure your IDL start_up file has been edited approriately. See Chris Fowler (christopher.fowler@lasp.colorado.edu) for details."
            print, "-----------------"
        endif
    endelse
endif

;===============
;---Find Data---
;===============
if not keyword_set(filetype) then filetype = 'L0'  ;default
filetype = strupcase(filetype)

;First check that we are connected to the fast1 server, if working at LASP:
;I'm assuming that the file directory will be the same for Macs. I need to check what it is for Windows:
rd = getenv('ROOT_DATA_DIR')  ;root dir

if keyword_set(filetype) and not keyword_set(utc_in) then utc_in='0000-00-00'  ;a default utc date when loading ground data, as utc_in is not needed.

IF size(utc_in, /type) EQ 7 THEN BEGIN  ;utc_in must be a string
    IF n_elements(utc_in) NE 1 THEN BEGIN  ;only one date entry
        print, "#### WARNING ####: UTC time of orbit must be a string in the format 'yyyy-mm-dd'."
        print, "For example: utc_in = '2014-02-01'. For now, must read in one orbit at a time."
        success = 0.
        return            
    ENDIF
    IF strmatch(utc_in, '[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789]') NE 1 THEN BEGIN
        print, "#### WARNING ####: UTC time of orbit must be a string in the format 'yyyy-mm-dd'."
        print, "For example: utc_in = '2014-02-01'. For now, must read in one orbit at a time."
        success = 0.
        return        
    ENDIF
ENDIF ELSE BEGIN
    print, "#### WARNING ####: UTC time of orbit must be a string in the format 'yyyy-mm-dd'."
    print, "For example: utc_in = '2014-02-01'. For now, must read in one orbit at a time."
    success = 0.
    return
ENDELSE

if filetype eq 'L0' then begin 

   IF NOT keyword_set(notatlasp) THEN BEGIN  ;quick fix as this section only works if you're on the lasp server!
      IF file_test(rd+'server_check'+sl+'lpw_server_check.rtf') EQ 0. THEN BEGIN
            print, "### WARNING ###: MAVEN data not detected. Are you connected to the right server?"
            print, "At LASP, this is the lds/spg/ server, assumed to be located at /Volumes/spg/ on a Mac."
            print, "If you are not at LASP, use the keyword '/notatlasp' to skip this check. See mvn_lpw_load.pro"
            print, "for more information. Returning."
            success = 0.
            return
      ENDIF
   ENDIF
      
      ;---------------------      
      ;Define your username and password, taken from a start up file. If not found, can enter manually.
      ;#### how to deal with non maven team members?
      if getenv('MAVENPFP_USER_PASS') eq '' and not keyword_set(noserver) then begin  ;no password found and we want to access the SSL server...
            print, "mvn_lpw_load: WARNING: your SSL password and username was not found. These are required to access the latest L0 data." 
            print, "Enter these in a startup file as the variable"
            print, "setenv, 'MAVENPFP_USER_PASS=username:password'" ;removed spaces, jmm, 2016-09-30
            print, "Enter 'yes' if you wish to continue anyway (you may not be able to get the L0 file you wanted) or 'no' to return to terminal..."
            response=''
            read, response, prompt='yes or no...'
            
            if response ne 'yes' then begin
                  print, "Returning to terminal."
                  success = 0.
                  return
            endif 
      endif  ;over mavenpfp_user_pass
      
      ;password = getenv('SSL_log_in')  ;get password if it isn't ''.  ;OLD version, line below conforms with SSL software.
      password = getenv('MAVENPFP_USER_PASS')  ;Same as SSL
      
      print, "#########################"
      print, "Getting latest L0 file..."
      print, "#########################"      
      
      if keyword_set(noserver) then begin    ;These two routines set common blocks that tell the SSL routines whether to use servers or not
            dummy = mvn_file_source(/set, USER_PASS=password, no_server=1)
            dummy = spice_file_source(/set, no_server=1)
      endif else begin       
            dummy = mvn_file_source(/set, USER_PASS=password) 
            dummy = spice_file_source(/set)
      endelse
      ;---------------------
      
      ;Retrieve files:
      ;Extract year, month, day out of utc_in:
      year = strmid(utc_in, 0, 4)  ;first four characters
      mon = strmid(utc_in, 5, 2)
      day = strmid(utc_in, 8, 2)
      pformat='maven/data/sci/pfp/l0_all/'+year+'/'+mon+'/mvn_pfp_all_l0_YYYYMMDD_v???.dat'   ;NEW format, works
      ;pformat='maven/pfp/l0/'+year+'/'+mon+'/mvn_pfp_all_l0_YYYYMMDD_v???.dat'  ;OLD format, no longer works 
      tr = [utc_in[0],utc_in[0]]  ;Can only retrieve ony day at a time, as load routine only works on one orbit at a time.
      
      files = mvn_pfp_file_retrieve(pformat,trange=tr,/daily)   ;files contains path to the data file for this date.
      ;Sometimes Davin's software will get v1,2,3; make sure we take the latest version, the last element in files
      nnf = n_elements(files)
      files = files[nnf-1]
      
      IF strpos(files, '??') NE -1 THEN BEGIN  ;Data not available if we have v???.dat on the file name
          print, "#### WARNING ####: Date entered (", utc_in[0], ") is outside of the MAVEN mission time frame or is not yet available."
          print, "Exiting routine."
          success = 0.
          return
      ENDIF
      
      IF (strmid(files[0], 0, 2) EQ '//') OR (strmid(files[0], 0, 2) EQ '/\') THEN BEGIN   ;files[0] begins with '//' if the file wasn't found
          print, "#### WARNING ####: Date entered (", utc_in[0], ") is outside of the MAVEN mission time frame or is not yet available."
          print, "Exiting routine."
          success = 0.
          return
      ENDIF
      
      ;=====================================
      ;----Now find correct SPICE kernels---
      ;=====================================
      ;Check for SPICE here:
      if spice_test() eq 0 then nospice=1.  ;set /nospice if SPICE is not installed on the machine
      
      if not keyword_set(nospice) then begin  ;/nospice means ignore this and don't use SPICE
          ;Add 20 minutes to each end to make sure we cover all times; some packets can lie a few minutes outside of the day.
          Tload = time_double(utc_in[0])
          Tload1 = Tload - 1200.d  ;1200s = 20 minutes
          Tload2 = Tload + 86400.d + 1200.d

          ; Don't reinitialize SPICE by default, dlm, 2017-02-22
          ; (Experienced users will initialize SPICE for themselves.
          ;  Use keyword SPICEINIT to force re-initialization, if desired.)
          kernels = spice_test('*', verbose=-1)
          indx = where(kernels ne '', count)
          if (keyword_set(spiceinit) or (count eq 0)) then begin
            print, "Locating correct SPICE kernels..."
            mvn_lpw_anc_get_spice_kernels, [Tload1, Tload2], notatlasp = notatlasp, /load  ;add notatlasp, jmm, 2015-01-29     , CMF added /load keyword
          endif else begin
            ; Inform LPW code that SPICE has already been loaded.  White lie about the time range.
            store_data, 'mvn_lpw_load_kernel_files', data={x:1., y:1.}, dlimit={Kernel_files: kernels, $
            Purpose: "Directories to kernel files needed for UTC date "+time_string(Tload1)+" - "+time_string(Tload2), $
            Notes: "Load in order first entry to last entry to ensure correct coverage"}
          endelse
      endif 
      
      ;==========================
      ;---Save tplot variables---
      ;==========================
      ;Save name of data file for this orbit:
      dl = create_struct('Purpose', "Directory to data file for UTC date "+utc_in, 'Data_file', files[0], 'utc', utc_in[0])
      store_data, 'mvn_lpw_load_file', data={x:1., y:1.}, dlimit=dl
      
      ;SPICE information is now saved within mvn_lpw_anc_get_spice_kernels    
      
      
endif ;Over loading L0

if filetype eq 'CDF' then begin
  mvn_lpw_cdf_read, utc_in   ;L2 data, grab it from SSL
  files = 'CDF'
endif  
          
if (filetype eq 'GROUND') then begin
    print, ""
    print, "-------------------------"
    print, "Filetype 'GROUND' selected. Enter full directory and filename to the ground data you want to load:"
    response3 = ''
    read, response3, prompt="Enter full directory and file name, followed by return key..."
   
    if file_search(response3) eq '' then begin
        print, "#### WARNING ####: File ", response3, " not found by IDL. Returning to terminal."
        success = 0.
        return 
    endif else begin
        print, "File ", response3, " found."
        files = response3
    endelse
endif


;Check that files has been defined:
if size(files, /type) eq 0 then begin
    print, "### WARNING ###: Data file has not been defined. Did you enter keywords correctly? Returning."
    success = 0.
    return
endif


;===============
;---Load data---
;===============

if keyword_set(get_file_info) then begin
      get_data, 'mvn_lpw_load_kernel_files', dlimit=spdl

      print, ""
      print, "########"
      print, "L0 file: ", files[0]
      print, "########"
      print, "SPICE kernel files:"
      print, spdl.Kernel_files
      print, "########"
      print, ""
      print, "Press .c to continue file load..."
      stop
endif

;=======================
;Load L0 or ground data:
;=======================
if (filetype eq 'L0') or (filetype eq 'GROUND') then begin
    if keyword_set(nospice) then mvn_lpw_load_file, files[0], tplot_var=tplot_var, filetype=filetype, packet=packet, board=board, /nospice else $  ;dont use spice
                                 mvn_lpw_load_file, files[0], tplot_var=tplot_var, filetype=filetype, packet=packet, board=board        ;use spice
endif
;=======================

if keyword_set(get_clock_jumps) then begin
      nele = n_elements(jump_times_nospice)
      if nele gt 1 then jump_times_nospice = jump_times_nospice[1:nele-1]  ;first element is a dummy entry
      
      if size(get_clock_jumps, /type) eq 7 then begin  ;save array
          
          ;Make sure there are clock jumps before saving:
          if n_elements(jump_times_nospice) gt 1 then begin
              fname = get_clock_jumps+utc_in+'_clk_jumps.sav'
              save, jump_times_nospice, filename=fname
              
              print, ""
              if file_test(fname) eq 1. then print, "Saved clock jumps at: ", fname
              print, ""
          endif else begin
              print, ""
              print, "No clock jumps found for this L0 file; no file saved."
              print, ""
          endelse
      endif
  
endif  


;CLEAR SPICE kernels here:
if not keyword_set(leavespice) then mvn_spc_clear_spice_kernels

success = 1.

;stop
end



