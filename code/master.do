***************
*	Project: Air Pollution and Lockdown <Replication Codes>
*	Author: Guojun, Yuhang, Tanaka
* 	Date: 2020 Jul
***************
clear
cd /Users/smileternity/Desktop


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








