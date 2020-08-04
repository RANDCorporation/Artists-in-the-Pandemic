* COMMENTARY (The RAND Blog)
* Title: The pandemic is a disaster for artists

* This Do file uses a pre-generated data dictionary from IPUMS to format the CPS extract.

* NOTE(S): 
* 1. You need to set the Stata working directory to the path where the data file is located.
* 2. You also need to ensure that the CPS data extract file name reflects the file name of your query (see line 51 of "Format CPS extract.do").

/*
Variables in our extract: 
Type	Variable	Label
H		YEAR		Survey year
H		SERIAL		Household serial number
H		MONTH		Month
H		HWTFINL		Household weight, Basic Monthly
H		CPSID		CPSID, household record
H		ASECFLAG	Flag for ASEC
H		MISH		Month in sample, household level
H		REGION		Region and division
H		STATEFIP	State (FIPS code)
H		METAREA		Metropolitan area
H		COUNTY		FIPS county code
H		FAMINC		Family income of householder
H		HRHHID		Household ID, part 1
H		HRHHID2		Household ID, part 2
P		PERNUM		Person number in sample unit
P		WTFINL		Final Basic Weight
P		CPSIDP		CPSID, person record
P		RELATE		Relationship to household head
P		AGE			Age
P		SEX			Sex
P		RACE		Race
P		POPSTAT		Adult civilian, armed forces, or child
P		HISPAN		Hispanic origin
P		EMPSTAT		Employment status
P		LABFORCE	Labor force status
P		OCC			Occupation
P		OCC2010		Occupation, 2010 basis
P		IND1990		Industry, 1990 basis
P		IND			Industry
P		CLASSWKR	Class of worker
P		AHRSWORKT	Hours worked last week
P		AHRSWORK1	Hours worked last week, main job
P		AHRSWORK2	Hours worked last week, other job(s)
P		ABSENT		Absent from work last week
P		DURUNEM2	Continuous weeks unemployed, intervalled
P		DURUNEMP	Continuous weeks unemployed
P		WHYUNEMP	Reason for unemployment
P		WHYABSNT	Reason for absence from work
P		WHYPTLWK	Reason for working part time last week
P		WKSTAT		Full or part time status
P		EDUC		Educational attainment recode
P		EDUC99		Educational attainment, 1990
P		EDDIPGED	High school or GED
P		SCHLCOLL	School or college attendance
*/

* Set working directory
global dirs []

* Format raw CPS data
do "$dirs/Format CPS extract.do"

* Re-load analytic file
use "$dirs/cps_00035.dta", clear

keep if year == 2020 & (month == 1 | month == 5)

* Drop individuals not in the labor force.
drop if labforce != 2

* Drop unpaid family workers
drop if classwkr == 29

drop if age < 18

* Identify employed and unemployed persons
gen emp_person = (empstat == 10 | empstat == 12)
gen unemp_person = (empstat == 21 | empstat == 22)

* Assign individual occupations to artist categories
* Note(s): occ2010 are not yet available for 2020 CPS data (as of June 16, 2020), 
* so here we use the current occupation code.

* Performing artists and directors, dancers and choreographers, Musicians & Composers, 
* and Other
gen art_cat = 1 if occ == 2700 | occ == 2710 | occ == 2740
replace art_cat = 1 if occ == 2751 | occ == 2752
replace art_cat = 1 if occ == 2755 | occ == 2770
 
* Artists (and related workers) and Photographers, Designers (all), and Writers
replace art_cat = 2 if occ == 2600 | occ == 2910
replace art_cat = 2 if occ >= 2631 & occ <= 2630
replace art_cat = 2 if occ == 2850

* Architects (except naval) and Landscape architects, Library, museum, and archival specialists
replace art_cat = 3 if occ == 1305 | occ == 1306
replace art_cat = 3 if occ >= 2400 & occ <= 2440

* As a comparison, we will also break out the following occupations that have a lot of artists:
* Retail & wholesale
replace art_cat = 4 if occ >= 4700 & occ <= 4760

* Food service
replace art_cat = 5 if occ >= 4000 & occ <= 4160

* All other occupationss
replace art_cat = 6 if art_cat == .

* Re-define two or more races
replace race = 800 if race >= 801


* Calculate the unemployment rate and plot
preserve
	* Aggregate to the artist category by year
	collapse (sum) emp_person unemp_person [pweight=wtfinl], by(art_cat year month)

	format emp_person unemp_person %15.0f
	
	label define art_labs 1 "Performing artists" 2 "Non-performing artists" 3 "Architects and archivists" 4 "Retail and wholesale" 5 "Food services" 6 "All other occupations" 
	label values art_cat art_labs

	* Calculate the unemployment rate
	gen unemp_rate = (unemp_person / (emp_person + unemp_person)) * 100
	
	* Reshape to wide
	quietly reshape wide unemp_rate unemp_person emp_person, i(year art_cat) j(month)

	* Figure 1
	graph hbar unemp_rate1 unemp_rate5, over(art_cat) graphregion(color(white)) ytitle(Unemployment Rate) legend(order(1 "January" 2 "May") rows(1)) bar(1, color(navy)) bar(2, color(maroon)) blabel(total, format(%02.01f)) ylabel(0(10)50, grid) yline(50, lcolor(gs13))
	graph export "$dirs/unemp_rate_janmay2020.pdf", replace
	
	* Export figure data to Excel
	keep year art_cat unemp_rate1 unemp_rate5
	label var art_cat "Artist category"
	label var unemp_rate1 "January unemployment rate"
	label var unemp_rate5 "May unemployment rate"
	export excel "$dirs/figure_output.xlsx", sheetreplace sheet("Jan-May Unemp Rate") firstrow(varlabels)
restore
