****************************************************************** sensitivity to filters
clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID.dta", clear

keep if dist<=5000
tab yeargap
egen month_year = group(month year)

drop if est == .
drop treat D
gen treat = 0
replace treat = 1 if dist <= 2200
gen D = treat * post 

xtset importparcelid date

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

xtreg lhprice D treat post i.year i.month_year if yeargap<6, fe robust cluster(importparcelid) level(90)
eststo, title(yeargap<=5 without control)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_sensitivityToFilters.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post $control_variables i.year i.month_year if yeargap<6, fe robust cluster(importparcelid) level(90)
eststo, title(yeargap<=5 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_sensitivityToFilters.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post est $control_variables i.year i.month_year if yeargap<6, fe robust cluster(importparcelid) level(90)
eststo, title(yeargap<=5 all)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_sensitivityToFilters.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


**************************************************************************************************************************
clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID_county.dta", clear
****调整treatment 组的数据
keep if dist<=5000

egen month_year = group(month year)
egen county_year = group(fips year)

xtset importparcelid date

//global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .

drop D treat post
gen treat = 0
replace treat = 1 if dist <= 2200

gen lnlotsizeacres = log(lotsizeacres)
gen lnpopulation = log(population)
gen lnlandvalue = log(landassessedvalue)
gen lnbuilding_area = log(building_area)
gen lnper_income = log(per_inc)

global control_variables "lnlotsizeacres lotsizesquarefeet lnlandvalue totalbedrooms lnbuilding_area buildingage lnper_income lnpopulation hispanicshare whiteshare blackshare"

reg treat $control_variables est i.year i.month_year, robust cluster(importparcelid) level(90)
eststo, title(reg treat with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg treat $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(xtreg treat with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

logit treat $control_variables est i.year i.month_year, robust cluster(importparcelid) level(90)
eststo, title(logit treat with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

reg lhprice $control_variables est i.year i.month_year, robust cluster(importparcelid) level(90)
eststo, title(reg lhprice with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(xtreg lhprice with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles



logit treat $control_variables est i.year i.month_year, robust cluster(importparcelid) level(90)


xtreg lhprice D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200 m/5000 with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


xtreg hp D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 2200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 2200 m/5000 with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


************Supplementary Table 设置buffer为3.2km************
clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID_county.dta", clear

****调整treatment 组的数据
keep if dist<=5000

drop treat D
gen treat = 0
replace treat =1 if dist <= 3200
gen D = treat * post 

xtset importparcelid date

egen month_year = group(month year)
*egen zip_year = group( propertyzip year)
*egen county_year = group(fips year)

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .

xtreg lhprice D treat post i.year, fe robust cluster(importparcelid) level(90)
eststo, title(3200 m/5000)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(3200 m/5000 with month_year)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(3200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(3200 m/5000 with est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


**use hp as outcome variable
xtreg hp D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 3200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 3200 m/5000 with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID3_2km_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles








use "zillowCA_cleaned_control_DID.dta", clear
****调整treatment 组的数据
keep if dist<=5000

drop treat D
gen treat = 0
replace treat =1 if dist <= 1750
gen D = treat * post 

xtset importparcelid date
*global control_variables "lotsizesquarefeet noofstories building_area area"

egen month_year = group(month year)
egen zip_year = group( propertyzip year)
egen county_year = group(fips year)

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

xtreg lhprice D treat post i.year, fe robust cluster(importparcelid) level(90)
eststo, title(1750 m/5000 zip without Variable)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D treat post $control_variables i.year, fe robust cluster(importparcelid) level(90)
eststo, title(1750 m/5000 zip with Variable)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D treat post i.year, fe robust cluster(importparcelid) level(90)
eststo, title(1750 m/5000 zip without Variable)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D treat post $control_variables i.year, fe robust cluster(importparcelid) level(90)
eststo, title(1750 m/5000 zip with Variable)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles






/*

qui xtreg lhprice D treat post i.importparcelid i.year i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(190 m/1000)

esttab using "DID1000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


///
gen post = 0
replace post = 1 if date >= open 
gen lndist = log(dist)
gen treat_dist = 0
replace treat_dist = lndist if dist <= 180
gen D_dist = treat_dist * post

qui xtreg lhprice D_dist buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(180 m/1000)
esttab using "DID_lndist1000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
*///

set maxvar 120000
set matsize 11000
use "zillowCA_cleaned_control.dta", clear
keep if dist<=2000									// keep 211,091
drop if year < 1990

xtset importparcelid date
egen zip_year = group(propertyzip year)
egen month_year = group(month year)



quietly: summarize lhprice if D == 1
local mean_lhprice = r(mean)
scatter lhprice year if D == 1, title("D=1 175m/2000 mean_lhprice = `mean_lhprice1'")

quietly: summarize lhprice if D == 1
local mean_lhprice = r(mean)
scatter lhprice year if D == 1, title("D=1 175m/2000 mean_lhprice = `mean_lhprice1'")

drop if year == 2012
drop if year == 2014
qui xtreg lhprice D buildingage i.zip_year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(175 m/2000)

esttab using "DID2000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*zip_y* *month_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


/*
gen post = 0
replace post = 1 if date >= open 
gen lndist = log(dist)
gen treat_dist = 0
replace treat_dist = lndist if dist <= 175
gen D_dist = treat_dist * post

by D, sort: distinct importparcelid

qui xtreg lhprice D_dist buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(175 m/2000)
esttab using "DID_lndist2000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
///

/*
set maxvar 120000
set matsize 11000
use "zillowCA_cleaned_control.dta", clear
keep if dist<=3000
drop if year < 1996

* repeated sales sample
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

xtset importparcelid date
egen zip_year = group(propertyzip year)
egen month_year = group(month year)

/*gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 155
gen D = treat * post    

xtreg lhprice D buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(155 m/3000)

esttab using "DID3000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
*/
///
gen post = 0
replace post = 1 if date >= open 
gen lndist = log(dist)
gen treat_dist = 0
replace treat_dist = lndist if dist <= 310
gen D_dist = treat_dist * post

qui xtreg lhprice D_dist buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(310 m/3000)
esttab using "DID_lndist3000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
///



use "zillowCA_cleaned_control.dta", clear
keep if dist<=4000
drop if year < 1996

* repeated sales sample
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

xtset importparcelid date
egen zip_year = group(propertyzip year)
egen month_year = group(month year)

/*gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 125
gen D = treat * post    

xtreg lhprice D buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(125 m/4000)

esttab using "DID4000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
*/
///
gen post = 0
replace post = 1 if date >= open 
gen lndist = log(dist)
gen treat_dist = 0
replace treat_dist = lndist if dist <= 480
gen D_dist = treat_dist * post

qui xtreg lhprice D_dist buildingage i.month_year i.zip_year, fe robust cluster(importparcelid) level(90)
eststo, title(480 m/3000)
esttab using "DID_lndist4000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*month_y* *zip_y*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
///


set maxvar 120000
set matsize 11000
use "zillowCA_cleaned_control.dta", clear
keep if dist<=10000									// keep 2,133,511
drop if year < 1990

* repeated sales sample
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1								// keep 1,983,827
drop repeatsale

* 缩尾处理
winsor2 lhprice, cut(5 95) trim
drop if lhprice == . 								// keep 1,982,969

xtset importparcelid date
egen zip_year = group(propertyzip year)
egen month_year = group(month year)

gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 3500
gen D = treat * post

qui xtreg lhprice D treat post buildingage i.year i.month, fe robust cluster(importparcelid) level(90)
eststo, title(3500 m/10000 zipyearFE)

esttab using "DID10000.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.015 *** 0.01) replace drop(*year* *month*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

drop post treat D