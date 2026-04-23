use ../Data/all

drop code subchapter unit

encode title, gen(title_id)
drop title

reshape long v, i(country title_id) j(year)
reshape wide v, i(country year) j(title_id)

replace year = year + 1954
drop unnamed73

ren v1 NAWRU
ren v2 CPI
ren v3 UR

destring UR, replace ignore("NA")
destring NAWRU, replace ignore("NA")
destring CPI, replace ignore("NA")

gen UGAP = UR - NAWRU

encode country, gen(country_id)
tsset country_id year // apparently this is fine

gen inflation = 100*(log(CPI) - log(L.CPI))

save ../Data/panel
