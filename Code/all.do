import delimited ../Data/AMECO2.CSV

keep if inlist(country, "Germany","Belgium", "Bulgaria", "Cyprus", "Croatia", "Czech Republic", "Denmark", "Estonia", "Spain") | inlist(country, "Finland", "France", "Greece", "Hungary", "Ireland", "Italy", "Lithuania", "Latvia", "Luxembourg") | inlist(country, "Malta", "Netherlands", "Austria", "Poland", "Portugal", "Romania", "Sweden", "Slovenia", "Slovakia") | inlist(country,"United Kingdom")

keep if substr(code,-5,.) == "ZCPIN"

append using ../Data/unemp

save ../Data/all.dta
