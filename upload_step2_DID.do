clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID.dta", clear
keep if dist<=5000

drop treat D
gen treat = 0
replace treat =1 if dist <= 2200
gen D = treat * post 

xtset importparcelid date
*global control_variables "lotsizesquarefeet noofstories building_area area"

egen month_year = group(month year)

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .
xtreg lhprice D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

reghdfe lhprice D treat post $control_variables est i.year i.month_year, absorb(importparcelid) cluster(station_id) level(90)
reghdfe lhprice D treat post $control_variables est i.year i.county_year, absorb(importparcelid) cluster(importparcelid) level(90)


bysort propertyzip: egen count_panel = count(importparcelid)
list propertyzip if count_panel == 1
xtreg lhprice D treat post $control_variables est i.year i.month_year if count_panel>100, fe robust cluster(propertyzip) level(90)

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200 m/5000 with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_lhprice_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


xtreg hp D treat post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 2200 m/5000 without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D treat post $control_variables est i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(hp 2200 m/5000 with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DID_hp_results.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


************Supplementary Table set buffer to 3.2km************
clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID_county.dta", clear
keep if dist<=5000

drop treat D
gen treat = 0
replace treat =1 if dist <= 3200
gen D = treat * post 

xtset importparcelid date

egen month_year = group(month year)

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
