" Test multiple pattern argument matches.

SearchPositionMultiple /tool/,/\(['"]\)one\s\+line\1/

call vimtest#Quit()
