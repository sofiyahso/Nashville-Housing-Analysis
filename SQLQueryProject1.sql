--Data Cleaning
SELECT * FROM NashvilleHousing1

DROP TABLE NashvilleHousing;

SELECT *
FROM NashvilleHousing

--1)Standardize data format and change column name
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

Update NashvilleHousing
SET SaleDateConverted = CAST(SaleDate AS date)	

sp_rename 'NashvilleHousing.PropertyAddress', 'FullPropertyAddress', 'COLUMN';

sp_rename 'NashvilleHousing.OwnerAddress', 'FullOwnerAddress', 'COLUMN';

SELECT PropertyCity, COUNT(*)
FROM NashvilleHousing
Group by PropertyCity
Order by COUNT(*) desc


--2)Fill in Property Address column
--Show 29 Property Adress is null
SELECT ParcelID, FullPropertyAddress, FullOwnerAddress
FROM NashvilleHousing
WHERE FullPropertyAddress is null

--Show link between ParcelID, Property Adress & Owner Address 
SELECT UniqueID, ParcelID, FullPropertyAddress, FullOwnerAddress, SaleDate
FROM NashvilleHousing
WHERE ParcelID IN (SELECT ParcelID FROM NashvilleHousing GROUP BY ParcelID HAVING COUNT(ParcelID) > 1 ) 

--Do a self join 
SELECT a. UniqueID, a.ParcelID, a.FullPropertyAddress, b.UniqueID, b.ParcelID, b.FullPropertyAddress, ISNULL(a.FullPropertyAddress,b.FullPropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.FullPropertyAddress is null

--Update identified null Property Address to the the Property Address column
Update a
SET FullPropertyAddress = ISNULL(a.FullPropertyAddress,b.FullPropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.FullPropertyAddress is null



--3)Fill in Owner Address column
UPDATE NashvilleHousing
SET FullOwnerAddress = ISNULL(FullOwnerAddress, FullPropertyAddress)



--4)Split Property Address into individual columns (Address, City)
SELECT FullPropertyAddress 
FROM NashvilleHousing

--PropertyAddressSplit & PropertyCitySplit
SELECT 
PARSENAME(REPLACE(FullPropertyAddress, ',', '.'),2),
PARSENAME(REPLACE(FullPropertyAddress, ',', '.'),1)
FROM NashvilleHousing

--Add column & update PropertyAddressSplit & PropertyCitySplit

ALTER TABLE NashvilleHousing
Add PropertyAddress nvarchar(100)

ALTER TABLE NashvilleHousing
Add PropertyCity nvarchar(100)

UPDATE NashvilleHousing
SET PropertyAddress = PARSENAME(REPLACE(FullPropertyAddress, ',', '.'),2)

UPDATE NashvilleHousing
SET PropertyCity = PARSENAME(REPLACE(FullPropertyAddress, ',', '.'),1)



--5)Split Owner Address into individual columns (Address, City, State)
SELECT FullOwnerAddress 
FROM NashvilleHousing

--OwnerAddressSplit, OwnerCitySplit & OwnerStateSplit
SELECT SUBSTRING(FullOwnerAddress, 1, CHARINDEX(',', FullOwnerAddress)-1)
FROM NashvilleHousing

SELECT CAST('<x>' + REPLACE(FullOwnerAddress,',','</x><x>') + '</x>' AS XML).value('/x[2]','nvarchar(max)')
FROM NashvilleHousing

SELECT
FullOwnerAddress
FROM NashvilleHousing
WHERE OwnerAddress
LIKE '%TN'

--Add column & update OwnerAddressSpli, OwnerCitySplit & OwnerCountrySplit


ALTER TABLE NashvilleHousing
Add OwnerAddress nvarchar(100)

ALTER TABLE NashvilleHousing
Add OwnerCity nvarchar(100)

ALTER TABLE NashvilleHousing
Add OwnerCountry nvarchar(100)

UPDATE NashvilleHousing
SET OwnerAddress = SUBSTRING(FullOwnerAddress, 1, CHARINDEX(',', FullOwnerAddress)-1)

UPDATE NashvilleHousing
SET OwnerCity = CAST('<x>' + REPLACE(FullOwnerAddress,',','</x><x>') + '</x>' AS XML).value('/x[2]','nvarchar(max)')

UPDATE NashvilleHousing
SET OwnerCountry = 'TN'
WHERE FullOwnerAddress IN (SELECT
FullOwnerAddress
FROM NashvilleHousing
WHERE FullOwnerAddress
LIKE '%TN')

--Update null value of OwnerCountry based on the record of OwnerCity 
SELECT DISTINCT OwnerCity , OwnerCountry
FROM NashvilleHousing
WHERE OwnerCountry is not null
ORDER BY OwnerCity

UPDATE NashvilleHousing
SET OwnerCountry = 'TN'
WHERE OwnercITY IN (SELECT DISTINCT OwnerCity
FROM NashvilleHousing
WHERE OwnerCountry is not null
)

SELECT *
FROM NashvilleHousing


--6)Change Y and N to Yes and No in Sold as Vacant column
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END
FROM NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END



--7))Remove Duplicates with the same ParcelID, FullPropertyAddress,SalePrice,SaleDate & LegalReference
--Show duplicates table 

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 FullPropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM NashvilleHousing
)
Select UniqueID, ParcelID, FullPropertyAddress, SalePrice, SaleDate, LegalReference, row_num 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY ParcelID

--Delete duplicates row

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM NashvilleHousing)
DELETE
FROM RowNumCTE
WHERE row_num > 1



--8)Delete Unused Columns
ALTER TABLE NashvilleHousing
DROP COLUMN FullOwnerAddress, TaxDistrict, FullPropertyAddress, SaleDate

SELECT * FROM NashvilleHousing



