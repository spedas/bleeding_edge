;***************************************************************************** 
;*NAME:
;
; mvn_mag_ql_tsmaker.pro
;
;*PURPOSE:
;
; Procedure for creating L0 time series (TS) of MAG files from decommutated
; L0 MAVEN MAG binary data.
; 
;*PARAMETERS:
;
; text
;
;*EXAMPLES:
;
; text
;
;*SUBROUTINES CALLED:
;
; maven_mag_pkts_read.pro
; mvn_spc_met_to_unixtime.pro
;
;*NOTES:
;
; Typically called by mvn_mag_ql.pro
; 
; This file includes the source code for cmsystime.pro, its subroutines,
; and the accompanying documentation.
;
;*MODIFICATION HISTORY:
; 16Jul13 JRE: Modified to use CMSYSTIME /extended
; 22May13 JRE: First draft compiled from previous similar code
; 29May13 JRE: Further revisions and inclusion of cmsystime into file
; 17Dec13 JRE: Removed cmsystime from file
; 17Dec13 JRE: Updated to default to ccsds decom structure type
; 11Feb14 JRE: Added keyword for decom structure types
;******************************************************************************

pro mvn_mag_ql_tsmaker, datafile=datafile, input_path=input_path, $
    data_output_path=data_output_path, stsmake=stsmake, pkt_type=pkt_type,$
    mag1=mag1, mag2=mag2

if keyword_set(datafile) NE 1 then begin
  datafile=''
  read, prompt='Datafile?', datafile
endif
if keyword_set(input_path) NE 1 then begin
  input_path=''
  read, prompt='Input path (with final \)?', input_path
end
if keyword_set(data_output_path) NE 1 then begin
  data_output_path=''
  read, prompt='Output path (with final \)?', data_output_path
end

maven_mag_pkts_read, datafile, data, pkt_type, input_path=input_path

if keyword_set(mag1) EQ 1 then begin
  dataorig=data
  mag1=where(data.pfp_header.apid_hex EQ '40')
  data=data[mag1]
endif

if keyword_set(mag2) EQ 1 then begin
  dataorig=data
  mag2=where(data.pfp_header.apid_hex EQ '41')
  data=data[mag2]
endif

;list of outputs
bx=1.
by=1.
bz=1.
time=1d
range=1
packet_type=1
samplespersec=1
framecounter=1

numpkts=n_elements(data.pfp_header.second)

bxraw=data.science.cnts.x
byraw=data.science.cnts.y
bzraw=data.science.cnts.z

;2 = science data without differencing
;3 = science data with differencing
pkt_type=data.header.pkt_type

;this gives amount of averaging done on science vectors
; see FSW specifications
avg_n=data.header.avg_n
maxsample=32 ;change this if we ever get 256 Hz data

;Calculating time from P&F clock
;epoch=946771200.0D ;=2-Jan-2000, 0000GMT for data before Dec2012
epoch=946728000.0D ;=1-Jan-2000, 1200GMT for data after Dec2012
timeraw=data.header.pkt_time+epoch+data.header.time_mod/65536.0D
;This method is Davin's style but doesn't correctly deal with
; earlier epoch data (from prior to Apr or Dec 2012) 
;met=data.header.pkt_time+data.header.time_mod/65536.0D
;timeraw=mvn_spc_met_to_unixtime(met) 

rangeraw=data.header.rng

pkt_seq=data.header.pkt_seq

for i=0L, numpkts-1L do begin
  
  currentdelta=1./(maxsample/2^avg_n[i])
   
  if pkt_type[i] EQ 2 then numvecsperpkt=32L else $
                           numvecsperpkt=64L
  
  timetemp=dblarr(numvecsperpkt) 
  for j=0d, numvecsperpkt-1d do begin
    timetemp[j]=timeraw[i]+(currentdelta*j)
  endfor 
  
  rangetemp=intarr(numvecsperpkt)
  rangetemp[*]=rangeraw[i]
  
  samplespersec_temp=intarr(numvecsperpkt)
  samplespersec_temp[*]=maxsample/2^avg_n[i]
        
  packet_type_temp=intarr(numvecsperpkt)
  packet_type_temp[*]=pkt_type[i]      
        
  framecounter_temp=intarr(numvecsperpkt)      
  framecounter_temp[*]=pkt_seq[i]
  
  bxtemp=bxraw[0:numvecsperpkt-1,i]
  bytemp=byraw[0:numvecsperpkt-1,i]
  bztemp=bzraw[0:numvecsperpkt-1,i]

  if pkt_type[i] EQ 3 then begin
    
    for j=1, 63 do begin
      bxfull=bxtemp[j-1]+bxtemp[j]
      bxtemp[j]=bxfull
      byfull=bytemp[j-1]+bytemp[j]
      bytemp[j]=byfull
      bzfull=bztemp[j-1]+bztemp[j]
      bztemp[j]=bzfull
    endfor

  endif

  bx=[bx, bxtemp]
  by=[by, bytemp]
  bz=[bz, bztemp]
  time=[time, timetemp]
  range=[range, rangetemp] 
  packet_type=[packet_type, packet_type_temp]  
  samplespersec=[samplespersec, samplespersec_temp]
  framecounter=[framecounter, framecounter_temp] 
   
endfor

numtotal=n_elements(bx)

;Remove initial zeros
bx=bx[1:numtotal-1]
by=by[1:numtotal-1]
bz=bz[1:numtotal-1]
time=time[1:numtotal-1]
range=range[1:numtotal-1]
packet_type=packet_type[1:numtotal-1]
samplespersec=samplespersec[1:numtotal-1]
framecounter=framecounter[1:numtotal-1]

;Apply scale factors
scalefactor=dblarr(numtotal)
range0=where(range EQ 0)
range1=where(range EQ 1)
range3=where(range EQ 3)
if range0[0] NE -1 then scalefactor[range0]=0.015625d
if range1[0] NE -1 then scalefactor[range1]=0.625d
if range3[0] NE -1 then scalefactor[range3]=2d
bx=bx*scalefactor
by=by*scalefactor
bz=bz*scalefactor

;Make full array calendar time 
calendartime=cmsystime(time, /extended)
day=float(strmid(calendartime, 8, 2))
hour=float(strmid(calendartime, 16, 2))
minute=float(strmid(calendartime, 19, 2))
seconds=double(strmid(calendartime, 22, 9))  
;dhour=hour+minute/60.+seconds/3600.
dday=day+hour/(24d)+minute/(60d)/(24d)+seconds/(24d)/(3600d)

save, bx, by, bz, time, calendartime, dday, range, samplespersec, packet_type, framecounter, $
  filename=data_output_path+datafile+'.sav'

end
