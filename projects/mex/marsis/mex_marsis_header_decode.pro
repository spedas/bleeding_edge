;+
; PROCEDURE:
;       mex_marsis_header_decode
; PURPOSE:
;       Decodes header info. of AIS RDR data
;       https://space.physics.uiowa.edu/pds/MEX-M-MARSIS-3-RDR-AIS-V1.0/LABEL/AIS_FORMAT.FMT
; CALLING SEQUENCE:
;       h = mex_marsis_header_decode(byt80)
; INPUTS:
;       bytarr(80) or bytarr(160,80) or bytarr(160,80,N)
; KEYWORDS:
;       
; CREATED BY:
;       Yuki Harada on 2022-06-30
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function mex_marsis_header_decode, byt80

s = size(byt80)
if s[0] eq 1 and s[1] eq 80 then begin
   nfreq = 1
   ndata = 1
endif else if s[0] eq 2 and s[1] eq 160 and s[2] eq 80 then begin
   nfreq = 160
   ndata = 1
endif else if s[0] eq 3 and s[1] eq 160 and s[2] eq 80 then begin
   nfreq = 160
   ndata = s[3]
endif else begin
   dprint,'Input must be bytarr(80) or bytarr(160,80) or bytarr(160,80,N).'
   dprint,'Returning...'
   return,-1
endelse



for idata=0,ndata-1 do begin
   for ifreq=0,nfreq-1 do begin
      if nfreq eq 1 then bytdum = byt80 $
      else bytdum = reform(byt80[ifreq,*,idata])
;;; https://space.physics.uiowa.edu/pds/MEX-M-MARSIS-3-RDR-AIS-V1.0/LABEL/AIS_FORMAT.FMT

SCLK_SECOND = ulong(reverse(bytdum[0:3]),0)
  ;; DESCRIPTION             = "Spacecraft clock counter of onboard seconds,
  ;;                            since the epoch of May 3, 2003 (123) at which
  ;;                            the first pulse of a sounding set is 
  ;;                            transmitted.  This value is typically referred 
  ;;                            to as the frame time. Since 160 pulses are
  ;;                            transmitted during the collection of a single
  ;;                            frame's worth of measurements, this value is
  ;;                            almost always constant for each set of 160 
  ;;                            records."
SCLK_PARTITION = uint(reverse(bytdum[4:5]),0)
  ;; DESCRIPTION             = "Spacecraft clock counter partition of onboard
  ;;                            counter roll-over/reset.  Zero or one
  ;;                            indicates the counter is in the first
  ;;                            partition.  See the NAIF Spice documentation."
SCLK_FINE = uint(reverse(bytdum[6:7]),0)
  ;; DESCRIPTION             = "Spacecraft clock counter of onboard fractions
  ;;                            of a second with one fraction being 1/65536.
  ;;                            This is the sub-seconds portion of the frame
  ;;                            time and is thus also constant for 160 records"
SCET_DAYS = ulong(reverse(bytdum[8:11]),0)
  ;; DESCRIPTION             = "Spacecraft event time in days since
  ;;                            1958-001T00:00:00Z.  This is the historical
  ;;                            epoch used since the launch of the first U.S.
  ;;                            satellite Explorer I with Dr. James Van Allen's
  ;;                            (University of Iowa) cosmic-ray instrument as
  ;;                            the principal element of the payload, resulting
  ;;                            in the discovery of the Van Allen Radiation
  ;;                            Belts."
SCET_MSEC = ulong(reverse(bytdum[12:15]),0)
  ;; DESCRIPTION             = "Spacecraft event time in milliseconds of day.
  ;;                            SCET_DAYS and SCET_MSEC are provided to
  ;;                            accurately time tag the data in UTC without
  ;;                            the need for calls to the spice kernel."
SCET_STRING = string(bytdum[24:47])
  ;; DESCRIPTION             = "Spacecraft event time of the first transmit pulse
  ;;                            in a set.  Pulse sets typically consist of 160
  ;;                            frequencies which are triggered sequentially with
  ;;                            7.8571 milliseconds between pulses."
PROCESS_ID = bytdum[48]
  ;; DESCRIPTION             = "The seven bits from the 20,3 telemetry packet
  ;;                            header which determine the instrument process id.
  ;;                            0x4D (77d) = Subsurface Sounder (SS1 to SS4)
  ;;                            0x4E (78d) = Active Ionospheric Sounder (AIS)
  ;;                            0x4F (79d) = Calibration (CAL)
  ;;                            0x50 (80d) = Receive Only (RCV)"
INSTRUMENT_MODE = bytdum[49]
  ;; DESCRIPTION             = "The bits from the 20,3 telemetry packet header
  ;;                            used to determine the instrument data type and
  ;;                            mode selection."
TRANSMIT_POWER = bytdum[59]
  ;; DESCRIPTION             = "The transmit power level, expressed as the
  ;;                            power supply regulation voltage for the
  ;;                            final power amplifier output.
  ;;                              0x00  (0d) = minimum transmit power  2.5V
  ;;                              0x0F (15d) = maximum transmit power 40.0V "
FREQUENCY_TABLE_NUMBER = bytdum[60]
  ;; DESCRIPTION             = "The Active Ionospheric Sounder may select
  ;;                            one of sixteen frequency tables to use during
  ;;                            transmit.  Each table has 160 frequencies
  ;;                            that are transmitted during an AIS capture.
  ;;                            Table 0 is the default table"
FREQUENCY_NUMBER = bytdum[61]
  ;; DESCRIPTION             = "The frequency number from the table, ranging
  ;;                            from 0 to 159."
BAND_NUMBER = bytdum[62]
  ;; DESCRIPTION             = "The band that was selected to receive the echo.
  ;;                              0 = band 0      3 = band 3
  ;;                              1 = band 1      4 = band 4
  ;;                              2 = band 2"
RECEIVER_ATTENUATION = bytdum[63]
  ;; DESCRIPTION             = "The receiver attenuation for band selected
  ;;                            measured in dB."
FREQUENCY = float(reverse(bytdum[76:79]),0)
  ;; DESCRIPTION             = "The frequency of the transmit pulse"




h80 = { $
      SCLK_SECOND:SCLK_SECOND, $
      SCLK_PARTITION:SCLK_PARTITION, $
      SCLK_FINE:SCLK_FINE, $
      SCET_DAYS:SCET_DAYS, $
      SCET_MSEC:SCET_MSEC, $
      SCET_STRING:SCET_STRING, $
      PROCESS_ID:PROCESS_ID, $
      INSTRUMENT_MODE:INSTRUMENT_MODE, $
      TRANSMIT_POWER:TRANSMIT_POWER, $
      FREQUENCY_TABLE_NUMBER:FREQUENCY_TABLE_NUMBER, $
      FREQUENCY_NUMBER:FREQUENCY_NUMBER, $
      BAND_NUMBER:BAND_NUMBER, $
      RECEIVER_ATTENUATION:RECEIVER_ATTENUATION, $
      FREQUENCY:FREQUENCY }

if size(header,/type) eq 0 then header = replicate(h80,nfreq,ndata)
header[ifreq,idata] = h80

   endfor                       ;- ifreq
endfor                          ;- idata



return,reform(header)




end
