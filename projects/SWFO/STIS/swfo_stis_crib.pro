;+
; This crib sheet will help explain how to use the SWFO STIS Ground processing software
; Typically a crib sheet can be used to "copy" and "paste" commands into an IDL command window
; This crib sheet can be used as a program to be run from beginning to end.
;
; These tools are not intended as a final product but can be used to create high level ouput.
;
;
; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_crib.pro $
; $ID: $
;-


; sample plotting procedure
pro  swfo_stis_plot_example,nsamples=nsamples    ; This is very simple sample routine to demonstrate how to plot recently collecte spectra
  sci = swfo_apdat('stis_sci')
  da = sci.data    ; the dynamic array that contains all the data collected  (it gets bigger with time)
  size= da.size    ;  Current size of the data  (it gets bigger with time)

  if ~keyword_set(nsamples) then nsamples = 20
  index = [size-nsamples:size-1]    ; get indices of last N samples
  samples=da.slice(index)           ; extract the last N samples

  spectra = total(samples.counts,2)    ;  get the total over slice
  xval = findgen( n_elements( spectra)) * 1.
  wi,2                                ; Open window

  plot,xval,spectra,psym=10,xtitle='Bin Number',ytitle='Counts', $
    title='Science Data (Integrated over '+strtrim(nsamples,2)+' samples)',/ylog,yrange=minmax(/pos,[spectra,[8,10]]);[.5,max(spectra)]

  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end


file_type ='ptp_file'
file_type ='gse_file'
;  Define the "options" dictionary -   Opts
if ~isa(opts,'dictionary') || opts.refresh eq 1 then begin   ; set default options
  !quiet = 1
  opts=dictionary()
  opts.root = root_data_dir()
  opts.remote_data_dir = 'sprg.ssl.berkeley.edu/data/'
  ;opts.local_data_dir = root_data_dir()
  opts.reldir = 'swfo/data/sci/stis/prelaunch/realtime/
  opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
  opts.host = '128.32.98.57'
  opts.title = 'SWFO STIS'
  opts.port = 2428
  opts.init_realtime = 0                 ; Set to 1 to start realtime stream widget
  opts.init_stis =1                      ; set to 1 to initialize the STIS APID definitions
  opts.exec_text = ['tplot,verbose=0,trange=systime(1)+[-10,1]*60.','timebar,systime(1)']   ; commands to be run in exec widget
  ;opts.exec_text = ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','swfo_stis_plot_example','timebar,systime(1)']      ; commands to be run in exec widget
  opts.file_trange = 2 ;set a time range for the last N hours: download last 2 hours of data files and then open real time system
  opts.file_trange = ['2021-10-10'   ,'2021-10-19'   ]   ;Temp margin test data
  opts.file_trange = ['2021-08-23/04','2021-08-24/02']   ;This time range includes some good sample data to test robustness of the code - includes a version change
  opts.file_trange = ['2021-10-18/14','2021-10-18/16']   ;Temp margin test data
  opts.file_trange = ['2022-04-17'   ,'2022-04-21'   ]   ;recent data
  opts.file_trange = ['2022-04-17/23','2022-04-18/01'] ;Example with 2 LPT's from ETU rev A (channel 5 not working)
  opts.file_trange = ['2022-4-21 2','2022 4 21 3']
  opts.file_trange = ['2022-6-14 1','2022 6 14 3']  ;Amptek 250 test of 6 potential flight preamps.
  opts.file_trange = ['2022-7-7 22','2022 7 8 /3']  ;4 LPTs with non-LUT mode
  opts.file_trange = ['2022-7-8 20','2022 7 8 22']  ;LPT with non-LUT mode  ; (possibly incomplete)
  opts.file_trange = ['2022-7-16 2','2022 7 16 3:30']  ;Amptek 250 test of 9 potential flight preamps. (5 turned out to be not suitable for flight)
  opts.file_trange = ['2022-8-4 22','2022 8 4 23']  ;LPT with non-LUT mode after instrument reset
  opts.file_trange = ['2022-8-5 17:30','2022 8 5 17:52']  ;LPT with non-LUT mode
  ;opts.file_trange = !null
  ;opts.filenames=['socket_128.32.98.57.2028_20211216_004610.dat', 'socket_128.32.98.57.20484_20211216_005158.dat']
  opts.filenames = ''
  opts.stepbystep = 0               ; this flag allows a step by step progress through this crib sheet
  opts.refresh = 0                  ; set to zero to skip this section next time
  opts.file_type = 'gse_file'
  printdat,opts
  dprint,'The variable "OPTS" is a dictionary of options.  These can be changed by the user as desired.'
  if opts.stepbystep then stop
endif

if opts.init_stis then begin
  dprint,'Initialize the STIS apid objects.  This will define the decomumutators for each of the STIS APIDS'
  swfo_stis_apdat_init,/save_flag
  if opts.stepbystep then stop
endif

dprint,'Displaying APID definitions and current status'
swfo_apdat_info,/print,/all
if opts.stepbystep then stop

if keyword_set(opts.file_trange) then begin
  trange = opts.file_trange
  pathformat = opts.reldir + opts.fileformat
  if opts.stepbystep then stop
  ;if stepbystep then stop
  ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
  if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0]*3600.
  dprint,dlevel=2,'Download raw telemetry files...'
  filenames = swfo_file_retrieve(pathformat,trange=trange,/hourly_names)
  dprint,dlevel=2, "Print the raw data files..."
  dprint,dlevel=2,file_info_string(filenames)
  opts.filenames = filenames
endif

if keyword_set(opts.filenames) then begin
  dprint,dlevel=2, "Reading in the data files...."
  swfo_ptp_file_read,opts.filenames,file_type=file_type
  dprint,dlevel=2,'A list of packet types and their statistics should be displayed after all the files have been read.'
  if opts.stepbystep then stop
endif

if keyword_set(opts.init_realtime) then begin
  ;if stepbystep then stop
  swfo_init_realtime,/stis   ,opts = opts
  dprint,'"swfo_init_realtime" will create a widget that can read a realtime data stream.'
  dprint,'Click on "Connect to:" to connect to the host:port'
  dprint,'(If a connection can not be made then there is nothing more to do here.)'
  dprint,'Click on "Write to:" to record the stream to a local file.  (not required)'
  dprint,'Click on the "Procedure" checkbox to start decummutating data.'
  if opts.stepbystep then stop
  if keyword_set(opts.exec_text) then begin
    dprint,'Create a generic widget that can execute a list of IDL commands at regular intervals.  These are defined by the user.'
    exec, exec_text = opts.exec_text,title=opts.title+' EXEC',interval=3
  endif
endif

!except =0
dprint,dlevel=2,'Create a "Time Plot" (tplot) showing key parameters of the STIS instrument'
swfo_stis_tplot,/setlim

if 0 then tplot,'*hkp1_ADC_TEMP_S1 *hkp1_ADC_BIAS_* *hkp1_ADC_?5? swfo_stis_hkp1_RATES_CNTR swfo_stis_sci_COUNTS swfo_stis_nse_NHIST swfo_stis_hkp1_CMDS'

dprint,'Statistics of all packets:'
swfo_apdat_info,/print,/all

dprint,dlevel=2,'Obtain IDL objects that hold data from each of the STIS APIDS:'
hkp1 = swfo_apdat('stis_hkp1') ; obtain object that contains all the "housekeeping 1" packets
hkp2 = swfo_apdat('stis_hkp2') ; obtain object that contains all the "housekeeping 2" packets
nse = swfo_apdat('stis_nse')    ; obtain object that contains all the "noise" packets
sci = swfo_apdat('stis_sci')   ; obtain object that contains all the "science data" packets
mem = swfo_apdat('stis_mem') ; obtain object that contains all the "memory dump" packets

if 0 then begin
  if opts.stepbystep then stop
  dprint,'Display contents of most recent decomutated data product'
  printdat,hkp1.last_data   ; Display decommutated contents of most recent hkp1 packet
  printdat,hkp2.last_data
  printdat,nse.last_data
  printdat,sci.last_data   ; Display decommutated contents of most recent science packet
endif

if 1 then begin

  dprint,'Create Level 0B netcdf file for science packets:'
  sci.level_0b = dynamicarray()   ; Turn on storage of level_0b data by giving it a place to store data
  ;sci.file_resolution = 3600
  sci.ncdf_make_file ,ret_filename=sci_filename   ; the filename is returned
  hkp1.ncdf_make_file,ret_filename=hkp1_filename
  hkp2.ncdf_make_file,ret_filename=hkp2_filename
  nse.ncdf_make_file ,ret_filename=nse_filename

  sci_l0b = sci.data.array   ; obtain level 0B data directly from sci object
  sci_l0b_copy = swfo_ncdf_read(file=sci_filename)  ; read copy of data from file that was just created

  ; sci_l0b and sci_l0b_copy should be identical
  ; Note that sci_l0b_copy might have more samples if it was produced after sci_l0b was generated

  if 1 then begin
    sci_l1b = swfo_stis_sci_level_1b(sci_l0b,cal=cal,/reset) ; create L1b data from l0b data
    swfo_ncdf_create,sci_l1b, file=str_sub(sci_filename,'l0b','l1b') ; write data to a file. still awaiting meta data.
    if 1 then begin
      sci_l2 = swfo_stis_sci_level_2(sci_l1b)   ; create l2 data from L1b data
      swfo_ncdf_create,sci_l2, file=str_sub(sci_filename,'l0b','l2') ; write data to a file. still awaiting meta data.
    endif
  endif

endif

end
