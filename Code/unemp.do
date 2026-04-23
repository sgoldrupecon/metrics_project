import delimited ../../Downloads/ameco0_CSV/AMECO1.CSV

keep if inlist(country, "Germany","Belgium", "Bulgaria", "Cyprus", "Croatia", "Czech Republic", "Denmark", "Estonia", "Spain") | inlist(country, "Finland", "France", "Greece", "Hungary", "Ireland", "Italy", "Lithuania", "Latvia", "Luxembourg") | inlist(country, "Malta", "Netherlands", "Austria", "Poland", "Portugal", "Romania", "Sweden", "Slovenia", "Slovakia") | inlist(country,"United Kingdom")

keep if (substr(code,-6,.) == "ZNAWRU" | substr(code,-4,.) == "ZUTN")

save unemp.dta
