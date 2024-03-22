clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

******************************************************************************* Table S10
use "zillowCA_data.dta", clear

mat summary_stats = J(12, 4, .)
sum lhprice if treat == 1 & white == 0
mat summary_stats[1, 1] = r(mean)
mat summary_stats[2, 1] = r(sd)
mat summary_stats[3, 1] = r(N)
sum lhprice if treat == 1 & white == 1
mat summary_stats[4, 1] = r(mean)
mat summary_stats[5, 1] = r(sd)
mat summary_stats[6, 1] = r(N)
sum lhprice if treat == 0 & white == 0
mat summary_stats[7, 1] = r(mean)
mat summary_stats[8, 1] = r(sd)
mat summary_stats[9, 1] = r(N)
sum lhprice if treat == 0 & white == 1
mat summary_stats[10, 1] = r(mean)
mat summary_stats[11, 1] = r(sd)
mat summary_stats[12, 1] = r(N)

sum lhprice if treat == 1 & black == 0
mat summary_stats[1, 2] = r(mean)
mat summary_stats[2, 2] = r(sd)
mat summary_stats[3, 2] = r(N)
sum lhprice if treat == 1 & black == 1
mat summary_stats[4, 2] = r(mean)
mat summary_stats[5, 2] = r(sd)
mat summary_stats[6, 2] = r(N)
sum lhprice if treat == 0 & black == 0
mat summary_stats[7, 2] = r(mean)
mat summary_stats[8, 2] = r(sd)
mat summary_stats[9, 2] = r(N)
sum lhprice if treat == 0 & black == 1
mat summary_stats[10, 2] = r(mean)
mat summary_stats[11, 2] = r(sd)
mat summary_stats[12, 2] = r(N)

sum lhprice if treat == 1 & hispanic == 0
mat summary_stats[1, 3] = r(mean)
mat summary_stats[2, 3] = r(sd)
mat summary_stats[3, 3] = r(N)
sum lhprice if treat == 1 & hispanic == 1
mat summary_stats[4, 3] = r(mean)
mat summary_stats[5, 3] = r(sd)
mat summary_stats[6, 3] = r(N)
sum lhprice if treat == 0 & hispanic == 0
mat summary_stats[7, 3] = r(mean)
mat summary_stats[8, 3] = r(sd)
mat summary_stats[9, 3] = r(N)
sum lhprice if treat == 0 & hispanic == 1
mat summary_stats[10, 3] = r(mean)
mat summary_stats[11, 3] = r(sd)
mat summary_stats[12, 3] = r(N)

sum lhprice if treat == 1 & other == 0
mat summary_stats[1, 4] = r(mean)
mat summary_stats[2, 4] = r(sd)
mat summary_stats[3, 4] = r(N)
sum lhprice if treat == 1 & other == 1
mat summary_stats[4, 4] = r(mean)
mat summary_stats[5, 4] = r(sd)
mat summary_stats[6, 4] = r(N)
sum lhprice if treat == 0 & other == 0
mat summary_stats[7, 4] = r(mean)
mat summary_stats[8, 4] = r(sd)
mat summary_stats[9, 4] = r(N)
sum lhprice if treat == 0 & other == 1
mat summary_stats[10, 4] = r(mean)
mat summary_stats[11, 4] = r(sd)
mat summary_stats[12, 4] = r(N)

matrix list summary_stats
svmat summary_stats
export excel summary_stats1 summary_stats2 summary_stats3  summary_stats4 using /// 
			"C:\Users\lubin\OneDrive\Hy_Housing\results\summary_stats_race.xlsx", replace

******************************************************************************* Table 3
use "zillowCA_data.dta", clear

keep if dist<=5000

gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post 

xtset importparcelid year

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

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

	// Outcome
	local Y					lhprice
	// Treatment
	local suffixes			D
	// Covs by col
	#delimit ;
	local covs_1			lotsizeacres ///
							lotsizesquarefeet ///
							landassessedvalue ///
							totalbedrooms ///
							building_area ///
							buildingage ///
							per_inc ///
							population ///
							hispanicshare ///
							whiteshare ///
							blackshare ///
	;
	#delimit cr
	//local covs_2			`cov_1' (1.black 1.hispanic 1.other)##(zip year)
	//local covs_3			`covs_2' year#zip
	//local covs_4			`covs_2' year#zip

	// Get output matrix format
	local n_cols = 9
	local n_rows = 21
	mat results = J(`n_rows', `n_cols', 0)

	// Loop over treatment suffixes (which define tables)
	//foreach suf of local suffixes {
		// Loop over samples (which also define tables)
		//foreach s of local samples {	
			// Declare treatment
			local X D	
			// Store sample means
			local col = 1
			local row = 1
			local races_1 !nonwhite nonwhite
			local races_2 !nonwhite hispanic black other
			forvalues r = 1/2 {
				foreach race of local races_`r' {
					gstats sum lhprice if `race' , meanonly
					mat results[`row', `col'] = r(mean)
					local row = `row'+2
				}
				// Add two empty rows between panels
				local row = `row'+2
			}
			// Initialize first col counter (i.e., adds a col for means)
			local col0 = 1

			****************
			****************
			*** DD specs ***
			****************
			****************	
			forvalues col = 1/2 {
			//column(1)
				// Initialize row counter
				local row = 1
				
				**************************************
				*** PANEL A: WHITES vs. NON-WHITES ***
				**************************************
				local inter nonwhite
				local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
				;
				#delimit cr
				// Store estimates
				lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']				
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				//mat results[`row', `n_cols'-2] = `tstat'
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
				
				mat results[`row'+2, `col0'+`col'] = r(estimate)
				mat results[`row'+3, `col0'+`col'] = r(se)				
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+2, `col0'+`col'+4] = `pval'							
				
				lincom (1.`X'#1.`inter') + 1.`inter'
				mat results[`row'+4, `col0'+`col'] = r(estimate)
				mat results[`row'+5, `col0'+`col'] = r(se)	
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+4, `col0'+`col'+4] = `pval'
				
				mat results[`n_rows', `col0'+`col'] = e(N)
				// Increase col counter
				local row = `row'+6
				
				***********************************************************
				*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
				***********************************************************
				local interactions hispanic black other

				// Run regression				
				xtreg lhprice `covs_`col'' `X'##`inter' , fe cluster(importparcelid)				
				// Store estimates
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'				
				// Increase row counter
				local row = `row'+2
				
				// Store main effects
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr					
					
					// Main effect on group
					lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store differential effects from baseline group
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr						
					lincom (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store sample size
				mat results[`n_rows', `col0'+`col'] = e(N)
			}				


			**************************
			**************************
			*** DDD specifications ***
			**************************
			**************************

			// Initialize col and row counters
			local col = 3
			local row = 5

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.`inter')##(zip year)
			local covs_3			`covs_2' zip##year
			
			// Run regression
			timer clear 2
			timer on 2
			#delimit ;
			xtreg `Y' `covs_`col'' `X'#`inter', fe cluster(importparcelid)
			;
			#delimit cr
			timer off 2
			timer list 2

			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X'#1.`inter']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`inter']
			// t-test
			local tstat = _b[1.`X'#1.`inter']/_se[1.`X'#1.`inter']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'
					
			mat results[`n_rows', `col0'+`col'] = e(N)

			// Increase row counter
			local row = `row'+10

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Store estimates
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_3			`covs_2' zip##year
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'#`v', fe cluster(importparcelid)
				;
				#delimit cr				
				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
			
				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)

			********************
			********************
			*** Property FEs ***
			********************
			********************

			// Initialize col and row counters
			local col = 4
			local row = 1

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
			local covs_4			`covs_2' zip##year
			
			// Run regression
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			// Store estimates
			lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
			
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'			
			
			mat results[`row'+2, `col0'+`col'] = r(estimate)
			mat results[`row'+3, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+2, `col0'+`col'+4] = `pval'			

			lincom (1.`X'#1.nonwhite) + 1.`inter'
			mat results[`row'+4, `col0'+`col'] = r(estimate)
			mat results[`row'+5, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+4, `col0'+`col'+4] = `pval'			
			
			mat results[`n_rows', `col0'+`col'] = e(N)
	
			// Increase row counter
			local row = `row'+6

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Run regression
			#delimit ;
			//xtreg `Y' `covs_`col'' `X'##(1.hispanic 1.black 1.other), fe cluster(importparcelid)
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			;
			#delimit cr
			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'	
			
			// Increase row counter
			local row = `row'+2

			// Store main effects
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
				// Main effect on group
				lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
				mat results[`row', `col0'+`col'] = r(estimate)
				mat results[`row'+1, `col0'+`col'] = r(se)
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'					
				
				// Increase row counter
				local row = `row'+2
			}

			// Store differential effects from baseline group
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' 1.`X'#1.`v', fe cluster(importparcelid)				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'	

				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)
		
			svmat results
		
			foreach i of numlist 6/9 {
				gen stars`i' = ""
				replace stars`i' = "***" if results`i' < 0.01
				replace stars`i' = "**" if results`i' >= 0.01 & results`i' < 0.05
				replace stars`i' = "*" if results`i' >= 0.05 & results`i' < 0.1
			}
			
export excel results1 results2 results3 results4 results5 stars6 stars7 ///
				stars8 stars9 using "C:\Users\lubin\OneDrive\Hy_Housing\results\final_results_raceFE.xlsx", replace
}


******************************************************************************* Table S12
use "zillowCA_data.dta", clear
keep if dist<=5000

gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post 

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

drop nonwhite white black hispanic other
local whiteshare_mean = 34.7
gen nonwhite = .
replace nonwhite = 1 if whiteshare <= `whiteshare_mean'
replace nonwhite = 0 if whiteshare > `whiteshare_mean'
gen white = (nonwhite == 0)

local hispanicshare_mean = 39.4
gen hispanic = .
replace hispanic = 1 if hispanicshare >= `hispanicshare_mean'
replace hispanic = 0 if hispanicshare < `hispanicshare_mean'

local blackshare_mean = 5.7
gen black = .
replace black = 1 if blackshare >= `blackshare_mean'
replace black = 0 if blackshare < `blackshare_mean'

local other_race_mean = 20
gen other = .
//gen other_race = 100 - whiteshare - blackshare - hispanicshare
replace other = 1 if other_race >= `other_race_mean'
replace other = 0 if other_race < `other_race_mean'


	// Outcome
	local Y					lhprice
	// Treatment suffixes and samples, whose combos determine tables
	local suffixes			D //strict
	// Covs by col
	#delimit ;
	local covs_1			lotsizeacres ///
							lotsizesquarefeet ///
							landassessedvalue ///
							totalbedrooms ///
							building_area ///
							buildingage ///
							per_inc ///
							population ///
							hispanicshare ///
							whiteshare ///
							blackshare ///
	;
	#delimit cr
	//local covs_2			`cov_1' (1.black 1.hispanic 1.other)##(zip year)
	//local covs_3			`covs_2' year#zip
	//local covs_4			`covs_2' year#zip

	// Get output matrix format
	local n_cols = 9
	local n_rows = 21
	mat results = J(`n_rows', `n_cols', 0)

	// Loop over treatment suffixes (which define tables)
	//foreach suf of local suffixes {
		// Loop over samples (which also define tables)
		//foreach s of local samples {	
			// Declare treatment
			local X D	
			// Store sample means
			local col = 1
			local row = 1
			local races_1 !nonwhite nonwhite
			local races_2 !nonwhite hispanic black other
			forvalues r = 1/2 {
				foreach race of local races_`r' {
					gstats sum lhprice if `race' , meanonly
					mat results[`row', `col'] = r(mean)
					local row = `row'+2
				}
				// Add two empty rows between panels
				local row = `row'+2
			}
			// Initialize first col counter (i.e., adds a col for means)
			local col0 = 1

			****************
			****************
			*** DD specs ***
			****************
			****************	
			forvalues col = 1/2 {
			//column(1)
				// Initialize row counter
				local row = 1
				
				**************************************
				*** PANEL A: WHITES vs. NON-WHITES ***
				**************************************
				local inter nonwhite
				local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
				;
				#delimit cr
				// Store estimates
				lincom 1.`X' + (1.`X'#1.nonwhite) + 1.nonwhite
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']				
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				//mat results[`row', `n_cols'-2] = `tstat'
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
				
				mat results[`row'+2, `col0'+`col'] = r(estimate)
				mat results[`row'+3, `col0'+`col'] = r(se)				
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+2, `col0'+`col'+4] = `pval'							
				
				lincom (1.`X'#1.`inter') + 1.`inter'
				mat results[`row'+4, `col0'+`col'] = r(estimate)
				mat results[`row'+5, `col0'+`col'] = r(se)	
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+4, `col0'+`col'+4] = `pval'
				
				mat results[`n_rows', `col0'+`col'] = e(N)
				// Increase col counter
				local row = `row'+6
				
				***********************************************************
				*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
				***********************************************************
				local interactions hispanic black other

				// Run regression				
				xtreg lhprice `covs_`col'' `X'##nonwhite , fe cluster(importparcelid)				
				// Store estimates
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'				
				// Increase row counter
				local row = `row'+2
				
				// Store main effects
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					//xtreg `Y' `covs_`col'' `X'##(1.hispanic 1.black 1.other), fe cluster(importparcelid)
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr					
					
					// Main effect on group
					lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store differential effects from baseline group
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr						
					lincom (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store sample size
				mat results[`n_rows', `col0'+`col'] = e(N)
			}				


			**************************
			**************************
			*** DDD specifications ***
			**************************
			**************************

			// Initialize col and row counters
			local col = 3
			local row = 5

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.nonwhite)##(zip year)
			local covs_3			`covs_2' zip##year
			
			// Run regression
			timer clear 2
			timer on 2
			#delimit ;
			xtreg `Y' `covs_`col'' `X'#`inter', fe cluster(importparcelid)
			;
			#delimit cr
			timer off 2
			timer list 2

			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X'#1.`inter']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`inter']
			// t-test
			local tstat = _b[1.`X'#1.`inter']/_se[1.`X'#1.`inter']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'
					
			mat results[`n_rows', `col0'+`col'] = e(N)

			// Increase row counter
			local row = `row'+10

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Store estimates
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_3			`covs_2' zip##year
				// Run regression
				#delimit ;
				//xtreg `Y' `covs_`col'' 1.`X'#1.hispanic 1.`X'#1.black 1.`X'#1.other, fe cluster(importparcelid)
				xtreg `Y' `covs_`col'' `X'#`v', fe cluster(importparcelid)
				;
				#delimit cr				
				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
			
				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)

			********************
			********************
			*** Property FEs ***
			********************
			********************

			// Initialize col and row counters
			local col = 4
			local row = 1

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
			local covs_4			`covs_2' zip##year
			
			// Run regression
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			// Store estimates
			lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
			
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'			
			
			mat results[`row'+2, `col0'+`col'] = r(estimate)
			mat results[`row'+3, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+2, `col0'+`col'+4] = `pval'			

			lincom (1.`X'#1.nonwhite) + 1.`inter'
			mat results[`row'+4, `col0'+`col'] = r(estimate)
			mat results[`row'+5, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+4, `col0'+`col'+4] = `pval'			
			
			mat results[`n_rows', `col0'+`col'] = e(N)
	
			// Increase row counter
			local row = `row'+6

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Run regression
			#delimit ;
			//xtreg `Y' `covs_`col'' `X'##(1.hispanic 1.black 1.other), fe cluster(importparcelid)
			xtreg `Y' `covs_`col'' `X'##nonwhite, fe cluster(importparcelid)
			;
			#delimit cr
			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'	
			
			// Increase row counter
			local row = `row'+2

			// Store main effects
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
				// Main effect on group
				lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
				mat results[`row', `col0'+`col'] = r(estimate)
				mat results[`row'+1, `col0'+`col'] = r(se)
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'					
				
				// Increase row counter
				local row = `row'+2
			}

			// Store differential effects from baseline group
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' 1.`X'#1.`v', fe cluster(importparcelid)				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'	

				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)

			svmat results

			foreach i of numlist 6/9 {
				gen stars`i' = ""
				replace stars`i' = "***" if results`i' < 0.01
				replace stars`i' = "**" if results`i' >= 0.01 & results`i' < 0.05
				replace stars`i' = "*" if results`i' >= 0.05 & results`i' < 0.1
			}
			
export excel results1 results2 results3 results4 results5 stars6 stars7 ///
				stars8 stars9 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_final_results_raceFE_mean.xlsx", replace
}

******************************************************************************* Table S13-S14
use "zillowCA_data.dta", clear

gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post 

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen ///
keep(match) keepusing(whiteshare blackshare hispanicshare)

local whiteshare_mean = 59.5
gen nonwhite = .
replace nonwhite = 1 if whiteshare <= `whiteshare_mean'
replace nonwhite = 0 if whiteshare > `whiteshare_mean'
gen white = (nonwhite == 0)

local blackshare_mean = 5.8
gen black = .
replace black = 1 if blackshare >= `blackshare_mean'
replace black = 0 if blackshare < `blackshare_mean'

local hispanicshare_mean = 39.4
gen hispanic = .
replace hispanic = 1 if hispanicshare >= `hispanicshare_mean'
replace hispanic = 0 if hispanicshare < `hispanicshare_mean'

local other_race_mean = 20
gen other = .
gen other_race = 100 - whiteshare - blackshare - hispanicshare
replace other = 1 if other_race >= `other_race_mean'
replace other = 0 if other_race < `other_race_mean'

********Table S14
mat summary_stats = J(12, 2, .)
sum lhprice if treat == 1 & white == 0
mat summary_stats[1, 1] = r(mean)
mat summary_stats[2, 1] = r(sd)
mat summary_stats[3, 1] = r(N)
sum lhprice if treat == 1 & white == 1
mat summary_stats[4, 1] = r(mean)
mat summary_stats[5, 1] = r(sd)
mat summary_stats[6, 1] = r(N)
sum lhprice if treat == 0 & white == 0
mat summary_stats[7, 1] = r(mean)
mat summary_stats[8, 1] = r(sd)
mat summary_stats[9, 1] = r(N)
sum lhprice if treat == 0 & white == 1
mat summary_stats[10, 1] = r(mean)
mat summary_stats[11, 1] = r(sd)
mat summary_stats[12, 1] = r(N)

sum lhprice if treat == 1 & black == 0
mat summary_stats[1, 2] = r(mean)
mat summary_stats[2, 2] = r(sd)
mat summary_stats[3, 2] = r(N)
sum lhprice if treat == 1 & black == 1
mat summary_stats[4, 2] = r(mean)
mat summary_stats[5, 2] = r(sd)
mat summary_stats[6, 2] = r(N)
sum lhprice if treat == 0 & black == 0
mat summary_stats[7, 2] = r(mean)
mat summary_stats[8, 2] = r(sd)
mat summary_stats[9, 2] = r(N)
sum lhprice if treat == 0 & black == 1
mat summary_stats[10, 2] = r(mean)
mat summary_stats[11, 2] = r(sd)
mat summary_stats[12, 2] = r(N)


matrix list summary_stats
svmat summary_stats
export excel summary_stats1 summary_stats2 using /// 
			"C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_summary_stats_race.xlsx", replace
drop summary_stats1 summary_stats2

			
	// Outcome
	local Y					lhprice
	// Treatment suffixes and samples, whose combos determine tables
	local suffixes			D //strict
	// Covs by col
	#delimit ;
	local covs_1			lotsizeacres ///
							lotsizesquarefeet ///
							landassessedvalue ///
							totalbedrooms ///
							building_area ///
							buildingage ///
							per_inc ///
							population ///
							hispanicshare ///
							whiteshare ///
							blackshare ///
	;
	#delimit cr
	//local covs_2			`cov_1' (1.black 1.hispanic 1.other)##(zip year)
	//local covs_3			`covs_2' year#zip
	//local covs_4			`covs_2' year#zip

	// Get output matrix format
	local n_cols = 9
	local n_rows = 21
	mat results = J(`n_rows', `n_cols', 0)

	// Loop over treatment suffixes (which define tables)
	//foreach suf of local suffixes {
		// Loop over samples (which also define tables)
		//foreach s of local samples {	
			// Declare treatment
			local X D	
			// Store sample means
			local col = 1
			local row = 1
			local races_1 !nonwhite nonwhite
			local races_2 black !black
			forvalues r = 1/2 {
				foreach race of local races_`r' {
					gstats sum lhprice if `race' , meanonly
					mat results[`row', `col'] = r(mean)
					local row = `row'+2
				}
				// Add two empty rows between panels
				local row = `row'+2
			}
			// Initialize first col counter (i.e., adds a col for means)
			local col0 = 1

			****************
			****************
			*** DD specs ***
			****************
			****************	
			forvalues col = 1/2 {
			//column(1)
				// Initialize row counter
				local row = 1
				
				**************************************
				*** PANEL A: WHITES vs. NON-WHITES ***
				**************************************
				local inter nonwhite
				local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
				;
				#delimit cr
				// Store estimates
				lincom 1.`X' + (1.`X'#1.nonwhite) + 1.nonwhite
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']				
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				//mat results[`row', `n_cols'-2] = `tstat'
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
				
				mat results[`row'+2, `col0'+`col'] = r(estimate)
				mat results[`row'+3, `col0'+`col'] = r(se)				
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+2, `col0'+`col'+4] = `pval'							
				
				lincom (1.`X'#1.`inter') + 1.`inter'
				mat results[`row'+4, `col0'+`col'] = r(estimate)
				mat results[`row'+5, `col0'+`col'] = r(se)	
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+4, `col0'+`col'+4] = `pval'
				
				mat results[`n_rows', `col0'+`col'] = e(N)
				// Increase col counter
				local row = `row'+6
				
				***********************************************************
				*** PANEL B: BLACKS  ***
				***********************************************************
				local inter black
				local covs_2			`covs_1' (1.black)##(zip year)
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
				;
				#delimit cr
				// Store estimates
				lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
				mat results[`row', `col0'+`col'] = r(estimate)
				mat results[`row'+1, `col0'+`col'] = r(se)				
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
				
				mat results[`row'+2, `col0'+`col'] = _b[1.`X']
				mat results[`row'+3, `col0'+`col'] = _se[1.`X']				
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+2, `col0'+`col'+4] = `pval'							
				
				lincom (1.`X'#1.`inter') + 1.`inter'
				mat results[`row'+4, `col0'+`col'] = r(estimate)
				mat results[`row'+5, `col0'+`col'] = r(se)	
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+4, `col0'+`col'+4] = `pval'		

			**************************
			**************************
			*** DDD specifications ***
			**************************
			**************************

			// Initialize col and row counters
			local col = 3
			local row = 5

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
			local covs_3			`covs_2' zip##year
			
			// Run regression
			timer clear 2
			timer on 2
			#delimit ;
			xtreg `Y' `covs_`col'' `X'#`inter', fe cluster(importparcelid)
			;
			#delimit cr
			timer off 2
			timer list 2

			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X'#1.`inter']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`inter']
			// t-test
			local tstat = _b[1.`X'#1.`inter']/_se[1.`X'#1.`inter']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'

			// Increase row counter
			local row = `row'+6

			***********************************************************
			*** PANEL B: BLACKS ***
			***********************************************************
			local inter black
			local covs_2			`covs_1' (1.black)##(zip year)
			local covs_3			`covs_2' zip##year
			
			// Run regression
			#delimit ;
			xtreg `Y' `covs_`col'' `X'#`inter', fe cluster(importparcelid)
			;
			#delimit cr

			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X'#1.`inter']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`inter']
			// t-test
			local tstat = _b[1.`X'#1.`inter']/_se[1.`X'#1.`inter']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'
			}

			********************
			********************
			*** Property FEs ***
			********************
			********************

			// Initialize col and row counters
			local col = 4
			local row = 1

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
			local covs_4			`covs_2' zip##year
			
			// Run regression
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			// Store estimates
			lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
			
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'			
			
			mat results[`row'+2, `col0'+`col'] = r(estimate)
			mat results[`row'+3, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+2, `col0'+`col'+4] = `pval'			

			lincom (1.`X'#1.nonwhite) + 1.`inter'
			mat results[`row'+4, `col0'+`col'] = r(estimate)
			mat results[`row'+5, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+4, `col0'+`col'+4] = `pval'			
			
			mat results[`n_rows', `col0'+`col'] = e(N)
	
			// Increase row counter
			local row = `row'+6

			***********************************************************
			*** PANEL B: BLACKS ***
			***********************************************************
			local inter black
			local covs_2			`covs_1' (1.black)##(zip year)
			local covs_4			`covs_2' zip##year
			
			// Run regression
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			// Store estimates
			lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
			
			mat results[`row', `col0'+`col'] = r(estimate)
			mat results[`row'+1, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'			
			
			mat results[`row'+2, `col0'+`col'] = _b[1.`X']
			mat results[`row'+3, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+2, `col0'+`col'+4] = `pval'			

			lincom (1.`X'#1.`inter') + 1.`inter'
			mat results[`row'+4, `col0'+`col'] = r(estimate)
			mat results[`row'+5, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+4, `col0'+`col'+4] = `pval'			
			
			svmat results

			foreach i of numlist 6/9 {
				gen stars`i' = ""
				replace stars`i' = "***" if results`i' < 0.01
				replace stars`i' = "**" if results`i' >= 0.01 & results`i' < 0.05
				replace stars`i' = "*" if results`i' >= 0.05 & results`i' < 0.1
			}
			
export excel results1 results2 results3 results4 results5 stars6 stars7 ///
				stars8 stars9 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_final_results_raceFE_mean_NoHispanic.xlsx", replace
}			
			
			
******************************************************************************* Table S17
drop if date > date("2020-03-11", "YMD")
	
	// Outcome
	local Y					lhprice
	// Treatment suffixes and samples, whose combos determine tables
	local suffixes			D
	// Covs by col
	#delimit ;
	local covs_1			lotsizeacres ///
							lotsizesquarefeet ///
							landassessedvalue ///
							totalbedrooms ///
							building_area ///
							buildingage ///
							per_inc ///
							population ///
							hispanicshare ///
							whiteshare ///
							blackshare ///
	;
	#delimit cr
	//local covs_2			`cov_1' (1.black 1.hispanic 1.other)##(zip year)
	//local covs_3			`covs_2' year#zip
	//local covs_4			`covs_2' year#zip

	// Get output matrix format
	local n_cols = 9
	local n_rows = 21
	mat results = J(`n_rows', `n_cols', 0)

	// Loop over treatment suffixes (which define tables)
	//foreach suf of local suffixes {
		// Loop over samples (which also define tables)
		//foreach s of local samples {	
			// Declare treatment
			local X D	
			// Store sample means
			local col = 1
			local row = 1
			local races_1 !nonwhite nonwhite
			local races_2 !nonwhite hispanic black other
			forvalues r = 1/2 {
				foreach race of local races_`r' {
					gstats sum lhprice if `race' , meanonly
					mat results[`row', `col'] = r(mean)
					local row = `row'+2
				}
				// Add two empty rows between panels
				local row = `row'+2
			}
			// Initialize first col counter (i.e., adds a col for means)
			local col0 = 1

			****************
			****************
			*** DD specs ***
			****************
			****************	
			forvalues col = 1/2 {
			//column(1)
				// Initialize row counter
				local row = 1
				
				**************************************
				*** PANEL A: WHITES vs. NON-WHITES ***
				**************************************
				local inter nonwhite
				local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
				// Run regression
				#delimit ;
				xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
				;
				#delimit cr
				// Store estimates
				lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']				
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				//mat results[`row', `n_cols'-2] = `tstat'
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
				
				mat results[`row'+2, `col0'+`col'] = r(estimate)
				mat results[`row'+3, `col0'+`col'] = r(se)				
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+2, `col0'+`col'+4] = `pval'							
				
				lincom (1.`X'#1.`inter') + 1.`inter'
				mat results[`row'+4, `col0'+`col'] = r(estimate)
				mat results[`row'+5, `col0'+`col'] = r(se)	
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row'+4, `col0'+`col'+4] = `pval'
				
				mat results[`n_rows', `col0'+`col'] = e(N)
				// Increase col counter
				local row = `row'+6
				
				***********************************************************
				*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
				***********************************************************
				local interactions hispanic black other

				// Run regression				
				xtreg lhprice `covs_`col'' `X'##`inter' , fe cluster(importparcelid)				
				// Store estimates
				mat results[`row', `col0'+`col'] = _b[1.`X']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X']
				// t-test
				local tstat = _b[1.`X']/_se[1.`X']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'				
				// Increase row counter
				local row = `row'+2
				
				// Store main effects
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr					
					
					// Main effect on group
					lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store differential effects from baseline group
				foreach v of varlist `interactions' {
					local covs_2			`covs_1' (1.`v')##(zip year)
					#delimit ;
					xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
					;
					#delimit cr						
					lincom (1.`X'#1.`v') + 1.`v'
					mat results[`row', `col0'+`col'] = r(estimate)
					mat results[`row'+1, `col0'+`col'] = r(se)
					// t-test
					local tstat = r(estimate)/r(se)
					// p-value, twotail
					local pval = 2*normal(-abs(`tstat'))
					mat results[`row', `col0'+`col'+4] = `pval'
					
					// Increase row counter
					local row = `row'+2
				}

				// Store sample size
				mat results[`n_rows', `col0'+`col'] = e(N)
			}				


			**************************
			**************************
			*** DDD specifications ***
			**************************
			**************************

			// Initialize col and row counters
			local col = 3
			local row = 5

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.nonwhite)##(zip year)
			local covs_3			`covs_2' zip##year
			
			// Run regression
			timer clear 2
			timer on 2
			#delimit ;
			xtreg `Y' `covs_`col'' `X'#`inter', fe cluster(importparcelid)
			;
			#delimit cr
			timer off 2
			timer list 2

			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X'#1.`inter']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`inter']
			// t-test
			local tstat = _b[1.`X'#1.`inter']/_se[1.`X'#1.`inter']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'
					
			mat results[`n_rows', `col0'+`col'] = e(N)

			// Increase row counter
			local row = `row'+10

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Store estimates
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_3			`covs_2' zip##year
				// Run regression
				#delimit ;
				//xtreg `Y' `covs_`col'' 1.`X'#1.hispanic 1.`X'#1.black 1.`X'#1.other, fe cluster(importparcelid)
				xtreg `Y' `covs_`col'' `X'#`v', fe cluster(importparcelid)
				;
				#delimit cr				
				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'
			
				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)

			********************
			********************
			*** Property FEs ***
			********************
			********************

			// Initialize col and row counters
			local col = 4
			local row = 1

			**************************************
			*** PANEL A: WHITES vs. NON-WHITES ***
			**************************************
			local inter nonwhite
			local covs_2			`covs_1' (1.black 1.hispanic 1.other)##(zip year)
			local covs_4			`covs_2' zip##year
			
			// Run regression
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			// Store estimates
			lincom 1.`X' + (1.`X'#1.`inter') + 1.`inter'
			
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'			
			
			mat results[`row'+2, `col0'+`col'] = r(estimate)
			mat results[`row'+3, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+2, `col0'+`col'+4] = `pval'			

			lincom (1.`X'#1.nonwhite) + 1.`inter'
			mat results[`row'+4, `col0'+`col'] = r(estimate)
			mat results[`row'+5, `col0'+`col'] = r(se)
			// t-test
			local tstat = r(estimate)/r(se)
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row'+4, `col0'+`col'+4] = `pval'			
			
			mat results[`n_rows', `col0'+`col'] = e(N)
	
			// Increase row counter
			local row = `row'+6

			***********************************************************
			*** PANEL B: WHITES vs. HISPANICS vs. BLACKS vs. OTHERS ***
			***********************************************************
			local interactions hispanic black other
			
			// Run regression
			#delimit ;
			xtreg `Y' `covs_`col'' `X'##`inter', fe cluster(importparcelid)
			;
			#delimit cr
			// Store estimates
			mat results[`row', `col0'+`col'] = _b[1.`X']
			mat results[`row'+1, `col0'+`col'] = _se[1.`X']
			// t-test
			local tstat = _b[1.`X']/_se[1.`X']
			// p-value, twotail
			local pval = 2*normal(-abs(`tstat'))
			mat results[`row', `col0'+`col'+4] = `pval'	
			
			// Increase row counter
			local row = `row'+2

			// Store main effects
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' `X'##`v', fe cluster(importparcelid)
				// Main effect on group
				lincom 1.`X' + (1.`X'#1.`v') + 1.`v'
				mat results[`row', `col0'+`col'] = r(estimate)
				mat results[`row'+1, `col0'+`col'] = r(se)
				// t-test
				local tstat = r(estimate)/r(se)
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'					
				
				// Increase row counter
				local row = `row'+2
			}

			// Store differential effects from baseline group
			foreach v of varlist `interactions' {
				local covs_2			`covs_1' (1.`v')##(zip year)
				local covs_4			`covs_2' zip##year
				
				xtreg `Y' `covs_`col'' 1.`X'#1.`v', fe cluster(importparcelid)				
				mat results[`row', `col0'+`col'] = _b[1.`X'#1.`v']
				mat results[`row'+1, `col0'+`col'] = _se[1.`X'#1.`v']
				// t-test
				local tstat = _b[1.`X'#1.`v']/_se[1.`X'#1.`v']
				// p-value, twotail
				local pval = 2*normal(-abs(`tstat'))
				mat results[`row', `col0'+`col'+4] = `pval'	

				// Increase row counter
				local row = `row'+2
			}

			// Store sample size
			mat results[`n_rows', `col0'+`col'] = e(N)
		
			svmat results
		
			foreach i of numlist 6/9 {
				gen stars`i' = ""
				replace stars`i' = "***" if results`i' < 0.01
				replace stars`i' = "**" if results`i' >= 0.01 & results`i' < 0.05
				replace stars`i' = "*" if results`i' >= 0.05 & results`i' < 0.1
			}
			
export excel results1 results2 results3 results4 results5 stars6 stars7 ///
				stars8 stars9 using "C:\Users\lubin\OneDrive\Hy_Housing\results\final_results_raceFE_dropCovid19.xlsx", replace
}			
			
		