-- Založení pomocné tabulky se mzdami pouze pro fyzické mzdy
CREATE TABLE t_milan_durek_project_SQL_primary_pomocna_mzdy
	(SELECT				
		cp.payroll_year AS year_data,
		cp.payroll_quarter AS quarter_data,
		cpib.name AS name,
		cp.value AS value,
		cpu.name AS value_unit,
		cpc.name AS additional_info
	FROM czechia_payroll cp
	LEFT JOIN czechia_payroll_value_type cpvt
		ON cp.value_type_code = cpvt.code
	LEFT JOIN czechia_payroll_unit cpu
		ON cp.unit_code = cpu.code
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE cp.value IS NOT NULL AND cp.industry_branch_code IS NOT NULL AND cpu.code = '200'
);

-- Přidání sloupce s informací o jaká data se jedná.
ALTER TABLE t_milan_durek_project_SQL_primary_pomocna_mzdy
ADD COLUMN source_table varchar(255);

UPDATE t_milan_durek_project_SQL_primary_pomocna_mzdy
SET source_table = 'mzdy';

-- Pomocné výrazy pro zrušení tabulky a vybrání tabulky
/*
DROP TABLE	t_milan_durek_project_SQL_primary_pomocna_mzdy

SELECT
	*
FROM t_milan_durek_project_SQL_primary_pomocna_mzdy;
*/

SELECT DISTINCT 
	price_unit
FROM czechia_price_category

-- Založení pomocné tabulky se potravinami
CREATE TABLE t_milan_durek_project_SQL_primary_final_pomocna_potraviny
	(SELECT				
		year(cp.date_from) AS year_data,
		CASE 
			WHEN dayofyear(cp.date_from) < 92 THEN '1'
			WHEN dayofyear(cp.date_from) < 183 THEN '2'
			WHEN dayofyear(cp.date_from) < 274 THEN '3'
			ELSE '4'
		END AS	quarter_data,
		cpc.name AS name,
		CASE 
			WHEN cpc.price_unit = 'g' THEN round(avg(cp.value * cpc.price_value / 1000),1)
			ELSE round(avg(cp.value * cpc.price_value),1)
		END AS value,
		CASE 
			WHEN cpc.price_unit = 'g' THEN 'kg'
			ELSE cpc.price_unit
		END AS value_unit
	FROM czechia_price cp
	LEFT JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	GROUP BY year_data, quarter_data, name
	ORDER BY name, year_data, quarter_data 
);

-- Přidání sloupce s informací o jaká data se jedná.
ALTER TABLE t_milan_durek_project_SQL_primary_final_pomocna_potraviny
ADD COLUMN additional_info varchar(255),
ADD COLUMN source_table varchar(255);

UPDATE t_milan_durek_project_SQL_primary_final_pomocna_potraviny
SET source_table = 'potraviny'

-- Pomocné výrazy pro zrušení tabulky a vybrání tabulky
/*
DROP TABLE	t_milan_durek_project_SQL_primary_final_pomocna_potraviny;

SELECT
	*
FROM t_milan_durek_project_SQL_primary_final_pomocna_potraviny
*/

-- Založení společné tabulky, která obsahuje jak mzdy tak ceny potravin
CREATE TABLE t_milan_durek_project_SQL_primary(
SELECT
	*
FROM t_milan_durek_project_SQL_primary_final_pomocna_potraviny
UNION
SELECT
	*
FROM t_milan_durek_project_SQL_primary_pomocna_mzdy);

SELECT
	*
FROM t_milan_durek_project_SQL_primary;


-- OTÁZKA 1 - Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

SELECT
	name,
	year_data,
    round(avg(
		CASE 
			WHEN additional_info = 'fyzicky' THEN value
			ELSE Null
		END
    )) AS fyzicky,
    round(avg(
		CASE 
			WHEN additional_info = 'prepocteny' THEN value
			ELSE Null
		END
    )) AS prepocteny    
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'mzdy'
GROUP BY name, year_data;


-- OTÁZKA 2 - Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT
	*
FROM t_milan_durek_project_SQL_primary;


-- Netuším, jak mám spojit tyto dva výrazy do jedné tabulky. Vytáhl jsem tedy ve dvou výrazech a spojil v excelu
SELECT
	name,
	year_data,
	avg(value)
FROM t_milan_durek_project_SQL_primary
WHERE name ='Chléb konzumní kmínový' OR name ='Mléko polotučné pasterované'
GROUP BY name, year_data;

SELECT
	year_data,
	round(avg(value)) AS prumerna_hodnota_mzdy
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'mzdy'
GROUP BY year_data;


-- OTÁZKA 3 - Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

SELECT
	*
FROM t_milan_durek_project_SQL_primary

-- Netuším, jak mám spojit tyto dva výrazy do jedné tabulky. Vytáhl jsem tedy ve dvou výrazech a spojil v excelu
SELECT
	name,
	year_data,
	avg(value)
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'potraviny'
GROUP BY name, year_data;

SELECT
	name,
	year_data - 1 AS year_data_previous,
	avg(value)
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'potraviny'
GROUP BY name, year_data;

-- OTÁZKA 4 - Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- Netuším, jak mám spojit tyto dva výrazy do jedné tabulky. Vytáhl jsem tedy ve dvou výrazech a spojil v excelu
SELECT
	source_table,
	year_data,
	avg(value)
FROM t_milan_durek_project_SQL_primary
GROUP BY source_table, year_data;

SELECT
	source_table,
	year_data - 1 AS year_data_previous,
	avg(value)
FROM t_milan_durek_project_SQL_primary
GROUP BY source_table, year_data;


-- OTÁZKA 5 - Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

-- Vytvoření druhé tabulky se státy
SELECT
	*
FROM countries c;

SELECT
	*
FROM economies e;

CREATE TABLE t_milan_durek_project_SQL_secondary(
SELECT
	e.year,
	SUM(e.GDP) AS sum_GDP,
	SUM(e.population) AS sum_population,
	c.region_in_world
FROM economies e
INNER JOIN countries c
	ON e.country = c.country
WHERE GDP IS NOT NULL AND e.population IS NOT NULL AND region_in_world IS NOT NULL
GROUP BY region_in_world, year);

-- Pomocné výrazy pro zrušení tabulky a vybrání tabulky
/*
DROP TABLE	t_milan_durek_project_SQL_secondary
*/

-- Netuším, jak mám spojit tyto 4 výrazy do jedné tabulky. Vytáhl jsem tedy ve 4 výrazech a spojil v excelu
SELECT
	*
FROM t_milan_durek_project_SQL_secondary;

SELECT
	year - 1 AS year_previous,
	sum_GDP,
	sum_population,
	region_in_world
FROM t_milan_durek_project_SQL_secondary;

SELECT
	year_data,
	avg(value)
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'potraviny'
GROUP BY year_data;

SELECT
	year_data - 1 AS year_data_previous,
	avg(value)
FROM t_milan_durek_project_SQL_primary
WHERE source_table = 'potraviny'
GROUP BY year_data;
