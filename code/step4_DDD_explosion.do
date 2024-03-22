clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

set more off

******************************************************************************* Table 2
* Load the Zillow data for California and merge it with covariates
use "zillowCA_explosion.dta", clear
merge n:1 propertyzip year using "C:\\Users\\lubin\\OneDrive\\Hy_Housing\\data\\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)

* Keep observations within 5000 meters
keep if dist<=5000

* Generation of variables for event study analysis
* Indicator for post-hydrogen infrastructure exposure
gen hydropost = 0
replace hydropost = 1 if date >= open 

* Indicator for treatment based on proximity to hydrogen infrastructure
gen hydrotreat = 0
replace hydrotreat = 1 if dist <= 2200

* Create date variables for the explosion event
gen explosion = "20190601"
gen explosiondate = date(explosion, "YMD") 
format explosiondate %td

* Indicator for post-explosion exposure
gen explosion_post = 0
replace explosion_post = 1 if date >= explosiondate

* Generate interaction terms
gen D = hydrotreat * hydropost
gen D1 = hydrotreat * explosion_post
gen D2 = hydropost * explosion_post
gen DDD = explosion_post * hydrotreat * hydropost

* Setting up panel data structure
xtset importparcelid year

* Define control variables
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc hispanicshare whiteshare blackshare"

* Initialize an empty matrix for results storage
matrix results = J(4, 8, .)

* Loop through four regressions, varying fixed effects and covariates
forval i = 1/4 {
    * Define model specifications dynamically
    local model_spec if `i' == 1 "fe" 
    local model_spec if `i' == 2 "fe i.zip"
    local model_spec if `i' == 3 "$control_variables fe i.zip"
    local model_spec if `i' == 4 "$control_variables fe i.zip zip#c.year"
    
    * Perform regression with robust standard errors and fixed effects
    qui xtreg lhprice DDD D1 D2 D hydrotreat hydropost explosion_post i.year i.zip `model_spec', robust cluster(importparcelid) level(95)
    
    * Store coefficients, standard errors, and p-values in the results matrix
    matrix results[1,`i'] = _b[DDD]
    matrix results[2,`i'] = _se[DDD]
    matrix results[1,`i'+4] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))
    matrix results[3,`i'] = _b[D]
    matrix results[4,`i'] = _se[D]
    matrix results[3,`i'+4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
}

* Display the results matrix
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

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionDDD_explosion_results.xlsx", replace
drop c1-stars_c8

******************************************************************************* Table S16
* Exclude observations after the start of the COVID-19 pandemic
drop if date > date("2020-03-11", "YMD")

* Initialize an empty matrix for results storage
matrix results = J(4, 8, .)

* Loop through four regressions, varying fixed effects and covariates
forval i = 1/4 {
    * Define model specifications dynamically
    local model_spec if `i' == 1 "fe" 
    local model_spec if `i' == 2 "fe i.zip"
    local model_spec if `i' == 3 "$control_variables fe i.zip"
    local model_spec if `i' == 4 "$control_variables fe i.zip zip#c.year"
    
    * Perform regression with robust standard errors and fixed effects
    qui xtreg lhprice DDD D1 D2 D hydrotreat hydropost explosion_post i.year i.zip `model_spec', robust cluster(importparcelid) level(95)
    
    * Store coefficients, standard errors, and p-values in the results matrix
    matrix results[1,`i'] = _b[DDD]
    matrix results[2,`i'] = _se[DDD]
    matrix results[1,`i'+4] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))
    matrix results[3,`i'] = _b[D]
    matrix results[4,`i'] = _se[D]
    matrix results[3,`i'+4] = 2 * (1 - normal(abs(_b[D]/_se[D])))
}
	
* Display the results matrix
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

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionDDD_explosion_results_dropCovid19.xlsx", replace
drop c1-stars_c8


