;+
; This crib sheet will help explain how to use the SWFO STIS Ground processing software
; Typically a crib sheet can be used to "copy" and "paste" commands into an IDL command window
; This crib sheet can be used as a program to be run from beginning to end.
;
; These tools are not intended as a final product but can be used to create high level ouput.
;
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-01-17 12:57:50 -0800 (Tue, 17 Jan 2023) $
; $LastChangedRevision: 31415 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_crib.pro $
; $ID: $
;-


; sample plotting procedure


pro swfo_stis_nonlut_decomp_array, nrg=nrg, dnrg=dnrg
  clog_17_6=[$
    0,     1,     2,     3,$
    4,     5,     6,     7,$
    8,     10,    12,    14,$
    16,    20,    24,    28,$
    32,    40,    48,    56,$
    64,    80,    96,    112,$
    128,   160,   192,   224,$
    256,   320,   384,   448,$
    512,   640,   768,   896,$
    1024,  1280,  1536,  1792,$
    2048,  2560,  3072,  3584,$
    4096,  5120,  6144,  7168,$
   ; 8192,  10240, 12288, 14336,$
   ; 16384, 20480, 24576, 28672,$
   ; 32768, 40960, 49152, 57344,$
   ; 65536, 81920, 98304, 114688, $
   2L^13    ]
    
    adc0 =  float(clog_17_6)           ; low adc threshold
    d_adc0 = shift(adc0 ,-1) - adc0 

    nrg_per_adc = 1.  ;1.5   ; keV per adc unit
    
    nrg = nrg_per_adc * (adc0 + d_adc0/2.)   ; midpoint energy
    dnrg = nrg_per_adc * d_adc0              ; energy width
end






pro  swfo_stis_plot_example,trange=trange,nsamples=nsamples,lim=lim    ; This is very simple sample routine to demonstrate how to plot recently collecte spectra
  sci = swfo_apdat('stis_sci')
  da = sci.data    ; the dynamic array that contains all the data collected  (it gets bigger with time)
  size= da.size    ;  Current size of the data  (it gets bigger with time)

  if keyword_set(trange) then begin
    samples=da.sample(range=trange,tagname='time')
    nsamples = n_elements(samples)
  endif else begin
    if ~keyword_set(nsamples) then nsamples = 20
    index = [size-nsamples:size-1]    ; get indices of last N samples
    samples=da.slice(index)           ; extract the last N samples
  endelse
  
    
  counts = total(samples.counts,2)    ;  get the total over slice
  integ_time = total(samples.duration)

  if 1 then begin
    xval = findgen( n_elements( counts)) * 1.
    wi,2                                ; Open window
    plot,xval,counts,psym=10,xtitle='Bin Number',ytitle='Counts', /xstyle, $
      title='Science Data (Integrated over '+strtrim(nsamples,2)+' samples)',/ylog,yrange=minmax(/pos,[counts,[8,10]]);[.5,max(counts)]
  endif
  datsize = 672
  if  1 && datsize eq 672 then begin  ; Non LUT only
    wi,3
    bins = indgen(672)
    bin14    = bins / 48
    bin_nrg  = bins mod 48
    bin_ptrn = bin14 / 2          ; C123 pattern minus 1
    bin_tid  = bin14 mod 2
    
    g3=1.
    g2=g3
    g1=g3/100.
    g0= g3
    g4=g1
    g5=g2
    g6=g3
    
    alt = 150
    col= [180,2,4,6,1,3,0,5,5,5,alt,alt,5,5]
    gfs= [g0,g1,g2,g3,g4,g5,g6]
    ;           1       2      12     3      13    23     123
    channel= [[1,4],  [2,5],  [0,0],  [3,6],   [0,0],   [0,0],   [0,0] ] 
    ;colors = [[2,6],  [4,0],  [1,3],  [2,6],   [4,0],   [4,0],   [4,0] ]
    colors = col[channel]
    print,'colors'
    print,colors
    symb   = [[2,6],  [4,0],   [1,3],  [2,6],   [4,0],   [4,0],   [4,0] ]
    lstyle = [[2,6],  [4,0],   [1,3],  [2,6],   [4,0],   [4,0],   [4,0] ]
    gf     = [[g1,g4],[g2,g5], [g1,g4],[g3,g6], [g1,g4], [g3,g6], [g2,g4] ]
    
    xlim,lim,.1,10000,1
    ylim,lim,1e-10,1000,1
    box,lim
    
    ;counts = counts > .01
    
    swfo_stis_nonlut_decomp_array, nrg=nrg, dnrg=dnrg
    x = nrg[bin_nrg]
    y = counts/integ_time  /dnrg[bin_nrg]  / gf[bin14]
    
    plots,x,y,color = colors[bin14],psym=-1,noclip=0,thick=2
    ;dprint,nrg

  endif

;  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end

;file_type ='ptp_file'
file_type ='gse_file'
station = 's1'


;  Define the "options" dictionary -   Opts
if ~isa(opts,'dictionary') || opts.refresh eq 1 then begin   ; set default options
  !quiet = 1
  opts=dictionary()
  opts.root = root_data_dir()
  opts.remote_data_dir = 'sprg.ssl.berkeley.edu/data/'
  ;opts.local_data_dir = root_data_dir()
  opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
  opts.reldir = 'swfo/data/sci/stis/prelaunch/realtime/' ;s0/s0/
  opts.title = 'SWFO STIS'
  opts.port = 2028
  case strupcase(station) of
    'S0' : begin
      opts.reldir += 'S0/S0/'
      opts.host = '128.32.98.57'
      opts.port = 2028
      end
    'S1' : begin
      ;opts.reldir += 'S1/'
      opts.host = '128.32.98.57'
      opts.port = 2128
      end
  endcase
  opts.init_realtime =1                  ; Set to 1 to start realtime stream widget
  opts.init_stis =1                      ; set to 1 to initialize the STIS APID definitions
  opts.exec_text = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*60.*10','timebar,systime(1)']   ; commands to be run in exec widget
  ;opts.exec_text = ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','swfo_stis_plot_example','timebar,systime(1)']      ; commands to be run in exec widget
  opts.file_trange = 2 ;set a time range for the last N hours: download last 2 hours of data files and then open real time system
  opts.file_trange = ['2021-10-10'   ,'2021-10-19'   ]   ;Temp margin test data
  opts.file_trange = ['2021-08-23/04','2021-08-24/02']   ;This time range includes some good sample data to test robustness of the code - includes a version change
  opts.file_trange = ['2021-10-18/14','2021-10-18/16']   ;Temp margin test data
  opts.file_trange = ['2022-04-17'   ,'2022-04-21'   ]   ;recent data
  opts.file_trange = ['2022-04-17/23','2022-04-18/01'] ;Example with 2 LPT's from ETU rev A (channel 5 not working)
  opts.file_trange = ['2022-4-21 2','2022 4 21 3']
  opts.file_trange = ['2022-6-14 1','2022 6 14 3']  ;Amptek A250F test of 6 potential flight preamps.
  opts.file_trange = ['2022-7-7 22','2022 7 8 /3']  ;4 LPTs with non-LUT mode
  opts.file_trange = ['2022-7-8 20','2022 7 8 22']  ;LPT with non-LUT mode  ; (possibly incomplete)
  opts.file_trange = ['2022-7-16 2','2022 7 16 3:30']  ;Amptek A250F test of 9 potential flight preamps. (5 turned out to be not suitable for flight)
  opts.file_trange = ['2022-8-4 22','2022 8 4 23']  ;LPT with non-LUT mode after instrument reset
  opts.file_trange = ['2022-8-5 17:30','2022 8 5 17:52']  ;LPT with non-LUT mode
  opts.file_trange = ['2022-8-24 2','2022 8 24 3']  ;Amptek A250F test of 18 potential flight preamps
  opts.file_trange = ['2022-8-24 16','2022 8 24 19']  ;extreme counts: baseline and threshold tests on EM with internal LVPS showing weird count rates behavior (sci higher than hkp)
  opts.file_trange = ['2022-9-12 15','2022 9 12 17']  ;good LPT with non-LUT mode
  opts.file_trange = ['2022-9-14 22','2022 9 15 1']  ;FM first light with two LPT runs showing intermittent DAC behavior
  opts.file_trange = ['2022-9-15 21','2022 9 16 3']  ;FM test procedure releaving intermittent DAC behavior. Followed by an LPT and more testing
  opts.file_trange = ['2022-9-23 22','2022 9 24']  ;FM DAC fixed: continued test procedure w/ CM. followed by an LPT run.
  opts.file_trange = ['2022-10-14 22','2022 10 14 25']  ;Am241 x-ray source - first light longer time ran
  opts.file_trange = ['2022-10-14 23:48','2022 10 14 23:50']  ;Am241 x-ray source - first light
  opts.file_trange = ['2022-12-27','2022 12 28']  ;Am241 x-ray source - flight like detectors
  opts.file_trange = ['2023 1 5','2023 1 5 2']  ;Am241 x-ray source - flight like detectors
  opts.file_trange = ['2023 1 3 16','2023 1 3 21']  ;Am241 x-ray source - flight like detectors with transition
  opts.file_trange = ['2023 1 3 ','2023 1 5 ']  ;Am241 x-ray source - flight like detectors with transition - 2 days
  ;opts.file_trange = !null
  opts.file_trange = 4
  ;opts.filenames=['socket_128.32.98.57.2028_20211216_004610.dat', 'socket_128.32.98.57.20484_20211216_005158.dat']
  opts.filenames = ''
  opts.stepbystep = 0               ; this flag allows a step by step progress through this crib sheet
  opts.refresh = 0                  ; set to zero to skip this section next time
  opts.file_type = 'gse_file'
  printdat,opts
  dprint,'The variable "OPTS" is a dictionary of options.  These can be changed by the user as desired.'
  if opts.stepbystep then stop
endif

if opts.init_stis && opts.refresh then begin
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
  swfo_ptp_file_read,opts.filenames,file_type=opts.file_type  ;,/no_clear
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
if 1 || opts.refresh then begin
  dprint,dlevel=2,'Create a "Time Plot" (tplot) showing key parameters of the STIS instrument'
  swfo_stis_tplot,/setlim  
endif else tplot

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

if 0 then begin

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
