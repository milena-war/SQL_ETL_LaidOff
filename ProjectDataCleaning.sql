--Czyszczenie Danych /Data Cleaning
USE Project
GO

SELECT *
from layoffs

--1. Usunniêcie duplikatów/ Remove duplicates
--2. Ujednolicenie dancyh / Standardlize the Data
--3. Wartosci null albo puste / Null values or blank values
--4. Usuniêcie wszytskich kolumn i wierszy, które nie s¹ konieczne/ Remove any columns or row 

--Tworzê now¹ tymczasow¹ tabelê (kopiowanie danych z surowej tabeli do tabeli pomostowej)
SELECT *
INTO layoffs_staging
FROM layoffs
WHERE 1 = 0; -- 0 powoduje, ¿e nie zostan¹ skopiowane ¿adne rekordy

SELECT *
FROM layoffs_staging

-- £adowanie danych z tabeli layoffs do nowej tabeli layoffs_staging

INSERT layoffs_staging
SELECT *
FROM layoffs

--1. Usunniêcie duplikatów/ Remove duplicates
-- Identyfikowanie duplikatów ( zwróæ uwagê, ze nie ma klucza g³ównego)

SELECT *,
-- OVER - dzeli wg wszystkich kolumn w tabeli
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date'
ORDER BY  company) AS row_num
FROM layoffs_staging

-- znalezienie duplikatów

WITH duplicates_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date",
stage, country, funds_raised_millions
ORDER BY  company) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1

-- DELETE usuniêcie duplikatów (jednego z 2 wierszy)

WITH duplicates_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date",
stage, country, funds_raised_millions
ORDER BY  company) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicates_cte
WHERE row_num > 1

-- Utworzenie nowej tabeli aby skopiowaæ dane z oczyszczonej tabeli - bez duplikatów (opcjonalnie)
CREATE TABLE [dbo].[layoffs_staging2](
	[company] [varchar](50) NULL,
	[location] [varchar](50) NULL,
	[industry] [varchar](50) NULL,
	[total_laid_off] [varchar](50) NULL,
	[percentage_laid_off] [varchar](50) NULL,
	[date] [varchar](50) NULL,
	[stage] [varchar](50) NULL,
	[country] [varchar](50) NULL,
	[funds_raised_millions] [varchar](50) NULL,
	[row_num] [INT]
) ON [PRIMARY]
GO

select *
from layoffs_staging2

 -- za³adowanie oczyszczonych danych do nowej tabeli
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date",
stage, country, funds_raised_millions
ORDER BY  company) AS row_num
FROM layoffs_staging

select *
from layoffs_staging2
WHERE row_num > 1

-- 2 Standaryzacja Danych / Standardizing Data
--Polega na znajdowaniu problemów w danych a nastepnie na naprawianiu

-- usuniêcie bia³ych znaków

SELECT company, (TRIM(company))
FROM layoffs_staging
WHERE company LIKE '%inclu%'

-- aktualizacja kolumny company

UPDATE layoffs_staging
SET company = TRIM(company)

-- sprawdzenie kolumny industry (przemys³)

SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1 

SELECT *
FROM layoffs_staging
WHERE industry LIKE '%crypto%'

--aktualizacja 
UPDATE layoffs_staging 
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%'

-- sprawdzenie i aktualizacja kolumny location

SELECT DISTINCT location
FROM layoffs_staging
ORDER BY 1 

SELECT *
FROM layoffs_staging
WHERE location LIKE '%seldorf%'

UPDATE layoffs_staging 
SET location = 'Dusseldorf'
WHERE location LIKE '%seldorf%'

SELECT *
FROM layoffs_staging
WHERE location LIKE '%Malm%'

UPDATE layoffs_staging 
SET location = 'Malmo'
WHERE location LIKE '%malm%'

-- sprawdzenie kolumny country

SELECT DISTINCT country
from layoffs_staging
order by 1

-- TRIM() usuniêcie bia³ych znakow lub innych okreœlonych znaków z pocz¹tku i koñca ci¹gu
SELECT DISTINCT country, TRIM('.' from country)
from layoffs_staging
order by 1

--aktualizacja
UPDATE layoffs_staging 
SET country = 'United States'
WHERE country = 'United States.'

UPDATE layoffs_staging 
SET country = TRIM('.' from country)
WHERE country = 'United States.'

-- sprawdzenie kolumny date
select "date"
from layoffs_staging

/* Zmiana tekstu na format datatime
** MySQL str_to_date()
UPDATE layoffs_staging
SET "date" = str_to_date("date", '%m/%d/%Y')

** Microsoft SQL Server SELECT convert(datetime, @mystring np.'3/6/2023', @format np. 101)
*/

-- zmiana typu tekstowego na datê 
UPDATE layoffs_staging
SET "date" = CONVERT(date, "date", 101) 


--3. Obs³uga wartoœci NULL i pustych wierszy/rekordów

SELECT *
FROM layoffs_staging
WHERE industry = 'Null'
OR industry = ''

-- w jednej pozycji Airbnb industry nie ma nic, wype³niam tê lukê informacj¹ z innego rekordu
SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'

SELECT *
from layoffs_staging st1
JOIN layoffs_staging st2
	ON st1.company = st2.company
	AND st1.location = st2.location
WHERE st1.industry IS NULL OR st1.industry = ''
AND st2.industry IS NOT NULL

/*MySQL
UPDATE layoffs_staging st1
JOIN layoffs_staging st2
	ON st1.company = st2.company
SET st1.industry = st2. industry
WHERE (st1.industry IS NULL OR st1.industry = '')
AND st2.industry IS NOT NULL
*/
UPDATE layoffs_staging 
SET industry = NULL
WHERE industry= ''


UPDATE st1
SET st1.industry = st2.industry
FROM layoffs_staging st1
JOIN layoffs_staging st2
    ON st1.company = st2.company
WHERE (st1.industry IS NULL OR st1.industry = '')
  AND st2.industry IS NOT NULL;


SELECT *
from layoffs_staging
WHERE industry = 'NULL'

  /*UPDATE st1: Wskazuje, ¿e zaktualizowane zostan¹ rekordy z aliasu st1.
FROM layoffs_staging st1 JOIN layoffs_staging st2: Definiuje, jakie tabele i aliasy s¹ u¿ywane oraz jak s¹ ³¹czone (tu przez JOIN na company).
SET st1.industry = st2.industry: Okreœla, ¿e kolumna industry w rekordach st1 zostanie ustawiona na wartoœæ industry z pasuj¹cych rekordów st2.
WHERE: Warunki, które musz¹ byæ spe³nione, aby aktualizacja zosta³a przeprowadzona:
st1.industry IS NULL OR st1.industry = '': Aktualizacja jest wykonywana tylko wtedy, gdy industry w st1 jest NULL lub pusty.
st2.industry IS NOT NULL: Aktualizacja jest wykonywana tylko wtedy, gdy industry w st2 nie jest NULL.
Dodatkowe Uwagi
Upewnij siê, ¿e aliasy tabel s¹ dobrze zdefiniowane i nie ma konfliktów nazw.
Jeœli masz przypadki, gdzie industry mo¿e byæ pusty ('') lub mieæ wartoœæ NULL, warunek WHERE powinien uwzglêdniaæ obie mo¿liwoœci, aby nie przeoczyæ ¿adnych rekordów do aktualizacji.
Ta metoda jest bezpieczna w przypadku SQL Server i powinna dzia³aæ bez problemów.*/



SELECT *
FROM layoffs_staging
WHERE total_laid_off = 'Null'
AND percentage_laid_off = 'Null'

--usuniêcie wierszy, w których total_laid_off i percentage_laid_off s¹ NULL ( w takim przypadku nie maj¹ znaczenia w analizie)
DELETE
FROM layoffs_staging
WHERE total_laid_off = 'Null'
AND percentage_laid_off = 'Null'

SELECT *
FROM layoffs_staging


-- aktualizacja danych z kolumny na wartosci liczbowe
UPDATE layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off = '';

-- dodaje kolumne, ustawiajac wartosci na liczbowe
ALTER TABLE layoffs_staging
ADD total_laid_off_int INT;

--kopiuje dane z kolumny 1 do nowo utworzonej
UPDATE layoffs_staging
SET total_laid_off_int = TRY_CAST(total_laid_off AS INT);

--usuwam kolumne 1, do nowej ustalam nazwe z 1
ALTER TABLE layoffs_staging
DROP COLUMN total_laid_off;

EXEC sp_rename 'layoffs_staging.total_laid_off_int', 'total_laid_off', 'COLUMN';