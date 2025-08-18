;+
;NAME: DSC_CRIB
;
;DESCRIPTION:
; Crib sheet to demonstrate the loading, plotting, and miscellaneous 
; routines added to support the DSCOVR mission data.
;
;CALLING SEQUENCE:
;   .run dsc_crib  OR cut-and-paste relevant portions
;
;NOTES:
; DSCOVR launch: 2015-02-11
; Data product availability start dates -
;   2015-02-11: Ephemeris & Definitive Attitude
;   2015-06-08: Magnetometer ('h0': 1-sec Definitive Data)
;   2016-06-04: Faraday Cup ('h1': 1-minute Isotropic Maxwellian parameters for solar wind protons)

; 
;OUTLINE:
; 1) Configuration
;   1.1) Initialization
;   1.2) Read Configuration
;   1.3) Modify Configuration
;   1.4) Save Configuration
;   1.5) Reset Configuration
;
; 2) Loading Data
;   2.1) Load Routine Basics
;   2.2) Working with Time Ranges
;   2.3) Examining Loaded Data
;     2.3.1) General Notes
;     2.3.2) Faraday Cup Confidence Intervals
;   2.4) Loading Subsets with VARFORMAT=
;
; 3) Plotting
;   3.1) Plotting Basics
;     3.1.1) Using TPLOT
;     3.1.2) Modifying Plot Options
;     3.1.3) Using DSC_DYPLOT
;       3.1.3.1) Introduction
;       3.1.3.2) Using DSC_GET_YLIMITS
;       3.1.3.3) Use with Multiple Windows
;   3.2) Overview Plots
;     3.2.1) Routines and Basic Usage
;     3.2.2) Time Splits
;     3.2.3) Saving Images
;
; 4) Helper Routines
;   4.1) DSC_NOWIN
;   4.2) DSC_CLEAROPTS
;   4.3) DSC_EZNAME
;   4.4) DSC_DELETEVARS
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/examples/dsc_crib.pro $
;-
;
;------------------------------------------------------------------------------
; 1) Configuration
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   1.1) Initialization
;------------------------------------------------------------------------------
dsc_init  ; Initialize !dsc system variable if not yet defined
stop      ; Uses last saved config file

help,!dsc ; View the config values that are in use
stop

;------------------------------------------------------------------------------
;   1.2) Read Configuration
;------------------------------------------------------------------------------
stored_cfg = dsc_read_config(header=hh) ;Read last stored config file 
stop

foreach line,hh do print,line ;Header shows file creation timestamp
stop

help,stored_cfg               ;Show stored configuration settings
stop

;------------------------------------------------------------------------------
;   1.3) Modify Configuration
;------------------------------------------------------------------------------
; Modify the configuration for your current session
!dsc.local_data_dir = 'D:\NewDir\mySpedasDir\dsc\'              ; Local directory for copies of downloaded DSCOVR data files
!dsc.remote_data_dir = 'https://newserver.com/dscovrdata/'      ; Remote DSCOVR data server
!dsc.save_plots_dir = 'D:\Plots\i_want_spedas_plots_here\dsc\'  ; Local directory for storing DSCOVR overview plot PNG files
!dsc.no_download = 1    ; Do not download from remote server
!dsc.no_update = 1      ; Do not check for newer file versions
!dsc.verbose = 4        ; Set verbosity level
                        ;   1 - Report only Errors/Usage Warnings
                        ;   2 - Also report informational messages
                        ;   4 - Also include Debug level statements
stop

;------------------------------------------------------------------------------
;   1.4) Save Configuration
;------------------------------------------------------------------------------
; Store config.  At *next session* 'dsc_init' will load the above values.
dsc_write_config  
stop

; Change configuration in this session
!dsc.verbose = 1      
!dsc.no_update = 0 
help,!dsc
stop

;**N.B.- Running init again now will *not* change !dsc b/c it already exists in this session
dsc_init     
help,!dsc             
stop

; Simulate a new session
!dsc = dsc_read_config()
help,!dsc                 ; Now values match those stored with 'dsc_write_config' call
stop


;------------------------------------------------------------------------------
;   1.5) Reset Configuration
;------------------------------------------------------------------------------
; Those config values don't work. Let's reset to the defaults.
dsc_init,/reset
stop

;------------------------------------------------------------------------------
; 2) Loading Data
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   2.1) Load Routine Basics
;------------------------------------------------------------------------------
; Set TPLOT timerange
timespan,'2016-08-04',2   ;2 days beginning 2016-08-04/00:00:00
print,time_string(timerange())
stop

; Using the set TPLOT timerange . . .
dsc_load_mag  ; Load Magnetometer data
dsc_load_fc   ; Load Faraday Cup data
dsc_load_att  ; Load Attitude data
dsc_load_or   ; Load Orbit data
stop

dsc_load_all  ; OR just load them all with one call
stop

; Keywords common to all load routines . . . 
dsc_load_fc,/downloadonly ;Download files but *not* store data in TPLOT.
stop

dsc_load_mag,/no_update   ;Only download if a new filename exists. Uses !dsc.no_update by default
stop

dsc_load_or,/no_download  ;Load only locally available files into TPLOT. Uses !dsc.no_download by default.
stop

dsc_load_all,verbose=1    ;Override verbosity set in !dsc.verbose
stop

;------------------------------------------------------------------------------
;   2.2) Working with Time Ranges
;------------------------------------------------------------------------------
;Clear stored TPLOT timerange info
tplot_options,'trange_full'
tplot_options,'trange'
tplot_options,'refdate'
stop

;If TPLOT timerange not set - routines will prompt for and set timerange
dsc_load_or 
stop

; Or load a timerange other than the stored TPLOT timerange
;   - can vary across variables
dsc_load_fc,trange=['2017-01-01/12:00:00','2017-01-02/12:00:00']  ;As a string array

trg = timerange(['2017-01-01','2017-01-02'])
dsc_load_or,trange=trg                                            ;Or a double array
stop

;**N.B. - May actually store more than the requested range depending on data file contents.
;         Passsing 'trange=' to load routines will *not* alter the stored TPLOT timerange.
;         Adjust plotted range by setting the TPLOT timerange.

;Load all with same timerange matching TPLOT timerange
timespan,'2016-12-13',1
dsc_load_all              
stop

;------------------------------------------------------------------------------
;   2.3) Examining Loaded Data
;------------------------------------------------------------------------------
;     2.3.1) General Notes

; See what's loaded
tn = tnames()                   ;Retrieve list of loaded variables
foreach name,tn do print,name
stop

tplot_names                     ;Prints list of loaded variables with index number
stop

                                        ; Or use 'tplotnames' keyword in load call 
dsc_load_mag,tplotnames=magnames        ;'magnames' shows only what was loaded in this call
foreach name,magnames do print,name   
stop

; Get data and options for a given variable
get_data,'dsc_h0_mag_B1F1',data=d,dlimits=dl,limits=l   ;By variable name
                                                        ; or
get_data,2,data=d,dlimits=dl,limits=l                   ;By variable index number
stop

help,d  ;Data array
help,dl ;Structure holding default variable options
help,l  ;Structure holding user modified variable options
stop

;     2.3.2) Faraday Cup Confidence Intervals 
; A closer look at the Faraday Cup variables
tplot_names,'dsc_h1_fc*'  ;All loaded h1 FC variables
stop                          

; Most Faraday Cup variables include data confidence
; For example - proton density
tplot_names,'*fc*Np*'   ;All loaded FC vars dealing with proton density
stop

; Note there is reduncancy here to support both command line and gui interfaces
get_data,'dsc_h1_fc_Np',data=dataNp
get_data,'dsc_h1_fc_Np+DY',data=data_pDy
get_data,'dsc_h1_fc_Np-DY',data=data_mDy
get_data,'dsc_h1_fc_Np_wCONF',data=data_wCONF
help,dataNp   ; data holds x=time, y=Np, and dy=confidence_delta
help,data_pDY ; data holds x=time, y=Np + confidence_delta
help,data_mDY ; data holds x=time, y=Np - confidence_delta
help,data_wCONF ; data holds a string array of TPLOT variable names included in this combined variable
foreach var,data_wCONF do print,var
stop    

;------------------------------------------------------------------------------
;   2.4) Loading Subsets with VARFORMAT=
;------------------------------------------------------------------------------
; The datatype specific load routines also take the keyword VARFORMAT=
; to only load a subset of the CDF data, based on the CDF variable names

store_data,delete='*'         ; Delete all TPLOT variables
dsc_load_or,varformat='*GSE*' ; Load only CDF vars with 'GSE' in the name
dsc_load_mag,varformat='*SD*' ; Load standard deviation vars
tn = tnames()
foreach name,tn do print,name
stop

;------------------------------------------------------------------------------   
; 3) Plotting
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   3.1) Plotting Basics
;------------------------------------------------------------------------------
; For a more detailed description see crib_tplot.pro
; 
;-----------------------------------
;     3.1.1) Using TPLOT
;-----------------------------------
store_data,delete='*'           ; Delete all TPLOT variables
dsc_load_mag,tplotnames=mnames  ; Still using the timerange set with 'timespan,'2016-12-13',1'
dsc_load_fc,tplotnames=fnames   

tplot,'dsc_h0_mag_B1F1' ; Set the variable to plot by name
tplot,9                 ; or TPLOT index number
stop

tplot,[2,21,22]   ; Mult-panel plot
stop

tplot,[21,22,2]   ; Reorder the multi-panel plot
stop

tplot,['dsc_h0_mag_B1GSE_PHI','dsc_h0_mag_B1GSE_THETA'] ; Same with strings
stop

;**N.B. - Loaded variable data timerange may not match that stored as the TPLOT timerange.
;         Adjust plotted range by setting the TPLOT timerange with 'timespan' or 'tlimit' call
;         If TPLOT timerange is undefined - Plot defaults to timerange of the loaded data for plotted variables

tlimit,'2016-12-13/08:00:00','2016-12-13/12:00:00'  ; Zoom-in on smaller time range programmatically
stop

tlimit,/full    ; Restore plot to TPLOT full time range 
stop

tlimit    ; Use cursor (2 clicks) to select new time interval on plot
stop

tplot,'dsc_h0_mag_B1F1' ;**Note- new plot still using the timerange set by 'tlimit' cursors
stop

;-----------------------------------
;     3.1.2) Modifying Plot Options       
;-----------------------------------
; Plot options are set as structure field/value pairs for each TPLOT variable.
; Some defaults have been set by the load routines. These may be overridden using 'options'
; Most routines can reference variables by name or TPLOT index number

get_data,'dsc_h0_mag_B1F1',dlimit=dl,limit=l
help,dl ; (default options stored here)
help,l  ; (user set options here) 
stop    ; Options are a combination of both structures with the values 
        ; in 'l' taking precedence when a field is present in both structures.

; Change line color
options,'dsc_h0_mag_B1F1',colors='r'
tplot   ; If called with no params will repeat the last tplot call 
stop

; Change multiple options at a time
options,2,yrange=[2,10],title='DSCOVR Magnetic Field'
tplot
stop

; Remove the user-set option for color
options,'dsc_h0_mag_B1F1','colors'    ; Can only remove one at a time by name
tplot
stop

; Remove all user-set options by resetting the options structure
store_data,2,limits=0l
tplot 
stop

options,[2,21,22],colors='b'  ; Can set options for multiple variables at one time
tplot,[2,21,22]
stop

options,2,title='panel 1'
options,21,title='panel 2'
options,22,title='panel 3'
tplot
stop

; Global plot options can also be set using 'tplot_options'
tplot_options,'ygap',3        ;Vertical spacing between panels
tplot_options,'ynozero',1     ;Don't force y=0 to be included 
tplot   ;**Remember - axis modifiers like 'ynozero' are ignored if a range is specifically set
stop

; Vector variables can set multiple colors
tplot_options,'ygap'
options,'dsc_h0_mag_B1GSE',colors='krb'       ; By string
tplot,'dsc_h0_mag_B1GSE'
stop

options,'dsc_h0_mag_B1GSE',colors=[42,200,10] ; Or by array of color table values
tplot
stop

;-----------------------------------
;     3.1.3) Using DSC_DYPLOT 
;-----------------------------------
;       3.1.3.1) Introduction
; After a tplot call, use the 'dsc_dyplot' utility to show a shaded area
; representing the confidence interval for the DSCOVR Faraday Cup variable
tlimit,/full
tplot,['dsc_h1_fc_Np','dsc_h1_fc_THERMAL_TEMP','dsc_h1_fc_THERMAL_SPD','dsc_h1_fc_V_GSE_x'] ;aka [25,26,24,27]
dsc_dyplot
stop

; dsc_dyplot overplots the existing window
; => When clearing panels of shading, use another call to tplot first
options,24,dsc_dy=0
tplot
dsc_dyplot
stop

;--Color options to DSC_DYPLOT disabled. Currently uses a transparent gray
;
		;; DSC_DYPLOT looks for special variable options flags:
		;;   dsc_dy: 1 --> Shade the confidence interval for this variable
		;;           0 or undefined --> Do not shade the confidence interval
		;;   dsc_dycolor: Color of the shaded area (int reference to color table. Can be array for vector variables)
		;options,26,dsc_dycolor=190    ; Change shading for variable #26 
		;dsc_dyplot
		;stop
		
		;; Can override the variable color options for all panels by passing keyword COLOR=
		;tplot
		;dsc_dyplot,color=120
		;stop

; Use the PANEL keyword to select a subset of panels to shade (1 indexed)
tplot
dsc_dyplot,panel=[1,3,4]  ; Only try to shade panels 1,3, and 4
stop                    

;Note - panel 3 still remains unshaded because its 'dsc_dy' flag = 0
;Use the /FORCE flag to override the variable's 'dsc_dy' setting
tplot
dsc_dyplot,panel=[1,3,4],/force ; Now the selected panels are all shaded
stop 

; dsc_dyplot will ignore panels where no DY information is available
tplot,['dsc_h1_fc_Np','dsc_h0_mag_B1GSE_x','dsc_h1_fc_THERMAL_TEMP']
dsc_dyplot
stop

; Can call 'dsc_dyplot' multiple times without a tplot call if you are adding
; panels or changing colors
tplot,[25,27,28,29]
dsc_dyplot,panel=3
stop

;dsc_dyplot,panel=3,color=200
;stop

dsc_dyplot,panel=[3,2]
stop

dsc_dyplot
stop

options,[25,27],dsc_dycolor=200
options,[28,29],dsc_dycolor=5
dsc_dyplot
stop

;       3.1.3.2) Using DSC_GET_YLIMITS

; Find range fit to the max/min of measured data
trg = timerange()
name1 = tnames(28)  
name2 = tnames(29)
dsc_get_ylimits,name1,lstruct,trg   ;Returns yrange as a field in 'lstruct' structure
print,lstruct.yrange
stop

;Find range fit to measured data with confidence intervals
dsc_get_ylimits,name1,lstruct,trg,/include_err  
print,lstruct.yrange
options,name1,yrange=lstruct.yrange,ystyle=1  ;Set range using 'options'
tplot
dsc_dyplot
stop

;Use /buff to include a 10% buffer around max/min values
dsc_get_ylimits,name2,lstruct,trg,/include_err,/buff  
options,name2,yrange=lstruct.yrange,ystyle=1
tplot
dsc_dyplot
stop


;       3.1.3.3) Use with Multiple Windows
; Use dsc_dyplot with multiple windows by saving the reference information
; from your tplot call using 'new_tvar=' keyword

; Create and plot in 2 windows
window,1
window,2
tplot,[25,27,28,29],window=1,new_tvar=tinfo1
tplot,[24,45],window=2,new_tvar=tinfo2
stop

; Calling dsc_dyplot defaults to the active window
dsc_dyplot  ;In this case, window 2
stop

; Use tinfo1 structure to shade confidence intervals on window 1
dsc_dyplot,tvinfo=tinfo1
stop

;------------------------------------------------------------------------------
;   3.2) Overview Plots
;------------------------------------------------------------------------------
;     3.2.1) Routines and Basic Usage
trg = timerange(['2017-02-18/03:00:00','2017-02-18/15:00:00'])
dsc_overview,trange=trg       ; Overview for a given timerange
dsc_overview_mag,trange=trg   ; Overview of Magnetometer data
dsc_overview_fc,trange=trg    ; Overview of Faraday Cup data
stop

dsc_overview,'2017-04-18' ;Or pass a date to see a 24hour overview
stop

;     3.2.2) Time Splits
; Use /splits keyword to see given range broken into quarters
dsc_overview_fc,'2017-04-18',/splits
stop

;     3.2.3) Saving Images 
; Use /save to  store png files containing the generated plots
; in the directory specified in !dsc.save_plots_dir
dsc_overview_mag,'2017-04-18',/splits,/save
stop

;------------------------------------------------------------------------------   
; 4) Helper Routines
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   4.1) DSC_NOWIN
;------------------------------------------------------------------------------
; Delete all open direct graphics windows
dsc_nowin 
stop

;------------------------------------------------------------------------------
;   4.2) DSC_CLEAROPTS
;------------------------------------------------------------------------------
; Remove non-default TPLOT variable options . . . 
dsc_clearopts,'dsc_h1_fc_Np'  ;... from variable 'dsc_h1_fc_Np'
stop

tn = tnames('dsc*h1*')
dsc_clearopts,tn      ;... from variable list
stop

dsc_clearopts,/all    ;... from all loaded DSCOVR variables
stop

;------------------------------------------------------------------------------
;   4.3) DSC_EZNAME
;------------------------------------------------------------------------------
; Given a DSCOVR shortcut string or string array, returns the full TPLOT variable name(s).
; Vector quantities refer to variables in GSE coordinate system
var1 = dsc_ezname('vx')
print,var1
stop

tn = dsc_ezname(['b','bphi','btheta','vx','vy','vz'])
tplot,tn
stop

;------------------------------------------------------------------------------
;   4.4) DSC_DELETEVARS
;------------------------------------------------------------------------------
; Delete all loaded DSCOVR TPLOT variables
dsc_deletevars
stop

END
