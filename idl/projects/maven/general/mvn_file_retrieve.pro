function mvn_file_retrieve,trange=trange,verbose=verbose, $
   DPU=DPU,ATLO=ATLO,L0=L0,source=source,pformat=pformat,realtime=realtime,no_download=no_download,name=name,no_server=no_server


message,'This routine has been deprecated. Use mvn_pfp_file_retrieve instead'


source = mvn_file_source(source)
serverdir = source.remote_data_dir
localdir = source.local_data_dir

;message,"Don't use this routine yet - Penalty could be deleted files!"

if not keyword_set(trange) then trange= systime(1)    ; Gets the most recent file generally

if not keyword_set(pformat) then begin
   if keyword_set(L0) then name='L0'   ;pformat = 'maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_????????_v?.dat'          ; Daily files
   if keyword_set(ATLO) then begin
      name = 'ATLO'
      if keyword_set(L0) then name='ATLO-L0'
   endif
   if keyword_set(DPU) then name='DPU'   ;pformat='maven/dpu/prelaunch/FM/????????_??????_*/commonBlock_*.dat'  ;    Use for calibration data
   if keyword_set(realtime) then name = 'RT'
      if 0 then begin
         localdir = '~/RealTime/'
         serverdir = ''
         pformat= 'CMNBLK_*.dat'
      endif 
   if not keyword_set(name) then begin
      if time_double(trange[0]) lt time_double('2012-12-1') then name = 'DPU'  else name = 'ATLO'
   endif

   case name of
   'DPU'     :  pformat='maven/prelaunch/dpu/prelaunch/FM/????????_??????_*/commonBlock_*.dat'     ; SEP TV and calibration and all non S/C testing
   'ATLO'    :  pformat='maven/prelaunch/dpu/prelaunch/live/flight/Split_At_*/initial/common_block.dat'  ; 
   'ATLO-L0' :  pformat='maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_????????_v?.dat'          ; daily from SOC
   'RT'      :  pformat='maven/prelaunch/sep/prelaunch_tests/realtime/CMNBLK_*.dat'
   'RT-L0'   :  pformat='maven/prelaunch/dpu/prelaunch/ATLO/*_atlo_l0.dat'
   'RTC-L0'  :  pformat='maven/ITF/CruisePhase_SOCRealtime_LevelZero/2013????_??????_cruise_l0.dat'
   'RTC-CB'  :  pformat='maven/ITF/CruisePhase_SOCRealtime_SplitFiles/Split_At_20??????_??????/initial/common_block.dat'
   ;http://sprg.ssl.berkeley.edu/data/maven/ITF/CruisePhase_SOCRealtime_SplitFiles/Split_At_20140107_213857/initial/common_block.dat
   else :   message,'Error'
   endcase
endif

dprint,dlevel=2,verbose=verbose,/phelp,pformat
;no_download = 1
if keyword_set(no_server) then serverdir=''
;serverdir=''  ; disable temporarily
files = file_search_plus(localdir,pformat,trange=trange,verbose=verbose,serverdir=serverdir,no_download=no_download)

dprint,dlevel=2,verbose=verbose,/phelp,files
return,files
end