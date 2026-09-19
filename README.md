# ♟️ ChessGo

A feature-rich, high-performance cross-platform Chess application built with Flutter, Riverpod, and Supabase. ChessGo delivers seamless offline gameplay against robust local AI bots alongside real-time online multiplayer capabilities, custom user profile customization, and global matchmaking leaderboards.

---

## 🚀 Key Features

*   **🎮 Cross-Platform Play:** Fully responsive design optimizing gameplay layout ecosystems across Android, iOS, and Web (compiled and deployed on Vercel).
*   **📡 Real-Time Multiplayer:** Instant custom private lobby room generation via secure code synchronization and active live move broadcasting streams built on Supabase Realtime Channels.
*   **🤖 Smart Offline Engine Bot:** Challenge an offline pure-Dart chess analyzer across tiered customizable difficulties (`Easy`, `Medium`, `Hard`) with dual player color orchestration.
*   **🏆 Global Leaderboard Ranking:** Live global leaderboards tracking top Grandmasters sorted dynamically by active Elo rating metrics.
*   **👤 Custom Profile Management:** Integrated user dashboard displaying individual match history parameters (Wins, Losses, Draws), dynamic monogram badges, and real-time custom display name modification keys.
*   **🌓 Unified Adaptive Themes:** Premium multi-theme design matrix fully supporting automated Dark Mode and Light Mode rendering mechanics, centralized via Riverpod hooks.
*   **🎨 Custom Branded Visual Assets:** Beautiful, minimalist custom vector chess piece arrays coupled with animated high-performance splash initialization logos and adaptive launcher icons.

---

## 🛠️ Technology Stack & Architectures

*   **Framework:** [Flutter SDK](https://flutter.dev) (Stable Channel)
*   **State Management:** [Flutter Riverpod](https://riverpod.dev) (Highly decoupled, reactive state architecture providers)
*   **Backend Ecosystem:** [Supabase Flutter](https://supabase.com) (GoTrue Auth sessions, Realtime Broadcast channels, PostgreSQL tables infrastructure)
*   **Navigation Routing:** [GoRouter](https://pub.dev/packages/go_router) (Declarative type-safe routing matrices ideal for smooth Web and mobile view handling)
*   **Audio FX Pipeline:** [Audioplayers](https://pub.dev/packages/audioplayers) ( Tactile move, capture, check, and game-over sound triggers)

---

## 📦 Local Installation & Setup

Follow these steps to run ChessGo on your local workstation engine:

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/arafat-netul10/chess_go.git
    cd chess_go
    ```

2.  **Restore Dependency Bundles:**
    ```bash
    flutter pub get
    ```

3.  **Configure Environment Parameters:**
    ChessGo leverages secure `String.fromEnvironment` wrappers. You can run the application by passing your public Supabase endpoint credentials directly as compilation define arguments:
    ```bash
    flutter run --dart-define=SUPABASE_URL="https://your-project.supabase.co" --dart-define=SUPABASE_ANON_KEY="your-anon-key-string"
    ```

---

## 🌐 Production Web Deployment (Vercel)

ChessGo is optimized for single-page static web application hosting on Vercel utilizing optimized pre-compiled production distributions.

### Static Local Assets Workflow (Recommended)

1.  **Generate Production Release Targets:**
    Compile your production web binaries locally while baking in your Supabase backend client configuration definitions:
    ```bash
    flutter build web --release --dart-define=SUPABASE_URL="https://your-project.supabase.co" --dart-define=SUPABASE_ANON_KEY="your-anon-key-string"
    ```

2.  **Commit Distribution Bundles:**
    Force add the generated compilation output folder tracking to push your static assets directly up to your remote repository:
    ```bash
    git add -f build/web
    git commit -m "Deploy compiled high-performance production distribution assets"
    git push origin master
    ```

3.  **Vercel Build Configurations:**
    *   **Framework Preset:** `Other`
    *   **Build Command:** *Toggle to OFF (Leave completely empty)*
    *   **Output Directory:** `build/web`

---

## 🔒 Security Configuration Checklist (Supabase RLS)

Ensure your database tables (`profiles`, `rooms`, `matches`) have Row Level Security enabled with these standard production permission rulesets:

*   **`profiles` Table [SELECT]:** Enable public permissive access expression (`true`) so all users can pull and populate the global leaderboard ranking list.
*   **`profiles` Table [UPDATE]:** Enforce strict authenticated user validation policies checking `(auth.uid() = id)` to secure score alteration privileges.
*   **`rooms` & `matches` Tables:** Assign authenticated operation mandates (`auth.uid() IS NOT NULL`) to completely eliminate unauthenticated request anomalies.

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.
