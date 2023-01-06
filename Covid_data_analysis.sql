-- Select relevant columns from dataset
SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM 
    covid_deaths
ORDER BY
    1,2;

-- Total cases vs Total deaths. List by location.
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM 
    covid_deaths;    

/* Since total_deaths and total_cases are of data type integer, the resulting values 
when computing percentage does not have decimals. One way to resolve this is to use CAST to change 
data type to float. In the end, I decided edit the source table by changing data type of the column  
using pgAdmin. */

SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS percent
FROM 
    covid_deaths;

-- Total cases vs population. Shows what percentage of the US population got covid
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS percent_population_infected
FROM 
    covid_deaths
WHERE location = 'United States'
ORDER BY
	2;   

-- Countries with the highest infection rate compared to population
SELECT 
	location,
	population,
	MAX(total_cases) AS Highest_Infection_Count,
	MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM 
    covid_deaths
GROUP by 
	location, 
	population
ORDER BY
	Percent_Population_Infected DESC;

-- Countries with the highest death count per population
SELECT
	location,
	MAX(total_deaths) AS total_death_count
FROM 
	covid_deaths
WHERE 
	continent is not null
GROUP by 
	location
ORDER BY
	total_death_count DESC;

-- Highest death count per population by Continent. nb that there are continent values that are not really continents
SELECT
	location,
	MAX(total_deaths) AS total_death_count
FROM 
	covid_deaths
WHERE 
	continent is null /* AND location != 'World' AND location != 'High income'
	AND location != 'Upper middle income' AND location != 'Lower middle income'
	AND location != 'Low income' AND location != 'International' */
GROUP by 
	location 
ORDER BY
	total_death_count DESC;


-- Global numbers > death percentage. Shows the percentage of deaths out of those who got infected
SELECT 
	date,
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(new_cases) AS death_percentage
FROM 
	covid_deaths
WHERE
	continent IS NOT null
GROUP BY
	date
ORDER BY
	1,2;

/* Global numbers > death percentage. Computes the percentage of people all over the world 
who died out of those who got infected */
SELECT 
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(new_cases) AS death_percentage
FROM 
	covid_deaths
WHERE
	continent IS NOT null
ORDER BY
	1,2;

-- Joining covid_deaths table and covid_vaccinations table
SELECT *
FROM
	covid_deaths dea
JOIN
	covid_vaccinations vac
ON
	dea.location = vac.location
	AND dea.date = vac.date;

/* Total Population vs Vaccinations. Computing total number of individuals 
in the world who got vaccinated with running totals of people vaccinated */
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_people_vaccinated
FROM
	covid_deaths dea
JOIN
	covid_vaccinations vac
ON
	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT null
	--AND dea.location = 'Albania'
ORDER BY
	2,3;

-- USE CTE. Computing the total number of individuals vaccinated vs total population
WITH 
	Pop_vs_Vac (continent,
				location,
			    date,
				population,
				new_vaccinations,
				running_people_vaccinated
			   )
AS (SELECT
   		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_people_vaccinated
	FROM
		covid_deaths dea
	JOIN
		covid_vaccinations vac
	ON
		dea.location = vac.location
	AND dea.date = vac.date	
	WHERE dea.continent IS NOT null
   )
SELECT 
 	*,
	(running_people_vaccinated/population)*100 AS percentage_vaccinated
FROM
	Pop_vs_Vac;

