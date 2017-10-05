;This is intended as a demonstration script of how to use mvn_mag_ql.pro
; and its subroutines. One could change the input variables and execute it
; as an IDL main procedure or simple copy and paste the relevant lines of
; code to the IDL command line.

;;;;;;;;;;;;;;;;;;;
;Example Execution;
;;;;;;;;;;;;;;;;;;;

;.run mvn_mag_ql_script.pro

;;;;;;;;;;;;;;;;;;
;Input Parameters;
;;;;;;;;;;;;;;;;;;

;datafile= String name of the input binary file to be processed
;          Examples:
;           SSL split files 
;             'apid_40_all.dat'
;           L0 MAG data files from the SOC 
;             'mvn_mag_arc_l0_20150803_v1.dat'
;           L0 P&F compiled data files from the SOC
;             '20130524_224257_atlo_l0.dat'

;input_path = Where that datafile is. Note the final slash (either \ or / )is
;               included

;data_output_path = Where the IDL .sav file is saved or to be loaded from                   created during processing.

;plot_save_path = Where a plot made by the jreplot procedure should be saved.
;                    Note there is no final \ or /
;pkt_type = data_source (required) (input) (scalar) (string)
;    Describes the source of the data file.
;    'instrument' - from the instrument, no PFP or spacecraft in path
;    'pfp_eng' - engineering data via the PFP DPU which includes
;          the PFP header
;    'pfp_sci' - science data via the PFP DPU which includes the
;          PFP header
;    'ccsds' - data from the spacecraft which includes the CCSDS
;        and PFP headers


;;;;;;;;;;;;;;;;;;;;;
;Optional Parameters;
;;;;;;;;;;;;;;;;;;;;;                    
                    
;/tsmake = Convert the decommutated data into a proper time series
;           and save it as an IDL save file. Usually yes. Only not included
;           if you've already done that before and want to save the computations.
;                                                   
;/mag1 = Extract and process APID 40 data from a compiled P&F L0 datafile.
;  
;/mag2 = Extract and process APID 41 data from a compiled P&F L0 datafile.
;  
;/jreplot = Make plots in the style used during ATLO by the MAG team. 
;            Not included in code package delivered to SSL and SOC
;

;;;;;;;;;;;;;;;;
;Code Hierarchy;
;;;;;;;;;;;;;;;;

;mvn_mag_ql_script.pro
;   mvn_mag_ql.pro
;       mvn_mag_ql_tsmaker.pro
;           maven_mag_pkts_read.pro
;               bitlis.pro
;               decom_2s_complement.pro
;               marker_search.pro
;               parsestr.pro
;           mvn_spc_met_to_unixtime.pro
;       mvn_mag_ql_jreplot.pro*
;           fsc_color.pro*
;               pickcolorname.pro*
;               error_message.pro*
;           tvread.pro*
; *Not included in code package delivered to SSL and SOC

datafile='mvn_mag_svy_l0_20140319_v001.dat'
pkt_type='ccsds'
;pkt_type='pfp_sci'
;pkt_type='instrument'
input_path='C:\Research\MAVEN\MAVEN_Data\Cruise\Cruciform\'
data_output_path=input_path
plot_save_path='C:\Research\MAVEN\plots\Cruise\Cruciform'

mvn_mag_ql, datafile=datafile, pkt_type=pkt_type, input_path=input_path, $
  data_output_path=data_output_path, plot_save_path=plot_save_path, $
  /jreplot, /mag2;, /tsmake



end