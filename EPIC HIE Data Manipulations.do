//EPIC HIE DATA MANIPULATIONS
//Changes being tracked in GitHub
//Testing for git hub
//Testing Again

---------------------------------------------------------------
//Hospitalizations-CE-Users Query Data July 1 to Dec 31 2014
//This file is the join of hospitalization table from OHSU DW on ceid_query_audit and ORG-Details


//----Formatting Data Set-----//
//Dropping all observations for non-adults
drop if age_at_admission < 18
//Giving first instance of varname new column nvals ==1
by pat_enc_csn_id , sort: gen nvals = _n == 1
//Creating single variable for admission name admit
//Admit=1, ER = 0
generate admit = 1 if (encounter_visit_type == "Inpatient" | encounter_visit_type =="Observation")
replace admit = 0 if admit ==.
//Creating Dummy Variable for Emergency
//Redundnat to above Admit variable
generate ER = 1 if (encounter_visit_type == "Emergency")
replace ER = 0 if ER ==.
//----End Formatting Data-----//


//----Analysis of query initiation for encounters by admit vs. ED
//tabulate CE_Queried for each type of visit for each unique CSN
bysort admit : tabulate ce_queried if nvals==1 




//-------Collapsing to idv. pt encounters where queries used--------
//to determine for patients whom were queried what was the sucess of those queries//
//Collapsing to single pat_enc_csn_id for patient in whom query was initiated----//
//drops all obs where no query performed
drop if ce_queried==0
//creates query_sucess dummy variable sucess=1, failure =0
generate query_sucess =1 if query_outcome_c ==1
replace query_sucess = 0 if query_sucess ==.
//collapses all pat_enc_csn_id to one observation and if query_sucess >0 then at least
//one of the queries was sucessful
collapse (sum) query_sucess admit, by( pat_enc_csn_id)
//returns query_sucess to binary 1=sucess, 0=failure
replace query_sucess =1 if query_sucess >0
//returns admit variable to binary admit =1 and ED =0
replace admit =1 if admit >0
//tabulates whether individual encounters in restricted dataset(only those with queries initiated)
//had at least one succesful query by admission vs. ED
bysort admit: tabulate query_sucess
//----------Collapsing----------------------



//-------------GENDER ANALYSIS---------------

//Creating Male dummy variable
generate male =1 if gender =="M"
replace male = 0 if male ==.

//Tabulate Male vs. Female by Queried (if age>=18 and unique encounters)
bysort ce_queried: tabulate gender if (nvals==1 & age_at_admission >=18)

//Probability test on male 
prtest male if (nvals==1 & age_at_admission >=18), by (ce_queried)



//------------Age Analysis------------------//

//t-test of age for ED and admitted 
ttest age if (nvals==1 & age_at_admission >=18), by (ce_queried)

//T-test of age for those admitted
ttest age if (nvals==1 & admit== 1 & age_at_admission >=18), by (ce_queried)



//---LOS Analysis----------------------//
//ttest of LOS for those admitted and >=18 
ttest inpatient_length_of_stay if (nvals==1 & admit ==1 & age_at_admission >=18), by (ce_queried)


//-----CMI Analysis-----------------/
//Ttest of case mix index for those admitted and >= 18
ttest ms_cmi if (nvals==1 & admit ==1 & age_at_admission >=18), by (ce_queried)


//----Query success Analysis-------//


//Query techinical results, i.e. succesful, unsuccesful and timed out.
//Varaible comes from Clarity ceid_query_audit
//1 - Successful, 2 Unsuccessful, 3 User Canceled, 4 - Timed Out, 5 User Rejected, 6 Deferred Response   
 

//All comers  
bysort ce_queried: tabulate query_outcome_c if (age_at_admission >=18)
//ED Patients
bysort ce_queried: tabulate query_outcome_c if (age_at_admission >=18 & ER ==1)
//Admited patients
bysort ce_queried: tabulate query_outcome_c if (age_at_admission >=18 & admit ==1)



//-------------------------------------Extra Commands

//Not sure if this is helpful
//Tabulate CE_queried for each unique visit and where patient was a transfer and adult pt
bysort encounter_visit_type: tabulate ce_queried if (nvals ==1 & transfer_yn == "Y"& age_at_admission >=18 )


//Queries are generated from selected list this provides no useful info
//Tabulate organizations queried by descending frequency if age > 18 
tabulate organization_name if (age_at_admission >=18) , sort
