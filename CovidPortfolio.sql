-- Quick overview of the data set
-- SELECT *
-- FROM PortfolioProject..CovidVaccinations
-- ORDER BY 3, 4

--Select the data that we are going to be using
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Calculate percent chance of death after contracting COVID-19 in US
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS PercentFatality
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

-- Looking at total cases vs population, calculate COVID-19 infection rate
SELECT 
	location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to population
SELECT 
	location, 
	-- Taking the latest total number of confirmed cases
	MAX(total_cases) 			AS HighestInfectionCount, 
	population, 
	MAX((total_cases/population))*100 	AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC

-- Looking at countries with highest death count per population
SELECT 
	location, 
	-- After importing, total_deaths data type was set as NVARCHAR. Had to change to INT for aggregation
	MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
/* Since continent and location cols contain duplicated value,
e.g. when location is 'Asia', continent is NULL
so the WHERE clause is used to filter out continent data */
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Show continents with highest death count per population
SELECT 
	location, 
	-- After importing, total_deaths data type was set as NVARCHAR. Had to change to INT for aggregation
	MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing daily total new confirmed cases, new deaths and percent death
SELECT 
	date, 
	SUM(new_cases) 			AS total_new_cases, 
	SUM(cast(new_deaths AS int)) 	AS total_new_deaths, 
	SUM(cast(new_deaths AS int))/SUM(new_cases)*100
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Shows total new confirmed cases, new deaths and percent death since day 1
SELECT 
	date, 
	SUM(new_cases) 			AS total_new_cases, 
	SUM(cast(new_deaths AS int)) 	AS total_new_deaths, 
	SUM(cast(new_deaths AS int))/SUM(new_cases)*100
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at total population vs vaccinations
-- Learning to use CTE
WITH PopvsVac (
	-- Set the columns for PopvsVac CTE
	continent, 
	location, 
	date, 
	population, 
	new_vaccinations, 
	running_total_vaccinated
) AS (
	SELECT 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		-- Running total for number of new vaccinations
		SUM(CONVERT(int, vac.new_vaccinations)) 
			-- Breaking up new vaccinations according to location, arrange by location and date
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_total_vaccinated
	FROM PortfolioProject..CovidDeaths 		AS dea
	JOIN PortfolioProject..CovidVaccinations 	AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2, 3
)
SELECT *, (running_total_vaccinated/population)*100
FROM PopvsVac

-- Learn to use Temp Table
-- Recommended to include DROP TABLE when making changes and easy to maintain
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	CumulatedVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations AS int)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulatedVaccinated
FROM PortfolioProject..CovidDeaths 		AS dea
JOIN PortfolioProject..CovidVaccinations 	AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (CumulatedVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Learn to create view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
	SELECT 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS int)) 
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulatedVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated
