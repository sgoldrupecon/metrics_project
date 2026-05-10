pwd

import delimited ../Data/Agg_Inflation_Expectations
isid year
save ../Data/euagg, replace
clear all

use ../Data/panel
keep if country != "European Union"
/*
merge m:1 year using ../Data/euagg
xtset country_id year


//i don't like this...need to change it
xtreg inflation L.UGAP L.e_agg_inflation L.inflation, fe vce(cluster country_id)
// -.1646766 with expectation...partial anchoring of inflation dynamics
xtreg inflation L.UGAP L.inflation, fe vce(cluster country_id)
// -.5385103, but it's CI includes the above coeff, so slight evidence of expectation anchoring
// btw... should i put in time fe? then it's apples-apples comparison 
drop e_agg_inflation agg_inflation
*/


summ NAWRU CPI UR UGAP inflation
misstable summarize NAWRU CPI UR UGAP inflation

gen regime1 = year < y(2004)
gen regime2 = year >= y(2004)

/* ALL TIME REGRESSION
// INSERT regression with/without time fe
// this is a test on inflation targeting
// This will be an all time one, so we don't have to do Kivet corrections on it (T is enough)
// Or it can be by regime, why don't we just compare the results? (<-- TODO)
xtreg inflation L.UGAP L.inflation i.year, fe vce(cluster country_id)
// all time coeff is -0.563
xtreg inflation L.UGAP L.inflation, fe vce(cluster country_id)
// all time coeff is -0.540
*/

// post 2004 test on inflation targeting? ignore previous one because it wasn't useful?
xtreg inflation L.UGAP L.inflation i.year if regime2==1, fe vce(cluster country_id)
// post-2004 coeff is -.086
xtreg inflation L.UGAP L.inflation if regime2==1, fe vce(cluster country_id)
// post-2004 coeff is -.142
// This is a nontrivial difference, so we'll go for including time FE for identification

//STOP 


/* NO LAG
xtreg inflation L.UGAP, fe vce(cluster country_id)
estimates store eu_1
//the hell is this for?
// INSERT regression with inflation expecatations
// ECB survey was launched only in 2020
// Found an aggregtae one
*/

// REGRESSION WITH KIVET BIAS CORRECTION
//ssc install xtlsdvc // COMMENT out if you've already installed this
// ssc install xtscc // COMMENT out if you've already installed this
gen L_UGAP = L.UGAP //xtlsdvc is old school, doesn't allow L. or i. operators
gen L_inflation = L.inflation
tab year, gen(yr_)
/*
xtlsdvc inflation L_inflation L_UGAP yr_2-yr_68, initial(ah) bias(3) vcov(50) //FE?
// -0.52
estimates store eu_kivet
*/
// drop yr_1-yr_68 // only needed for kivet code
// ah stands for Anderson and Hsiao estimator
// 3 means cubic order polynomial expansion in (1/T)
// 50 is a bootstrapping 

//conclusion: we don't care about kivet

// TODO: estimate the structural break

// this is DK SE's for small T
//xtreg inflation L.UGAP L.inflation i.year if regime1 == 1, fe vce(cluster country_id)
xtscc inflation L.UGAP L.inflation i.year if regime1 == 1, fe lag(3)
//xtreg inflation L.UGAP L.inflation i.year if regime2 == 1, fe vce(cluster country_id)
xtscc inflation L.UGAP L.inflation i.year if regime2 == 1, fe lag(3)

preserve
gen post = (regime2 == 1)
//xtscc inflation c.L_UGAP##i.post c.L_inflation##i.post i.year if regime1 == 1 | regime2 == 1, fe lag(3)


xtscc inflation c.L_UGAP##i.post c.L_inflation##i.post i.country_id#i.post i.year if regime1 == 1 | regime2 == 1, fe lag(3)
lincom 1.post#c.L_UGAP

restore

// TODO: estimate rich and poor

// RE FE thing

preserve
bysort country_id: egen ugap_mean = mean(UGAP)
label var ugap_mean "Country mean of ugap (Mundlak device)"
xtreg inflation L.inflation ugap ugap_mean, re vce(cluster country_id)
test ugap_mean = 0
restore

// Random Coeffs

preserve
mixed inflation L_inflation L_UGAP if regime1 == 1 || country_id: L_inflation L_UGAP, covariance(independent) 
predict u0 urho ulambda, reffects
gen beta_ugap_country = _b[L_UGAP] + ulambda
collapse (first) beta_ugap_country, by(country_id country)
save ../Output/country_random_slopes_regime_1.dta, replace
gen rich = 1 if inlist(country, "Luxembourg","Ireland", "Denmark", "Netherlands", "Austria", "Germany", "Sweden", "Belgium", "Finland") | inlist(country, "France", "United Kingdom")
twoway (kdensity beta_ugap_country if rich!=1, color(navy) range(-5 0)) (kdensity beta_ugap_country if rich==1, color(maroon) range(-5 0)), title("1960-2004") legend(label(1 "Rich") label(2 "Poor")) xtitle("Country-specific UGAP slope") ytitle("Density")
graph export "../Output/random_slopes_kdensity_regime_1.pdf", replace
restore

preserve
mixed inflation L_inflation L_UGAP if regime2 == 1 || country_id: L_inflation L_UGAP, covariance(unstructured) 
predict u0 urho ulambda, reffects
gen beta_ugap_country = _b[L_UGAP] + ulambda
collapse (first) beta_ugap_country, by(country_id country)
save ../Output/country_random_slopes_regime_2.dta, replace
gen rich = 1 if inlist(country, "Luxembourg","Ireland", "Denmark", "Netherlands", "Austria", "Germany", "Sweden", "Belgium", "Finland") | inlist(country, "France", "United Kingdom")
twoway (kdensity beta_ugap_country if rich!=1, color(navy)) (kdensity beta_ugap_country if rich==1, color(maroon)),  title("2004-Present") legend(label(1 "Rich") label(2 "Poor")) xtitle("Country-specific UGAP slope") ytitle("Density")
graph export "../Output/random_slopes_kdensity_regime_2.pdf", replace
restore


// do endogenous sorting with G=2


// after note: so it's confirmed that we'll forgo kivet, keep i.year when possible, and not worry about anchoring expectations

// grouped FE model

gen rich = 1 if inlist(country, "Luxembourg","Ireland", "Denmark", "Netherlands", "Austria", "Germany", "Sweden", "Belgium", "Finland") | inlist(country, "France", "United Kingdom")
replace rich = 0 if missing(rich)
// xtreg inflation ibn.rich#c.L_inflation ibn.rich#c.L_UGAP i.year if regime1 == 1, fe vce(cluster country_id)
//
// xtreg inflation ibn.rich#c.L_inflation ibn.rich#c.L_UGAP i.year if regime2 == 1, fe vce(cluster country_id)

xtscc inflation c.L_inflation##i.rich c.L_UGAP##i.rich i.year if regime1==1, fe lag(3)
xtscc inflation c.L_inflation##i.rich c.L_UGAP##i.rich i.year if regime2==1, fe lag(3)

gen post = (regime2 == 1)

// xtreg inflation c.L_inflation##i.rich##i.post c.L_UGAP##i.rich##i.post i.year, fe vce(cluster country_id)
//lincom 1.rich#1.post#c.L_UGAP

// DK SE's

xtscc inflation c.L_inflation##i.rich##i.post c.L_UGAP##i.rich##i.post i.country_id#i.post i.year, fe lag(3)
lincom 1.rich#1.post#c.L_UGAP

//kiviet correction robustness

gen Linf_rich      = L_inflation*rich
gen Linf_post      = L_inflation*post
gen Linf_rich_post = L_inflation*rich*post

gen Lugap_rich      = L_UGAP*rich
gen Lugap_post      = L_UGAP*post
gen Lugap_rich_post = L_UGAP*rich*post



//regimes
xtlsdvc inflation L_inflation Linf_rich L_UGAP Lugap_rich yr_*, initial(ah) bias(3) vcov(200) if regime1 == 1
xtlsdvc inflation L_inflation Linf_rich L_UGAP Lugap_rich yr_*, initial(ah) bias(3) vcov(200) if regime2 == 1

STOP

xtlsdvc inflation L_inflation Linf_rich Linf_post Linf_rich_post L_UGAP Lugap_rich Lugap_post Lugap_rich_post yr_2-yr_68, initial(ah) bias(3) vcov(200)

lincom Lugap_rich_post

