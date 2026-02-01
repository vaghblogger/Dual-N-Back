Perfect. Below is a clean, end-to-end consolidated summary that merges:

Free vs Premium feature matrix

Paywall messaging

US + India pricing logic

How to test premium-gated features properly (without ads)

Think of this as your product + QA blueprint for Dual N-Back Pro.

A. Core Principle (Read This First)

You are not selling access.
You are selling depth, continuity, and measurable progress.

So everything revolves around:

Progressive difficulty

Trust

Clear entitlement states

Graceful limits (not hard blocks)

B. Free vs Premium – Master Feature Matrix
🧠 Gameplay & Limits
Feature	Free	Premium
Dual N-Back (Audio + Visual)	✅	✅
Max N-Level	N = 3	N = 10+ (adaptive)
Sessions per day	2	Unlimited
Session Length Control	❌	✅
Pause / Resume	❌	✅
Adaptive Difficulty	❌	✅
📊 Progress & Analytics (Main Conversion Lever)
Feature	Free	Premium
Accuracy % (per session)	✅	✅
Today’s Max N	✅	✅
Weekly / Monthly Graphs	❌	✅
Visual vs Audio Accuracy	❌	✅
Reaction Time Tracking	❌	✅
Long-term Trend (30–90 days)	❌	✅
Export Progress (CSV / Image)	❌	✅
🎯 Training Quality & Experience
Feature	Free	Premium
Pre-session breathing (1 min)	❌	✅
Focus breaks	❌	✅
Distraction-free mode	❌	✅
Dark mode / themes	❌	✅
Sound packs	❌	✅
🔬 Advanced Training
Feature	Free	Premium
Audio-only / Visual-only mode	❌	✅
Speed control	❌	✅
Custom grid size	❌	✅
Challenge mode	❌	✅
Performance heatmap	❌	✅
🔐 Data & Continuity
Feature	Free	Premium
Local progress save	✅	✅
Cloud backup	❌	✅
Cross-device sync	❌	✅
Restore purchases	❌	✅
C. Level Unlock Rules (Critical)
N-Level	Access
N = 1–3	Free
N = 4+	Premium

Paywall triggers ONLY when:

User tries N = 4

OR daily session limit is reached

Never mid-session. Never on first launch.

D. Subscription Messaging (Use These Exactly)
1️⃣ Soft Gate (Best overall)

You’re progressing well.
Level 4 increases working-memory load significantly.

Unlock advanced training to continue improving.

Buttons:

Unlock Pro

Continue Tomorrow

2️⃣ Progress-Based (High conversion)

Your accuracy is improving 📈
Pro users train with higher N-levels and unlimited sessions.

3️⃣ Science-respecting (No hype)

Dual N-Back works best with consistent, progressive difficulty.

Pro removes limits and enables deeper training.

E. Pricing (US + India Optimized)
🇮🇳 India

Monthly: ₹199

Yearly: ₹1199 (highlighted)

🇺🇸 USA

Monthly: $4.99

Yearly: $29.99 (highlighted)

Rules:

Show Yearly as “Best Value”

No forced trial (optional later)

Cancel anytime clearly visible

F. Subscription State Model (For Logic + Testing)

You only support 3 states:

State	Meaning
FREE	Never subscribed
PREMIUM_ACTIVE	Valid subscription
PREMIUM_EXPIRED	Subscription ended

Every feature checks this state.
Never hard-code feature locks.

G. How to Test Premium Gating (Very Important)
1️⃣ Local Dev Testing (Fastest)

Add a hidden Developer Mode:

Tap App Version 7 times

Toggle state:

FREE

PREMIUM_ACTIVE

PREMIUM_EXPIRED

Test:

Locked features

Paywall copy

Downgrade behavior

(Disable in production builds.)

2️⃣ Store Sandbox Testing (Real Payments, No Money)
Android

Add yourself as license tester

Use test card

Subscription renews in minutes

Test:

Purchase

Restore

Expiry

App restart

iOS (later)

Sandbox Apple ID

Accelerated renewals

3️⃣ Entitlement Testing Checklist
FREE

N ≤ 3 only

Session limit enforced

Paywall shows politely

No crashes

PREMIUM

Unlimited sessions

All analytics visible

State survives app restart

EXPIRED

Downgrade gracefully

No data loss

Clear explanation

Restore works

H. UI Rules (Do Not Break These)

✅ Show locked features with 🔒
✅ Explain why they’re locked
❌ Never hide features completely
❌ Never say “Pay to continue”
❌ Never interrupt gameplay

I. Analytics You Should Track

Log these events:

paywall_shown

paywall_dismissed

feature_blocked

subscription_started

subscription_expired

This tells you which feature actually sells Pro.

J. Final Reality Check (Important)

If a user asks:

“Why is this locked?”

…and you can’t answer in one calm sentence → redesign the gate.