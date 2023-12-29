clear all
set maxvar 120000
set matsize 11000
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

*************set EVCS as control variable
use "DDDdata_SFR_APT_county.dta", clear
set more off

keep if dist <= 5000

drop D treat post

xtset importparcelid date
egen month_year = group(month year)

gen hydropost = 0
replace hydropost = 1 if date >= open 
gen hydrotreat =0
replace hydrotreat = 1 if dist <= 2200
gen electreat = 0
replace electreat = 1 if elecdist <= 1000

gen D = hydrotreat * hydropost

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

xtreg lhprice D electreat hydropost $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(electreat 2200m/5000 county)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DDD.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

