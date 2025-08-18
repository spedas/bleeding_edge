;date = ['2014-03-19', '2014-03-20', '2014-03-21']
;date = '2014-03-19'
;date = ['2014-09-22', '2014-09-23', '2014-09-24']
;date = ['2014-10-17', '2014-10-18', '2014-10-19']
set_plot, 'z'

date = '2015-05-21'

For j = 0, n_elements(date)-1 Do Begin
   mvn_over_shell, date=date[j], /date_only, /multipngplot, device='z', instr=['pfpl2']
Endfor

End

