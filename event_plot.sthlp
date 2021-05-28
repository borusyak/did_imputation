{smcl}
{* *! version 1 2021-05-26}{...}
{vieweralsosee "did_imputation" "help did_imputation"}{...}
{vieweralsosee "csdid" "help csdid"}{...}
{vieweralsosee "did_multiplegt" "help did_multiplegt"}{...}
{vieweralsosee "eventstudyinteract" "help eventstudyinteract"}{...}
{vieweralsosee "did_multiplegt" "help did_multiplegt"}{...}
{vieweralsosee "estimates store" "help estimates store"}{...}
{viewerjumpto "Syntax" "event_plot##syntax"}{...}
{viewerjumpto "The list of models" "event_plot##listmodels"}{...}
{viewerjumpto "Options" "event_plot##options"}{...}
{viewerjumpto "Combining plots" "event_plot##combine"}{...}
{viewerjumpto "Usage examples" "event_plot##usage"}{...}
{title:Description}

{pstd}
{bf:event_plot} - Plot the staggered-adoption diff-in-diff ("event study") estimates: coefficients post treatment ("lags") and, if available, pre-trend coefficients ("leads") along with confidence intervals (CIs). 

{pstd}
This command is used once estimates have been produced by the imputation estimator of Borusyak et al. 2021 ({help did_imputation}),
other methods robust to treatment effect heterogeneity ({help did_multiplegt}, {help csdid}, {help eventstudyinteract}), and conventional event-study OLS.


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: event_plot} [{help event_plot##listmodels:list of models}] [, {help event_plot##options:options}]


{marker listmodels}{...}
{title:The List of Models}

{phang}
Each term in the list of models specifies where to read the coefficient estimates (and variances) from.{p_end}

{phang}1) Leave empty or specify a dot ({bf:.}) to plot the current estimates, stored in the {cmd:e()} output;{p_end}
{phang}2) To show previously constructed estimates which were saved by {help estimates store}, provide their name;{p_end}
{phang}3) To read the estimates from an arbitrary row-vector, specify {it:bmat}{bf:#}{it:vmat} where:{p_end}
{pmore}- {it:bmat} is the name of the coefficient matrix or an expression to access it, e.g. r(myestimates) (with no internal spaces).
This should be a row-vector;{p_end}
{pmore}- {it:vmat} is the name of the variance matrix or an expression to access it.
This can be a square matrix or a row-vector of invidiual coefficient variances, and it is optional
(i.e. {it:bmat}{bf:#} would plot the coefs without CIs).{p_end}

{phang}By including several terms like this, you can combine several sets of estimates on one plot, see {help event_plot##combine:Combining plots}.


{marker options}{...}
{title:Options}

{pstd}
These options are designs for a showing single plot. Please see {help event_plot##combine:Combining plots} for adjustments and additional options when plots are combined.

{dlgtab:Which Coefficients to Show}

{phang}{opt stub_lag(prefix#postfix)}: a template for how the relevant coefficients are called in the estimation output.
No lag coefficients will be shown if {opt stub_lag} is not specified, except after {cmd:did_imputation} (in which case {opt stub_lag(tau#)} is assumed).
The template must include the symbol {it:#} indicating where the number is located (running from 0).{p_end}

{pmore}{it:Examples:}{p_end}
{phang2}{opt stub_lag(tau#)} means that the relevant coefficients are called tau0, tau1, ..., as with {cmd:did_imputation} (note that the postfix is empty in this example);{p_end}
{phang2}{opt stub_lag(L#xyz)} means they are called L0xyz, L1xyz, ... (note that just specifying {opt stub_lag(L#)} will not be enough in this case).

{phang}{opt stub_lead(prefix#postfix)}: same for the leads. Here the number runs from 1. {it:Examples:} {opt stub_lead(pre#)} or {opt stub_lead(F#xyz)}.

{phang}{opt trimlag(integer)}: lags 0..{bf:trimlag} will be shown, while others will be suppressed. To show none (i.e. pre-trends only), specify {opt trimlag(-1)}. The default is to show all available lags. 

{phang}{opt trimlead(integer)}: leads 1..{bf:trimlead} will be shown, while others will be suppressed. To show none (i.e no pre-trends), specify {opt trimlead(0)}. The default is to show all available lags. 

{dlgtab:How to Show The Coefficients}

{phang}{opt plottype(string)}: the {help twoway} plot type used to show coefficient estimates. Supported options: {help twoway connected:connected} (by default), {help line}, {help scatter}.{p_end}

{phang}{opt ciplottype(string)}; the {help twoway} plot type used to show CI estimates. Supported options:{p_end}
{phang2}- {help rarea} (default for {opt plottype(connected)} and {opt plottype(line)});{p_end}
{phang2}- {help rcap} (default for {opt plottype(scatter)});{p_end}
{phang2}- {help twoway connected:connected};{p_end}
{phang2}- {help scatter};{p_end}
{phang2}- {bf:none} (i.e. don't show CIs at all; default if SE are not available).{p_end}

{phang}{opt together}: by default the leads and lags are shown as two separate lines (as recommended by Borusyak, Jaravel, and Spiess 2021).
If {opt together} is specified, they are shown as one line, and the options for the lags are used for this line
(while the options for the leads are ignored). {p_end}

{phang}{opt shift(integer)}: Shift all coefficients to the left (when {opt shift}>0) or right (when {opt shift}<0). Specify if lag 0 actually corresponds to period -{opt shift} relative to the event time, as in the case of anticipation effects. This is similar to the {opt shift} option in {help did_imputation}. The default is zero. {p_end}

{dlgtab:Graph options}

{phang}{opt default_look}: sets default graph parameters. Additional graph options can still be specified and will be combined with these, but options cannot be repeated. See details in the {help event_plot##defaultlook:Default Look} section below. {p_end}

{phang}{opt graph_opt(string)}: additional {help twoway options} for the graph overall (e.g. {opt title}, {opt xlabel}).{p_end}

{phang}{opt lag_opt(string)}: additional options for the lag coefficient graph (e.g. {opt msymbol}, {opt lpattern}, {opt color}).{p_end}

{phang}{opt lag_ci_opt(string)}: additional options for the lag CI graph (e.g. {opt color}) {p_end}

{phang}{opt lead_opt(string)}, {opt lead_ci_opt(string)}: same for lead coefficients and CIs. Ignored if {opt together} is specified.{p_end}

{dlgtab:Legend options}

{pstd}A legend is shown by default, unless {opt together} is specified. You can either adjust the automatic legend by using {opt legend_opt()}
, or suppress or replace it by specifying {opt noautolegend} and modifying {opt graph_opt()}.{p_end}
{pmore}{it:Notes:}{p_end}
{phang2}- the order of graphs for the legend: lead coefs, lead CIs, lag coefs, lag CIs, excluding those not applicable
(e.g. CIs with {opt ciplottype(none)} or leads with {opt together}).{p_end}
{phang2}- with {opt ciplottype(connected)} or {opt ciplottype(scatter)}, each CI is two lines instead of one.{p_end}
{phang2}- if {opt together} is specified, the legend is automatically off. Use {opt noautolegend} to add a manual legend.{p_end}

{phang}{opt legend_opt(string)}: additional options for the automatic legend.{p_end}

{phang}{opt noautolegend}: suppresses the automatic legend. A manual legend (or the {opt legend(off)} option) should be added to {opt graph_opt()}.{p_end}

{dlgtab:Miscellaneous}

{phang}{opt savecoef}: save the data underlying the plot in the current dataset, e.g. to later use it in more elaborate manual plots.
Variables {it:__event_H#}, {it:__event_pos#}, {it:__event_coef#}, {it:__event_lo#}, and {it:__event_hi#} will be created for each model {it:#}=1,..., where:{p_end}
{phang2}- {it:H} is the number of periods relative to treatment;{p_end}
{phang2}- {it:pos} is the x-coordinate (equals to {it:H} by default but modified by {opt perturb} and {opt shift});{p_end}
{phang2}- {it:coef} is the point estimate;{p_end}
{phang2}- [{it:lo},{it:hi}] is the CI.{p_end}

{phang}{opt reportcommand}: report the command for the plot. Use it together with {opt savecoef} to then create more elaborate manual plots.{p_end}

{phang}{opt noplot}: do not show the plot (useful together with {opt savecoef}).{p_end}

{phang}{opt alpha(real)}: CIs will be shown for the confidence level {opt alpha}. Default is 0.05. {p_end}

{phang}{opt verbose}: debugging mode.{p_end}


{marker combine}{...}
{title:Combining plots}

{phang}Up to 8 models can be combined, e.g. to show how the estimates differ between {cmd:did_imputation} and OLS, or between males and females.

{phang}With several models, additional options are available, while the syntax and meaning of others is modified: {p_end}

{phang2}{opt perturb(numlist)}: shifts the plots horizontally relative to each other, so that the estimates are easier to read. The numlist is the list of x-shifts, and the default is an equally spaced sequence from 0 to 0.2 (but negative numbers are allowed). To prevent the shifts, specify {opt perturb(0)}. {p_end}

{phang2}{opt lag_opt#(string)}, {opt lag_ci_opt#(string)}, {opt lead_opt#(string)}, {opt lead_ci_opt#()} for #=1,...,5: extra parameters 
for individual models (e.g. colors). Similar options without an index, e.g. {opt lag_opt()}, are passed to all relevant graphs. {p_end}

{phang2}{opt stub_lag}, {opt stub_lead}, {opt trim_lag}, {opt trim_lead}, {opt shift} can be specified either as a list of values (one per plot), or as just one value to be used for all plots.{p_end}

{phang2}{opt plottype} and {opt together} are currently required to be the same for all graphs.{p_end}


{marker defaultlook}{...}
{title:Default Look}

{phang} With one model, specifying {opt default_look} is equivalent to including these options:{p_end}

{phang2}{opt graph_opt(xline(0, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)))}
{opt lag_opt(color(navy))} {opt lead_opt(color(maroon) msymbol(S))}
{opt lag_ci_opt(color(navy%45 navy%45))} {opt lead_ci_opt(color(maroon%45 maroon%45))}
{opt legend_opt(region(lstyle(none)))}

{phang}With multiple models, the only difference is in colors. Both lags and leads use the same color: navy for the first plot, maroon for the second, etc.{p_end}

{marker usage}{...}
{title:Usage examples}

    1) Estimation + plottting via {help did_imputation}:

        {cmd:did_imputation Y i t Ei, autosample hor(0/20) pretrend(14)}
        {cmd:estimates store bjs} {it:// you need to store the coefs only to combined the plots, see Exanple 3}
        {cmd:event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-14(7)14 20))}

    2) Estimation + plotting via conventional OLS-based event study estimation:

        {it:// creating dummies for the lags 0..19, based on K = number of periods since treatment (or missing if there is a never-treated group)}
        {cmd:forvalues l = 0/19} {
        	{cmd:gen L`l'event = K==`l'}
        }
        {cmd:gen L20event = K>=20} {it:// binning K=20 and above}
        
        {it:// creating dummies for the leads 1..14}
        {cmd:forvalues l = 0/13} { 
        	{cmd:gen F`l'event = K==-`l'}
        }
        {cmd:gen F14event = K<=-14} {it:// binning K=-14 and below}

        {it:// running the event study regression. Drop leads 1 and 2 to avoid underidentification}
        {it://if there is no never-treated group (could instead drop any others); see Borusyak et al. 2021}
        {cmd:reghdfe outcome o.F1event o.F2event F3event-F14event L*event, a(i t) cluster(i)}
		
        {it:// plotting the coeffients}
        {cmd:event_plot, default_look stub_lag(L#event) stub_lead(F#event) together plottype(scatter)} ///
		{cmd:graph_opt(xtitle("Days since the event") ytitle("OLS coefficients") xlabel(-14(7)14 20))}

    3) Combining estimates from {help did_imputation} OLS:

        {cmd:event_plot bjs ., stub_lag(tau# L#event) stub_lead(pre# F#event) together plottype(scatter) default_look} ///
		{cmd:graph_opt(xtitle("Days since the event") ytitle("OLS coefficients") xlabel(-14(7)14 20))}
		
    4) For estimation + plotting with {help csdid}, {help did_multiplegt}, and {help eventstudyinteract}, see our example on GitHub.


{title:Missing Features}

{phang}- More flexibility for {opt stub_lag} and {opt stub_lead} for reading the coefficients of conventional event studies{p_end}
{phang}- Automatic support of alternative robust estimators: {cmd:did_multiplegt}, {cmd:csdid}, and {cmd:eventstudyinteract}{p_end}
{phang}- Allow {opt plottype} and {opt together} to vary across the combined plots{p_end}

{pstd}
If you are interested in discussing these or others, please {help event_plot##author:contact me}.

{title:References}

{phang}{it:If using this command, please cite:}

{phang}
Borusyak, Kirill, Xavier Jaravel, and Jann Spiess (2021). "Revisiting Event Study Designs: Robust and Efficient Estimation," Working paper.
{p_end}

{title:Acknowledgements}

{pstd}
We thank Kyle Butts for the help in preparing this helpfile.

{marker author}{...}
{title:Author}

{pstd}
Kirill Borusyak (UCL Economics), k.borusyak@ucl.ac.uk

