;+
;NAME:
;  show_acknowledgement
;
;PURPOSE:
;  Show data usage policy for each observation data.
;
;EXAMPLE:
;  Answer=show_acknowledgement(instrument=instrument, datatype=datatype, $
;	par_names=par_names)
;
;Code:
;  A. Shinbori, 13/01/2011.
;  
;Modifications:
;  Y.-M. Tanaka, 11/05/2012
;-

function show_acknowledgement, instrument=instrument, datatype=datatype, $
	par_names=par_names

  ;----- Title of popup window -----;
  title='Rules of Data Use:'

  ;----- keyword check -----;
  if (not keyword_set(par_names)) then return,0

  ;----- Get acknowledgement message -----;
  get_data, par_names[0], dlimit=str
  if (instrument eq 'EISCAT_radar') or (instrument eq 'Imaging_Riometer') or $
     (instrument eq 'SuperDARN_radar#') then begin
     theMessage = [ $
                str.cdf.gatt.LOGICAL_SOURCE_DESCRIPTION, '', $
                'PI: ', str.cdf.gatt.PI_name, '', $
                'Affiliations:', str.cdf.gatt.pi_affiliation, '', $
                'Rules of the Road: ',str.cdf.gatt.rules_of_use, '', $
                str.cdf.gatt.LINK_TEXT, str.cdf.gatt.HTTP_LINK]
  endif else if (instrument eq 'Low_Frequency_radio_transmitter') or $
     (instrument eq 'HF_Solar_Jupiter_radio_spectrometer') then begin
     theMessage = [ $
                str.cdf.gatt.LOGICAL_SOURCE_DESCRIPTION, '', $
                'PI and HOST PI(s):', str.cdf.gatt.PI_name, '', $
                'Affiliations:', str.cdf.gatt.pi_affiliation, '', '', $
                'Rules of the Road:',str.cdf.gatt.text, $
                '', str.cdf.gatt.LINK_TEXT, str.cdf.gatt.HTTP_LINK ] 
  endif else if datatype eq 'NIPR#' then begin
     theMessage = [ $
                str.cdf.gatt.LOGICAL_SOURCE_DESCRIPTION, '', $
                'Information about '+str.cdf.gatt.station_code, '', $
                'PI:', str.cdf.gatt.pi_name, '', $
                'Affiliations:', str.cdf.gatt.pi_affiliation, '', $
                'Rules of the Road: ',str.cdf.gatt.rules_of_use, '', $
                str.cdf.gatt.LINK_TEXT, str.cdf.gatt.HTTP_LINK]
  endif else if (datatype eq '210mm#') or (datatype eq 'ISEE#') or $
     (datatype eq 'magdas#') then begin
     theMessage = [ $
                str.cdf.gatt.LOGICAL_SOURCE_DESCRIPTION, '', $
                'Information about '+str.cdf.gatt.station_code, '', $
                'PI and HOST PI(s):', str.cdf.gatt.pi_name, '', $
                'Affiliations:', str.cdf.gatt.pi_affiliation, '', '', $
                'Rules of the Road:',str.cdf.gatt.text, $
                '', str.cdf.gatt.LINK_TEXT, str.cdf.gatt.HTTP_LINK ] 
  endif else begin
     theMessage=str.data_att.acknowledgment
  endelse

  ;----- If OS is Windows, divide the message into a string array -----;
  if (strlowcase(!version.os_family) ne 'windows') then begin
     theMessage=str2arr_maxlet(theMessage, maxlet=100)
  endif

  Result = dialog_message(theMessage, /cancel, /information, $
                                /center, title=title)

  return, Result

end


