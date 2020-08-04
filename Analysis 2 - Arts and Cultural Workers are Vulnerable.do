* COMMENTARY (The RAND Blog)
* Title: Arts and Cultural Workers are Especially Vulnerable to the Pandemic

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

* Load analytic file
use "$dirs/cps_00035.dta", clear

* Part 1: Historical unemployment rate
drop if year > 2019

* Drop individuals not in the labor force.
drop if labforce != 2

* Drop unpaid family workers
drop if classwkr == 29

drop if age < 18

* Identify employed and unemployed persons
gen emp_person = (empstat == 10 | empstat == 12)
gen unemp_person = (empstat == 21 | empstat == 22)

* Assign individual occupations to artist categories
* Performing artists, Directors, Musicians, Composers, and Dancers and choreographers,
* and Other
gen art_cat = 1 if occ2010 == 2700 | occ2010 == 2740
replace art_cat = 1 if occ2010 == 2750
replace art_cat = 1 if occ2010 == 2760

* Visual artists, Photographers, Designers, and Writers
replace art_cat = 2 if occ2010 == 2600 | occ2010 == 2910
replace art_cat = 2 if occ2010 == 2630
replace art_cat = 2 if occ2010 == 2850

* Architects (except naval), Librarians, museum, and archival specialists
replace art_cat = 3 if occ2010 == 1300
replace art_cat = 3 if occ2010 >= 2400 & occ2010 <= 2440

* Retail and wholesale
replace art_cat = 4 if occ2010 >= 4700 & occ2010 <= 4760

* Food service
replace art_cat = 5 if occ2010 >= 4000 & occ2010 <= 4160

* Remaining
replace art_cat = 6 if art_cat == .

* Aggregate to the artist category by year
collapse (sum) emp_person unemp_person [pweight=wtfinl], by(art_cat year month)

format emp_person unemp_person %15.0f

* Calculate the unemployment rate
gen unemp_rate = (unemp_person / (emp_person + unemp_person)) * 100

* Set panel structure
gen date = ym(year, month)
format date %tm
sort art_cat date
xtset art_cat date

label define art_labs 1 "Performing artists" 2 "Non-performing artists" 3 "Architects and archivists" 4 "Retail and wholesale" 5 "Food services" 6 "All other occupations"
label values art_cat art_labs

tssmooth ma unemp_rate_ma=unemp_rate, window(12 0 0)

sort art_cat date

* Plot January of each year
keep if month == 1
drop if year == 2009

sum date

* Figure 2: Unemployment Rates for the Arts and Cultural Workers
twoway (line unemp_rate_ma date if art_cat == 1 & month == 1, lcolor(navy)) (line unemp_rate_ma date if art_cat == 2 & month == 1, lcolor(midblue)) (line unemp_rate_ma date if art_cat == 3 & month == 1, lcolor(ltblue)) (line unemp_rate_ma date if art_cat == 4 & month == 1, lcolor(green)) (line unemp_rate_ma date if art_cat == 5 & month == 1, lcolor(lime)) (line unemp_rate_ma date if art_cat == 6 & month == 1, lcolor(black)), legend(order(1 "Performing artists" 2 "Non-performing artists" 3 "Architects and archivists" 4 "Retail and wholesale" 5 "Food services" 6 "All other occupations") rows(3)) graphregion(color(white)) xtitle(Year-Month) ytitle("Unemployment rate") ylabel(0(2.5)15, grid) yline(0 15, lcolor(gs13)) xlabel(`r(min)'(12)`r(max)', nogrid angle(45))
graph export "$dirs/unemp_rate_ma.pdf", replace

* Export figure data to Excel
keep year art_cat unemp_rate_ma
quietly reshape wide unemp_rate_ma, i(year) j(art_cat)
label var unemp_rate_ma1 "Performing artists"
label var unemp_rate_ma2 "Non-performing artists" 
label var unemp_rate_ma3 "Architects and archivists" 
label var unemp_rate_ma4 "Retail and wholesale" 
label var unemp_rate_ma5 "Food services" 
label var unemp_rate_ma6 "All other occupations"
export excel "$dirs/figure_output.xlsx", replace sheet("Historical Timeline") firstrow(varlabels)

* Part 2: January 2020 snapshot

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

* Of those that are employed, calculate the proportion that are self-employed
* vs. wage/salary
keep if emp_person == 1

* Subset to January 2020
drop if month == 5

gen selfemp = (classwkr == 13 | classwkr == 14)
gen wagesal = (classwkr == 22 | classwkr == 23 | classwkr == 25 | classwkr == 27 | classwkr == 28)

preserve
	collapse (sum) emp_person selfemp wagesal [pweight=wtfinl], by(art_cat year month)

	gen pct_selfemp = (selfemp / emp_person) * 100

	* Reshape to wide
	quietly reshape wide emp_person selfemp wagesal pct_selfemp, i(year art_cat) j(month)

	label define art_labs 1 "Performing artists" 2 "Non-performing artists" 3 "Architects and archivists" 4 "Retail and wholesale" 5 "Food services" 6 "All other occupations"
	label values art_cat art_labs

	format emp_person* selfemp* wagesal* %15.0f

	* Figure 1: Proportion of Self-Employed Workers in Arts & Artist-Heavy Occupations
	graph hbar pct_selfemp1, over(art_cat) graphregion(color(white)) ytitle(Percent self-employed) ylabel(0(10)50, grid) yline(50, lcolor(gs13)) blabel(total, format(%02.01f)) bar(1, color(navy))
	graph export "$dirs/pct_selfemp_jan2020.pdf", replace

	* Export figure data to Excel
	keep year art_cat pct_selfemp1
	label var art_cat "Artist category"
	label var pct_selfemp1 "Percent self-employed in January"
	export excel "$dirs/figure_output.xlsx", sheetreplace sheet("Jan Self Emp") firstrow(varlabels)
restore
