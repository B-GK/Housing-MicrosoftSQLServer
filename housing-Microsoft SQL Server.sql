SELECT *
FROM housing

--Convert timestamp format to date data type by removing timezone
SELECT saledate
FROM housing 

SELECT CONVERT(date, saledate) 
FROM housing

UPDATE housing
SET saledate = CONVERT(date, saledate)

--change the data type permanently
ALTER TABLE housing
ALTER COLUMN saledate DATE;

--Populate property address data
SELECT *, PropertyAddress
FROM housing
WHERE propertyaddress IS NULL
order by parcelid

--Fill the Null propertyaddress using join
WITH addresscte as (
    SELECT 
        h1.parcelid AS h1parcelid,
        h1.propertyaddress AS h1propertyaddress, 
        h2.parcelid AS h2parcelid, 
        h2.propertyaddress AS h2propertyaddress, 
        ISNULL(h1.propertyaddress, h2.propertyaddress) AS newpropertyaddress
    FROM housing AS h1
    JOIN housing AS h2 
        ON h1.parcelid = h2.parcelid
        AND h1.uniqueid <> h2.uniqueid
    WHERE h1.propertyaddress IS NULL 
        AND h2.propertyaddress IS NOT NULL) -- To ensure the joined row has a valid address
SELECT * FROM addresscte;

--Now update table permanently
UPDATE h1
SET propertyaddress =  ISNULL(h1.propertyaddress, h2.propertyaddress) 
    FROM housing AS h1
    JOIN housing AS h2 
        ON h1.parcelid = h2.parcelid
        AND h1.uniqueid <> h2.uniqueid
    WHERE h1.propertyaddress IS NULL 
    
--Breaking out propertyaddress 
SELECT SUBSTRING(propertyaddress,1, CHARINDEX(',', propertyaddress)-1) as address,
       SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress)+1 ,LEN(propertyaddress)) as address
FROM housing

--Make changes permanent
Alter TABLE housing
Add propertysplitaddress Nvarchar(255);
UPDATE housing
SET propertysplitaddress = SUBSTRING(propertyaddress,1, CHARINDEX(',', propertyaddress)-1) 


Alter TABLE housing
ADD propertysplitcity NVARCHAR(255);
UPDATE housing
SET propertysplitcity =  SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress)+1 ,LEN(propertyaddress))

--Split owneraddress into 3 fields
SELECT PARSENAME(REPLACE(owneraddress, ',', '.'), 3) as ownersplitaddress,
PARSENAME(REPLACE(owneraddress, ',', '.'), 2)as ownersplitcity,
PARSENAME(REPLACE(owneraddress, ',', '.'), 1)as ownersplitstate
FROM housing
--Make changes permanent
ALTER TABLE housing
ADD ownersplitaddress NVARCHAR(225);
UPDATE housing
SET ownersplitaddress = PARSENAME(REPLACE(owneraddress, ',', '.'), 3)

ALTER TABLE housing
ADD ownersplitcity NVARCHAR(225);
UPDATE housing
SET ownersplitcity = PARSENAME(REPLACE(owneraddress, ',', '.'), 2)

ALTER TABLE housing
ADD ownersplitstate NVARCHAR(225);
UPDATE housing
SET ownersplitstate = PARSENAME(REPLACE(owneraddress, ',', '.'), 1)

--Change Y and N to Yes and No in Soldasvacant column
SELECT DISTINCT soldasvacant, COUNT(soldasvacant)
FROM housing
GROUP BY soldasvacant

SELECT soldasvacant,
	    CASE WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant END
FROM housing

UPDATE housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant END
		
	    
--Remove duplicates using CTE
WITH rownumcte as
	(SELECT *, ROW_NUMBER() OVER(PARTITION BY parcelid, 
											propertyaddress, 
											saleprice,
											saledate,
											legalreference 
											ORDER BY uniqueid) row_num
											FROM housing)
DELETE
FROM rownumcte
WHERE row_num  > 1

--Delete unused columns
 ALTER TABLE housing
 DROP COLUMN owneraddress, taxdistrict, propertyaddress
