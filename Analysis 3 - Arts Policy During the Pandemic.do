* COMMENTARY (The RAND Blog)
* Title: Arts Policy During the Pandemic: What are We Measuring, and What Can We Know?

* This Do file uses a pre-generated data dictionary from IPUMS to format the CPS extract.

* NOTE(S): 
* 1. You need to set the Stata working directory to the path where the data file is located.
* 2. You also need to ensure that the CPS data extract file name reflects the file name of your query (see line 51 of "format_cps_arts_policy.do").

/*
* Relevant variables
Type	Variable	Label
H		YEAR		Survey year
H		SERIAL		Household serial number
H		MONTH		Month
H		HWTFINL		Household weight, Basic Monthly
H		CPSID		CPSID, household record
H		ASECFLAG	Flag for ASEC
P		PERNUM		Person number in sample unit
P		WTFINL		Final Basic Weight
P		CPSIDP		CPSID, person record
P		AGE			Age
P		SEX			Sex
P		RACE		Race
P		POPSTAT		Adult civilian, armed forces, or child
P		EMPSTAT		Employment status
P		LABFORCE	Labor force status
P		OCC			Occupation
P		OCC2010		Occupation, 2010 basis
P		IND1990		Industry, 1990 basis
P		IND			Industry
P		CLASSWKR	Class of worker
P		EARNWT		Earnings weight
P		HOURWAGE	Hourly wage
P		PAIDHOUR	Paid by the hour
P		EARNWEEK	Weekly earnings
*/

* Using the Current Population Survey, examine what industries artists are in
* primarily in over the past decade.

* Set working directory
global basedir []

* CPS extract
global cpsextract 00053

* Format raw CPS data
do "${basedir}/format_cps_arts_policy.do"

* Re-load analytic file
use "${basedir}/cps_${cpsextract}.dta", clear

* Range of unweighted sample sizes in 2019 (2020 not reported due to COVID-19
* pandemic).
preserve
	gen n = 1
	drop if year != 2019
	collapse (sum) n, by(year month)
	collapse (min) min=n (max) max=n
	list
restore

* Drop individuals not in the labor force.
drop if labforce != 2

* Drop unpaid family workers
drop if classwkr == 29

* Identify employed and unemployed persons
gen emp_person = (empstat == 10 | empstat == 12)
gen unemp_person = (empstat == 21 | empstat == 22)

* Assign individual occupations to artist categories

* 1. This first classification combines occ codes across the 2003-2010, 2011-2019,
* and 2020+ codes

* Performing artists and directors, dancers and choreographers, 
* Musicians & Composers, and Other
gen art_cat = 1 if occ == 2700 | occ == 2710 | occ == 2740
replace art_cat = 1 if occ == 2750 | occ == 2751 | occ == 2752
replace art_cat = 1 if occ == 2755 | occ == 2760 | occ == 2770
 
* Artists (and related workers) and Photographers, Designers (all), and Writers
replace art_cat = 2 if occ == 2600 | occ == 2910 | occ == 2630
replace art_cat = 2 if occ >= 2631 & occ <= 2640
replace art_cat = 2 if occ == 2850

* Architects (except naval) and Landscape architects, Library, museum, and 
* archival specialists
replace art_cat = 3 if occ == 1300 | occ == 1305 | occ == 1306
replace art_cat = 3 if occ >= 2400 & occ <= 2440

* All other occupations
replace art_cat = 4 if art_cat == .

* 2. Standardized occupation codes using occ2010

* Performing artists, Directors, Musicians, Composers, and Dancers and 
* choreographers, and Other
gen art_cat2010 = 1 if occ2010 == 2700 | occ2010 == 2740
replace art_cat2010 = 1 if occ2010 == 2750
replace art_cat2010 = 1 if occ2010 == 2760

* Visual artists, Photographers, Designers, and Writers
replace art_cat2010 = 2 if occ2010 == 2600 | occ2010 == 2910
replace art_cat2010 = 2 if occ2010 == 2630
replace art_cat2010 = 2 if occ2010 == 2850

* Architects (except naval), Librarians, museum, and archival specialists
replace art_cat2010 = 3 if occ2010 == 1300
replace art_cat2010 = 3 if occ2010 >= 2400 & occ2010 <= 2440

* Remaining
replace art_cat2010 = 4 if art_cat2010 == .

tempfile cpsdata
save `cpsdata'

* As of January 2020, # artists (by occupation code) who are working in NAICS 711 
* or 712; # non-artists (by occupation) in 711/712, and # artists working but 
* NOT in 711/712
preserve

	* Subset to January 2020
	keep if year == 2020 & month == 1
	
	* NAICS code is used in variable name but Census code is used in formula
	gen works_in_711_712 = 1 if ind >= 8561 & ind <= 8564 & ind != 8562
	replace works_in_711_712 = 1 if ind == 8570
	replace works_in_711_712 = 0 if works_in_711_712 == .
	gen works_neither_711_712 = (works_in_711_712 != 1)
	
	* Identify artists based on coding scheme above
	gen artist = (art_cat <= 3)

	* Calculate weighted and unweighted counts of artists/non-artists by their
	* industry
	collapse (sum) works_in_711_712 works_neither_711_712 [pweight=wtfinl], by(artist year month)
	
	format works* %15.0f
	
	label define a 0 "Non-Artists" 1 "Artists", replace
	label values artist a
	
	label var artist "Occupation"
	label var works_in_711_712 "Works in art industry"
	label var works_neither_711_712 "Does not work art industry"
	
	* Export to Excel
	export excel using "${basedir}/technicalcommentary3.xlsx", replace sheet("Venn Diagram") firstrow(varlabels)
	
restore


* Top 5 industries employing artists, as of Jan. 2020, outside of NAICS code 711/712
preserve

	* Subset to artists as defined above
	drop if art_cat == 4
	
	* Subset to January 2020
	keep if year == 2020 & month == 1
	
	* Drop Census industry codes corresponding to NAICS 711 (8561, 8563, & 8564) and 712 (8570)
	drop if ind >= 8561 & ind <= 8564 & ind != 8562
	drop if ind == 8570

	* Count the number of employed artists
	collapse (sum) emp_person [pweight=wtfinl], by(ind)
	
	* Sort in descending order and keep top 5 industries
	gsort - emp_person
	keep in 1/5

	* Manually bring in NAICS industries
	gen naics = "5414" if ind == 7370
	replace naics = "5413" if ind == 7290
	replace naics = "5121" if ind == 6570
	replace naics = "5419 exc. 54194" if ind == 7490
	replace naics = "51912" if ind == 6770
	
	gen naics_des = "Specialized design services" if naics == "5414"
	replace naics_des = "Architectural, engineering, and related services" if naics == "5413"
	replace naics_des = "Motion pictures and video industries" if naics == "5121"
	replace naics_des = "Other professional, scientific, and technical services" if naics == "5419 exc. 54194"
	replace naics_des = "Libraries and archives" if naics == "51912"
	
	label var emp_person "Number of employed artists"
	label var naics "NAICS code"
	label var naics_des "NAICS description"
	
	* Export to Excel
	export excel using "${basedir}/technicalcommentary3.xlsx", sheetreplace sheet("Artist Industries") firstrow(varlabels)
	
restore


* Top 5 occupations BESIDES artist occupations who work in NAICS codes 711/712
preserve

	* Subset to non-artists
	keep if art_cat == 4
	
	* Subset to January 2020
	keep if year == 2020 & month == 1
	
	* Subset to NAICS 711 (8561, 8563, & 8564) and 712 (8570)
	gen keepobs = 1 if ind >= 8561 & ind <= 8564 & ind != 8562
	replace keepobs = 1 if ind == 8570
	keep if keepobs == 1

	* Count the number of employed non-artists
	collapse (sum) emp_person [pweight=wtfinl], by(occ)
	
	* Sort in descending order and keep top 5 occupations
	gsort - emp_person
	keep in 1/5

	* Manually bring in occupation descriptions
	gen occ_des = "Landscaping and grounds keeping workers" if occ == 4251
	replace occ_des = "Managers, all other" if occ == 440
	replace occ_des = "Animal caretakers" if occ == 4350
	replace occ_des = "First-line supervisors/managers of non-retail sales workers" if occ == 4710
	replace occ_des = "Security guards and gaming surveillance officers" if occ == 3930

	label var occ_des "Occupation description"
	
	* Export to Excel
	export excel using "${basedir}/technicalcommentary3.xlsx", sheetreplace sheet("Non-Artist Occupations") firstrow(varlabels)
	
restore

preserve

	* Subset to artists as defined above
	drop if art_cat == 4
	
	* Subset to January 2020
	keep if year == 2020 & month == 1

	* NAICS code is used in variable name but Census code is used in formula
	gen works_in_711 = (ind >= 8561 & ind <= 8564 & ind != 8562)
	gen works_in_712 = (ind == 8570)
	gen works_neither_711_712 = (works_in_711 != 1 & works_in_712 != 1)
	
	collapse (sum) works_in_711 works_in_712 works_neither_711_712, by(art_cat year month)
	
	gen pct_711 = works_in_711 / (works_in_711 + works_in_712 + works_neither_711_712)
	gen pct_712 = works_in_712 / (works_in_711 + works_in_712 + works_neither_711_712)
	gen pct_neither = works_neither_711_712 / (works_in_711 + works_in_712 + works_neither_711_712)
	
	foreach var of varlist pct_* {
		replace `var' = `var' * 100
	}
	
	* Plot
	graph bar pct_711 pct_712 pct_neither, over(art_cat, relabel(1 "Performing Artists" 2 "Non-Performing Artists" 3 "Architects/Archivists")) stack graphregion(color(white)) ytitle("Percent") legend(order(1 "Arts, Entertainment, and Recreation" 2 "Museums, Historical Sites, and Similar Institutions" 3 "Neither") rows(3))
	graph export "${basedir}/pct_of_artists.pdf", replace
	
restore

* Set a loop counter so we can preserve the import/format order. Will also be 
* used for saving/appending full panel dta file.
local loopnumber = 1

foreach ind of numlist 711 712 { // 5121 5413 5414 5419 7115 51912 54194
	
	if `ind' == 711 {
		local fname "2020.q1-q2 711 NAICS 711 Performing arts and spectator sports"
	}
	if `ind' == 712 {
		local fname "2020.q1-q2 712 NAICS 712 Museums, historical sites, zoos, and parks"
	}

	* Import raw data
	import delimited using "${basedir}/`fname'.csv", clear
	
	* Subset to US total and private industry
	keep if area_fips == "US000" & own_code == 5
	
	if `ind' == 711 {
		save "${basedir}/qcew_relevant_industries.dta", replace
	}
	else {
		append using "${basedir}/qcew_relevant_industries.dta"
		save "${basedir}/qcew_relevant_industries.dta", replace
	}
	
	local loopnumber = `loopnumber' + 1	
}

collapse (sum) qtrly_estabs_count month1_emplvl month2_emplvl month3_emplvl, by(industry_code industry_title year qtr)

* Reshape to long to create panel
ren (month1_emplvl month2_emplvl month3_emplvl) (month_emplvl1 month_emplvl2 month_emplvl3)
quietly reshape long month_emplvl, i(industry_code year qtr qtrly_estabs_count) j(month_in_quarter)

* Create monthly Stata date
gen month = month_in_quarter if qtr == 1
replace month = 4 if qtr == 2 & month_in_quarter == 1
replace month = 5 if qtr == 2 & month_in_quarter == 2
replace month = 6 if qtr == 2 & month_in_quarter == 3
replace month = 7 if qtr == 3 & month_in_quarter == 1
replace month = 8 if qtr == 3 & month_in_quarter == 2
replace month = 9 if qtr == 3 & month_in_quarter == 3
replace month = 10 if qtr == 4 & month_in_quarter == 1
replace month = 11 if qtr == 4 & month_in_quarter == 2
replace month = 12 if qtr == 4 & month_in_quarter == 3

gen date = ym(year, month)
format date %tm

keep industry_code year month month_emplvl
ren month_emplvl emp_person
quietly reshape wide emp_person, i(year month) j(industry_code)

save "${basedir}/qcew_relevant_industries.dta", replace

* Re-load CPS data
use `cpsdata', clear

* Subset to private sector
keep if classwkr == 22 | classwkr == 23

label define art_labs 1 "Performing artists" 2 "Non-performing artists" 3 "Architects and archivists" 4 "All other occupations", replace
label values art_cat art_labs

collapse (rawsum) unw_emp_person=emp_person unw_unemp_person=unemp_person (sum) emp_person unemp_person [pweight=wtfinl], by(art_cat year month)

keep year month art_cat emp_person unw_emp_person unw_unemp_person unemp_person
quietly reshape wide emp_person unw_emp_person unw_unemp_person unemp_person, i(year month) j(art_cat)

ren (*1 *2 *3 *4) (*_pa *_npa *_arch *_allother)

* Merge on data from QCEW (NAICS711 and NAICS712)
merge 1:1 year month using "${basedir}/qcew_relevant_industries.dta"
drop if _merge != 3
drop _merge

gen date = ym(year, month)
format date %tmMCY
sort date
tsset date

format emp* %15.0f

foreach var of varlist emp* unemp* {
	* Month-to-month percent changes in employment
	gen `var'_pctchg = ((`var' - L.`var') / L.`var') * 100
	
	* Rescaling
	replace `var' = `var' / 1000
}

graph twoway (line emp_person_pa date, lpattern(solid)) (line emp_person_npa date, lpattern(solid)) (line emp_person_arch date, lpattern(solid)) (line emp_person711 date, lpattern(dash)) (line emp_person712 date, lpattern(dash)), graphregion(color(white)) legend(order(1 "CPS: Performing Artists" 2 "CPS: Non-Performing Artists" 3 "CPS: Architects/Archivists" 4 "QCEW: Arts, Entertainment, and Recreation" 5 "QCEW: Museums, Historical Sites, and Similar Institutions") rows(5)) ytitle("Employment (000s)") xtitle("Year-Month") xlabel(720 `" "Jan" "2020" "' 721 `" "Feb" "2020" "' 722 `" "Mar" "2020" "' 723 `" "Apr" "2020" "' 724 `" "May" "2020" "' 725 `" "Jun" "2020" "')
graph export "${basedir}/emp_trend.pdf", replace

* Export figure data to Excel
keep date emp_person_pa emp_person_npa emp_person_arch emp_person711 emp_person712
order date emp_person_pa emp_person_npa emp_person_arch emp_person711 emp_person712
label var date "Year-Month"
label var emp_person_pa "CPS: Performing Artists"
label var emp_person_npa "CPS: Non-Performing Artists"
label var emp_person_arch "CPS: Architects/Archivists"
label var emp_person711 "QCEW: Arts, Entertainment, and Recreation"
label var emp_person712 "QCEW: Museums, Historical Sites, and Similar Institutions"

export excel using "${basedir}/technicalcommentary3.xlsx", sheetreplace sheet("Figure 2") firstrow(varlabels)
