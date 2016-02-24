" Test only one pattern supplied to SearchPositionMultiple.

call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#err#Throws('Must pass at least two (comma-separated) {pattern}', 'SearchPositionMultiple /foo/', 'Error when only one pattern is supplied')
call vimtest#Quit()
