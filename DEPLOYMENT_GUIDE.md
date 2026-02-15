# Streamlit Dashboard Deployment Guide

## Local Testing (First!)

### 1. Setup Local Environment

```bash
# Navigate to your project directory
cd /path/to/your/project

# Create virtual environment (if not already created)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Database Connection

Create `.streamlit/secrets.toml` (NOT the template):

```bash
mkdir -p .streamlit
cp .streamlit/secrets.toml.template .streamlit/secrets.toml
```

Edit `.streamlit/secrets.toml` and add your actual connection string:

```toml
[database]
connection_string = "postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.bwudeogkvmliqvsqidps.supabase.co:5432/postgres"
```

### 3. Run Locally

```bash
streamlit run dashboard_app.py
```

Your dashboard will open at `http://localhost:8501`

**Test everything works before deploying!**

---

## Deploy to Streamlit Cloud (Free!)

### Step 1: Push to GitHub

```bash
# Initialize git if not already done
git init

# Create .gitignore
echo ".streamlit/secrets.toml" >> .gitignore
echo "venv/" >> .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore

# Add files
git add .
git commit -m "Add marketing analytics dashboard"

# Create GitHub repo and push
# (Create repo on github.com first, then:)
git remote add origin https://github.com/YOUR_USERNAME/marketing-analytics-dashboard.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy on Streamlit Cloud

1. Go to https://share.streamlit.io/
2. Sign in with GitHub
3. Click **New app**
4. Select your repository: `YOUR_USERNAME/marketing-analytics-dashboard`
5. Set:
   - **Branch**: `main`
   - **Main file path**: `dashboard_app.py`
6. Click **Deploy**

### Step 3: Add Secrets to Streamlit Cloud

**IMPORTANT:** Don't deploy without this!

1. In Streamlit Cloud dashboard, click your app
2. Click **⚙️ Settings** (bottom right)
3. Click **Secrets** tab
4. Paste your database credentials:

```toml
[database]
connection_string = "postgresql://postgres:YOUR_PASSWORD@db.bwudeogkvmliqvsqidps.supabase.co:5432/postgres"
```

5. Click **Save**
6. App will automatically redeploy with secrets

### Step 4: Get Your Public URL

Your dashboard will be live at:
```
https://YOUR_USERNAME-marketing-analytics-dashboard-dashb-xxxxx.streamlit.app
```

Copy this URL - this is what you submit!

---

## Troubleshooting

### "Connection refused" or "Database error"
- Check your secrets.toml is configured correctly
- Verify Supabase password is correct
- Make sure `unified_ads` table exists in Supabase

### "ModuleNotFoundError"
- Ensure `requirements.txt` is in your repo root
- Check all dependencies are listed

### Charts not loading
- Check data is actually in your `unified_ads` table
- Run this SQL in Supabase to verify:
  ```sql
  SELECT COUNT(*) FROM unified_ads;
  ```

### App won't deploy on Streamlit Cloud
- Make sure `.streamlit/secrets.toml` is in `.gitignore`
- Verify `dashboard_app.py` is in repo root
- Check GitHub Actions tab for build errors

---

## File Structure

Your final project should look like:

```
marketing-analytics-dashboard/
├── dashboard_app.py          # Main Streamlit app
├── requirements.txt          # Python dependencies
├── .streamlit/
│   ├── config.toml          # Streamlit theme config
│   └── secrets.toml         # Database credentials (NOT in git)
├── .gitignore               # Ignore secrets and venv
└── README.md                # Optional: project description
```

---

## Testing Checklist

Before submitting, verify:

- [ ] Dashboard loads without errors
- [ ] All metrics display correctly
- [ ] Charts render properly
- [ ] Filters work (date range, platforms)
- [ ] Table shows top campaigns
- [ ] Public URL is accessible (test in incognito)
- [ ] No authentication required to view

---

## What to Submit

1. **Dashboard URL**: Your Streamlit Cloud link
   - Example: `https://pandagreg-marketing-analytics-dashboard.streamlit.app`

2. **SQL Script**: Your unified table creation SQL
   - Already created in previous steps

Submit both at: https://docs.google.com/forms/d/e/1FAIpQLSe-3UpHq1l6TiDMONDecHRa53otacxTReYF7gNIoCmmkW4Xyw/viewform

---

## Pro Tips

1. **Add a README to your GitHub repo** explaining the dashboard
2. **Use descriptive commit messages** (shows professionalism)
3. **Test the public URL in incognito mode** before submitting
4. **Take a screenshot** of your dashboard for backup

Good luck! 🚀
