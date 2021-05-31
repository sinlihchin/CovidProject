SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

--Select the data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--Looking at total cases vs total deaths
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as PercentFatality
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

--Looking at total cases vs population
SELECT Location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

--Looking at countries with highest infection rate compared to population
SELECT Location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Looking at countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Showing continents with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'United States'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing global numbers
SELECT date, SUM(new_cases) as total_new_cases, SUM(cast(new_deaths as int)) as total_new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100--, total_deaths, (total_deaths/population)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--Looking at total population vs vaccinations
--Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, CumulatedVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as CumulatedVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (CumulatedVaccinated/Population)*100
FROM PopvsVac

--Temp Table
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
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as CumulatedVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (CumulatedVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Create view to store data for later visualization
CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as CumulatedVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated