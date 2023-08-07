/*
1. Using SQL Queries to Clean Data
*/

Select *
From [SQL Project].dbo.NashvilleHousing;

/* 
Our data extracted contains 19 columns spanning from columns UniqueID to HalfBath.
*/
---------------------------------------------------------------------------------------------------------------------------------

/* 2.  Standardise the format of Date of Sales in Colmun 5
This date format includes a timestamp which does not add value to the data. 
Therefore, we will remove it to make the format presentable
*/
Select SaleDate
From dbo.NashvilleHousing;

Select SaleDate, CONVERT(Date, SaleDate) 
From [SQL Project].dbo.NashvilleHousing;

-- Now we will convert the date
Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

-- An alternative for the above could be:
-- The code above takes us back to the date format we want to change. Let's try this: 
ALTER TABLE NashvileHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted  = CONVERT(Date, SaleDate);

-- For now, let's keep both dates columns 
Select SaleDateConverted, CONVERT(Date, SaleDate) 
From [SQL Project].dbo.NashvilleHousing;
------------------------------------------------------------------------------------------------------------------------------

/*
3. Populate Property Address Data
*/

-- First, let's extract the addresses to all properties in our data
Select PropertyAddress
From [SQL Project].dbo.NashvilleHousing;

-- Now let's investigate if there are null values in in our extracted data
Select PropertyAddress
From [SQL Project].dbo.NashvilleHousing
Where PropertyAddress is null;

-- 29 of the houses had ns addresses. However, we do not know where which houses come without addresses so let's confirm:
Select *
From [SQL Project].dbo.NashvilleHousing
Where PropertyAddress is null;

-- From profiling the data, we can infer that each property have a unique ID and a Parcel ID. However, a property can have duplicate Parcel ID. Let's confirm this hypotheses  first:
Select *
From [SQL Project].dbo.NashvilleHousing
--Where PropertyAddress is null
Order by ParcelID;

--For all duplicate Parcel ID's for each property, if one of the duplicates have PropertyAddress, the its duplicate should have the same address. We can use a self-join to populate this:
Select *
From [SQL Project].dbo.NashvilleHousing AS a
Join [SQL Project].dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ];

-- Now let's fetch instances for only ParcelID which have no PropertyAddress:
Select a.ParcelID, a. PropertyAddress, b.ParcelID, b.PropertyAddress
	From [SQL Project].dbo.NashvilleHousing AS a
	Join [SQL Project].dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is Null;

-- 35 of the duplicate ParcelID misses the PropertyAddress for one of the duplicates. Now we can populate these with the ISNULL Function missing address with their duplicates

Select a.ParcelID, a. PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	From [SQL Project].dbo.NashvilleHousing AS a
	Join [SQL Project].dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is Null;

-- Now let's update our population
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [SQL Project].dbo.NashvilleHousing AS a
	Join [SQL Project].dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		And a.[UniqueID ] <> b.[UniqueID ];

-- Let's test this to ascertain if there is any missing PropertyAddress:

Select a.ParcelID, a. PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	From [SQL Project].dbo.NashvilleHousing AS a
	Join [SQL Project].dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is Null;

-- Confirmed, no missing addresses.
-------------------------------------------------------------------------------------------------------------------------------

/*
4. Separate PropertyAddress column into Address, City, State with Substring
*/

Select PropertyAddress
From [SQL Project].dbo.NashvilleHousing;

-- From each PropertyAddress, we could see that a delimeter (comma), separates the address from its City and State. We can use a substring or character index to achieve this:
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address
From [SQL Project].dbo.NashvilleHousing;

-- Here, we get every address but also comes with a comma. We will correct this but let's also verify the index position of the comma in each address:
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address,
CHARINDEX(',', PropertyAddress) AS Comma_Position
From [SQL Project].dbo.NashvilleHousing;

-- Simply, we can do away with the comma by negating the property index:
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
From [SQL Project].dbo.NashvilleHousing;

-- Now let's we can grap the other part (city) bit of the PropertyAddress. For now, we will alias them as Address:
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
From [SQL Project].dbo.NashvilleHousing;

-- Now let's make each columns uniques in our table by creating two unique columns:
ALTER TABLE NashvilleHousing
ADD SplitAddress Nvarchar(255);

/*ALTER TABLE NashvilleHousing
DROP COLUMN SlitAddress;

Select *
From NashvilleHousing
*/

Update NashvilleHousing
SET SplitAddress  = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE NashvilleHousing
ADD SplitCity Nvarchar(255);

Update NashvilleHousing
SET SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- View our Updated Table:
Select *
From NashvilleHousing;
-------------------------------------------------------------------------------------------------------------------------------

/*
5. Cleaning OwnerAddress column with ParseName
*/

-- The addresses and locations of the properties are now clean and presentable. 
-- Now there is another address details we have to clean and this is the property owners' address.
Select OwnerAddress
From NashvilleHousing;

-- Unlike the PropertyAddress, we can utilise the parse name fucnction to clean the address. 
Select 
PARSENAME(OwnerAddress, 1) AS OwnerAddress
From NashvilleHousing;

-- Well, nothing changed because ParseName leverages on fullatops (periods) as delimeters but we have commas here.
-- We can grap each target instances by replacing the commas with periods:
Select 
PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerAddress
From NashvilleHousing;

-- We have grapped our State successfully, now let's grap all instances (OwnerPostCode, OwnerCity and OwnerState).
Select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerPostCode,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerState
From NashvilleHousing;

-- We can now add these Columns as unique in our table.
ALTER TABLE NashvilleHousing
ADD OwnerPostCode Nvarchar(255);

/*ALTER TABLE NashvilleHousing
DROP COLUMN SlitAddress;

Select *
From NashvilleHousing
*/

Update NashvilleHousing
SET OwnerPostCode  = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE NashvilleHousing
ADD OwnerCity Nvarchar(255);

Update NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE NashvilleHousing
ADD OwnerState Nvarchar(255);

Update NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);


-- View our Updated Table:
Select *
From NashvilleHousing;
-------------------------------------------------------------------------------------------------------------------------------

/*
6. Change 'Y' and 'N' to 'Yes' and 'No' in the "SoldAsVacant" column.
*/
-- First view the column
Select DISTINCT SoldAsVacant
From NashvilleHousing;

-- Let's count the number of instances
Select DISTINCT SoldAsVacant,
	COUNT(SoldAsVacant) 
From NashvilleHousing
Group by SoldAsVacant
Order by 2;

-- We will employ Case statement to achieve our goal here.
Select SoldAsVacant,
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 END
From NashvilleHousing;

-- We will udate our table and set out new instances up.
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 END;

		 -- Let's test it now:
Select DISTINCT SoldAsVacant,
	COUNT(SoldAsVacant) 
From NashvilleHousing
Group by SoldAsVacant
Order by 2;
---------------------------------------------------------------------------------------------

/*
7. Remove Duplicates
*/

-- Just for this project, duplicates are removed but not the case with actual database----
------because this might cause the lost of relevant data:
WITH RowNumCTE AS (
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY 
							UniqueID
							) row_num

From NashvilleHousing
--Order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;

-- There are 104 duplicates that we will remove
WITH RowNumCTE AS (
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY 
							UniqueID
							) row_num

From NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1;

-- Let's test this:
WITH RowNumCTE AS (
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY 
							UniqueID
							) row_num

From NashvilleHousing
--Order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

-- Fantastic, nomore duplicates in the data

-----------------------------------------------------------------------------------------------------------

/*
8. Delete Unused Columns
*/
Select *
From NashvilleHousing;

-- Remove columns:
ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict;

Select *
From NashvilleHousing

