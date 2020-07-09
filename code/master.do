***************
*	Project: Air Pollution and Lockdown 
*	Author: Guojun, Yuhang, Tanaka
* 	Date: 2020 July
* 	<Replication Codes>
***************
clear
cd "Your Own Location"

****** Table 1 (Column 1-4) ******
use wf.dta
sort city_code daynum
keep if daynum <=8461 & daynum >= 8401
xtset city_code daynum

* temperature squared
gen temp2 = temp*temp

* outcomes (log)
foreach u of var aqi pm{
	gen l_`u' = log(1+`u')
}
*

label var treat "Lockdown"

foreach u of var aqi l_aqi pm l_pm{
	reghdfe `u' treat, absorb(city_code daynum) vce(cl city_code)
	reghdfe `u' treat prec snow temp temp2, absorb(city_code daynum) vce(cl city_code)
}
*

****** Table 1 (Column 5-8) ******
use wf.dta
sort city_code daynum
xtset city_code daynum
gen select = 1 if daynum <=8461 & daynum >= 8401 
replace select = 1 if daynum <=8107 & daynum >= 8047 
keep if select == 1
drop select 
gen t_group = (t_asign !=.)
gen daynum_i = daynum if year == 2020
replace daynum_i = daynum+354 if year == 2019
gen treat_SF1 = (daynum_i>=8425 & year == 2020)	

* temperature squared
gen temp2 = temp*temp

* outcomes (log)
foreach u of var aqi pm{
	gen l_`u' = log(1+`u')
}
*

label var treat_SF1 "Spring Festival in 2020"

foreach u of var aqi l_aqi pm l_pm{
	reghdfe `u' treat_SF1 if t_group == 0, absorb(city_code daynum_i year) vce(cl city_code)
	reghdfe `u' treat_SF1 prec snow temp temp2 if t_group == 0, absorb(city_code daynum_i year) vce(cl city_code)
}
*


****** Figure 3 ******
use wf.dta
sort city_code daynum
keep if daynum <=8461 & daynum >= 8401
xtset city_code daynum

* temperature squared
gen temp2 = temp*temp

* outcomes (log)
foreach u of var aqi pm{
	gen l_`u' = log(1+`u')
}
*

sort city_code daynum
xtset city_code daynum
bys city_code : gen t_sum = sum(treat)
tab t_sum

forvalues i = 0(1)27{
	local k = `i'+1
	gen D`i' = 0
	replace D`i' = 1 if t_sum == `k'
}
*
gen D28 = 0
replace D28 = 1 if t_sum >= 29
forvalues i=1(1)27{
	gen Lead_D`i' = F`i'.D0
replace Lead_D`i' = 0 if Lead_D`i' ==. 
}
*
egen lead_all = rowtotal(Lead_D1-Lead_D27)
gen Lead_D28 = treat - lead_all

drop lead_all

replace Lead_D28 = . if Lead_D28 !=0
replace Lead_D28 = 1 if Lead_D28 ==0
replace Lead_D28 = 0 if Lead_D28 == .

drop D1-D6 D8-D13 D15-D20 D22-D27

replace D0 = 1 if t_sum <= 9 & t_sum >= 1
replace D7 = 1 if t_sum <= 14 & t_sum >= 10
replace D14 = 1 if t_sum <= 21 & t_sum >= 15
replace D21 = 1 if t_sum <= 28 & t_sum >= 22
replace D28 = 1 if t_sum <= 35 & t_sum >= 29

forvalues i = 1(1)6{
	replace Lead_D7 = Lead_D`i' if Lead_D7 ==0
	drop Lead_D`i'
}
*
forvalues i = 8(1)13{
	replace Lead_D14 = Lead_D`i' if Lead_D14 ==0
	drop Lead_D`i'
}
*
forvalues i = 15(1)20{
	replace Lead_D21 = Lead_D`i' if Lead_D21 ==0
	drop Lead_D`i'
}
*
forvalues i = 22(1)27{
	replace Lead_D28 = Lead_D`i' if Lead_D28 ==0
	drop Lead_D`i'
}
*

gen base = 0


foreach u of var aqi l_aqi pm l_pm{
	reghdfe `u' D0-D28 base Lead_D14-Lead_D28 prec snow temp temp2, absorb(city_code daynum) vce(cl city_code)
	parmest, saving(event_`u'.dta, replace)
}
*


* AQI
preserve
use event_aqi.dta
drop if inlist(parm, "temp", "temp2", "prec", "snow", "_cons")
gen dup = _n
gen dup2 = _n
replace dup = dup - 7
replace dup = (dup+2)*-1 if dup >=0 
replace dup = (dup+6) if dup2 < 6
graph twoway (scatter estimate dup, mcolor("0 183 255") msymbol(diamond)) ///
			(rcap max95 min95 dup,  lpattern(solid) lcolor("0 183 255")) ///
			,scheme(lean1) ///
			xscale(range(-5 5)) ///
			xlabel(-4 "<=-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" ///
			1 "1" 2 "2" 3 "3" 4 ">=4", nogrid) ///
			legend(off) ///
			yline(0, lcolor(black%30) lwidth(medium) lpattern(dash)) ///
			xline(-1, lcolor(orange) lwidth(medthick) lpattern(dash)) ///
			xtitle("Weeks before and after the Lockdown") ///
			xscale(range(-5(1)5)) ///
			subtitle("AQI, levels", position(11)) ///
			text(5 -0.8 "Lockdown", place(e) color(black) size(3.5)) ///
			ytitle("Estimated Coefficient")
restore

* AQI - log
preserve
use event_l_aqi.dta
drop if inlist(parm, "temp", "temp2", "prec", "snow", "_cons")
gen dup = _n
gen dup2 = _n
replace dup = dup - 7
replace dup = (dup+2)*-1 if dup >=0 
replace dup = (dup+6) if dup2 < 6
graph twoway (scatter estimate dup, mcolor("0 183 255") msymbol(diamond)) ///
			(rcap max95 min95 dup,  lpattern(solid) lcolor("0 183 255")) ///
			,scheme(lean1) ///
			xscale(range(-5 5)) ///
			xlabel(-4 "<=-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" ///
			1 "1" 2 "2" 3 "3" 4 ">=4", nogrid) ///
			legend(off) ///
			yline(0, lcolor(black%30) lwidth(medium) lpattern(dash)) ///
			xline(-1, lcolor(orange) lwidth(medthick) lpattern(dash)) ///
			xtitle("Weeks before and after the Lockdown") ///
			xscale(range(-5(1)5)) ///
			subtitle("A-1. AQI, log", position(11)) ///
			text(0.05 -0.8 "Lockdown", place(e) color(black) size(3.5)) ///
			ytitle("Estimated Coefficient", xoffset(15))
restore


* PM2.5
preserve
use event_pm.dta
drop if inlist(parm, "temp", "temp2", "prec", "snow", "_cons")
gen dup = _n
gen dup2 = _n
replace dup = dup - 7
replace dup = (dup+2)*-1 if dup >=0 
replace dup = (dup+6) if dup2 < 6
graph twoway (scatter estimate dup, mcolor("255 122 158") msymbol(diamond)) ///
			(rcap max95 min95 dup,  lpattern(solid) lcolor("255 122 158")) ///
			,scheme(lean1) ///
			xscale(range(-5 5)) ///
			xlabel(-4 "<=-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" ///
			1 "1" 2 "2" 3 "3" 4 ">=4", nogrid) ///
			legend(off) ///
			yline(0, lcolor(black%30) lwidth(medium) lpattern(dash)) ///
			xline(-1, lcolor(orange) lwidth(medthick) lpattern(dash)) ///
			xtitle("Weeks before and after the Lockdown") ///
			xscale(range(-5(1)5)) ///
			subtitle("A-2. PM{sub:2.5}, levels", position(11)) ///
			text(5 -0.8 "Lockdown", place(e) color(black) size(3.5)) ///
			ytitle("Estimated Coefficient")
restore

* PM2.5 - log
preserve
use event_l_pm.dta
drop if inlist(parm, "temp", "temp2", "prec", "snow", "_cons")
gen dup = _n
gen dup2 = _n
replace dup = dup - 7
replace dup = (dup+2)*-1 if dup >=0 
replace dup = (dup+6) if dup2 < 6
graph twoway (scatter estimate dup, mcolor("255 122 158") msymbol(diamond)) ///
			(rcap max95 min95 dup,  lpattern(solid) lcolor("255 122 158")) ///
			,scheme(lean1) ///
			xscale(range(-5 5)) ///
			xlabel(-4 "<=-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" ///
			1 "1" 2 "2" 3 "3" 4 ">=4", nogrid) ///
			legend(off) ///
			yline(0, lcolor(black%30) lwidth(medium) lpattern(dash)) ///
			xline(-1, lcolor(orange) lwidth(medthick) lpattern(dash)) ///
			xtitle("Weeks before and after the Lockdown") ///
			xscale(range(-5(1)5)) ///
			subtitle("A-3. PM{sub:2.5}, log", position(11)) ///
			text(0.05 -0.8 "Lockdown", place(e) color(black) size(3.5)) ///
			ytitle("Estimated Coefficient", xoffset(15))
restore

****** Figure 4 ******
use wf.dta
keep if year == 2020

merge m:m city_code using city_yb.dta /* City-level yearbook data */
keep if daynum <=8461 & daynum >= 8401

* outcomes
foreach u of var aqi pm{
	gen l_`u' = log(1+`u')
}
*

* temperature squared
gen temp2 = temp*temp

* warm / cold
rename temp mean_temp
gen i_mean_temp1 = mean_temp if daynum == 8401
bys city_code : egen d_mean_temp1 = mean(i_mean_temp1)
egen mean_temp1 = mean(d_mean_temp1)
gen cold = (d_mean_temp1<=mean_temp1)
drop mean_temp1 d_mean_temp1 i_mean_temp1
rename mean_temp temp

* GDP
egen mean_gdp_city = mean(gdp_city)
gen high_GDP = (gdp_city>mean_gdp_city)
drop mean_gdp_city

* per capita GDP
egen mean_pgdp_city = mean(pgdp_city)
gen high_pGDP = (pgdp_city>mean_pgdp_city)
drop mean_pgdp_city

* population
egen mean_pop_city = mean(pop_city)
gen high_pop = (pop_city>mean_pop_city)
drop mean_pop_city

* sec ind
egen mean_sec_city = mean(sec_city)
gen high_sec = (sec_city>mean_sec_city)
drop mean_sec_city

* firm number
egen mean_firm_city = mean(firm_city)
gen high_firm = (firm_city>mean_firm_city)
drop mean_firm_city

* Traffic
	egen mean_gonglu = mean(gonglu)
	gen high_gonglu = (gonglu>mean_gonglu)
	drop mean_gonglu

	
foreach u of var emit_ww emit_so1 emi_dust1{
	egen mean_`u' = mean(`u')
	gen high_`u' = (`u'>mean_`u')
	drop mean_`u'
	}
	*

	

* regression
foreach p of var cold north high_GDP-high_emi_dust1{
	foreach u of var aqi l_aqi pm l_pm{		
		reghdfe `u' treat prec snow temp temp2 if `p' == 1, absorb(city_code daynum) vce(cl city_code)	
		reghdfe `u' treat prec snow temp temp2 if `p' == 0, absorb(city_code daynum) vce(cl city_code)
		}
}
*

* An example of plotting: same for all other graphs on Heterogeneous analysis
* For AQI graph
* min95 max95 estimate are the two 95% bounds and the point estimates, respectively.
graph twoway  (rspike min95 max95 order, horizontal lwidth(medthin) lcolor(black%50) lpattern(dash) lcolor(black%40)) ///
				(scatter order estimate, msize(medsmall) mcolor("0 183 255") msymbol(diamond)) ///
				,scheme(lean1) ///
				xsize(5) ysize(6) ///
				ylabel(1 "Dust Emission (L)" 1.5 "Dust Emission (H)" ///
				2 "SO{sub:2} Emission (L)" 2.5 "SO{sub:2} Emission (H)" ///
				3 "Wastewater Emission (L)" 3.5 "Wastewater Emission (H)" ///
				5 "Amount of Traffic (L)" 5.5 "Amount of Traffic (H)" ///
				6 "# of Firms (L)" 6.5 "# of Firms (H)" ///
				7 "Secondary Industry Output (L)" 7.5 "Secondary Industry Output (H)" /// 
				5 "Amount of Traffic (L)" 5.5 "Amount of Traffic (H)" ///
				9 "Population (L)" 9.5 "Population (H)" ///
				10 "per capita GDP (L)" 10.5 "per capita GDP (H)" ///
				11 "GDP (L)" 11.5 "GDP (H)" ///
				13 "Southern China" 13.5 "Northern China" ///
				14 "Warm Region" 14.5 "Cold Region" ///
				16 "Baseline" ///
				, labsize(small)) ///
				ytitle("") ///
				xtitle("Estimated Coefficient", size(small)) ///
				xlabel(, labsize(small)) ///
				xline(0, lpattern(dot)) ///
				yline(4.25 8.25 12.25 15.25, lpattern(dash) lcolor(orange%15) lwidth(thick)) ///
				legend(off) ///
				text(14.9 -0.4 "{it:Panel A}", place(e) size(2.5)) ///
				text(11.9 -0.4 "{it:Panel B}", place(e) size(2.5)) ///
				text(7.9 -0.4 "{it:Panel C}", place(e) size(2.5)) ///
				text(3.9 -0.4 "{it:Panel D}", place(e) size(2.5)) 



****** SI Table 3: Summary ******
use wf.dta

sort city_code daynum
xtset city_code daynum

gen select = 1 if daynum <=8461 & daynum >= 8401 
replace select = 1 if daynum <=8107 & daynum >= 8047 
keep if select == 1
drop select 

est clear
estpost summarize aqi pm temp prec snow treat if year == 2020
estpost summarize aqi pm temp prec snow treat if year == 2020 & t_asign !=. & treat == 0
estpost summarize aqi pm temp prec snow treat if treat == 1 & year == 2020
estpost summarize aqi pm temp prec snow treat if year == 2020 & t_asign ==.
estpost summarize aqi pm temp prec snow treat if year == 2019 & t_asign !=.
estpost summarize aqi pm temp prec snow treat if year == 2019 & t_asign ==.



****** SI Table 4: Other Air Pollutants ******
use wf.dta
sort city_code daynum
keep if daynum <=8461 & daynum >= 8401
xtset city_code daynum
foreach u of var co no2 o3 pm10 so2{
	gen l_`u' = log(1+`u')
}
*

label var treat "Lockdown"

gen temp2 = temp*temp

foreach u of var co no2 pm10 so2 o3{
	reghdfe `u' treat prec snow temp temp2, absorb(city_code daynum) vce(cl city_code)
	reghdfe l_`u' treat prec snow temp temp2, absorb(city_code daynum) vce(cl city_code)
}
*




