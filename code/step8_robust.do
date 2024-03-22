clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

******************************************************************************* Table S7  
use "zillowCA_data.dta", clear
keep if dist<=5000

* locate the nearest electric station for each home
geonear transid latitude longitude using "elecstation.dta", n(elecstation_id latitude3 longitude3)
rename nid elecstation_id
rename km_to_nid elecdist
replace elecdist = elecdist*1000 //convert unit to meter
tabstat elecdist, statistics(mean n sd min q p90 max)

* merge station characteristics based on station_id
merge m:1 elecstation_id using elecstation, force
drop if _merge != 3
drop _merge

gen hydropost = 0
replace hydropost = 1 if date >= open 
gen hydrotreat =0
replace hydrotreat = 1 if dist <= 2200
gen electreat = 0
replace electreat = 1 if elecdist <= 1000
drop D
gen D = hydrotreat * hydropost

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

matrix results = J(4, 8, .)

sum lhprice if 
xtreg lhprice D electreat $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[3,1] = e(N)
	matrix results[4,1] = e(r2)
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))
xtreg lhprice D electreat $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[3,2] = e(N)
	matrix results[4,2] = e(r2)		
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))
sum lhprice if e(sample)

merge m:1 propertyzip year using "C:\Users\lubin\Desktop\Hy_housing\data\business_establishments_zip.dta", force
drop if _merge == 2
drop _merge

xtreg lhprice D est $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[3,3] = e(N)
	matrix results[4,3] = e(r2)
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

xtreg lhprice D est $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[3,4] = e(N)
	matrix results[4,4] = e(r2)
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))	
sum lhprice if e(sample)
	
matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1 
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_TWFEregression_EVCSandEST.xlsx", replace
drop c1-stars_c8

******************************************************************************* Table S8
gen lnlotsizeacres = log(lotsizeacres)
gen lnpopulation = log(population)
gen lnlandvalue = log(landassessedvalue)
gen lnbuilding_area = log(building_area)
gen lnper_income = log(per_inc)

global lncontrol_variables "lnlotsizeacres lotsizesquarefeet lnlandvalue totalbedrooms lnbuilding_area buildingage lnper_income lnpopulation hispanicshare whiteshare blackshare"

reg lhprice $lncontrol_variables est i.year, robust cluster(importparcelid) level(95)
eststo, title(reg lhprice with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice $lncontrol_variables est i.year, fe robust cluster(importparcelid) level(95)
eststo, title(xtreg lhprice with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

logit treat $lncontrol_variables est i.year, robust cluster(importparcelid) level(95)
eststo, title(logit treat with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg treat $lncontrol_variables est i.year, fe robust cluster(importparcelid) level(95)
eststo, title(xtreg treat with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\SI_results_influenceFactors.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

******************************************************************************* Table S18
use "zillowCA_data.dta", clear
keep if dist<=5000

gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post 

drop if date > date("2020-03-11", "YMD")

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

matrix results = J(2, 8, .)
sum lhprice

qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))

matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_TWFEregression_results.xlsx", replace
drop c1-stars_c8

*** eventstudyinteract
gen temp = treat == 1 & post == 1
bysort importparcelid: egen always_treat = min(temp)
drop temp

gen treat_year = openyear if treat == 1
bysort importparcelid: egen first_treated = min(treat_year)
drop treat_year
gen ry = year - first_treated

gen never_treat = (first_treated == .)

* L0event-L5event
forvalues l = 0/5 {
    gen L`l'event = ry == `l'
}
* F1event-F8event
forvalues l = 1/8 {
    gen F`l'event = ry == -`l'
}

drop F1event 
gen F1event = 0

matrix results = J(10, 4, .)
* TWFE estimate
qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* TWFE estimate w/ staggered design and dropping always-treated properties
qui xtreg lhprice D i.year if always_treat == 0, fe robust cluster(importparcelid) level(95)
	matrix results[3,1] = _b[D]
	matrix results[4,1] = _se[D]
	matrix results[3,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if always_treat == 0, fe robust cluster(importparcelid) level(95)
	matrix results[3,2] = _b[D]
	matrix results[4,2] = _se[D]
	matrix results[3,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* Estimate w/ De Chaisemartin and D'Haultfœuille (2020)'s method
did_multiplegt lhprice importparcelid year D, cluster(importparcelid) breps(10) seed(1234)
	matrix results[5,1] = e(effect_0)
	matrix results[6,1] = e(se_effect_0)
	matrix results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D, cluster(importparcelid) breps(10) controls($control_variables) seed(1234)
	matrix results[5,2] = e(effect_0)
	matrix results[6,2] = e(se_effect_0)
	matrix results[5,4] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))		

* Estimate w/ Sun and Abraham (2021)'s method
eventstudyinteract lhprice F*event L*event, cohort(first_treated) control_cohort(never_treat) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix results[7,1] = `b_mean'
	matrix results[8,1] = `se_mean'
	matrix results[7,3] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))	

eventstudyinteract lhprice F*event L*event, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix results[7,2] = `b_mean'
	matrix results[8,2] = `se_mean'
	matrix results[7,4] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))		

* Estimate w/ Callaway and Sant'Anna (2021)'s method
gen first_treat = 0
replace first_treat = openyear if treat == 1
tab year, gen(dummyyear)
qui csdid lhprice dummyyear*, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix results[9,1] = _b[ATT]
	matrix results[10,1] = _se[ATT]
	matrix results[9,3] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))
qui csdid lhprice dummyyear* $control_variables, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix results[9,2] = _b[ATT]
	matrix results[10,2] = _se[ATT]
	matrix results[9,4] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))

matrix list results


svmat results, names(col)

foreach var in c3 c4 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1
    rename stars stars_`v'
}

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_Robustness_Alternative Estimators1.xlsx", replace
drop c1-stars_c4

preserve
	use "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", clear
    sort whiteshare
    centile whiteshare, centile(25 50 75)
	local whiteshare_25 = r(c_1)
	local whiteshare_50 = r(c_2)
	local whiteshare_75 = r(c_3)	
	display "First quartile (25%): " `whiteshare_25'
	display "Median / Second quartile (50%): " `whiteshare_50'
	display "Third quartile (75%): " `whiteshare_75'
restore
gen nonwhite = .
replace nonwhite = 1 if whiteshare <= `whiteshare_50'
replace nonwhite = 0 if whiteshare > `whiteshare_50'
gen white = (nonwhite == 0)

preserve
	use "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", clear
    sort hispanicshare
    centile hispanicshare, centile(25 50 75)
	local hispanicshare_25 = r(c_1)
	local hispanicshare_50 = r(c_2)
	local hispanicshare_75 = r(c_3)	
	display "First quartile (25%): " `hispanicshare_25'
	display "Median / Second quartile (50%): " `hispanicshare_50'
	display "Third quartile (75%): " `hispanicshare_75'
restore
gen hispanic = .
replace hispanic = 1 if hispanicshare >= `hispanicshare_50'
replace hispanic = 0 if hispanicshare < `hispanicshare_50'

preserve
	use "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", clear
    sort blackshare
    centile blackshare, centile(25 50 75)
	local blackshare_25 = r(c_1)
	local blackshare_50 = r(c_2)
	local blackshare_75 = r(c_3)	
	display "First quartile (25%): " `blackshare_25'
	display "Median / Second quartile (50%): " `blackshare_50'
	display "Third quartile (75%): " `blackshare_75'
restore
gen black = .
replace black = 1 if blackshare >= `blackshare_50'
replace black = 0 if blackshare < `blackshare_50'

preserve
	use "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", clear
	gen other_race = 100 - whiteshare - blackshare - hispanicshare
    sort other_race
    centile other_race, centile(25 50 75)
	local other_race_25 = r(c_1)
	local other_race_50 = r(c_2)
	local other_race_75 = r(c_3)	
	display "First quartile (25%): " `other_race_25'
	display "Median / Second quartile (50%): " `other_race_50'
	display "Third quartile (75%): " `other_race_75'
restore
gen other = .
gen other_race = 100 - whiteshare - blackshare - hispanicshare
replace other = 1 if other_race >= `other_race_50'
replace other = 0 if other_race < `other_race_50'


*************************************************************Panel B. Whites
local detailrace white
matrix `detailrace'_results = J(10, 4, .)

* TWFE estimate
qui xtreg lhprice D i.year if nonwhite == 0, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,1] = _b[D]
	matrix `detailrace'_results[2,1] = _se[D]
	matrix `detailrace'_results[1,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if nonwhite == 0, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,2] = _b[D]
	matrix `detailrace'_results[2,2] = _se[D]
	matrix `detailrace'_results[1,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* TWFE estimate w/ staggered design and dropping always-treated properties
qui xtreg lhprice D i.year if always_treat == 0 & nonwhite == 0, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,1] = _b[D]
	matrix `detailrace'_results[4,1] = _se[D]
	matrix `detailrace'_results[3,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if always_treat == 0 & nonwhite == 0, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,2] = _b[D]
	matrix `detailrace'_results[4,2] = _se[D]
	matrix `detailrace'_results[3,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* Estimate w/ De Chaisemartin and D'Haultfœuille (2020)'s method
did_multiplegt lhprice importparcelid year D if nonwhite == 0, cluster(importparcelid) breps(10) seed(1234)
	matrix `detailrace'_results[5,1] = e(effect_0)
	matrix `detailrace'_results[6,1] = e(se_effect_0)
	matrix `detailrace'_results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D if nonwhite == 0, cluster(importparcelid) breps(10) controls($control_variables) seed(1234)
	matrix `detailrace'_results[5,2] = e(effect_0)
	matrix `detailrace'_results[6,2] = e(se_effect_0)
	matrix `detailrace'_results[5,4] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))	

* Estimate w/ Sun and Abraham (2021)'s method
eventstudyinteract lhprice F*event L*event if nonwhite == 0, cohort(first_treated) control_cohort(never_treat) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,1] = `b_mean'
	matrix `detailrace'_results[8,1] = `se_mean'
	matrix `detailrace'_results[7,3] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))	

eventstudyinteract lhprice F*event L*event if nonwhite == 0, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,2] = `b_mean'
	matrix `detailrace'_results[8,2] = `se_mean'
	matrix `detailrace'_results[7,4] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))		

* Estimate w/ Callaway and Sant'Anna (2021)'s method
qui csdid lhprice dummyyear* if nonwhite == 0, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,1] = _b[ATT]
	matrix `detailrace'_results[10,1] = _se[ATT]
	matrix `detailrace'_results[9,3] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))
qui csdid lhprice dummyyear* $control_variables if nonwhite == 0, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,2] = _b[ATT]
	matrix `detailrace'_results[10,2] = _se[ATT]
	matrix `detailrace'_results[9,4] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))

matrix list `detailrace'_results

svmat white_results, names(col)

foreach var in c3 c4 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1  
    rename stars stars_`v'
}

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_Robustness_Alternative Estimators2.xlsx", replace
drop c1-stars_c4



*************************************************************Panel C. Hispanics
local detailrace hispanic
matrix `detailrace'_results = J(10, 4, .)

* TWFE estimate
qui xtreg lhprice D i.year if hispanic == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,1] = _b[D]
	matrix `detailrace'_results[2,1] = _se[D]
	matrix `detailrace'_results[1,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if hispanic == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,2] = _b[D]
	matrix `detailrace'_results[2,2] = _se[D]
	matrix `detailrace'_results[1,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* TWFE estimate w/ staggered design and dropping always-treated properties
qui xtreg lhprice D i.year if always_treat == 0 & hispanic == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,1] = _b[D]
	matrix `detailrace'_results[4,1] = _se[D]
	matrix `detailrace'_results[3,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if always_treat == 0 & hispanic == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,2] = _b[D]
	matrix `detailrace'_results[4,2] = _se[D]
	matrix `detailrace'_results[3,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* Estimate w/ De Chaisemartin and D'Haultfœuille (2020)'s method
did_multiplegt lhprice importparcelid year D if hispanic == 1, cluster(importparcelid) breps(10) seed(1234)
	matrix `detailrace'_results[5,1] = e(effect_0)
	matrix `detailrace'_results[6,1] = e(se_effect_0)
	matrix `detailrace'_results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D if hispanic == 1, cluster(importparcelid) breps(10) controls($control_variables) seed(1234)
	matrix `detailrace'_results[5,2] = e(effect_0)
	matrix `detailrace'_results[6,2] = e(se_effect_0)
	matrix `detailrace'_results[5,4] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))	
	
* Estimate w/ Sun and Abraham (2021)'s method
eventstudyinteract lhprice F*event L*event if hispanic == 1, cohort(first_treated) control_cohort(never_treat) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,1] = `b_mean'
	matrix `detailrace'_results[8,1] = `se_mean'
	matrix `detailrace'_results[7,3] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))	

eventstudyinteract lhprice F*event L*event if hispanic == 1, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,2] = `b_mean'
	matrix `detailrace'_results[8,2] = `se_mean'
	matrix `detailrace'_results[7,4] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))		

* Estimate w/ Callaway and Sant'Anna (2021)'s method
qui csdid lhprice dummyyear* if hispanic == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,1] = _b[ATT]
	matrix `detailrace'_results[10,1] = _se[ATT]
	matrix `detailrace'_results[9,3] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))
qui csdid lhprice dummyyear* $control_variables if hispanic == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,2] = _b[ATT]
	matrix `detailrace'_results[10,2] = _se[ATT]
	matrix `detailrace'_results[9,4] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))

matrix list `detailrace'_results	

svmat hispanic_results, names(col)

foreach var in c3 c4 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1
    rename stars stars_`v'
}

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_Robustness_Alternative Estimators3.xlsx", replace
drop c1-stars_c4

*************************************************************Panel D. Blacks

local detailrace black
matrix `detailrace'_results = J(10, 4, .)

* TWFE estimate
qui xtreg lhprice D i.year if black == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,1] = _b[D]
	matrix `detailrace'_results[2,1] = _se[D]
	matrix `detailrace'_results[1,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if black == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,2] = _b[D]
	matrix `detailrace'_results[2,2] = _se[D]
	matrix `detailrace'_results[1,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* TWFE estimate w/ staggered design and dropping always-treated properties
qui xtreg lhprice D i.year if always_treat == 0 & black == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,1] = _b[D]
	matrix `detailrace'_results[4,1] = _se[D]
	matrix `detailrace'_results[3,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if always_treat == 0 & black == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,2] = _b[D]
	matrix `detailrace'_results[4,2] = _se[D]
	matrix `detailrace'_results[3,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* Estimate w/ De Chaisemartin and D'Haultfœuille (2020)'s method
did_multiplegt lhprice importparcelid year D if black == 1, cluster(importparcelid) breps(10) seed(1234)
	matrix `detailrace'_results[5,1] = e(effect_0)
	matrix `detailrace'_results[6,1] = e(se_effect_0)
	matrix `detailrace'_results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D if black == 1, cluster(importparcelid) breps(10) controls($control_variables) seed(1234)
	matrix `detailrace'_results[5,2] = e(effect_0)
	matrix `detailrace'_results[6,2] = e(se_effect_0)
	matrix `detailrace'_results[5,4] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))	
	
* Estimate w/ Sun and Abraham (2021)'s method
eventstudyinteract lhprice F*event L*event if black == 1, cohort(first_treated) control_cohort(never_treat) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,1] = `b_mean'
	matrix `detailrace'_results[8,1] = `se_mean'
	matrix `detailrace'_results[7,3] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))	

eventstudyinteract lhprice F*event L*event if black == 1, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,2] = `b_mean'
	matrix `detailrace'_results[8,2] = `se_mean'
	matrix `detailrace'_results[7,4] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))		

* Estimate w/ Callaway and Sant'Anna (2021)'s method
qui csdid lhprice dummyyear* if black == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,1] = _b[ATT]
	matrix `detailrace'_results[10,1] = _se[ATT]
	matrix `detailrace'_results[9,3] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))
qui csdid lhprice dummyyear* $control_variables if black == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,2] = _b[ATT]
	matrix `detailrace'_results[10,2] = _se[ATT]
	matrix `detailrace'_results[9,4] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))

matrix list `detailrace'_results


svmat black_results, names(col)

foreach var in c3 c4 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1
    rename stars stars_`v'
}

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_Robustness_Alternative Estimators4.xlsx", replace
drop c1-stars_c4

*************************************************************Panel E. Other Races

local detailrace other
matrix `detailrace'_results = J(10, 4, .)

* TWFE estimate
qui xtreg lhprice D i.year if other == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,1] = _b[D]
	matrix `detailrace'_results[2,1] = _se[D]
	matrix `detailrace'_results[1,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if other == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[1,2] = _b[D]
	matrix `detailrace'_results[2,2] = _se[D]
	matrix `detailrace'_results[1,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
* TWFE estimate w/ staggered design and dropping always-treated properties
qui xtreg lhprice D i.year if always_treat == 0 & other == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,1] = _b[D]
	matrix `detailrace'_results[4,1] = _se[D]
	matrix `detailrace'_results[3,3] = 2 * (1 - normal(abs(_b[D]/_se[D])))
qui xtreg lhprice D $control_variables i.year if always_treat == 0 & other == 1, fe robust cluster(importparcelid) level(95)
	matrix `detailrace'_results[3,2] = _b[D]
	matrix `detailrace'_results[4,2] = _se[D]
	matrix `detailrace'_results[3,4] = 2 * (1 - normal(abs(_b[D]/_se[D])))	
* Estimate w/ De Chaisemartin and D'Haultfœuille (2020)'s method
did_multiplegt lhprice importparcelid year D if other == 1, cluster(importparcelid) breps(10) seed(1234)
	matrix `detailrace'_results[5,1] = e(effect_0)
	matrix `detailrace'_results[6,1] = e(se_effect_0)
	matrix `detailrace'_results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D if other == 1, cluster(importparcelid) breps(10) controls($control_variables) seed(1234)
	matrix `detailrace'_results[5,2] = e(effect_0)
	matrix `detailrace'_results[6,2] = e(se_effect_0)
	matrix `detailrace'_results[5,4] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))	
	
* Estimate w/ Sun and Abraham (2021)'s method
eventstudyinteract lhprice F*event L*event if other == 1, cohort(first_treated) control_cohort(never_treat) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,1] = `b_mean'
	matrix `detailrace'_results[8,1] = `se_mean'
	matrix `detailrace'_results[7,3] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))	

eventstudyinteract lhprice F*event L*event if other == 1, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)

matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'

matrix b_ = b[1, 9..14]
matrix se_ = se[1, 9..14]

scalar b_sum = 0
scalar se_sum = 0

forval i = 1 / 6 {
    scalar b_sum = b_sum + b_[1,`i']
	scalar se_sum = se_sum + se_[1,`i']
}
local b_mean = b_sum / 6
local se_mean = se_sum / 6
	matrix `detailrace'_results[7,2] = `b_mean'
	matrix `detailrace'_results[8,2] = `se_mean'
	matrix `detailrace'_results[7,4] = 2 * (1 - normal(abs(`b_mean'/`se_mean')))		

* Estimate w/ Callaway and Sant'Anna (2021)'s method
qui csdid lhprice dummyyear* if other == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,1] = _b[ATT]
	matrix `detailrace'_results[10,1] = _se[ATT]
	matrix `detailrace'_results[9,3] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))
qui csdid lhprice dummyyear* $control_variables if other == 1, ivar(importparcelid) time(year) gvar(first_treat) agg(simple)
	matrix `detailrace'_results[9,2] = _b[ATT]
	matrix `detailrace'_results[10,2] = _se[ATT]
	matrix `detailrace'_results[9,4] = 2 * (1 - normal(abs(_b[ATT]/_se[ATT])))

matrix list `detailrace'_results	

svmat other_results, names(col)

foreach var in c3 c4 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1 
    rename stars stars_`v'
}

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_Robustness_Alternative Estimators5.xlsx", replace
drop c1-stars_c4

