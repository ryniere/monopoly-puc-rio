# Monopoly Mobile Game — Design Spec

> ⚠️ **SUPERSEDED (2026-07-13):** este documento foi substituído por [`2026-07-13-plano-jogo-mobile-engajante.md`](2026-07-13-plano-jogo-mobile-engajante.md), que corrige as lacunas de engajamento, arquitetura e negócio identificadas em análise multi-agente. Mantido apenas como registro histórico.

## Overview

A modern mobile Monopoly-style board game built with Flutter, targeting iOS and Android. Brazilian cities theme with an original brand name. Online multiplayer via Supabase Realtime and single-player vs rule-based AI.

This is a modernization of a 2012 Java Swing desktop game (PUC-Rio university project), redesigned for mobile with real-time multiplayer.

## Goals & Constraints

- **Ship to App Store + Google Play**
- Online multiplayer (2-6 players, real-time)
- Single player vs AI (simple rule-based)
- Brazilian cities theme, original brand (not "Monopoly" trademark)
- Portuguese language only (v1)
- No monetization for v1
- Full feature parity with the original: all properties, luck/setback cards, houses/hotels, prison, player elimination, trading

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.24+ (latest stable) |
| Language | Dart |
| Backend | Supabase (Postgres + Realtime + Auth) |
| State Management | Riverpod (flutter_riverpod + riverpod_annotation) |
| Models | Freezed + json_serializable (immutable, code-gen) |
| Routing | go_router |
| Animation | Rive or Lottie (dice, cards) |
| Audio | audioplayers |
| Testing | flutter_test + mocktail |

### Minimum Targets

- iOS 15+
- Android API 24+ (Android 7)

### Explicitly Excluded (YAGNI)

- Analytics, crash reporting
- Push notifications
- Localization beyond Portuguese
- Monetization packages
- Complex DI frameworks
- Mortgage/hypothec mechanic (the original had the field but never implemented the logic)
- Auction when a player declines to buy (not in original)
- Money in trades (original only supports property-for-property swaps)

## App Structure & Navigation

```
SplashScreen -> HomeScreen -> LobbyScreen -> GameScreen
                    |
                    +-> SettingsScreen
```

| Screen | Purpose |
|--------|---------|
| HomeScreen | Main menu: Play Online, Play vs AI, Settings |
| LobbyScreen | Create/join game room, see players, choose pawn color, ready up |
| GameScreen | Board, player panels, action dialogs, game log |
| SettingsScreen | Sound, notifications, account |

### Authentication

Supabase Auth with anonymous sign-in by default (zero friction). Optional upgrade to email/social login for saved stats and friend lists in future versions.

## Data Model

Game state is a single JSON document stored as a JSONB column in Supabase, one row per game room.

### GameState

```
GameState
├── id: String (game room ID)
├── status: enum (waiting, playing, finished)
├── currentPlayerIndex: int
├── players: List<Player>
│   ├── id: String (Supabase user ID)
│   ├── name: String
│   ├── color: Color
│   ├── money: int
│   ├── position: int (board square index)
│   ├── properties: List<int> (square indices owned)
│   ├── arrestedTurns: int (0 = free)
│   ├── getOutOfJailCards: int
│   ├── isAI: bool (false for human players)
│   └── eliminated: bool
├── board: List<BoardSquare> (40 squares — only dynamic state)
│   ├── ownerPlayerIndex: int?
│   └── houses: int (0-5, where 5 = hotel)
├── luckCards: List<int> (shuffled indices into card definitions)
├── luckCardPointer: int (current position in deck)
├── diceRoll: DiceRoll? (last roll for animation)
├── lastAction: String (game log entry)
└── turnPhase: enum (preRoll, rolled, buying, debt, turnEnd)
```

### Turn Phase State Machine

```
preRoll -> rolled -> buying -> turnEnd
  |               |         |
  |               +-> debt -+
  |               |
  |               +-> turnEnd (for non-purchasable squares)
  |
  +-> prisonChoice -> rolled (if doubles) -> ...
                   |
                   +-> turnEnd (stayed in prison)
```

- `preRoll`: Player can build/sell/trade before rolling dice. If in prison, transitions to `prisonChoice` instead.
- `prisonChoice`: Player chooses: pay $50 to leave, use get-out-of-jail card, or roll for doubles. If doubles are rolled, transitions to `rolled`. Otherwise, decrement `arrestedTurns` and go to `turnEnd`. After 4 turns, forced to pay and leave.
- `rolled`: Pawn moved, processing square effect
- `buying`: Buy prompt shown for unowned property
- `debt`: Player must sell assets to cover negative balance

### Luck/Setback Card Lifecycle

The deck is a single shuffled list of card indices. A pointer advances on each draw. When the pointer reaches the end, the deck reshuffles.

**Get-out-of-jail cards** are special: when drawn, the card is removed from the deck and the player's `getOutOfJailCards` counter increments. When used (to avoid prison), the card returns to the bottom of the deck and the counter decrements. This matches the original game behavior.

### Declining to Buy

When a player lands on an unowned property and declines to buy, the property remains unowned and the turn ends. No auction occurs (explicitly excluded).

### Trade Rules

Trades are property-for-property only (no money component), matching the original game's `exchangeProperties` method. Properties with houses cannot be traded — houses must be sold to the bank first. Both players must confirm the trade.
- `turnEnd`: Turn passes to next player

### Board Configuration

Static board data lives in a local `board_config.dart` file, NOT in the database. Only dynamic state (owner, houses) is stored in Supabase.

Each square definition includes:

| Field | Description |
|-------|-------------|
| `index` | Position on the board (0-39) |
| `name` | Display name (e.g. "LEBLON") |
| `type` | One of: `property`, `company`, `luckSetback`, `incomeTax`, `profitsDividends`, `prison`, `goToPrison`, `freeParking`, `start` |
| `colorGroup` | For properties: one of 8 groups (rosa, azul, vinho, laranja, vermelho, amarelo, verde, roxo). 2-4 properties per group. |
| `price` | Purchase price (properties and companies) |
| `rentTable` | Array of 6 rents: [base, 1 house, 2 houses, 3 houses, 4 houses, hotel] |
| `housePrice` | Cost to build one house |
| `companyTax` | For companies: flat fee multiplied by dice roll |

**Square type behaviors:**
- **property**: Purchasable. Rent scales with houses. Must own all in color group to build.
- **company**: Purchasable. Rent = flat fee x dice sum. No houses.
- **luckSetback**: Draw a card from the deck. Effects: gain/lose money, go to prison, get-out-of-jail card.
- **incomeTax**: Pay $200.
- **profitsDividends**: Receive $200.
- **prison**: Just visiting (no effect). Separate from being arrested.
- **goToPrison**: Player is arrested. If they have a get-out-of-jail card, it is consumed automatically and they stay on the square without going to prison.
- **start**: Collect $200 salary when passing.
- **freeParking**: No effect.

### Supabase Tables

| Table | Purpose |
|-------|---------|
| `games` | One row per game room. `state` JSONB column holds GameState. `room_code` column for joining. |
| `profiles` | User display name, avatar, stats |

## Online Multiplayer

### Architecture: Supabase Realtime as Authority

Game state lives in a Supabase Postgres table. Each player action writes to the DB, and all players subscribe to real-time changes via Supabase Realtime (Postgres Changes).

This approach works because Monopoly is turn-based — 100-200ms latency is invisible. Benefits: server-authoritative, state persists for reconnection, minimal infrastructure.

### Room Lifecycle

1. **Host creates room** — inserts row into `games` with `status: waiting`, gets 6-char alphanumeric code
2. **Players join** — enter code, added to `players` array, pick a color from remaining
3. **Ready up** — each player marks ready; host sees "Start Game" when 2+ ready
4. **Game starts** — `status: playing`, luck cards shuffled, turn order is join order

### Turn Execution

1. Active player sees action buttons; others see "waiting for [name]"
2. Player rolls dice -> client computes new GameState -> writes to Supabase
3. All clients receive update via Realtime subscription and animate
4. Square-specific prompts (buy?) change `turnPhase` — only active player sees actions

### Concurrency Control

Updates use optimistic locking via a `version` integer on the `games` row:

```sql
UPDATE games SET state = $new_state, version = version + 1
WHERE id = $game_id AND version = $expected_version
```

If the update affects 0 rows, the client re-reads the current state and retries. This prevents stale writes from corrupting game state. In practice, conflicts are rare because only the active player writes during their turn.

### Validation

Game logic runs on the acting player's client for v1. Acceptable because:
- Casual game, not competitive ranked
- State visible to all players
- Server-side validation can be added via Edge Functions later without data model changes

### Disconnection

- Rejoin via room code (state persists in DB)
- Auto-forfeit turn after 3 minutes disconnected
- Supabase Presence tracks online status

## AI Opponents (Single Player)

- Same `GameState` model, runs entirely local (no Supabase)
- AI players are `Player` objects with `isAI: true` flag
- After human turn ends, AI turns execute with short delay for animation
- AI strategy (rule-based):
  - Buy property if affordable and balance stays above $200
  - Build houses when monopoly is complete, prioritizing highest-rent groups
  - Never initiate trades
  - Pay to leave prison immediately

## UI Layout

### GameScreen (Portrait)

```
┌──────────────────────────┐
│  Top Bar                 │
│  (current player + $)    │
├──────────────────────────┤
│                          │
│     Board                │
│     (pinch-to-zoom,      │
│      pan, tap squares)   │
│                          │
├──────────────────────────┤
│  Players Strip           │
│  (horizontal scroll,     │
│   avatars + money)       │
├──────────────────────────┤
│  Action Area             │
│  (dice, buy/sell buttons,│
│   game log)              │
└──────────────────────────┘
```

### Board Rendering

- `CustomPainter` draws the board on canvas — 40 squares in classic rectangular layout
- Programmatic rendering (not static image) — scales to any screen size
- Pawns: colored circles with player initials
- Houses: small colored rectangles; hotel: larger rectangle
- Tap square -> bottom sheet with property detail (owner, rent table, house price)
- `InteractiveViewer` for pinch-to-zoom and pan

### Interactions

| Action | UI Pattern |
|--------|-----------|
| Dice roll | Tap button, animated dice, result displayed |
| Buy property | Bottom sheet with property card, Yes/No |
| Build/Sell | Bottom sheet with owned properties list |
| Trade | Multi-step bottom sheet: your property -> opponent -> their property -> confirm |
| Debt resolution | Modal blocking until debt resolved or elimination |

### Key Animations

- Pawn slides square-by-square along the path
- Dice tumble animation
- Cards flip in from deck
- Money counter animates up/down
- Houses pop in when built

### Game Log

Expandable area at bottom showing recent events. Collapsed by default, shows last action.

## Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── board_config.dart        # 40 squares static data
│   ├── card_config.dart         # Luck/setback card definitions
│   ├── theme.dart               # App theme
│   └── constants.dart           # Initial money, prison fee, etc.
│
├── models/
│   ├── game_state.dart          # GameState + turnPhase enum (freezed)
│   ├── player.dart              # Player model (freezed)
│   ├── board_square.dart        # BoardSquare types (freezed)
│   ├── luck_card.dart           # LuckCard + CardType enum (freezed)
│   └── dice_roll.dart           # DiceRoll model (freezed)
│
├── providers/
│   ├── auth_provider.dart       # Supabase Auth state
│   ├── game_provider.dart       # GameState provider (core bridge)
│   ├── lobby_provider.dart      # Room creation, joining, ready
│   └── ai_provider.dart         # AI decision logic
│
├── services/
│   ├── supabase_service.dart    # Supabase client, realtime, CRUD
│   └── audio_service.dart       # Sound effects
│
├── screens/
│   ├── home_screen.dart
│   ├── lobby_screen.dart
│   ├── game_screen.dart
│   └── settings_screen.dart
│
├── widgets/
│   ├── board/
│   │   ├── board_painter.dart   # CustomPainter
│   │   ├── board_widget.dart    # InteractiveViewer wrapper
│   │   └── pawn_widget.dart     # Animated pawn
│   ├── game/
│   │   ├── dice_widget.dart     # Dice animation
│   │   ├── player_strip.dart    # Horizontal player list
│   │   ├── action_panel.dart    # Action buttons
│   │   ├── game_log.dart        # Event log
│   │   └── property_card.dart   # Property detail sheet
│   ├── lobby/
│   │   └── player_slot.dart     # Lobby player with color picker
│   └── common/
│       ├── money_counter.dart   # Animated money
│       └── loading_overlay.dart
│
└── utils/
    ├── game_logic.dart          # Pure functions (rent, monopoly check, etc.)
    └── room_code.dart           # Generate/validate room codes
```

### Architecture Principles

- **`game_logic.dart` contains pure functions** — takes GameState + action, returns new GameState. No side effects. Fully testable.
- **`game_provider.dart`** bridges logic and persistence — calls game_logic, writes to Supabase (online) or updates local state (AI).
- **Models are immutable** with `copyWith` via freezed.
- **Board painting is isolated** from game logic — `board_painter.dart` only draws.
- **Same GameState model** for online and AI modes — only the persistence layer differs.
