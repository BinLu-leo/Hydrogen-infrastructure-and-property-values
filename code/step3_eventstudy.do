clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

******************************************************************************* Fig.4
* Load the Zillow data for California properties
use "zillowCA_data.dta", clear

* Merge with covariate data on property zip and year
merge n:1 propertyzip year using "C:\\Users\\lubin\\OneDrive\\Hy_Housing\\data\\ca_covariates.dta", nogen ///
keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)

* Keep observations within 5000 meters distance
keep if dist<=5000

* Initialize treatment indicator variable as 0 (not treated)
gen treat = 0

* Mark properties within 2200 meters as treated (1)
replace treat =1 if dist <= 2200

* Generate interaction term for treatment and post-treatment period
gen D = treat * post


* Method for event study analysis using 'eventstudyinteract'
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

xtset importparcelid year

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage population per_inc hispanicshare whiteshare blackshare"

* eventstudyinteract
eventstudyinteract lhprice F*event L*event, cohort(first_treated) control_cohort(never_treat) covariates($control_variables) absorb(i.importparcelid i.year) vce(cluster importparcelid)

matrix b = e(b_iw)
matrix v = e(V_iw)
matrix se = J(rowsof(v), 1, .)
forval i = 1 / `=rowsof(v)' {
    local se_i = sqrt(el(v, `i', `i'))
    matrix se[`i', 1] = `se_i'
}
matrix se = se'
matrix p_value = J(1, 6, .)
forval i = 9/14 {
    local tstat = b[1,`i']/se[1,`i'-8]
    local pval = 2*normal(-abs(`tstat'))
    local pval_rounded = round(`pval', 0.0001)
    matrix p_value[1, `i'-8] = `pval_rounded'
    local star`i' = cond(`pval_rounded' < 0.01, "***", ///
                          cond(`pval_rounded' < 0.05, "**", ///
                          cond(`pval_rounded' < 0.1, "*", "")))
	local coef`i' : display %9.4f round(b[1,`i'], 0.0001)
}

#delimit ;
event_plot e(b_iw)#e(V_iw),
    plottype(connected) ciplottype(rcap) 
    graph_opt( 
        graphregion(color(white)) 
        xtitle("Periods since the event", size(medium)) 
        ytitle("Average effect (Coefficient)", size(medium)) 
        xlabel(-8(1)5, labsize(medium) nogrid) 
        ylabel(-0.1(0.05)0.1, labsize(medium) nogrid) 
        yline(0, lp(dot) lc(gs0) lw(thin)) 
        xline(0, lp(line) lc(gs0*0.1) lw(vvvthick)) 
        xline(-1, lp(dash) lc(gs0*0.6) lw(thin)) 
		text(0.02 0 "`coef9'`star9'", size(small)) 
        text(0.04 1 "`coef10'`star10'", size(small)) 
        text(0.02 2 "`coef11'`star11'", size(small))
        text(0.04 3 "`coef12'`star12'", size(small)) 
        text(0.02 4 "`coef13'`star13'", size(small)) 
        text(0.04 4.8 "`coef14'`star14'", size(small)) 
    ) 
    lag_opt(color(navy) msize(small)) 
    lag_ci_opt(color(black%50) msize(small)) 
    lead_opt(color(red)) lead_ci_opt(color(red%50))
    stub_lag(L#event) stub_lead(F#event) 
    trimlag(5) trimlead(8) together
;
#delimit cr
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\eventstudy.gph", replace


******************************************************************************* Fig.6
* Define a list of racial groups and their corresponding condition to be used in the loop
local groups "nonwhite=0 black=1 hispanic=1 other=1"
local graph_paths

* Loop over each racial group to perform the event study interaction and generate graphs
foreach grp in `groups' {
	
    * Split the group condition into a variable name and value
    local grp_name = word("`grp'", 1)
    local grp_condition = word("`grp'", 3)
	
    * Perform the event study interaction for the current group	
	
	#delimit ;
    eventstudyinteract lhprice F*event L*event if `grp_name'==`grp_condition', 
	cohort(first_treated) control_cohort(never_treat) 
	covariates($control_variables) absorb(i.importparcelid i.year) 
	vce(cluster importparcelid) 
	;
	#delimit cr
	
    * Extract coefficients and standard errors
    matrix b = e(b_iw)
    matrix v = e(V_iw)

    * Initialize matrices for standard errors and p-values
    matrix se = J(rowsof(v), 1, .)
    matrix p_value = J(1, 6, .)

    * Calculate standard errors for each coefficient
    forval i = 1 / `=rowsof(v)' {
        local se_i = sqrt(el(v, `i', `i'))
        matrix se[`i', 1] = `se_i'
    }
    matrix se = se'

    * Calculate p-values, assign significance stars, and round coefficients
    forval i = 9/14 {
        local tstat = b[1,`i']/se[1,`i'-8]
        local pval = 2*normal(-abs(`tstat'))
        local pval_rounded = round(`pval', 0.0001)
        matrix p_value[1, `i'-8] = `pval_rounded'
        #delimit ;
        local star`i' = cond(`pval_rounded' < 0.01, "***", 
						cond(`pval_rounded' < 0.05, "**", 
						cond(`pval_rounded' < 0.1, "*", "")))
		;
		#delimit cr				
	    local coef`i' : display %9.4f round(b[1,`i'], 0.0001)
    }

    * Generate the event plot with text annotations for coefficients and significance
	#delimit ;
    event_plot e(b_iw)#e(V_iw), 
	plottype(connected) ciplottype(rcap) 
	graph_opt(graphregion(color(white)) 
	xtitle("Periods since the event", size(small)) 
	ytitle("Average effect (Coefficient)", size(small)) 
	xlabel(-8(1)5, labsize(small) nogrid) 
	ylabel(-0.1(0.05)0.1, labsize(small) nogrid) 
	yline(0, lp(dot) lc(gs0) lw(thin)) 
	xline(0, lp(line) lc(gs0*0.1) lw(vvvthick)) 
	xline(-1, lp(dash) lc(gs0*0.6) lw(thin)) 
	title("(A) `grp_name' group", size(medium) color(black)) 
	text(0.02 0 "`coef9'`star9'", size(vsmall)) 
	text(0.04 1 "`coef10'`star10'", size(vsmall)) 
	text(0.02 2 "`coef11'`star11'", size(vsmall)) 
	text(0.04 3 "`coef12'`star12'", size(vsmall)) 
	text(0.02 4 "`coef13'`star13'", size(vsmall)) 
	text(0.04 5 "`coef14'`star14'", size(vsmall))) 
	lag_opt(color(navy) msize(small)) 
	lag_ci_opt(color(black%50) msize(small)) 
	lead_opt(color(red)) 
	lead_ci_opt(color(red%50)) 
	stub_lag(L#event) 
	stub_lead(F#event) 
	trimlag(5) 
	trimlead(8) together
	;
    #delimit cr
    * Save the graph with a title specific to the racial group
    local graph_paths "`graph_paths' C:\\Users\\lubin\\OneDrive\\Hy_Housing\\results\\`grp_name'_group.gph"
}

* Combine all saved graphs into one figure
graph combine `graph_paths', name(combined_graph, replace) ///
    imargin(0 0 0 0) bmargin(0)

* Save the combined graph to disk
graph save "C:\\Users\\lubin\\OneDrive\\Hy_Housing\\results\\hetero_race.gph", replace

