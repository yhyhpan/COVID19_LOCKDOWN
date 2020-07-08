***************
*	Project: Air Pollution and Lockdown 
*	Author: Guojun, Yuhang, Tanaka
* 	Date: 2020 July
* 	<Replication Codes>
***************
clear
cd "Your File Location"

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






