; This is to read files created by the GSE for MAY the SEP attenuator life test

pro read_attenuator_test_file,file =  file,  $
                              durationa =  durationa,  durationb =  durationb
  ;file ='C:\Users\rlillis\Work\MAVEN\SEP_instrument\GSE\actTest_test_2.dat'
  if not keyword_set (file) then stop
  
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
print, tmp1[1]
date = [date, tmp1 [0]]
Tmp2 = strsplit (tmp1 [1],',',/extract)
Time = [time, tmp2 [0]]
sense_a = [sense_a,tmp2 [1]]
sense_b = [sense_b, tmp2 [2]]
readf, unit, string1
tmp1 = strsplit (string1, ' ',/extract)
print, tmp1[1]
tmp2 = strsplit (tmp1 [1], ',',/extract)

pulse_duration = [pulse_duration, float (tmp2[2])]
Side = [side,'A']

if eof(unit) then break
readf, unit, string1 
tmp1 = strsplit (string1, ' ',/extract)
print, tmp1[1]

date = [date, tmp1 [0]]
Tmp2 = strsplit (tmp1 [1],',',/extract)
Time = [time, tmp2 [0]]
sense_a = [sense_a,tmp2 [1]]
sense_b = [sense_b, tmp2 [2]]

if eof(unit) then break
readf, unit, string1 & $
tmp1 = strsplit (string1, ' ',/extract )
print, tmp1[1]
tmp2 = strsplit ( tmp1 [1], ',',/extract)
pulse_duration = [pulse_duration, float (tmp2[2])]
Side = [side,'B']
Count = count +1
endwhile
aside = where (side eq 'A')
bside =  where (side eq 'B')
durationa=pulse_duration (aside)
Durationb = pulse_duration (bside)
print, 'Actuator A:',mean (durationa), stddev (durationa)
Print, 'actuator B:', Mean (durationb), stddev (durationb)
time_string =  date [1:*] + '/' + time[1:*]
time_double =  time_double (time_string)
minutes =  (time_double - time_double [0])/60.0


Plot, minutes[aside], Durationa,  $
  xtit =  'minutes',  ytit =  'stroke duration, ms',  $
  yr =  minmax ([durationa,  durationb]),  $
  title =  'Black: Open, Blue: Close'
Oplot, minutes[bside], durationb, Color = 54
xyouts,  100,  350,  'Open'
xyouts,  100,  305,  'Close',  Color =  54
Plot, Durationa,  $
  xtit =  'actuations',  ytit =  'stroke duration, ms',  $
  yr =  minmax ([durationa,  durationb])
Oplot, durationb, Color = 54
;stop
end
