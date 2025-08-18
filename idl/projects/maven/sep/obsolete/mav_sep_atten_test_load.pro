; This is to read files created by the GSE for MAY the SEP attenuator life test

pro mav_sep_atten_test_load



source = mav_file_source()
pathname = 'maven/sep/test/atten/actTest_20110216.dat'

file = file_retrieve(pathname,_extra= source)

string1 = 'gh'
String2 = string1
openr,unit,file,/get_lun
Date = 'na'
Time = 'na'
Pulse_duration =  sqrt (-9.3)
side='na'; actuating side A (B)means pulling the attenuator out (in)
sense_A =0b; 0 means switch A is closed, i.e. attenuator is in, 1 means switch A is open, or attenuator out
sense_B =0b; 0 means switch B is closed, i.e. attenuator is out, 1 means switch B is open, or attenuator in
Count = 0L
While (eof(unit) eq 0) do begin
readf, unit, string1
tmp1 = strsplit (string1, ' ',/extract)
date = [date, tmp1 [0]]
Tmp2 = strsplit (tmp1 [1],',',/extract)
Time = [time, tmp2 [0]]
sense_a = [sense_a,tmp2 [1]]
sense_b = [sense_b, tmp2 [2]]

readf, unit, string1
tmp1 = strsplit (string1, ' ',/extract)
tmp2 = strsplit (tmp1 [1], ',',/extract)

pulse_duration = [pulse_duration, float (tmp2[2])]
Side = [side,'A']


readf, unit, string1
tmp1 = strsplit (string1, ' ',/extract)
date = [date, tmp1 [0]]
Tmp2 = strsplit (tmp1 [1],',',/extract)
Time = [time, tmp2 [0]]
sense_a = [sense_a,tmp2 [1]]
sense_b = [sense_b, tmp2 [2]]

readf, unit, string1 & $
tmp1 = strsplit (string1, ' ',/extract )
tmp2 = strsplit ( tmp1 [1], ',',/extract)
pulse_duration = [pulse_duration, float (tmp2[2])]
Side = [side,'B']
Count = count +1
endwhile

durationa=pulse_duration (where (side eq 'A'))
Durationb = pulse_duration (where (side eq 'B'))
print, 'Actuator A:',mean (durationa), stddev (durationa)
Print, 'actuator B:', Mean (durationb), stddev (durationb)
Plot, Durationa
Oplot, durationb, Color = 54
stop
end
