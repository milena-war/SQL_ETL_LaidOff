-- Eksloprowanie danych /Exploring Data

--ETL Process
--Eksploracyjna analiza danych


select *
from layoffs_staging

SELECT MIN("date"), MAX("date")
FROM layoffs_staging

select max(total_laid_off) as max_laid, MAX(percentage_laid_off) as max_percentage
from layoffs_staging

select percentage_laid_off
from layoffs_staging

select company, total_laid_off, percentage_laid_off * 100 as laid_offs_percentage
from layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC

 -- sprawdzenie jakie firmy zwolni³y najwiêcej pracowników
SELECT company, SUM(total_laid_off) as sum_of_laid_offs
from layoffs_staging
GROUP BY company
ORDER BY 2 desc

-- sprawdzenie jakie obszary ucierpia³y najbardziej
SELECT industry, SUM(total_laid_off) as total_laid_offs
from layoffs_staging
GROUP BY industry
ORDER BY 2 desc

-- sprawdzenie które kraje ucierpia³y najbardziej
SELECT country, SUM(total_laid_off) as total_laid_offs
from layoffs_staging
GROUP BY country
ORDER BY 2 desc

-- sprawdzenie liczby zwolnien wg daty
SELECT YEAR("date") as "Year", SUM(total_laid_off) as total_laid_offs
from layoffs_staging
GROUP BY YEAR("date")
ORDER BY 1 desc

--- sprawdzenie liczby zwolnien wg stage
SELECT stage, SUM(total_laid_off) as total_laid_offs
from layoffs_staging
GROUP BY stage
ORDER BY 2 desc

-- suma krocz¹ca zwolnieñ wg miesiêcy (suma miesiaca ze wszystkich lat)

SELECT "date"
FROM layoffs_staging

SELECT SUBSTRING("date",6, 2 ) AS "Month", SUM(total_laid_off) AS total_laid_off_month
FROM layoffs_staging
WHERE SUBSTRING("date",6, 2 ) IS NOT NULL
GROUP BY SUBSTRING("date",6, 2 )
ORDER By "Month"


--suma krocz¹ca zwolnieñ wg miesiêcy w kazdym roku
SELECT SUBSTRING("date",1,7 ) AS "Month", SUM(total_laid_off) AS total_laid_off_month
FROM layoffs_staging
WHERE  SUBSTRING("date",1,7 ) IS NOT NULL
GROUP BY  SUBSTRING("date",1,7 )
ORDER BY 1 

--suma krocz¹ca
WITH Rolling_Total AS 
(
SELECT SUBSTRING("date",1,7 ) AS "Month", SUM(total_laid_off) as Total_laid_off
FROM layoffs_staging
WHERE  SUBSTRING("date",1,7 ) IS NOT NULL
GROUP BY  SUBSTRING("date",1,7 )
)
SELECT "Month", Total_laid_off,
SUM(total_laid_off) OVER(ORDER BY "Month") AS Rolling_total
FROM Rolling_Total


-- ustalenie, w których latch zwolniono najwiecej pracowników
-- uszeregowanie jaka firma zwolnila najwiecej pracownikow w danym roku (ranking)

SELECT  company, year("date") AS "years", SUM(total_laid_off) AS total_laid_offs
FROM layoffs_staging
GROUP BY company,  year("date")
ORDER BY 3 desc


-- 5 firm z najwiêksz¹ liczb¹ zwlonieñ w danym roku

WITH Company_Year AS
(
SELECT  company, year("date") AS "Year", SUM(total_laid_off) as Total_Laid_offs
from layoffs_staging
GROUP BY company,  year("date")
),
Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER (PARTITION BY "Year" ORDER BY Total_Laid_off desc) AS Ranking
FROM Company_Year
WHERE "Year" IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5




SELECT company, total_laid_off, "date",
sum(total_laid_off) OVER (PARTITION BY company) as sum_laid_offs
from layoffs_staging
WHERE company = 'Amazon'
