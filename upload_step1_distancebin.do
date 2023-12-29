clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

use "zillowCA_cleaned_control_DID.dta", clear
set more off

merge m:1 propertyzip using "C:\Users\lubin\Desktop\Hy_housing\data\ZIPFIPS.dta" 
keep if _merge == 3
drop _merge

keep if dist<=5000
drop if year < 1990

* use only houses that have been sold more than once
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

xtset importparcelid date
egen zip_year = group(geozip year)
egen county_year = group(fips year)
egen month_year = group(month year)

forval i=200(200)5000 {
local j=`i'-200 
gen byte vicinity_`i'=1 if dist <= `i' & dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}

drop post
gen post = 0
replace post = 1 if date >= open 

forval i=200(200)5000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

gen vicinity = 0
forval i=200(200)5000 {
local j=`i'-200 
gen byte vicinity_`i'=1 if dist <= `i' & dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}

reghdfe lhprice vicinitypost* post $control_variables est i.month_year i.year, absorb(importparcelid) cluster(station_id) level(90)


xtreg lhprice vicinitypost* post $control_variables i.month_year i.year, fe robust cluster(importparcelid) level(90)
coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "200" 2 "400" 3 "600" 4 "800" 5 "1000" 6 "1200" 7 "1400" 8 "1600" 9 "1800" 10 "2000" 11 "2200" 12 "2400" 13 "2600" 14 "2800" 15 "3000" 16 "3200" 17 "3400" 18 "3600" 19 "3800" 20 "4000" 21 "4200" 22 "4400" 23 "4600" 24 "4800" 25 "5000") ///
ytitle("Housing price (%)") xtitle("meters") title("Change in housing prices with hydrogen refueling stations",size(medium)) subtitle("(with fixed effects)")
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\vicinity5000a.gph", replace

xtreg lhprice vicinitypost* post $control_variables est i.month_year i.year, fe robust cluster(importparcelid) level(90)
coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "200" 2 "400" 3 "600" 4 "800" 5 "1000" 6 "1200" 7 "1400" 8 "1600" 9 "1800" 10 "2000" 11 "2200" 12 "2400" 13 "2600" 14 "2800" 15 "3000" 16 "3200" 17 "3400" 18 "3600" 19 "3800" 20 "4000" 21 "4200" 22 "4400" 23 "4600" 24 "4800" 25 "5000") ///
ytitle("Housing price (%)") xtitle("meters") title("Change in housing prices with hydrogen refueling stations",size(medium)) subtitle("(with fixed effects and business patterns)")
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\vicinity5000b.gph", replace

*combine graph
graph use "C:\Users\lubin\OneDrive\Hy_Housing\results\vicinity5000a.gph"
graph combine "C:\Users\lubin\OneDrive\Hy_Housing\results\vicinity5000a.gph" "C:\Users\lubin\OneDrive\Hy_Housing\results\vicinity5000b.gph", ///
ycommon xsize(11) ysize(4) graphregion(color(white) icolor(white))
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\combine_vicinity5000.gph", replace


**SupplementaryTable
xtreg lhprice vicinitypost* post i.year, fe robust cluster(importparcelid) level(90)
eststo, title((1))
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice vicinitypost* post i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(+ month-of-year FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice vicinitypost* post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(+ covariates)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice vicinitypost* post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(+ No. of establishments)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 nonumbers noparentheses mtitles


*SupplementaryTable
drop treat
gen treat = 0
replace treat = 1 if dist <= 2200

capture erase "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf"
eststo clear
foreach t in 1 0 {
	qui estpost sum vicinity_* if treat == `t', detail
}
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000_summary.rtf", cells("N mean sd min Max") label

sum hp year post if treat == 1
sum hp year post if treat == 0
