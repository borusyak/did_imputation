/*
	This simulated example illustrates how to estimate causal effects with event studies using a range of methods
	and plot the coefficients & confidence intervals using the event_plot command.
	
	Date: 26/05/2021
	Author: Kirill Borusyak (UCL), k.borusyak@ucl.ac.uk
	
	You'll need the following commands:
		- did_imputation (Borusyak et al. 2021): currently available at https://github.com/borusyak/did_imputation
		- did_multiplegt (De Chaisemartin and D'Haultfoeuille 2020): available on SSC
		- eventstudyinteract (San and Abraham 2020): available on SSC
		- scdid (Callaway and Sant'Anna 2020): currently available at https://friosavila.github.io/playingwithstata/main_csdid.html

*/

// Generate a complete panel of 250 units observed in 6 periods
clear all
set seed 123
global T = 6
global I = 250

set obs `=$I*$T'
gen i = int((_n-1)/$T )+1 // unit id
gen t = mod((_n-1),$T )+1 // period
tsset i t

// Randomly generate treatment rollout years
gen Ei = ceil(runiform()*$T )+1 // year first treated, 2..$T+1
bys i: replace Ei = Ei[1]
replace Ei = . if Ei==7 // view this group as never-treated => missing Ei
gen K = t-Ei // # of periods since treated (missing if never-treated)
gen D = K>=0 & Ei!=. // treatment dummy

// Generate the outcome with parallel trends and a linearly-growing treatment effect
gen tau = 0.2*cond(D==1, K+1, 0)
gen eps = rnormal()
gen Y = i + 3*t + tau*D + eps

// Estimation with did_imputation of Borusyak et al. (2021)
did_imputation Y i t Ei, allhorizons pretrend(2)
event_plot, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") title("Borusyak et al. 2021") xlabel(-2(1)4))

estimates store bjs // storing the estimates for later

// Estimation with did_multiplegt of De Chaisemartin and D'Haultfoeuille (2020)
did_multiplegt Y i t D, robust_dynamic dynamic(4) placebo(4) breps(100) cluster(i) 
event_plot e(estimates)#e(variances), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") ///
	title("De Chaisemartin and D'Haultfoeuille 2020") xlabel(-4(1)4)) stub_lag(Effect_#) stub_lead(Placebo_#) together

matrix dcdh_b = e(estimates) // storing the estimates for later
matrix dcdh_v = e(variances)

// Estimation with cldid of Callaway and Sant'Anna (2020)
gen gvar = cond(Ei==., 0, Ei)
csdid Y, ivar(i) time(t) gvar(gvar)
estat event, estore(cs) // this stores the estimates right away
event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ///
	title("Callaway and Sant'Anna 2020")) stub_lag(E#) stub_lead(E_#) together

// Estimation with eventstudyinteract of Sun and Abraham (2020)
sum Ei
gen lastcohort = Ei==r(max) // dummy for the latest- or never-treated cohort
forvalues l = 0/4 {
	gen L`l'event = K==`l'
}
forvalues l = 1/5 {
	gen F`l'event = K==-`l'
}
replace F1event = 0
eventstudyinteract Y L0event-L4event F1event-F4event, vce(cluster i) absorb(i t) cohort(Ei) control_cohort(lastcohort)
event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ///
	title("Sun and Abraham 2020")) stub_lag(L#event) stub_lead(F#event) together

drop L*event F*event
matrix sa_b = e(b_iw) // storing the estimates for later
matrix sa_v = e(V_iw)

// TWFE OLS estimation (which is correct here because of treatment effect homogeneity)
forvalues l = 0/4 {
	gen L`l'event = K==`l'
}
//gen L3event = K>=3  --- some groups are sometimes binned

// creating dummies for the leads 1..3
forvalues l = 1/3 { 
	gen F`l'event = K==-`l'
}
gen F4event = K<=-4 // binning K=-4 and below
reghdfe Y o.F1event F2event-F4event L*event, a(i t) cluster(i)
event_plot, default_look stub_lag(L#event) stub_lead(F#event) together graph_opt(xtitle("Days since the event") ytitle("OLS coefficients") xlabel(-4(1)4) ///
	title("OLS"))

estimates store ols // saving the estimates for later

// Combine all plots using the stored estimates
event_plot bjs dcdh_b#dcdh_v cs sa_b#sa_v ols, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ///
	legend(order(- "Estimator:" 1 "Borusyak et al." 3 "De Chaisemartin-D'Haultfoeuille" 5 "Callaway-Sant'Anna" 7 "Sun-Abraham" 9 "OLS") rows(2))) ///
	lag_opt2(msymbol(Dh)) lag_opt3(msymbol(Th)) lag_opt4(msymbol(Sh)) lag_opt5(msymbol(x)) noautolegend ///
	stub_lag(tau# Effect_# E# L#event L#event) stub_lead(pre# Placebo_# E_# F#event F#event) plottype(scatter) ciplottype(rcap) together perturb(-0.2(0.1)0.2) 
graph export "five_methods_combined.png", replace
