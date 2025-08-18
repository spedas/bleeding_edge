;***************************************************************************** 
;*NAME:
;
; mvn_mag_ql.pro
;
;*PURPOSE:
;
; Top level procedure for processing and creating MAVEN MAG quicklook data
; 
;*PARAMETERS:
;
;datafile= String name of the input binary file to be processed
;          Examples:
;           SSL split files 
;             'apid_40_all.dat'
;           L0 MAG data files from the SOC 
;             'mvn_mag_arc_l0_20150803_v1.dat'
;           L0 P&F compiled data files from the SOC
;             '20130524_224257_atlo_l0.dat'
;
;input_path = Where that datafile is. Note the final slash (either \ or / )is
;               included
;
;data_output_path = Where the IDL .sav file is saved or to be loaded from
;                   created during processing.
;
;plot_save_path = Where a plot made by the jreplot procedure should be saved.
;                    Note there is no final \ or /
;
;pkt_type = data_source (required) (input) (scalar) (string)
;    Describes the source os the data file.
;    'instrument' - from the instrument, no PFP or spacecraft in path
;    'pfp_eng' - engineering data via the PFP DPU which includes 
;          the PFP header
;    'pfp_sci' - science data via the PFP DPU which includes the 
;          PFP header
;    'ccsds' - data from the spacecraft which includes the CCSDS 
;        and PFP headers 
;
;/tsmake = Convert the decommutated data into a proper time series
;           and save it as an IDL save file. Usually yes. Only not included
;           if you've already done that before and want to save the computations.
;                                                   
;/mag1 = Extract and process APID 40 data from a compiled P&F L0 datafile.
;  
;/mag2 = Extract and process APID 41 data from a compiled P&F L0 datafile.
;  
;/jreplot = Make plots in the style used during ATLO by the MAG team
;
;*EXAMPLES:
;
;datafile='apid_40_all.dat'
;input_path='C:\Research\MAVEN\MAVEN_Data\AT_LM\24May13\'
;data_output_path=input_path
;plot_save_path='C:\research\MAVEN\plots\AT_LM\24May13'
;
;mvn_mag_ql, datafile=datafile, input_path=input_path, $
;  data_output_path=data_output_path, plot_save_path=plot_save_path, $
;  /tsmake, /jreplot
;
;*SUBROUTINES CALLED:
;
; mvn_mag_ql_tsmaker.pro
; mvn_mag_ql_jreplot.pro
;
;*NOTES:
;
; text
;
;*MODIFICATION HISTORY:
; 20Mar14 JRE: Updated to accept keywords from new maven_mag_pkts_read.pro
; 22May13 JRE: First draft compiled from previous similar code
; 29May13 JRE: Further revisions and inclusion of mvn_mag_ql_jreplot
;******************************************************************************

pro mvn_mag_ql, datafile=datafile, input_path=input_path, $
    data_output_path=data_output_path, plot_save_path=plot_save_path, pkt_type=pkt_type, $
    tsmake=tsmake, mag1=mag1, mag2=mag2, jreplot=jreplot, tplot=tplot, $
    out_varname=out_varname,delete_save_file=delete_save_file

if keyword_set(tsmake) then $
  mvn_mag_ql_tsmaker, datafile=datafile, input_path=input_path, $
    data_output_path=data_output_path, pkt_type=pkt_type, mag1=mag1, mag2=mag2

;Whether we just made the sts file or did it previously, now restore it.
restore, filename=data_output_path+datafile+'.sav'

;Make plots in the style used during ATLO by the MAG team
; This code is not included in package delivered to SSL and SOC
if keyword_set(jreplot) then begin
  plot_save=plot_save_path+'-'+datafile
  mvn_mag_ql_jreplot, dday, bx, by, bz, samplespersec, calendartime, plot_save
endif

if keyword_set(tplot) then begin
;create a tplot variable jmm, 4-jun-2013
   out_varname = 'mvn_ql_mag'
   if keyword_set(mag1) then out_varname = 'mvn_ql_mag1' $
   else if keyword_set(mag2) then out_varname = 'mvn_ql_mag2' $
   else dprint, 'Both mag1 and mag2 are not set'
   store_data, out_varname, data = {x:time, y:transpose([transpose(bx),transpose(by),transpose(bz)])}
;units and coordinate system?
   data_att = {units:'nT', coord_sys:'Sensor'}
   dlimits = {spec:0, log:0, colors:[2, 4, 6], labels: ['x', 'y', 'z'],  labflag:1, color_table:39, data_att:data_att}
   store_data, out_varname, dlimits = dlimits
endif
;Delete save file
If(keyword_set(delete_save_file)) Then file_delete,data_output_path+datafile+'.sav'


;This is where we deal with down selecting the time series if necessary
; so that plots don't go off scale.
;Currently done manually but will need algorithm
;Actual Mars data will not likely need much down selecting

;This is where we would do calculations like the RMS if that were to be
; included in the quicklook plots.

;This is where tplot variables could be created and stored

;This is where plotting with tplot variables might occur

end
