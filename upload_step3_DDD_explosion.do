clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

use zillowCA_cleaned_control_DID.dta, clear
set more off

keep if dist <= 5000

* use only houses that have been sold more than once
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

xtset importparcelid date
egen month_year = group(month year)

gen hydropost = 0
replace hydropost = 1 if date >= open 
gen hydrotreat =0
replace hydrotreat = 1 if dist <= 2200
gen explosion = "20190601"
gen explosiondate=date(explosion, "YMD") 
format explosiondate %td
gen explosion_post = 0
replace explosion_post = 1 if date >= explosiondate

drop D
gen D = hydrotreat * hydropost
gen D1 = hydrotreat * explosion_post
gen D2 = hydropost * explosion_post
gen DDD = explosion_post * hydropost * hydrotreat
tab DDD, missing

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .
xtreg lhprice DDD D1 D2 D hydrotreat hydropost explosion_post $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200m/5000 without est)
xtreg lhprice DDD D1 D2 D hydrotreat hydropost explosion_post est $control_variables i.year i.month_year, fe robust cluster(importparcelid) level(90)
eststo, title(2200m/5000 with est)

esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DDD_explosion.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


