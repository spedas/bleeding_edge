;
; thm_efi_cal_file_template provides a template for the text
; calibration files. This is intended to replace the reliance on IDL
; save files in the calibration directories. Note that the template is
; the same for all probes. If in the future, the template is different
; for different probes, the change should be made here.
; 2010-10-05, jmm, jimm@ssl.berkeley.edu
Function thm_efi_cal_file_template
  version = 1.0
  datastart = 1L
  delimiter = 32b
  missingvalue = !values.f_nan
  commentsymbol = ';'
  fieldcount = 36L
  fieldtypes = [7L, 3L, 3L, 3L, 3L, 3L, 3L, 4L, 4L, 4L, 4L, 4L, 4L, 7L, 3L, 3L, 3L, 4L, $
                4L, 4L, 3L, 3L, 3L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 4L, 7L]
  fieldnames = ['cal_par_time', 'v_offset', 'FIELD03', 'FIELD04', 'FIELD05', 'FIELD06', 'FIELD07', 'v_gain', 'FIELD09', 'FIELD10', $
                'FIELD11', 'FIELD12', 'FIELD13', 'v_unit', 'edc_offset', 'FIELD16', 'FIELD17', 'edc_gain', 'FIELD19', 'FIELD20', $
                'eac_offset', 'FIELD22', 'FIELD23', 'eac_gain', 'FIELD25', 'FIELD26', 'boom_length', 'FIELD28', 'FIELD29', $
                'boom_shorting_factor', 'FIELD31', 'FIELD32', 'dsc_offset', 'FIELD34', 'FIELD35', 'e_unit']
  fieldlocations = [0L, 20L, 22L, 24L, 26L, 28L, 30L, 34L, 44L, 54L, 64L, 74L, 84L, 95L, 97L, 99L, 101L, 105L, $
                    117L, 129L, 141L, 143L, 145L, 149L, 159L, 169L, 179L, 184L, 189L, 195L, 204L, 213L, 217L, 221L, 225L, 230L]
  fieldgroups = [0L,  1L,  1L,  1L,  1L,  1L,  1L,  7L,  7L,  7L,  7L,  7L,  7L, 13L, 14L, 14L, 14L, 17L, $
                 17L, 17L, 20L, 20L, 20L, 23L, 23L, 23L, 26L, 26L, 26L, 29L, 29L, 29L, 32L, 32L, 32L, 35L]

  templ = {version:version, datastart:datastart, delimiter:delimiter, missingvalue:missingvalue, $
           commentsymbol:commentsymbol, fieldcount:fieldcount, fieldtypes:fieldtypes, fieldnames:fieldnames, $
           fieldlocations:fieldlocations, fieldgroups:fieldgroups}
  Return,  templ
End

;+
;	Procedure:
;				thm_get_efi_cal_pars
;
;	Purpose:
;				Given the particular EFI waveform data type, and begin and end of the time interval, return the waveform RAW->PHYS
;				transformation parameters.
;
;	Calling Sequence:
;				thm_get_efi_cal_pars, times, name, probes, cal_pars=cal_pars
;
;	Arguements:
;		TIMES: 		Input, DOUBLE, time basis of data since THEMIS epoch.
;		NAME:		Input, STRING, waveform data type indicator.
;               PROBES: 	Input, SCALAR STRING, name of THEMIS probe (i.e., only one probe -- 'a','b',...).
;
;       Keywords:
;               CAL_PARS: 	Output, STRUCT, see Notes below for elements.
;               /TEST: 		Input, numeric, 0 or 1.  Disables selected /CONTINUE to MESSAGE.  For QA testing.
;
;Modifications:
;  Added FILE_RETRIEVE() mechanism so that this routine can read the
;    template and calibration files from the THEMIS local data directory.
;    Also, added the "probes" parameter for the above purpose,
;    W.M.Feuerstein, 2/27/2008.
;  Changed "History" to "Modifications" in header, commented out all local
;    calibration parameters, redifined ASCII template, now retrieving all
;    calibration parameters from calibration files (these were expanded last
;    Friday).  Updated doc'n, WMF, 3/17/08.
;  Implemented EAC/EDC gain conditional based on 1st element of TH?_EF?_HED_AC
;    tplot variable, updated doc'n, WMF, 3/18/08.
;  Inserted modern compile options, made ADC offsets integers in calibration
;    files, updated read templates, WMF, 3/20/08.
;  Fixed potential logical vs. bitwise conditional bug, updated calibration
;    fields, WMF, 3/21/2008.
;  Preparing for time-dependent calibration params. and AC/DC coupling gain
;    conditional -- code still commented, WMF, 4/4/2008 (F).
;  Replaced PRINT w/ MESSAGE for EAC/DC gain conditional warning. Added TEST kw
;    (default = 0) to disable CONTINUE kw to selected MESSAGE commands.  If a
;    non-EFI datatype is passed then routine will stop, WMF, 4/7/2008 (M).
;  Fixed typo "Defaulting to EAC gain"=>"...EDC...", rephrased, WMF,
;    4/9/2008 (W).
;  Reformatted, WMF, 4/10/2008 (Th).
;  Corrected an error to assigning the field gain to the output structure --
;    would only affect AC coupled data, WMF, 4/11/2008.
;  Implemented time-dependent EAC/EDC gain conditional, WMF, 4/22/2008 (Tu).
;  Removed "[0]" in some of the CP structure fields (moving to T-D calibration
;    parameters), clipping CAL_PAR_TIME to TIMES, WMF, 4/23/2008 (W).
;  Added 'efs' datatype to switch statement, WMF, 5/12/2008 (M).
;  Stripped out time-dependent EAC/EDC gain conditional handling and moved to
;    THM_CAL_EFI.PRO.  Also, now passing EAC_GAIN and EDC_GAIN instead of
;    just GAIN for the e?? datatype, WMF, 5/21 - 6/5/2008.
;  Fixed crash on reading calibration files with only one line of data, WMF, 8/6/2008.
;  Renamed from "thm_get_efi_cal_pars_td.pro" to "thm_get_efi_cal_pars.pro", WMF, 9/9/2008.
;
;	Notes:
;	-- use of TBEG and TEND for time-dependent calibration parameters is not currently implemented!
;	-- Difference in gain between DC and AC coupled E-field data implemented, but not calibrated yet (as of 6/18/2009)!
;	-- Elements of CAL_PARS are picked and chosen from the pertinent calibration file depending on NAME.  See switch statement in code.
;
; $LastChangedBy: michf $
; $LastChangedDate: 2008-05-15 11:17:41 -0700 (Thu, 15 May 2008) $
; $LastChangedRevision: 3095 $
; $URL $
;-
pro thm_get_efi_cal_pars, times, name, probes, cal_pars=cal_pars, test=test


compile_opt idl2, strictarrsubs              ;Bring this routine up to date.

if ~keyword_set(test) then test = 0   ;Certain MESSAGE commands /continue
                                      ;by default.

; nominal EFI waveform calibration parameters;
;	JWB, UCBSSL, 7 Feb 2007.
;cal_par_time = '2002-01-01/00:00:00' ;This now obtained from cal. file.

;These are now gotten from cal. file:
;====================================
;units_edc = 'V'	; <--- NOTE that E-field units are Volts!!!
;units_eac = 'V'	; <--- NOTE that E-field units are Volts!!!
;units_v = 'V'


;Smallest ADC step:
;===================
;adc_factor = 1.0/float( 2L^16 - 1L)  ;Now folded into cal. file.

;2 booms X max. voltage scale X smallest ADC step:
;=================================================
;gain_v = 2.0*105.2*adc_factor  ;Transferred to cal. file.
;gain_edc = 2.0*15.0*adc_factor ;Transferred to cal. file.
;gain_eac = 2.0*2.54*adc_factor ;Transferred to cal. file.


;Read in boom shorting factors, spin-independent, and
;spin-dependent offsets:
;=======================
;thx = 'tha'
;To be propagated to all satellites like this:
;=============================================
thx = 'th' + probes[0]
;
;To be propagated to all satellites like this:
;=============================================
cal_relpathname = thx+'/l1/eff/0000/'+thx+'_efi_calib_params.txt'
cal_file = spd_download(remote_file=cal_relpathname, _extra=!themis)
;cal_templ_relpathname = thx+'/l1/eff/0000/'+thx+'_efi_calib_templ.sav'
;
;cal_templ_file = file_retrieve(cal_templ_relpathname, _extra=!themis)
;restore,cal_templ_file
templ = thm_efi_cal_file_template() ;replaces save files, 5-Oct-2010
str=read_ascii(cal_file,template=templ)


;;==============================
;;Make the zeroth dimension the time dimension for all
;;fields whose dimension is > 1:
;;==============================
;tag_names=tag_names(str)
;strp=create_struct(tag_names[0],str.(0))
;for i=1,n_elements(tag_names)-1 do begin
;  if size((str.(i)),/n_dimensions) gt 1 then begin
;    strp=create_struct(strp,tag_names[i],transpose(str.(i)))
;  endif else strp=create_struct(strp,tag_names[i],str.(i))
;endfor
;str=temporary(strp)

;******************************************************************
;Arrange so that the zeroth dimension is the time dimension
;for all fields that *can potentially* have two or more dimensions:
;******************************************************************
strp=create_struct('cal_par_time',str.cal_par_time)
strp=create_struct(strp,'v_offset',transpose(str.v_offset))
strp=create_struct(strp,'v_gain',transpose(str.v_gain))
strp=create_struct(strp,'v_unit',str.v_unit)
strp=create_struct(strp,'edc_offset',transpose(str.edc_offset))
strp=create_struct(strp,'edc_gain',transpose(str.edc_gain))
strp=create_struct(strp,'eac_offset',transpose(str.eac_offset))
strp=create_struct(strp,'eac_gain',transpose(str.eac_gain))
strp=create_struct(strp,'boom_length',transpose(str.boom_length))
strp=create_struct(strp,'boom_shorting_factor',transpose(str.boom_shorting_factor))
strp=create_struct(strp,'dsc_offset',transpose(str.dsc_offset))
strp=create_struct(strp,'e_unit',str.e_unit)
str=temporary(strp)


;**********************************************
;Clip calibration parameters to range of TIMES:
;**********************************************
;Find relevant (that contain >= 1 data point) time indexes to the calibration parameters:
;========================================================================================
cptd = time_double(str.cal_par_time)     ;"Calibration Parameter Time Double."
ncptd=n_elements(cptd)                   ;"# CPTD".
if ~(~size(w,/type)) then foo=temporary(wp)
for i=0,ncptd-1 do begin
  if i ne ncptd-1 then begin
    w = where(cptd[i] le times and times lt cptd[i+1])
  endif else begin
    w = where(cptd[i] le times)
  endelse
  if ~(~size(wp,/type)) and w[0] ne -1 then wp=[wp,i] else begin
    if w[0] ne -1 then wp=[i]
  endelse
endfor
w=wp
;
;Keep relevant indexes (clip):
;=============================
tag_names=tag_names(str)
strp=create_struct(tag_names[0],(str.(0))[w])
for i=1,n_elements(tag_names)-1 do begin
  if size(str.(i),/n_dimensions) eq 2 then begin
    strp=create_struct(strp,tag_names[i],(str.(i))[w,*])
  endif else begin
    strp=create_struct(strp,tag_names[i],(str.(i))[w])
;    case 1  of
;      n_elements(w) ge 2: strp=create_struct(strp,tag_names[i],(str.(i))[w])
;      n_elements(w) eq 1: strp=create_struct(strp,tag_names[i],(str.(i)))
;    endcase
  endelse
endfor
str=temporary(strp)


;Some fields are common to all datatypes:
;========================================
cal_par_time=str.cal_par_time
boom_length=str.boom_length
boom_shorting_factor=str.boom_shorting_factor


switch strlowcase( name) of
  'vaf':
  'vbf':
  'vap':
  'vbp':
  'vaw':
  'vbw': begin
    cal_pars = { $
      cal_par_time:cal_par_time, $
      gain:str.v_gain, $
      offset:str.v_offset, $
      units:str.v_unit, $
      boom_length:boom_length, $
      boom_shorting_factor:boom_shorting_factor $
      }

    break
  end
  'eff':
  'efp':
  'efw': begin
    ;
    cal_pars = { $
      cal_par_time:cal_par_time, $
      ;gain:gain, $
      edc_gain:str.edc_gain, $
      eac_gain:str.eac_gain, $
      offset:str.edc_offset, $
      units:str.e_unit, $
      boom_length:boom_length, $
      boom_shorting_factor:boom_shorting_factor, $
      dsc_offset:str.dsc_offset $
      }

    break
  end
  'efs': begin
    ;================================
    ;'efs' data is always DC coupled.
    ;================================
    gain=str.edc_gain
    ;
    cal_pars = { $
      cal_par_time:cal_par_time, $
      gain:gain, $
      offset:str.edc_offset, $
      units:str.e_unit, $
      boom_length:boom_length, $
      boom_shorting_factor:boom_shorting_factor, $
      dsc_offset:str.dsc_offset $
      }

    break
  end
  else:	begin
	  message,'NOT AN EFI DATATYPE!'
  end
endswitch

;return
end
