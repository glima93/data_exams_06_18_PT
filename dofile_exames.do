* Do-file JNE
*************
*--------------------------------------------------------------------
* Date: August 2019
* Project: EXAMES
* Author: Gonçalo Lima
* Version: Stata 13.1
*------------------------------------------------------------------
* HOUSEKEEPING
clear
clear matrix
set more off
version 13.1

* DIRECTORIES
// Working directory ** Change accordingly
global wd "E:\WD SmartWare.swstor\Datasets\JNE"

// Setting working directory
cd "$wd"

* PACKAGES
ssc install labutil
ssc install gtools
* -------------------------------------------------------------------

** BASIC EDUCATION EXAMS

 // ENEB
cap erase eneb.dta
forvalues i=2006/2018 {
	odbc query "MS Access Database;DBQ=$wd\eneb_`i'.mdb;"
	odbc load, table(tblHomologa_`i') lowercase clear
	
	gen sexo2 = 1 if sexo == "F"
	replace sexo2 = 2 if sexo == "M"
	labmask sexo2, values(sexo)
	drop sexo
	rename sexo2 sexo
	
	gen ano1 = `i' - 1
	gen ano2 = `i'
	gen ano22 = `i'- 2000
	gen anoletivo = ano1
	gen anoletivo2 = string(ano1) + "/" + string(ano22)
	drop ano1 ano2 ano22 
	
	cap rename exame prova
	cap rename chamada fase 
	cap destring fase, replace
	
	cap destring exame, replace
	
	cd "$data_jne"
	cap append using eneb
	save eneb, replace
}
duplicates drop
labmask anoletivo, values(anoletivo2)
drop anoletivo2

save eneb, replace

cap erase escolas_eneb.dta
forvalues i=2006/2018 {
	cap erase escolas_`i'
	odbc query "MS Access Database;DBQ=$wd\eneb_`i'.mdb;"
	odbc load, table(tblEscolas) lowercase clear
		
	gen ano1 = `i' - 1
	gen ano2 = `i'
	gen ano22 = `i'- 2000
	gen anoletivo = ano1
	gen anoletivo2 = string(ano1) + "/" + string(ano22)
	drop ano1 ano2 ano22 
	
	cd "$data_jne"
	cap append using escolas_eneb
	save escolas_eneb, replace
}
duplicates drop
labmask anoletivo, values(anoletivo2)
drop anoletivo2

rename descr escola_nome

destring coddgeec, replace
gegen code_escola_dgeec = mode(coddgeec), by(escola) maxmode
drop coddgeec

gen tipo_escola = 1 if pubpriv == "PUB"
replace tipo_escola = 2 if pubpriv == "PRI"
label define tipo_escola 1 "Pública" 2 "Privada"
label values tipo_escola tipo_escola
drop pubpriv

merge m:1 distrito concelho using codes_concelhos, gen(_merge_concelho)
drop if _merge_concelho == 2
drop _merge_concelho
rename concelho eneb_concelho
rename descr concelho

merge m:1 distrito using codes_distrito, gen(_merge_distrito)
drop _merge*
rename distrito eneb_distrito
rename descr distrito

merge m:1 nuts3 using codes_nuts3, gen(_merge_nuts3)
drop _merge*
rename nuts3 eneb_nut3
rename descr nut3

order anoletivo escola escola_nome tipoescola tipo_escola nut3 distrito concelho 

save escolas_eneb, replace

use eneb, clear
replace escola = escolainsc if escola == ""

merge m:1 anoletivo escola using escolas_eneb, gen(_merge_escolas)
drop if _merge_escolas == 2
drop _merge*

merge m:1 prova using codes_provas, gen(_merge_provas)
drop _merge_provas
rename prova code_prova
rename descr prova

replace prova = "Português - 3º ciclo" if prova == "Língua Portuguesa"
replace code_prova = "91" if code_prova == "22"
replace prova = "Matemática - 3º ciclo" if prova == "Matemática"
replace code_prova = "92" if code_prova == "23"
replace prova = "PLNM A2 - 3º ciclo" if prova == "Líng. Port. não materna -iniciação"
replace code_prova = "93" if code_prova == "28"
replace prova = "PLNM B1 - 3º ciclo" if prova == "Líng. Port. não materna -intermédio"
replace code_prova = "94" if code_prova == "29"
replace code_prova = "96" if code_prova == "75"
replace code_prova = "911" if code_prova == "81"
replace code_prova = "921" if code_prova == "82"
replace code_prova = "611" if code_prova == "51"
replace code_prova = "621" if code_prova == "52"
destring code_prova, replace

gen tipo_aluno = 1 if tipoaluno == "I"
replace tipo_aluno = 2 if tipoaluno == "4"
replace tipo_aluno = 3 if tipoaluno == "3"
replace tipo_aluno = 4 if tipoaluno == "C"
label define tipo_aluno 1 "Interno" 2 "AP c/freq." 3 "AP s/freq." 4 "Outras Sit."
label values tipo_aluno tipo_aluno
drop tipoaluno

drop escolainsc
gegen tipo_escola2 = mode(tipo_escola), by(escola) maxmode
drop tipo_escola 
rename tipo_escola2 tipo_escola
label values tipo_escola tipo_escola

order anoletivo id escola escola_nome escolaorigem code_prova prova fase 

rename (id idade) (f_id f_idade)
drop i*
rename (f_id f_idade) (id idade)

save eneb, replace

** SECONDARY EDUCATION EXAMS

// ENES
cap erase enes.dta
forvalues i=2008/2018 {
	odbc query "MS Access Database;DBQ=$wd\enes_`i'.mdb;"
	odbc load, table(tblHomologa_`i') lowercase clear
	
	tempfile enes_`i'
	save `enes_`i''
	
	foreach x in escola distrito concelho exame curso ///
		 tpcurso subtipo {
		
		local tbl_escola tblEscolas
		local tbl_distrito tblCodsDistrito
		local tbl_concelho tblCodsConcelho
		local tbl_exame tblExames
		local tbl_curso tblCursos
		local tbl_tpcurso tblCursosTipos
		local tbl_subtipo tblCursosSubTipos
		
		local merger_escola escola
		local merger_distrito distrito
		local merger_concelho distrito concelho
		local merger_exame exame
		local merger_curso curso
		local merger_tpcurso tpcurso
		local merger_subtipo tpcurso subtipo
		
		odbc query "MS Access Database;DBQ=$wd\enes_`i'.mdb;"
		odbc load, table(`tbl_`x'') lowercase clear
		
		cap rename descr `x'_nome 
			
		merge 1:m `merger_`x'' using `enes_`i'', gen(_merge_`x')
		save `enes_`i'', replace
	}
	
	gen ano1 = `i' - 1
	gen ano2 = `i'
	gen ano22 = `i'- 2000
	gen anoletivo = ano1
	gen anoletivo2 = string(ano1) + "/" + string(ano22)
	drop ano1 ano2 ano22 
	
	cap rename exame prova
	cap rename chamada fase 
	cap destring fase, replace
	cap destring prova, replace
	
	cap drop _merge*
	drop if id == .
	cd "$data_jne"
	cap append using enes
	save enes, replace
}

duplicates drop
gen sexo2 = 1 if sexo == "F"
	replace sexo2 = 2 if sexo == "M"
	labmask sexo2, values(sexo)
	drop sexo
	rename sexo2 sexo
labmask anoletivo, values(anoletivo2)
drop anoletivo2

save enes, replace

odbc query "MS Access Database;DBQ=$wd\enes_2017.mdb;"
odbc load, table(tblCodsSitFreq) lowercase clear
merge 1:m sitfreq using enes, gen(_merge_sitfreq)
drop _merge_sitfreq
rename descr sitfreq_nome
drop defin
drop if id == .
drop ordena

gen tipo_escola = 1 if pubpriv == "PUB"
replace tipo_escola = 2 if pubpriv == "PRI"
label define tipo_escola 1 "Pública" 2 "Privada"
label values tipo_escola tipo_escola
drop pubpriv tipoexame

label define dummy 0 "Não" 1 "Sim" .n "Não aplicável"
foreach x in interno paramelhoria paraingresso paraaprov ///
	paracfcepe teminterno {
	gen `x'2 = .n
	replace `x'2 = 0 if `x' == "N"
	replace `x'2 = 1 if `x' == "S"
	drop `x' 
	rename `x'2 `x' 
	label values `x' dummy
	}

order id anoletivo prova exame_nome fase class_exam cif cfd sexo idade ///
	escola escola_nome tipo_escola coddgae coddgeec curso curso_nome tpcurso tpcurso_nome ///
	subtipo subtipo_nome ano_ini ano_term anoterminal sitfreq sitfreq_nome ///
	distrito distrito_nome concelho concelho_nome nuts3  ///
	interno paramelhoria paraingresso paraaprov paracfcepe teminterno
gsort anoletivo escola prova

save enes, replace





