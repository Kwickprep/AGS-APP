# Company API Integration - Required Updates

## API Endpoint for Create/Edit Form
**Endpoint:** `GET /api/companies/none?isPageLayout=true` (for create)
**Endpoint:** `GET /api/companies/{id}?isPageLayout=true` (for edit)

## Current Implementation vs API Requirements

### ✅ Already Implemented
1. Basic company fields (name, email, website, gstNumber)
2. Status (isActive) field
3. Country, State, City selection
4. Create and Update API calls

### ❌ Needs to be Added/Updated

#### 1. Industry Dropdown Options (75+ options from API)
The API provides 75+ industry options including:
- PHARMACEUTICALS – PHARMA
- BIOTECH – PHARMA
- IT & ITES – NON PHARMA
- BANKING – NON PHARMA
- etc.

**Current:** Hardcoded 9 options
**Required:** Fetch from API

#### 2. Employees Dropdown Options (8 options from API)
```
- 1-10 EMPLOYEES (MICRO)
- 11-50 EMPLOYEES (SMALL)
- 51-200 EMPLOYEES (SMALL-MEDIUM)
- 201-500 EMPLOYEES (MEDIUM)
- 501-1,000 EMPLOYEES (MEDIUM-LARGE)
- 1,001-5,000 EMPLOYEES (LARGE)
- 5,001-10,000 EMPLOYEES (ENTERPRISE)
- 10,000+ EMPLOYEES (LARGE ENTERPRISE)
```

**Current:** Hardcoded 7 options (slightly different ranges)
**Required:** Fetch from API

#### 3. Turnover Dropdown Options (13 options from API)
```
- < ₹50 LAKHS (MICRO)
- ₹50 LAKHS - 1 CR (MICRO)
- ₹1 - 5 CR (MICRO)
- ₹5 - 10 CR (SMALL)
- ₹10 - 25 CR (SMALL)
- ₹25 - 50 CR (SMALL)
- ₹50 - 100 CR (MEDIUM)
- ₹100 - 250 CR (MEDIUM)
- ₹250 - 500 CR (MID-SIZE)
- ₹500 - 1,000 CR (LARGE)
- ₹1,000 - 5,000 CR (ENTERPRISE)
- ₹5,000 - 10,000 CR (ENTERPRISE)
- > ₹10,000 CR (CONGLOMERATE)
```

**Current:** Hardcoded 6 options (simpler ranges)
**Required:** Fetch from API

#### 4. Address Fields - Missing Fields
**Current:** Country, State, City
**Required:** Also add:
- `addressLine1` (text input)
- `addressLine2` (text input)

#### 5. Note Field - Missing
**Required:** Add textarea field for additional notes
- Field: `note`
- Type: textarea
- Rows: 3
- Label: "Note"
- Placeholder: "Enter additional notes"

#### 6. User Selection Table - Missing
**Required:** Add user selection functionality
- Field: `userIds`
- Type: table with selection
- Shows list of all available users
- Multi-select capability
- Columns: firstName, middleName, lastName, email, phone, role, company, department, etc.
- User can select multiple users to associate with the company

## Implementation Options

### Option 1: Simple Update (Recommended for MVP)
Keep the current form structure but:
1. Update hardcoded dropdown options to match API options exactly
2. Add addressLine1 and addressLine2 fields
3. Add note field
4. Skip user selection table for now (can be added later)

**Pros:**
- Quick to implement
- Maintains current UI/UX
- All critical fields covered

**Cons:**
- Dropdowns not dynamic (need code changes if API options change)
- No user association feature

### Option 2: Full Dynamic Form
Fetch form configuration from API and build form dynamically:
1. Fetch `/api/companies/none?isPageLayout=true`
2. Parse `context.pageLayout.body.form.fields`
3. Generate form fields dynamically based on configuration
4. Add user selection table

**Pros:**
- Fully dynamic - no code changes if form fields change
- Supports all API features
- User association feature included

**Cons:**
- More complex implementation
- Requires generic form builder
- Takes more development time

### Option 3: Hybrid Approach (Balanced)
Keep manual form layout but fetch dropdown options from API:
1. Fetch form config API
2. Extract dropdown options dynamically
3. Keep existing form UI structure
4. Add missing fields (addressLine1, addressLine2, note)
5. Add basic user multi-select (simplified, not full table)

**Pros:**
- Dropdown options stay in sync with API
- Reasonable development time
- Maintains good UX
- All required fields included

**Cons:**
- Form structure still static
- User selection simpler than API spec

## Recommended Approach

**Start with Option 1** for quick delivery:
1. Update the three dropdown lists to match API exactly
2. Add addressLine1, addressLine2, and note fields
3. Ship this version first

**Then implement Option 3** in next iteration:
1. Make dropdowns dynamic by fetching from API
2. Add user selection feature
3. Enhance UX based on feedback

## Data Structure for API Submission

```dart
{
  "name": "Company Name",
  "email": "company@email.com",
  "website": "https://website.com",
  "industry": "IT & ITES – NON PHARMA",
  "employees": "51-200 EMPLOYEES (SMALL-MEDIUM)",
  "turnover": "₹50 - 100 CR (MEDIUM)",
  "gstNumber": "GST123456",
  "isActive": true,
  "address": {
    "countryIsoCode": "IN",
    "countryName": "India",
    "stateIsoCode": "GJ",
    "stateName": "Gujarat",
    "cityName": "Ahmedabad",
    "addressLine1": "Address line 1",
    "addressLine2": "Address line 2"
  },
  "note": "Additional notes",
  "userIds": ["userId1", "userId2", "userId3"]
}
```

## Files to Update

1. `lib/services/company_service.dart` - ✅ Already added `getCompanyFormConfig()` method
2. `lib/screens/companies/company_create_screen.dart` - Need to update with new fields
3. `lib/models/company_model.dart` - May need to add address and note fields

## Next Steps

Which option would you like me to implement?
