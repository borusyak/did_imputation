{smcl}
{* *! version 3.1 2023-11-22}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "event_plot" "help event_plot"}{...}
{viewerjumpto "Syntax" "did_imputation##syntax"}{...}
{viewerjumpto "Description" "did_imputation##description"}{...}
{viewerjumpto "What if imputation is not possible" "did_imputation##impfails"}{...}
{viewerjumpto "Options" "did_imputation##options"}{...}
{viewerjumpto "Weights" "did_imputation##weights"}{...}
{viewerjumpto "Stored results" "did_imputation##results"}{...}
{viewerjumpto "Usage examples" "did_imputation##usage"}{...}
{title:Title}

{pstd}
{bf:did_imputation} - Treatment effect estimation and pre-trend testing in event studies: difference-in-differences designs with staggered adoption of treatment, using the imputation approach of Borusyak, Jaravel, and Spiess (April 2023)

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: did_imputation} {it:Y i t Ei} [if] [in] [{help did_imputation##weights:estimation weights}] [{cmd:,} {help did_imputation##options:options}]
{p_end}

{synoptset 8 tabbed}{...}
{synopt : {it:Y}}outcome variable {p_end}
{synopt : {it:i}}variable for unique unit id{p_end}
{synopt : {it:t}}variable for calendar period {p_end}
{synopt : {it:Ei}}variable for unit-specific date of treatment (missing = never-treated) {p_end}

{phang} {it: Note:} These main parameters imply: {p_end}
{phang3}- the treatment indicator: {it:D=1[t>=Ei]}; {p_end}
{phang3}- "relative time", i.e. the number of periods since treatment: {it:K=(t-Ei)} (possibly adjusted by the {opt shift} and {opt delta} options described below). {p_end}

{phang}
{it: Note}: {cmd:did_imputation} requires a recent version of {help reghdfe}. If you get error messages (e.g. {it:r(123)} or {it:"verbose must be between 0 and 5"}), please (re)install {cmd:reghdfe} to make sure you have the most recent version.
{p_end}

{phang}
{it: Note}: Before emailing the authors about errors, please read the {help did_imputation##bugs:Bug reporting} section of this helpfile.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{bf:did_imputation} estimates the effects of a binary treatment with staggered rollout allowing for arbitrary heterogeneity and dynamics of causal effects, using the imputation estimator of Borusyak et al. (2023).
{p_end}

{pstd}
The benchmark case is with panel data, in which each unit {it:i} that gets treated as of period {it:Ei} stays treated forever; 
some units may never be treated. Other types of data (e.g. repeated cross-sections) and other designs (e.g. triple-diffs) are also allowed;
see {help did_imputation##usage:Usage examples}.
{p_end}

{pstd}Estimation proceeds in three steps:{p_end}

{p2col 5 8 8 0 : 1.}{ul:Estimate} a model for non-treated potential outcomes using the non-treated (i.e. never-treated or not-yet-treated) 
observations only. The benchmark model for diff-in-diff designs is a two-way fixed effect (FE) model: Y_it = a_i + b_t + eps_it, 
but other FEs, controls, etc., are also allowed.{p_end}
{p2col 5 8 8 0 : 2.}{ul:Extrapolate} the model from Step 1 to treated observations, {ul:imputing} non-treated potential outcomes Y_it(0),
and obtain an estimate of the treatment effect {it: tau_it = Y_it - Y_it(0)} for each treated observation. (See {help did_imputation##impfails:What if imputation is not possible}){p_end}
{p2col 5 8 8 0 : 3.}{ul:Take averages} of estimated treatment effects corresponding to the estimand of interest.{p_end}

{pstd}
A pre-trend test (for the assumptions of parallel trends and no anticipation) is a separate exercise 
(see the {opt pretrends} option). Regardless of whether the pre-trend test is performed, the reference group
for estimation is always all pre-treatment (or never-treated) observations.
{p_end}

{pstd}
To make "event study" plots, please use the accompanying command {help event_plot}.
{p_end}

{marker impfails}{...}
{title:What if imputation is not possible}

{phang}The imputation step (Step 2) is not always possible for all treated observations:{p_end}
{phang2}- With unit FEs, imputation is not possible for units treated in all periods in the sample;{p_end}
{phang2}- With period FEs, it is impossible to isolate the period FE from the variation in treatment effects
in a period when all units have already been treated (and if there are never-treated units);{p_end}
{phang2}- If you include group#period FEs, imputation is further impossible once all units {it:in the group} have been treated;{p_end}
{phang2}- Similar issues arise with other covariates in the model of Y(0).{p_end}

{phang}This is a fundamental issue: the model you specified does not allow to find unbiased estimates of treatment effects
for those observations (without restrictions on treatment effects; see Borusyak et al. 2023).

{phang}
If this problem arises (i.e. there is at least one treated observation that enters one of the estimands of interest with a non-zero weight
and for which the treatment effect cannot be imputed),
the command will throw an error and generate a dummy variable {it:cannot_impute} which equals to one for those observations.

{phang}You have two ways to proceed:{p_end}
{phang}- Modify the estimand, excluding those observations manually: via the {opt if} clause or by setting the weights on them to zero 
(via the {opt wtr} option);{p_end}
{phang}- Specify the {opt autosample} option that will do this automatically in most cases. But we recommend that you still review {it:cannot_impute}
to understand what estimand you will be getting.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Model of Y(0)}

{phang}{opt fe(list of FE)}: which FE to include in the model of Y(0). Default is {opt fe(i t)} for the diff-in-diff (two-way FE) model.
But you can include fewer FEs, e.g. just period FE {opt fe(t)} or, for repeated cross-sections at the individual level, {opt fe(state t)}. 
Or you can have more FEs: e.g. {bf:fe(}{it:i t{cmd:#}state}{bf:)} (for state-by-year FE with county-level data) 
or {bf:fe(}{it:i{cmd:#}dow t}{bf:)} (for unit by day-of-week FE). Each member of the list has to look like 
{it:v1{cmd:#}v2{cmd:#}...{cmd:#}vk}. If you want no FE at all, specify {opt fe(.)}.
{p_end}

{phang}{opt c:ontrols(varlist)}: list of continuous time-varying controls. (For dummy-variable controls, e.g. gender, please use the
{opt fe} option for better convergence.){p_end}

{phang}{opt unitc:ontrols(varlist)}: list of continuous controls (often unit-invariant) to be included {it:interacted} with unit dummies. 
E.g. with {opt unitcontrols(year)} the regression includes unit-specific trends.
(For binary controls interacted with unit dummies, use the {opt fe} option.) {p_end}

{pmore}{it:Use with caution}: the command may not recognize that imputation is not possible for some treated observations.
For example, a unit-specific trend is not possible to estimate if only one pre-treatment observation is available for the unit, but it is not
guaranteed that the command will throw an error.
{p_end}

{phang}{opt timec:ontrols(varlist)} list of continuous controls (often time-invariant) to be included {it:interacted} with period dummies.
E.g. with {opt timecontrols(population)} the regression includes {it:i.year#c.population}.
(For binary controls interacted with period dummies, use the {opt fe} option.){p_end}

{pmore}{it:Use with caution}: the command may not recognize that imputation is not possible for some treated observations.
{p_end}

{dlgtab:Estimands and Pre-trends}

{phang}{opt wtr(varlist)}: A list of variables, manually defining estimands of interest by storing the weights on the treated observations.{p_end}
{phang2}- If {help did_imputation##weights:estimation weights} ({bf:aw/iw/fw}) are used, {opt wtr} weights will be applied {it:in addition}
to those weights in defining the estimand.{p_end}
{phang2}- If nothing is specified, the default is the simple ATT across all treated observations (or, with {opt horizons} or {opt allhorizons}, by horizon). So {opt wtr}=1/number of the relevant observations. {p_end}
{phang2}- Values of {opt wtr} for untreated observations are ignored (except as initial values in the iterative procedure for computing SE).{p_end}
{phang2}- Values below 0 are only allowed  if {opt sum} is also specified (i.e. for weighted sums and not weighted averages).{p_end}
{phang2}- Using multiple {opt wtr} variables is faster than running {cmd:did_imputation} for each of them separately, and produces a joint variance-covariance matrix.{p_end}

{phang}{opt sum}: if specified, the weighted {it:sum}, rather than average, of treatment effects is computed (overall or by horizons).
With {opt sum} specified, it's OK to have some {opt wtr}<0 or even adding up to zero;
this is useful, for example, to estimate the difference between two weighted averages of treatment effects
(e.g. across horizons or between men and woment).{p_end}

{phang}{opt h:orizons(numlist)}: if specified, weighted averages/sums of treatment effects will be reported for each of these horizons separately
(i.e. tau0 for the treatment period, tau1 for one period after treatment, etc.). Horizons which are not specified will be ignored.
Each horizon must a be non-negative integer.{p_end}

{phang}{opt allh:orizons}: picks all non-negative horizons available in the sample.{p_end}

{phang}{opt hbal:ance}: if specified together with a list of horizons, estimands for each of the horizons will be based
only on the subset of units for which observations for all chosen horizons are available
(note that by contruction this means that the estimands will be based on different periods).
If {opt wtr} or estimation weights are specified, the researcher needs to make sure that the weights are constant over time
for the relevant units---otherwise proper balancing is impossible and an error will be thrown.
Note that excluded units will still be used in Step 1 (e.g. to recover the period FEs) and for pre-trend tests.{p_end}

{phang}{opt het:by(varname)}: reports estimands separately by subgroups defined by the discrete (non-negative integer or string) 
variable provided. This is the preferred option for treatment effect heterogeneity analyses (but see also {opt project}).{p_end}

{phang}{opt pro:ject(varlist)}: projects (i.e., regresses) treatment effect estimates on a set of numeric variables 
and reports the constant and slope coefficients. The variables should not be collinear. (To analyse effect heterogeneity
by subgroup, option {opt hetby} is preferred. Note that standard errors may not agree exactly between {opt hetby} and
{opt project}.){p_end}

{phang}{opt minn(#)}: the minimum effective number (i.e. inverse Herfindahl index) of treated observations,
below which a coefficient is suppressed and a warning is issued. 
The inference on coefficients which are based on a small number of observations is unreliable. The default is {opt minn(30)}.
Set to {opt minn(0)} to report all coefficients nevertheless.{p_end}

{phang}{opt autos:ample}: if specified, the observations for which FE cannot be imputed will be automatically dropped from the sample, 
with a warning issued. Otherwise an error will be thrown if any such observations are found.
{opt autosample} cannot be combined with {opt sum} or {opt hbalance};
please specify the sample explicitly if using one of those options and you get an error that imputation has failed (see {help did_imputation##impfails:What if imputation is not possible}).{p_end}

{phang}{opt shift(integer)}: specify to allow for anticipation effects.
The command will pretend that treatment happened {opt shift} periods earlier for each treated unit.{p_end}
{phang2}- Do NOT use this option for pre-trend testing;
use it if anticipation effects are expected in your setting.
(This option {it:can} be used for a placebo test but we recommend a pretrend test instead; see Section 4.4 of Borusyak et al. 2023.){p_end}
{phang2}- The command's output will be labeled relative to the shifted treated date {it:Ei}-shift.
For example, with {opt horizons(0/10)} {opt shift(3)} you will get coeffieints {it:_b[tau0]}...{it:_b[tau10]} where tau{it:h}
is the effect {it:h} periods after the shifted treatment. That is, {it:tau1} corresponds to the average anticipation effect 2 periods before
the actual treatment, while {it:tau8} to the average effect 5 periods after the actual treatment.{p_end}

{phang}{opt pre:trends(integer)}: if some value {it:k}>0 is specified, the command will performs a test for parallel trends,
by a {bf:separate} regression on nontreated observations only: of the outcome on the dummies for 1,...,{it:k} periods before treatment,
in addition to all the FE and controls. The coefficients are reported as {bf:pre}{it:1},...,{bf:pre}{it:k}.
The F-statistic (corresponding to the cluster-robust Wald test), corresponding pvalue, and degrees-of-freedom are reported in {res:e(pre_F)}, 
{res:e(pre_p)}, and {res:e(pre_df)} resp.{p_end}
{phang2}- Use a reasonable number of pre-trends, do not use all of the available ones unless you have a really large never-treated group. With too many pre-trend coefficients, the power of the joint test will be lower.{p_end}
{phang2}- The entire sample of nontreated observations is always used for pre-trend tests, regardless of {opt hbalance} and other options that restrict the sample for post-treatment effect estimation.{p_end}
{phang2}- The number of pretrend coefficients does not affect the post-treatment effect estimates, which are always computed under the assumption of parallel trends and no anticipation.{p_end}
{phang2}- The reference group for the pretrend test is all periods more than {it:k} periods prior to the event date (and all never-treated
observations, if available).{p_end}
{phang2}- Because of this reference group, it is expected that the SE are the largest for pre1 (opposite from some conventional tests).{p_end}
{phang2}- This is only one of many tests for the parallel trends and no anticipation assumptions. Others are easy to implement manually; please see
the paper for the discussion.{p_end}

{dlgtab:Standard errors}

{phang}{opt clus:ter(varname)}: cluster SE within groups defined by this variable. Default is {it:i}. {p_end}

{phang}{opt avgeff:ectsby(varlist)}: Use this option (and/or {opt leaveout}) if you have small cohorts of treated observations, and after reviewing
Section 4.3 of Borusyak et al. (2023). In brief, SE computation requires averaging the treatment effects by groups of treated observations.{p_end}
{phang2}- These groups should be large enough, so that there is no downward bias from overfitting. {p_end}
{phang2}- But the larger they are, the more conservative SE will be, unless treatment effects are homogeneous within these groups. {p_end}
{phang2}- The varlist in {opt avgeffectsby} defines these groups.{p_end}
{phang2}- The default is cohort-years {opt avgeffectsby(Ei t)}, which is appropriate for large cohorts.{p_end}
{phang2}- With small cohorts, specify coarser groupings: e.g. {opt avgeffectsby(K)} (to pool across cohorts) or 
{opt avgeffectsby(D)} (to pool across cohorts and periods when computing the overall ATT). {p_end}
{phang2}- The averages are computed using the "smart" formula from Section 4.3, adjusted for any clustering and any choice of {opt avgeffectsby}. {p_end}

{phang}{opt leaveout}: {it:Recommended option}. In particular, use it (and/or {opt avgeffectsby}) if you have small cohorts of treated observations.
The averages of treatment effects will be computed excluding the own unit (or, more generally, cluster).
See Section 4.3 of Borusyak et al. (2023) for details.{p_end}

{phang}{opt alpha(real)}: confidence intervals will be displayed corresponding to that significance level. Default is 0.05.{p_end}

{phang}{opt nose}: do not produce standard errors (much faster).{p_end}

{dlgtab:Miscellaneous}

{phang}{opt save:estimates(newvarname)}: if specified, a new variable will be created storing the estimates of treatment effects for each observation
are stored. The researcher can then construct weighted averages of their interest manually (but without SE). {p_end}
{pmore}{it:Note}: Individual estimates are of course not consistent. But weighted sums of many of them typically are, which is what {cmd:did_imputation} generally reports. {p_end}

{phang}{opt savew:eights}: if specified, new variables {it:__w_*} are generated, storing the weights corresponding to (each) coefficient.
Recall that the imputation estimator is a linear estimator that can be represented as a weighted sum of the outcomes.{p_end}
{phang2}- These weights are applied on top of any {help did_imputation##weights:estimation weights}.{p_end}
{phang2}- For treated observations these weights equal to the corresponding {opt wtr} - that's why the estimator is unbiased
under arbitrary treatment effect heterogeneity.{p_end}
{phang2}- If a weighted average is estimated (i.e. {opt sum} is not specified) and there are no estimation weights, 
the weights add up to one across all treated observations.{p_end}
{phang2}- With unit and period FEs, weights add up to zero for every unit and time period (when weighted by estimation weights).{p_end}

{phang}{opt loadw:eights(varlist)}: use this to speed up the analysis of different outcome variables with an identical specification
on an identical sample. To do so, provide the set of the weight variables (__w*, but can be renamed),
saved using the {opt saveweights} option when running the analysis for the first outcome.
[Warning: the validity of the weights is assumed and not double-checked.] [Currently works only if the varnames are not __w*]{p_end}

{phang}{opt saver:esid(name)}: if specified, a new variable {it:name}_* is generated for each estimand (e.g. {it:name}_tau0) to store 
model residuals used in the computation of standard errors. For untreated observations, they are residuals from the estimation step. For 
treated observations, they are the epsilon-tildes from the BJS Theorem 3 (based on the {opt avgeffectsby} option) or the leave-out
versions from Appendix A.6. The residuals may be heterogeneous across estimands in general --- see equation (8) in the paper
which depends on the estimator weights, and thus on the estimand. This option can be helpful for reproducing the standard errors manually.{p_end}

{phang}{opt delta(integer)}: indicates that one period should correpond to {opt delta} steps of {it:t} and {it:Ei}. 
Default is 1, except when the time dimension of the data is set (via {help tsset} or {help xtset});
in that case the default is the corresponding delta.{p_end}

{phang}{opt tol(real)}, {opt maxit(integer)}: tolerance and the maximum number of iterations.
This affects the iterative procedure used to search for the weights underlying the estimator (to produce SE).
Defaults are 10^-6 and 100, resp. If convergence is not achieved otherwise, try increasing them.{p_end}

{phang}{opt verbose}: specify for the debugging mode.{p_end}


{marker weights}{...}
{title:Estimation weights}

{phang} Estimation weights (only {opt aw} or {opt iw} are allowed) play two roles: 

{p2col 5 8 8 0 : 1.}Step 1 estimation is done by a weighted regression. This is most efficient when the variance
of the error terms is inversely proportionate to the weights.

{p2col 5 8 8 0 : 2.}In Step 3, the average that defines the estimand is weighted by these weights.
If {opt wtr} is specified explicitly, estimation weights are applied on top of them.{p_end}
{phang2}- If {opt sum} is not specified, the estimand is the average of treatment effects weighted by {opt wtr}*{opt aw} {p_end}
{phang2}- If {opt sum} is specified, the estimand is the sum of treatment effects multiplied by {opt wtr}*{opt aw} {p_end}

{phang} Do NOT specify regression weights if you only have the second motivation to use the weights,
e.g. if you want to measure the ATT weighted by county size but you have no reason to think that the outcomes of larger counties have less noise.
Instead specify the estimand of your interest via {opt wtr}.{p_end}

{phang} All weight types ({opt aw/iw/fw}) produce identical results. Weights should always be non-negative. {p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:did_imputation} stores the following in {cmd:e()}:

{synoptset 10 tabbed}{...}
{p2col 5 15 15 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}A row-vector of (i) the estimates, (ii) pre-trend coefficients, and (iii) coefficients on controls from Step 1:{p_end}
{pmore3}- If {opt horizons} is specified, the program returns {bf:tau}{it:h} for each {it:h} in the list of horizons.{p_end}
{pmore3}- If multiple {opt wtr} are specified, the program returns {bf:tau_}{it:v} for each {it:v} in the list of {opt wtr} variables. {p_end}
{pmore3}- Otherwise the single returned coefficient is called {bf:tau}. {p_end}
{pmore3}- If {opt hetby} is specified, the coefficient names are appended with underscore and the values of the grouping variable. For instance, with {opt hetby(female)} where {it:female} takes values 0 and 1, the command will return {bf:tau}{it:h}_0 and {bf:tau}{it:h}_1 for each horizon, corresponding to average treatment effects by horizon and sex.{p_end}
{pmore3}- If {opt project} is specified, the coefficient names are appended with underscore and the constant plus the list of slope coefficients. For instance, with {opt project(female income)}, the command will return {bf:tau}{it:h}{bf:_cons}, {bf:tau}{it:h}{bf:_female}, and {bf:tau}{it:h}{bf:_income}.{p_end}
{pmore3}- In addition, if {cmd:pretrends} is specified, the command returns {bf:pre}{it:h} for each pre-trend coefficient {it:h}=1..{opt pretrends}. {p_end}
{pmore3}- And if {cmd:controls} is specified, the command returns the coefficients on those controls. (Estimated fixed effects, {cmd:unitcontrols}, and {cmd:timecontrols} are not reported in the {cmd:e(b)}.){p_end}
{synopt:{cmd:e(V)}}Corresponding variance-covariance matrix {p_end}
{synopt:{cmd:e(Nt)}}A row-vector of the number of treated observations used to compute each estimator {p_end}

{p2col 5 15 15 2: Scalars}{p_end}
{synopt:{cmd:e(Nc)}} the number of control observations used in imputation (scalar) {p_end}
{synopt:{cmd:e(pre_F), e(pre_p), e(pre_df)}} if {opt pretrends} is specified, the F-statistic, pvalue, and dof for the joint test for no pre-trends {p_end}
{synopt:{cmd:e(Niter)}} the # of iterations to compute SE {p_end}

{p2col 5 15 15 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}} {cmd:did_imputation} {p_end}
{synopt:{cmd:e(droplist)}} the set of coefficients suppressed to zero because of insufficient effective sample size (see the {opt minn} option){p_end}
{synopt:{cmd:e(autosample_drop)}} the set of coefficients suppressed to zero because treatment effects could not be imputed for any observation (if {opt autosample} is specified) {p_end}
{synopt:{cmd:e(autosample_trim)}} the set of coefficients where the sample was partially reduced because treatment effects could not be imputed for some observations (if {opt autosample} is specified) {p_end}

{p2col 5 15 15 2: Functions}{p_end}
{synopt:{cmd:e(sample)}} Marks the estimation sample: all treated observations for which imputation was successful and the weights are non-zero for at least one coefficient + all non-treated observations used in Step 1 {p_end}

{marker usage}{...}
{title:Usage Examples}

	{phang}{ul:Conventional panels}{p_end}

    1) Estimate the single average treatment-on-the-treated (ATT) across all treated observations, assuming that FE can be imputed for all treated observations (which is rarely the case)
        {cmd:. did_imputation Y i t Ei}

    2) Same but dropping the observations for which it cannot be imputed. (After running, investigate that the sample is what you think it is!)
        {cmd:. did_imputation Y i t Ei, autosample}

    3) Estimate the ATT by horizon
        {cmd:. did_imputation Y i t Ei, allhorizons autosample}

    4) Estimate the ATT at horizons 0..+6 only
        {cmd:. did_imputation Y i t Ei, horizons(0/6)}

    5) Estimate the ATT at horizons 0..+6 for the subset of units available for all of these horizons (such that the dynamics are not driven by compositional effects)
        {cmd:. did_imputation Y i t Ei, horizons(0/6) hbalance}

    6) Include time-varying controls:
        {cmd:. did_imputation Y i t Ei, controls(w_first w_other*)}

    7) Include state-by-year FE
        {cmd:. did_imputation Y county year Ei, fe(county state#year)}

    8) Drop unit FE
        {cmd:. did_imputation Y i t Ei, fe(t)}

    9) Additionally report pre-trend coefficients for leads 1,...,5. The estimates for post-treatment effects will NOT change.
        {cmd:. did_imputation Y i t Ei, horizons(0/6) pretrends(5)}

    10) Estimate the difference between ATE at horizons +2 vs +1 [this can equivalently be done via {help lincom} after estimating ATT by horizon]
        {cmd:. count if K==1}
        {cmd:. gen wtr1 = (K==1)/r(N)}
        {cmd:. count if K==2}
        {cmd:. gen wtr2 = (K==2)/r(N)}
        {cmd:. gen wtr_diff = wtr2-wtr1}
        {cmd:. did_imputation Y i t Ei, wtr(wtr_diff) sum}

    11) Reduce estimation time by using {opt loadweights} when analyzing several outcomes with identical specifications on identical samples:
        {cmd:. did_imputation Y1 i t Ei, horizons(0/10) saveweights}
        {cmd:. rename __* myweights* // optional}
        {cmd:. did_imputation Y2 i t Ei, horizons(0/10) loadweights(myweights*)}
		
{phang}12) {ul:Treatment effect heterogeneity}: {p_end}
{pmore}To estimate heterogeneity by individual's sex {it:female}, you can obtain individual treatment effect estimates 
(via {opt saveestimates}) and simply run a second-step regression of the estimates on {it:female}: {p_end}
{pmore}{cmd:. did_imputation Y i t Ei, saveestimates(tau)}{p_end}
{pmore}{cmd:. reg tau female} (DON'T DO THIS!){p_end}

{pmore}HOWEVER, standard errors will be incorrect. Instead, use {opt hetby} or {opt project}:{p_end}
{pmore}{cmd:. did_imputation Y i t Ei, hetby(female)}{p_end}
{pmore}will produce the ATT for males (tau_0) and females (tau_1). You can further use{p_end}
{pmore}{cmd:. lincom tau_1-tau_0}{p_end}
{pmore}to compute the difference between them with a SE. Alternatively,{p_end}
{pmore}{cmd:. did_imputation Y i t Ei, project(female)}{p_end}
{pmore}will produce the ATT for males (tau_cons) and the difference in ATTs between females and males (tau_female).{p_end}

{pmore}Both options can be combined with {opt horizons} to do heterogeneity analysis within each horizon.{p_end}

{pmore}If you also want to allow different period effects for the two groups, you can use the {opt fe()} option as usual, e.g.:{p_end}
{pmore}{cmd:. did_imputation Y i t Ei, hetby(female) fe(i t#female)}{p_end}
		
{phang}21) {ul:Repeated cross-sections}: {p_end}
{pmore}When in each period you have a different sample of individiuals {it:i} in the same groups (e.g. regions), 
replace individual FEs with group FEs and consider clustering at the regional level:{p_end}
{phang2}{cmd:. did_imputation Y i t Ei, fe(region t) cluster(region) ...}{p_end}

{pmore}Note the main parameters still include {it:i}, and not {it:region}, as the unit identifier.{p_end}

{phang}22) {ul:Triple-diffs}: {p_end}
{pmore}When observations are defined by {it:i,g,t} when, say, {it:i} are counties and {it:g} are age groups,
specify a variable {it:ig} identifying the {it:(i,g)} pairs as the unit identifier, add appropriate FEs, and choose your clustering level, e.g.:{p_end}
{phang2}{cmd:. did_imputation Y ig t Eig, fe(ig i#t g#t) cluster(i) ...}{p_end}

{pmore}Note that the event time {it:Eig} should be specific to the {it:i,g} pairs, not to the {it:i}. For instance, {it:Eig} is missing for a never-treated age group in a county where other groups are treated at some point.{p_end}

{title:Missing Features}

{phang}- Save imputed Y(0) in addition to treatment effects {p_end}
{phang}- Making {opt hbalance} work with {opt autosample} {p_end}
{phang}- Throw an error if imputation is not possible with complicated controls {p_end}
{phang}- Allow to use treatment effect averages for SE computation which rely even on observations
outside the estimation sample for the current {opt wtr} {p_end}
{phang}- Estimation when treatment switches on and off {p_end}
{phang}- More general interactions between FEs and continuous controls than with {opt timecontrols} and {opt unitcontrols}{p_end}
{phang}- Frequency weights{p_end}
{phang}- Verify that the unit ID variable is numeric{p_end}
{phang}- In Stata 13 there may be a problem with the {opt df} option of {cmd:test} {p_end}
{phang}- {opt loadweights} doesn't work when the weights are saved with the default names {it:__w*}{p_end}
{phang}- Allow for designs in which treatment is not binary{p_end}
{phang}- Add a check that ranges of {opt t} and {opt Ei} match{p_end}

{pstd}
If you are interested in discussing these or others, please {help did_imputation##author:contact me}.

{marker bugs}{...}
{title:Bug reporting}

{phang}If you get an error message, please:{p_end}
{phang}- Reinstall {cmd:reghdfe} and {cmd:ftools} to have the most recent version{p_end}
{phang}- Double check the syntax: e.g. make sure that {it:Ei} is the event date and not the treatment dummy, and that 
the treatment dummy can be obtained as {it:t>=Ei}{p_end}
{phang}- If it's a message with an explanation, read the message carefully.{p_end}

{phang}If this doesn't help:{p_end}
{phang}- Rerun your command adding the {opt verbose} option and save the log-file{p_end}
{phang}- If possible, create a version of the dataset in which you can replicate the error (e.g. with a fake outcome variable).{p_end}
{phang}- If you can't share a fake dataset, summarize all the relevant variables in the log-file before calling {cmd:did_imputation}.{p_end}
{phang}- Report this on {browse "https://github.com/borusyak/did_imputation/issues":github} or
{help did_imputation##author:email me} with all of this.{p_end}

{title:References}

{phang}
Borusyak, Kirill, Xavier Jaravel, and Jann Spiess (2023). "Revisiting Event Study Designs: Robust and Efficient Estimation," Working paper.
{p_end}

{title:Acknowledgements}

{pstd}
We thank Kyle Butts for the help in preparing this helpfile.

{marker author}{...}
{title:Author}

{pstd}
Kirill Borusyak (UC Berkeley), k.borusyak@berkeley.edu

