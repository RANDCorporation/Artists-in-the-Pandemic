# RAND Commentary – Artists and Cultural Workers in the Pandemic
ED & Labor Unit

This GitHub repository supports three RAND Commentaries written by James Marrone, Susan Resetar, and Daniel Schwam. The first can be found at the URL: https://www.rand.org/blog/2020/07/the-pandemic-is-a-disaster-for-artists.html. The second can be found at the URL: https://www.rand.org/blog/2020/07/arts-and-cultural-workers-are-especially-vulnerable.html. The third commentary can be found at the URL: https://www.rand.org/blog/2021/03/arts-policy-during-the-pandemic-what-are-we-measuring.html

#### -- Project Status: Completed.

## Project Description
Using the CPS Basic Monthly Sample of the Current Population Survey (CPS), we examine the vulnerability of individuals in the arts and cultural occupations (as defined by the National Endowment for the Arts) to the COVID-19 crisis.

### Methods Used
* Descriptive statistics

### Technologies
* Stata 15

## Getting Started

1. Download the Do files in this repository. The required Do files for each commentary are listed below:
	a. The pandemic is a disaster for artists: “Format CPS extract.do” & “Analysis 1 - The pandemic is a disaster for artists.do”
	b. Arts and cultural workers are especially vulnerable: “Format CPS extract.do” & “Analysis 2 - Arts and Cultural Workers are Vulnerable.do”
	c. Arts policy during the pandemic: “format_cps_arts_policy.do” & “Analysis 3 - Arts Policy During the Pandemic.do”

2. Download data from the cps.ipums.org (see Analysis 1, Analysis 2, or Analysis 3 do files for variables needed from the CPS). Data from the Quarterly Census of Employment and Wages (required for analysis 3) can be downloaded from the Bureau of Labor Statistics using the following URL: https://www.bls.gov/cew/downloadable-data-files.htm. The following NAICS CSV files are required and can be accessed after downloading 2020 data by industry:
	a. 2020.q1-q2 711 NAICS 711 Performing arts and spectator sports.csv
	b. 2020.q1-q2 712 NAICS 712 Museums, historical sites, zoos, and parks.csv
    
3. Run pre-generated CPS Do file.

4. Run “Analysis 1 - The pandemic is a disaster for artists.do” for analysis referenced in “The pandemic is a disaster for artists” commentary

5. Run “Analysis 2 - Arts and Cultural Workers are Vulnerable.do” for analysis referenced in “Arts and Cultural Workers are Especially Vulnerable to the Pandemic” commentary

6. Run “Analysis 3 - Arts Policy During the Pandemic.do” for analysis referenced in “Arts Policy During the Pandemic: What are We Measuring, and What Can We Know?” commentary

### Other notes

Data extract for analyses 1 & 2 from the CPS downloaded on June 23, 2020 by Daniel Schwam. Data extract for analysis 3 downloaded on January 28, 2021 by Daniel Schwam

Reference: Sarah Flood, Miriam King, Renae Rodgers, Steven Ruggles and J. Robert Warren. Integrated Public Use Microdata Series, Current Population Survey: Version 7.0 [dataset]. Minneapolis, MN: IPUMS, 2020. 
https://doi.org/10.18128/D030.V7.0

Update: December 10, 2020.
Both do files conducting the analysis for "The Disaster is a Pandemic for Artists" and "Arts and Cultural Workers are Especially Vulnerable" were updated. Originally, designers were being excluded from the analysis because of the following misspecification: 2361 <= occ <= 2630. This has been corrected to the following to ensure designers are included: 2361 <= occ <= 2640.

Update: March 10, 2021.
Repository updated to include code for a third commentary on artists during the pandemic.

## Project Members:

James Marrone (jmarrone@rand.org)
Susan Resetar (susanr@rand.org) 
Daniel Schwam (dschwam@rand.org)

* Feel free to contact team leads with any questions or if you are interested in contributing!

## Suggested citations for this repository:

Marrone, James V., Resetar, Susan A., and Schwam, Daniel, “The Pandemic Is a Disaster for Artists” GitHub, RAND Corporation Repository, last updated 4 August 2020. As of March 10, 2021: https://github.com/RANDCorporation/Artists-in-the-Pandemic

Resetar, Susan A., Marrone, James V., and Schwam, Daniel, “Arts and Cultural Workers Are Especially Vulnerable to the Pandemic” GitHub, RAND Corporation Repository, last updated 4 August 2020. As of March 10, 2021: https://github.com/RANDCorporation/Artists-in-the-Pandemic

Marrone, James V., Resetar, Susan A., and Schwam, Daniel, “Arts Policy During the Pandemic: What are We Measuring, and What Can We Know?” GitHub, RAND Corporation Repository, last updated 10 March 2021. As of March 10, 2021: https://github.com/RANDCorporation/Artists-in-the-Pandemic
