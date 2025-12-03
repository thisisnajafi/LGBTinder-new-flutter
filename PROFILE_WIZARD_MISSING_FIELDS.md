# Profile Wizard - Missing Fields Analysis

## Backend Required Fields (from `completeRegistration` API)

### Currently Implemented ✅
1. **Profile Photo** - Step 1 ✅
2. **Country** - Step 2 ✅
3. **City** - Step 2 ✅
4. **Gender** - Step 2 ✅
5. **Birth Date** - Step 2 ✅
6. **Profile Bio** - Step 2 ✅
7. **Interests** - Step 3 ✅
8. **Additional Photos** - Step 4 ✅
9. **Name** - Step 2 (but not required by backend)

### Missing Required Fields ❌

#### 1. Phone Number (with Country Code) - **REQUIRED**
   - Field: `phone_number` (string, regex: `/^\+?[0-9]{10,15}$/`)
   - Country code: `country_code` (derived from country selection)
   - **Status**: ❌ Not implemented
   - **Backend Validation**: Required, unique, must match phone format

#### 2. Education - **REQUIRED**
   - Field: `educations` (array of IDs, min: 1)
   - Provider: `educationLevelsProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 3. Relation Goals - **REQUIRED**
   - Field: `relation_goals` (array of IDs, min: 1)
   - Provider: `relationshipGoalsProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 4. Preferred Genders - **REQUIRED**
   - Field: `preferred_genders` (array of IDs, min: 1)
   - Provider: `preferredGendersProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 5. Music Genres - **REQUIRED**
   - Field: `music_genres` (array of IDs, min: 1)
   - Provider: `musicGenresProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 6. Jobs - **REQUIRED**
   - Field: `jobs` (array of IDs, min: 1)
   - Provider: `jobsProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 7. Languages - **REQUIRED**
   - Field: `languages` (array of IDs, min: 1)
   - Provider: `languagesProvider` ✅ (exists)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required array, min 1 item

#### 8. Min Age Preference - **REQUIRED**
   - Field: `min_age_preference` (integer, 18-100)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required, min: 18, max: 100

#### 9. Max Age Preference - **REQUIRED**
   - Field: `max_age_preference` (integer, 18-100, must be >= min_age_preference)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required, min: 18, max: 100, gte: min_age_preference

#### 10. Weight - **REQUIRED**
   - Field: `weight` (integer, 30-200)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required, min: 30, max: 200

#### 11. Height - **REQUIRED**
   - Field: `height` (integer, 100-250)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required, min: 100, max: 250

#### 12. Smoke - **REQUIRED**
   - Field: `smoke` (boolean)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required boolean

#### 13. Drink - **REQUIRED**
   - Field: `drink` (boolean)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required boolean

#### 14. Gym - **REQUIRED**
   - Field: `gym` (boolean)
   - **Status**: ❌ Not implemented in UI
   - **Backend Validation**: Required boolean

---

## Current Profile Wizard Steps

### Step 1: Profile Photo ✅
- Primary profile photo upload
- **Status**: Complete

### Step 2: Basic Information
- Name (optional, not required by backend)
- Country ✅
- City ✅
- Gender ✅
- Birth Date ✅
- Bio ✅

### Step 3: Interests ✅
- Multi-select interests
- **Status**: Complete

### Step 4: Additional Photos ✅
- Up to 6 additional photos
- **Status**: Complete

### Step 5: Summary ✅
- Review all entered information
- **Status**: Complete

---

## Recommended Step Organization

### Step 1: Profile Photo ✅ (Keep as is)
- Primary profile photo

### Step 2: Basic Information & Contact
- **Name** (optional)
- **Phone Number** ❌ (with country code selector)
- **Country** ✅
- **City** ✅
- **Gender** ✅
- **Birth Date** ✅

### Step 3: About You
- **Profile Bio** ✅
- **Height** ❌ (in cm, 100-250)
- **Weight** ❌ (in kg, 30-200)
- **Education** ❌ (multi-select)
- **Jobs** ❌ (multi-select)
- **Languages** ❌ (multi-select)

### Step 4: Preferences & Lifestyle
- **Min Age Preference** ❌ (18-100)
- **Max Age Preference** ❌ (18-100, >= min)
- **Preferred Genders** ❌ (multi-select with images)
- **Relation Goals** ❌ (multi-select)
- **Smoke** ❌ (Yes/No/Sometimes - boolean)
- **Drink** ❌ (Yes/No/Sometimes - boolean)
- **Gym** ❌ (Yes/No/Sometimes - boolean)

### Step 5: Interests & Music
- **Interests** ✅ (keep existing)
- **Music Genres** ❌ (multi-select)

### Step 6: Additional Photos ✅ (Keep as is)
- Up to 6 additional photos

### Step 7: Summary ✅ (Update to include all new fields)
- Review all entered information

---

## Implementation Priority

### High Priority (Required by Backend)
1. **Phone Number** - Critical for user verification
2. **Education** - Required array
3. **Relation Goals** - Required array
4. **Preferred Genders** - Required array
5. **Music Genres** - Required array
6. **Jobs** - Required array
7. **Languages** - Required array
8. **Min/Max Age Preference** - Required integers
9. **Weight** - Required integer
10. **Height** - Required integer
11. **Smoke/Drink/Gym** - Required booleans

### Medium Priority
- Better organization of steps
- Validation messages
- Summary page updates

---

## Field Details for Implementation

### Phone Number
- Format: `+1234567890` (country code + number)
- Country code should be auto-selected based on country
- Validation: 10-15 digits after country code
- UI: Text field with country code prefix selector

### Age Preferences
- Min: 18-100 (slider or number picker)
- Max: 18-100, must be >= min
- UI: Range slider or two number pickers

### Physical Attributes
- Height: 100-250 cm (slider or number picker)
- Weight: 30-200 kg (slider or number picker)
- UI: Sliders or number pickers

### Lifestyle Choices
- Smoke: Boolean (Yes/No toggle or Yes/No/Sometimes)
- Drink: Boolean (Yes/No toggle or Yes/No/Sometimes)
- Gym: Boolean (Yes/No toggle or Yes/No/Sometimes)
- UI: Toggle switches or segmented buttons

### Multi-Select Fields (All use bottom sheets with search)
- Education: Multi-select from `educationLevelsProvider`
- Jobs: Multi-select from `jobsProvider`
- Languages: Multi-select from `languagesProvider`
- Preferred Genders: Multi-select from `preferredGendersProvider` (with images)
- Relation Goals: Multi-select from `relationshipGoalsProvider`
- Music Genres: Multi-select from `musicGenresProvider`

---

## Summary

**Total Missing Required Fields: 14**

All of these fields are **REQUIRED** by the backend API, so the profile wizard will fail without them. The good news is that all the necessary providers already exist in the Flutter app - they just need to be added to the UI.

