;+
;Function: THM_UNPACK_HED
;	thm_unpack_hed, data_type, hed_array
;
;Purpose:  Unpacks data packed into HED data.
;
;Arguements:
;	DATA_TYPE	STRING, one of the L1 data types (eff, scp, fbk, etc.)
;	HED_ARRAY	BYTE[ N, 16], array of header data.
;
;keywords:
;	None.
;
;Example:
;	get_data, 'tha_fit_hed', data=d_hed
;   hed_data = thm_unpack_hed( 'fit', d_hed.y)
;
;Notes:
;	-- Returns int( 0) if requested DATA_TYPE is not implemented.
;	-- Returns annonymous structure with variable elements if DATA_TYPE is recognized.
;	-- Not all DATA_TYPEs are implemented; implemented data types (APIDs) listed below:
;		FIT (on-board EFI and FGM spin fits, 410),
;		FBK (FilterBank data, 440),
;		EFI waveform (VA?, VB?, EF?; 441,442,443, 445,446,447, 449,44A,44B),
;		SCM waveform (SCF, SCP, SCW; 444; 448; 44C),
;		FGM waveform (FGL, FGH; 460, 461),
;		FFT spectra (FFP, FFW; 44D, 44E).
;
; Modification History:
; Written by J Bonnell, 31 Jan 2007
; Modified by
;  LeContel 2007-05-24 10:39  (Wed, 24 May 2007)
;           Modification for reading scm and efw headers:
;           speed = reform( dh[ *, 14]/16b)
;
; $LastChangedBy: jbonnell $
; $LastChangedDate: 2007-06-16 10:57:56 -0700 (Sat, 16 Jun 2007) $
; $LastChangedRevision: 794 $
; $URL $
;-

function thm_unpack_hed, data_type, dh
; some useful constants for building multi-byte values.
uint_256 = uint( 256)
long_256 = long( 256)

; unpack the portion of the header that doesn't change between APIDs.
apid = reform( uint( ( 32b*dh[ *, 0]/32b))*uint_256 + uint( dh[ *, 1]))
apid_ctr = reform( uint( ( 4b*dh[ *, 2]/2b))*uint_256 + uint( dh[ *, 3]))
app_data_field_len = reform( uint( dh[ *, 4])*uint_256 + uint( dh[ *, 5]))
clock_bytes = reform( dh[ *, 6:9])
subsec_bytes = reform( dh[ *, 10:11])
clock = reform( long( dh[ *, 9]) $
	+ long_256*( long( dh[ *, 8]) $
	+ long_256*( long( dh[ *, 7]) $
	+ long_256*( long( dh[ *, 6])))))
subsec = reform( long( dh[ *, 11]) $
	+ long_256*( long( dh[ *, 10])))

; unpack the parts of the header that are different between APIDs.
; note the use of the SWITCH rather than CASE, allowing for basically identical
; header processing on many of the waveform data types.
switch strlowcase( data_type) of
	'fit':	begin ;	APID 0x410.
		compression = reform( dh[ *, 12]/128b)
		efi_config = reform( dh[ *, 12] and 127b)
		fgm_config = reform( dh[ *, 13] and 127b)
		fgm_range_x = reform( dh[ *, 14]/16b)
		fgm_range_y = reform( dh[ *, 14] and 15b)
		fgm_range_z = reform( dh[ *, 15]/16b)
		fgm_rate = reform( dh[ *, 15] and 7b)
		fgm_rate = 2.^(2+fgm_rate)

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			efi_config:efi_config, fgm_config:fgm_config, $
			fgm_range_x:fgm_range_x, fgm_range_y:fgm_range_y, fgm_range_z:fgm_range_z, $
			fgm_rate:fgm_rate }
		break
	end	; of FIT case.
	'fbk':	begin	; APID 0x440.
		compression = reform( dh[ *, 12]/128b)
		config = reform( dh[ *, 12] and 127b)
		spare_config = reform( dh[ *, 13])

		speed = reform( (dh[ *, 14]/16b) and 7b)
		speed = 2.^( float(speed)-4.)	; filterBank rate, spectra/s.

		fb1_sel = reform( dh[ *, 15]/16b)
		fb2_sel = reform( dh[ *, 15] and 15b)
		fb_sel_str = [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', $
			'E12DC', 'E34DC', 'E56DC', $
			'SCM1', 'SCM2', 'SCM3', $
			'E12AC', 'E34AC', 'E56AC', $
			'UNDEF' ]
		fb1_sel_str = fb_sel_str[ fb1_sel]
		fb2_sel_str = fb_sel_str[ fb2_sel]

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			speed:speed, $
			fb1_sel:fb1_sel, fb1_sel_str:fb1_sel_str, $
			fb2_sel:fb2_sel, fb2_sel_str:fb2_sel_str }
		break
	end	; of FBK (FilterBank) case.
	'vaf':	; APID 0x441.
	'vbf':	; APID 0x442.
	'eff':	; APID 0x443.
	'vap':	; APID 0x445.
	'vbp':	; APID 0x446.
	'efp':	; APID 0x447.
	'vaw':	; APID 0x449.
	'vbw':	begin	; APID 0x44A.
		compression = reform( dh[ *, 12]/128b)
		config = reform( dh[ *, 12] and 127b)
		spare_config = reform( dh[ *, 13])

		speed = reform( dh[ *, 14]/16b)
		speed = 2.^( float(speed) + 1.)	; waveform sample rate, samples/s.

		chan_sel = reform( dh[ *, 15] and 63b)

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			speed:speed, $
			chan_sel:chan_sel }
		break
	end	; of {VAF. VBF, EFF, VAP, VBP, EFP, VAW, VBW} case.
	'scf':	; APID 0x444.
	'scp':	begin	; APID 0x448.
		compression = reform( dh[ *, 12]/128b)
		config = reform( dh[ *, 12] and 127b)
		spare_config = reform( dh[ *, 13])

		speed = reform( dh[ *, 14]/16b)
		speed = 2.^( float(speed) + 1.)	; filterBank rate, spectra/s.

		chan_sel = reform( dh[ *, 15] and 7b)

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			speed:speed, $
			chan_sel:chan_sel }
		break
	end	; of {SCF, SCP} case.
	'efw':	; APID 44B.
	'scw':	begin	; APID 0x44C.
		compression = reform( dh[ *, 12]/128b)
		config = reform( dh[ *, 12] and 127b)
		spare_config = reform( dh[ *, 13])

		speed = reform(dh[ *, 14]/16b)
		speed = 2.^( float(speed) + 1.)	; Samples/s.

		chan_sel = reform( dh[ *, 15])

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			speed:speed, $
			chan_sel:chan_sel }
		break
	end	; of {SCF, SCP} case.
	'ffp':	; APID 0x44D.
	'ffw':	begin	; APID 0x44E.
		compression = reform( dh[ *, 12]/128b)

;		speed = reform(dh[ *, 14]/16b)
		speed = reform( (dh[ *, 14]/16b) and 7b)
		speed = 2.^( float(speed)-4.)	; filterBank rate, spectra/s.

;		nbins = reform( 16b*dh[ *, 14]/64b)
		nbins = reform( (dh[ *, 14]/4b) and 3b)
		nbins = 16.*2.^( float(nbins))

;		ff1_sel = reform( uint( dh[ *, 13]/32b) + uint_256*uint(64b*dh[ *, 12]/64b))
;		ff2_sel = reform( 8b*dh[ *, 13]/8b)

;		ff3_sel = reform( uint( dh[ *, 15]/32b) + uint_256*uint(64b*dh[ *, 14]/64b))
;		ff4_sel = reform( 8b*dh[ *, 15]/8b)

		if (strlowcase( data_type) eq 'ffw') then begin
			ff1_sel = reform( dh[ *, 13] and 31b)
			ff2_sel = reform( dh[ *, 13]/32b + (dh[ *, 12] and 3b)*8b)
			ff3_sel = reform( dh[ *, 15] and 31b)
			ff4_sel = reform( dh[ *, 15]/32b + (dh[ *, 14] and 3b)*8b)
		endif else if (strlowcase( data_type) eq 'ffp') then begin
			ff1_sel = reform( dh[ *, 15] and 31b)
			ff2_sel = reform( dh[ *, 15]/32b + (dh[ *, 14] and 3b)*8b)
			ff3_sel = reform( dh[ *, 13] and 31b)
			ff4_sel = reform( dh[ *, 13]/32b + (dh[ *, 12] and 3b)*8b)
		endif else begin	; should not get here.
		endelse

		ff_sel_str = [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', $
			'E12DC', 'E34DC', 'E56DC', $
			'SCM1', 'SCM2', 'SCM3', $
			'E12AC', 'E34AC', 'E56AC', $
			'UNDEF', $
			'EXB', 'EDOTB', 'SCMXB', 'SCMDOTB', $
			'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF', $
			'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF', 'UNDEF' ]

		ff1_sel_str = ff_sel_str[ ff1_sel]
		ff2_sel_str = ff_sel_str[ ff2_sel]
		ff3_sel_str = ff_sel_str[ ff3_sel]
		ff4_sel_str = ff_sel_str[ ff4_sel]

		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			speed:speed, $
			ff1_sel:ff1_sel, ff1_sel_str:ff1_sel_str, $
			ff2_sel:ff2_sel, ff2_sel_str:ff2_sel_str, $
			ff3_sel:ff3_sel, ff3_sel_str:ff3_sel_str, $
			ff4_sel:ff4_sel, ff4_sel_str:ff4_sel_str }
		break
	end	; of {FFP, FFW} (FFT Spectra) case.
	'fgl':	; APID 0x460.
	'fgh':	begin	; APID 0x461.
		compression = reform( dh[ *, 12]/128b)
		fgm_config = reform( dh[ *, 12] and 127b)
		fgm_msg = reform( dh[ *, 13])
		fgm_range_x = reform( dh[ *, 14]/16b)
		fgm_range_y = reform( dh[ *, 14] and 15b)
		fgm_range_z = reform( dh[ *, 15]/16b)
		fgm_rate = reform( dh[ *, 15] and 7b)
		if strlowcase( data_type) eq 'fgh' then $
			fgm_rate = bytarr( n_elements( fgm_rate)) + 5b
		fgm_rate = 2.^(2+fgm_rate)
		hed_data = { data_type:data_type, $
			apid:apid, apid_ctr:apid_ctr, app_data_field_len:app_data_field_len, $
			clock_bytes:clock_bytes, subsec_bytes:subsec_bytes, $
			clock:clock, subsec:subsec, $
			compression:compression, $
			fgm_config:fgm_config, fgm_msg:fgm_msg, $
			fgm_range_x:fgm_range_x, fgm_range_y:fgm_range_y, fgm_range_z:fgm_range_z, $
			fgm_rate:fgm_rate }
		break
	end	; of {FGL, FGH} (FGM Waveform) case.

	else: begin
		hed_data = 0
	end	; of ELSE case.
	endswitch

return, hed_data
end
