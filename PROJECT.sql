/*
Data Exploration project of COVID19
Skills used: Windows Functions, Joints, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types

*/

--Looking at the COVID19 Deaths table
SELECT *
FROM Project..CovidDeaths
ORDER BY 3,4


--Select Working Data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY 1,2


--Total Cases vs Total Deaths in China
-- Shows the likelihood of dying if you contract covid19 in China
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths)/total_cases) * 100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE location = 'China'
ORDER BY 1,2


--Total Cases vs Population in China
--Shows the percentage of the population that got covid19 in China
SELECT location, date, total_cases, population, 
(total_cases/population) * 100 AS InfectionPercentage
FROM Project..CovidDeaths
WHERE location = 'China'
ORDER BY 1,2


--Total Cases vs Total Deaths in USA
-- Shows the likelihood of dying if you contract covid19 in The USA
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths)/total_cases) * 100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2


--Total cases vs Population in USA
--Shows the percentage of the population that got covid19 in The USA
SELECT location, date, total_cases, population, 
(total_cases/population) * 100 AS InfectionPercentage
FROM Project..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2


--Total Cases vs Population (Break down by Country)
--Shows the percentage of the population that got Covid19 per country.
SELECT location, population, 
MAX(CAST(total_cases AS int)) as HighInfectionCount, (MAX(CAST(total_cases AS int))/population)*100 AS PercentPopulationInfected
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


--Death Count (Break down by Continent)
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc 


--GLOBAL NUMBERS
--Global Death percentage by date (2020/01 - 2024/01)
SELECT date, SUM(new_cases) AS GlobalCases, SUM(CAST(new_deaths AS int)) AS GlobalDeaths,
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2


--GLOBAL NUMBERS
--Death percentage GLOBALLY (likelihood of dying if you contract covid19)
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths,
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentaje
FROM Project..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2


--Looking at the vaccinations table
SELECT *
FROM Project..CovidVaccination
ORDER BY 3,4


--Population vs Vacccination (Break down by Country)
--Shows the percentage of the population of each country that is fully vaccinated
SELECT dea.location, MAX(dea.population) AS Population, MAX(CONVERT(FLOAT,vac.people_fully_vaccinated)) AS TotalPeopleVaccinated
, MAX(CONVERT(FLOAT,vac.people_fully_vaccinated))/MAX(dea.population)*100 AS PeopleVaccinatedPercentage
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.population > 1000000
GROUP BY dea.location
ORDER BY PeopleVaccinatedPercentage desc


-- Total doses of the Covid19 vaccine applied (Break down by Country)
--Using a CTE
WITH DosesCount (Continent, Location, Date, Population, New_vaccinations, RollingVaccination) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccination AS vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.population > 1000000
)
SELECT location, MAX(RollingVaccination) AS TotalDoses
FROM DosesCount
GROUP BY location
ORDER BY TotalDoses desc 


--Total Doses (WORKING TABLE)
--Creating a Temp Table from the previous query to perform calculations
DROP TABLE IF EXISTS #DosesCount 
CREATE TABLE #DosesCount 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccination numeric
)
INSERT INTO #DosesCount 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccination AS vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.population > 1000000


--Total Doses
--Using Temp Table
SELECT location, MAX(RollingVaccination) AS TotalDoses
FROM #DosesCount
GROUP BY location
ORDER BY TotalDoses desc


--Total Doses View
--Creating a view to store data for later visualizations
DROP VIEW IF EXISTS TotalDoses 

CREATE VIEW TotalDoses AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccination AS vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.population > 1000000

SELECT *
FROM TotalDoses



