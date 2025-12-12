# 🚀 Quick Start: Plan Limits System

## ⚡ TL;DR

Your app now has dynamic plan limits! Free users get 10 swipes/day, premium users get unlimited.

---

## 🎯 What's New

### **For Free Users:**
- 10 swipes per day
- 1 superlike per day  
- 5 active conversations
- Beautiful upgrade prompts when limits reached

### **For Premium Users:**
- Unlimited swipes
- 5 superlikes per day
- Unlimited conversations
- All premium features unlocked

---

## 🔧 Quick Configuration

### **Change Free User Limits:**

Edit `lgbtinder-backend/.env`:

```env
FREE_DAILY_SWIPES=10
FREE_DAILY_LIKES=8
```

Then restart backend:
```bash
php artisan config:cache
```

### **Change Premium Limits:**

Edit database `plans` table:

```sql
UPDATE plans 
SET daily_profile = 9999,    -- Unlimited swipes
    superlike_limit = 5      -- 5 superlikes/day
WHERE title = 'Premium';
```

---

## 🧪 Quick Test

### **Test Free User Limits:**

1. Login as free user
2. Go to Discovery page
3. Swipe 10 times
4. 11th swipe → See upgrade dialog ✨

### **Test Premium User:**

1. Subscribe to premium
2. Go to Discovery page
3. Swipe unlimitedly ✅
4. No upgrade prompts

---

## 📱 API Endpoints

### **Get User's Limits:**
```
GET /api/plan-limits
Authorization: Bearer {token}
```

### **Check Specific Limit:**
```
POST /api/plan-limits/check
Authorization: Bearer {token}
Content-Type: application/json

{
  "feature": "swipes"
}
```

---

## 🎨 UI Updates

### **Discovery Page:**
- Shows remaining swipes indicator (when < 50% left)
- Upgrade button next to indicator
- Beautiful upgrade dialogs on limit reached

### **Upgrade Dialog Features:**
- Shows current usage (e.g., "10/10 swipes used")
- Lists premium benefits
- Direct link to subscription page
- "Maybe Later" option

---

## 🔍 Key Files

### **Backend:**
- `app/Http/Controllers/Api/PlanLimitsController.php` - Main controller
- `app/Http/Controllers/Api/MatchingController.php` - Updated for limits
- `routes/api.php` - Added `/plan-limits` routes
- `config/plans.php` - Free user defaults
- `.env` - Configuration

### **Flutter:**
- `lib/features/payments/data/models/plan_limits.dart` - Model
- `lib/features/payments/data/services/plan_limits_service.dart` - Service
- `lib/widgets/premium/upgrade_dialog.dart` - Upgrade UI
- `lib/pages/discovery_page.dart` - Updated with limits

---

## ✅ Everything Works!

- ✅ Backend API returns limits
- ✅ Flutter fetches and caches limits
- ✅ Discovery page respects limits
- ✅ Upgrade dialogs show on limit reached
- ✅ Optimistic UI updates
- ✅ Premium users get unlimited access

---

## 📞 Need Help?

### **Change limits:** Edit `.env` file
### **Add new limit:** Update `PlanLimitsController` + Flutter models
### **Debug:** Check API response at `/api/plan-limits`

---

**Ready to go!** 🎉

