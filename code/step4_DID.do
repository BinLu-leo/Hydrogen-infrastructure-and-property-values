clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

******************************************************************************* Table 1
* Load the dataset
use "zillowCA_data.dta", clear

* Keep properties within 5000 meters
keep if dist<=5000

* Generate treatment variable based on distance
gen treat = 0
replace treat = 1 if dist <= 2200

* Generate interaction term for treatment and post-period
gen D = treat * post 

* Set panel data structure
xtset importparcelid year

* Define control variables for regression analysis
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

* Initialize a results matrix to store coefficients and standard errors
matrix results = J(2, 8, .)

* Define list of regression specifications
#delimit ;
local specs "i.year" "i.year i.zip" 
			"$control_variables i.year i.zip" 
			"$control_variables i.year i.zip zip#c.year"
;
#delimit cr
* Loop through regression specifications
forval i = 1/4 {
    * Run regression with fixed effects, clustering, and robust standard errors
    qui xtreg lhprice D `specs[`i']', fe robust cluster(importparcelid) level(95)
    
    * Store the coefficient and standard error of D in the results matrix
    matrix results[1,`i'] = _b[D]
    matrix results[2,`i'] = _se[D]
    * Calculate p-value for the coefficient and store it in the second half of the matrix
    matrix results[1,`i'+4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
}

* Display the matrix with results
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

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregression_results.xlsx", replace
drop c1-stars_c8

******************************************************************************* Table S5
twowayfeweights lhprice importparcelid year D, type(feTR) controls($control_variables) summary_measures

******************************************************************************* Table S11
* Preserving the current dataset state for restoration later
preserve

* Define a list of racial groups for looping
local races "white black hispanic other"

* Load the covariates data for California housing
use "C:\\Users\\lubin\\OneDrive\\Hy_Housing\\data\\ca_covariates.dta", clear

* Generate the percentage for other races (if not already calculated in your dataset)
gen other_race = 100 - whiteshare - blackshare - hispanicshare

* Loop through each racial group to perform operations
foreach race of local races {
    * Special handling for "other" race
    if ("`race'" == "other") {
        sort other_race
    }
    else {
        sort `race'share
    }
    
    * Calculate and display the percentile values
    centile `race'share, centile(25 50 75) if ("`race'" != "other")
    centile other_race, centile(25 50 75) if ("`race'" == "other")
    
    * Store the percentile values in local macros
    local `race'_25 = r(c_1)
    local `race'_50 = r(c_2)
    local `race'_75 = r(c_3)
    
    * Display the calculated percentile values
    display "First quartile (25%): " ``race'_25''
    display "Median/Second quartile (50%): " ``race'_50''
    display "Third quartile (75%): " ``race'_75''
    
    * Restore the dataset to its previous state for next iteration
    restore, preserve
    
    * Reload the dataset for next racial group processing
    use "C:\\Users\\lubin\\OneDrive\\Hy_Housing\\data\\ca_covariates.dta", clear
    
    * Special handling for generating indicators
    if ("`race'" == "other") {
        gen `race' = .
        replace `race' = 1 if other_race >= ``race'_50''
        replace `race' = 0 if other_race < ``race'_50''
    }
    else {
        gen non`race' = .
        replace non`race' = 1 if `race'share <= ``race'_50''
        replace non`race' = 0 if `race'share > ``race'_50''
        gen `race' = (non`race' == 0)
    }
}

* Generate an indicator variable for units that are always treated
gen temp = treat == 1 & post == 1

* For each 'importparcelid', mark as 1 if all records meet the condition (i.e., 'temp' is 1 for all)
bysort importparcelid: egen always_treat = min(temp)

* Clear the temporary variable
drop temp

* Generate the year of first treatment
gen treat_year = openyear if treat == 1
bysort importparcelid: egen first_treated = min(treat_year)
drop treat_year

* Code the relative time categorical variable
gen ry = year - first_treated

* Define the control cohort as individuals who never unionized
gen never_treat = (first_treated == .)
tab ry

* Generate dummy variables for after the event occurrence (L0event to L5event)
forvalues l = 0/5 {
    gen L`l'event = ry == `l'
}

* Generate dummy variables for before the event occurrence (F1event to F8event)
forvalues l = 1/8 {
    gen F`l'event = ry == -`l'
}

* Special handling for F1event, reset it to 0 after dropping
drop F1event 
gen F1event = 0

*************************************************************Panel A. All sample
* Initialize an empty results matrix
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
did_multiplegt lhprice importparcelid year D, cluster(importparcelid) breps(100) seed(1234)
	matrix results[5,1] = e(effect_0)
	matrix results[6,1] = e(se_effect_0)
	matrix results[5,3] = 2 * (1 - normal(abs(e(effect_0)/e(se_effect_0))))
did_multiplegt lhprice importparcelid year D, cluster(importparcelid) breps(100) controls($control_variables) seed(1234)
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

* 将矩阵转换为数据集
svmat results, names(col)
* 生成星号标记
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
* 导出数据到Excel
export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robustness_Alternative Estimators1.xlsx", replace
drop c1-stars_c4


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

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robustness_Alternative Estimators2.xlsx", replace
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

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robustness_Alternative Estimators3.xlsx", replace
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

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robustness_Alternative Estimators4.xlsx", replace
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

export excel c1 c2 stars_c3 stars_c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robustness_Alternative Estimators5.xlsx", replace
drop c1-stars_c4
