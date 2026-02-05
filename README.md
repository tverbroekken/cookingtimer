# Cooking Timer

A beautiful iOS cooking timer app that helps you coordinate multiple dishes for perfect meal timing. Built with SwiftUI and featuring Apple's Liquid Glass design system.

<div align="center">
  <img src="Screenshots/meals-list.png" width="250" alt="Meals List">
  <img src="Screenshots/meal-detail.png" width="250" alt="Meal Detail">
  <img src="Screenshots/cooking-view-5burners.png" width="250" alt="Active Cooking">
</div>

## ✨ Features

### 🍳 Smart Timer Sequencing
- Create meals with multiple timers for different dishes
- Set up complex timer dependencies:
  - **Manual**: Start timers manually when you're ready
  - **With Meal**: Start automatically when you begin cooking
  - **After Timer Starts**: Begin X seconds/minutes after another timer starts
  - **When Timer Completes**: Start automatically when another timer finishes

### 🔥 Stove Burner Visualization
- Realistic stove burner interface with glowing effects
- Color-coded status indicators:
  - Dark gray: Waiting to start
  - Orange/Red: Actively cooking
  - Yellow: Paused
  - Green: Completed
- Animated pulsing glow for running timers

### 💎 Modern Design
- Built with Apple's **Liquid Glass** design system
- Beautiful card-based layouts
- Smooth animations and transitions
- Native iOS design patterns
- Dark mode support

### 📱 User Experience
- Intuitive meal creation and editing
- Visual timeline showing total cooking time
- Easy timer management with drag-to-reorder
- Haptic feedback on timer completion
- Persistent storage with SwiftData + CloudKit sync

### 🔔 Timer Completion Notifications
- **Full-screen alert** when timers complete (like Clock app)
- **Repeating timer sound** that plays until dismissed
- **Critical alerts** that bypass silent mode and Do Not Disturb
- **Background notifications** when app is not active
- Shows timer name and meal context
- Prominent "Stop" button to dismiss

### 🎙️ Siri Integration
- **Voice control** for hands-free cooking
- **"Start cooking [meal name]"** - Begin cooking a saved meal
- **"List my meals"** - Hear all your saved meals
- **App Shortcuts** for quick access from Spotlight and Siri
- **Siri suggestions** based on your cooking patterns
- Seamless integration with Apple Intelligence

### 📖 Recipe Integration
- **Import from websites** - Automatically parse recipes from URLs
- **JSON-LD parsing** - Extract ingredients, instructions, and cooking times
- **Recipe library** - Browse and search your recipe collection
- **Create meals from recipes** - Auto-generate sequential timers from recipe steps
- **Smart timer selection** - Choose which timed steps become timers
- **Seamless workflow** - Import → Browse → Create Meal → Cook

## 📸 Screenshots

### Meal Management
<div align="center">
  <img src="Screenshots/meals-list.png" width="250" alt="Meals List">
  <img src="Screenshots/meal-detail-compact.png" width="250" alt="Meal Overview">
</div>

### Timer Configuration
<div align="center">
  <img src="Screenshots/add-timer.png" width="250" alt="Add Timer">
  <img src="Screenshots/timer-details.png" width="250" alt="Timer Details">
  <img src="Screenshots/edit-timer.png" width="250" alt="Edit Timer">
</div>

### Active Cooking
<div align="center">
  <img src="Screenshots/cooking-view-2burners.png" width="250" alt="Cooking - 2 Burners">
  <img src="Screenshots/cooking-view-5burners.png" width="250" alt="Cooking - 5 Burners">
</div>

## 🛠 Technical Details

### Built With
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's latest data persistence framework
- **CloudKit**: Automatic cloud sync across devices
- **Liquid Glass**: Apple's newest design system
- **App Intents**: Siri and Shortcuts integration
- **Combine**: Reactive timer management

### Requirements
- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+

### Architecture
- **MVVM pattern** with SwiftUI
- **SwiftData models** with enum support via raw value storage
- **ID-based relationships** for robust timer dependencies
- **Observable pattern** for reactive state management
- **Automatic schema migration** during development

### Key Implementations
- Custom `@Model` classes with computed properties for enums
- UUID-based timer relationships to avoid SwiftData conflicts
- Real-time timer coordination with `DispatchQueue` scheduling
- Liquid Glass effects using `.glassProminent` and `.glass` button styles
- Custom burner views with animated glow effects
- Critical alert notifications with `AudioServicesPlaySystemSound` for repeating timer sounds
- Full-screen timer completion view with animated UI
- App Intents with `MealEntity`, `StartCookingIntent`, and `ListMealsIntent`
- `AppShortcutsProvider` for Siri phrase registration
- `SiriTipView` components for user discoverability

## 🚀 Getting Started

1. Clone the repository
```bash
git clone https://github.com/yourusername/cooking-timer.git
```

2. Open in Xcode
```bash
cd cooking-timer
open "Cooking Timer.xcodeproj"
```

3. Build and run on your device or simulator

## 💡 Usage Examples

### Simple Meal
Perfect for straightforward cooking:
- **Pasta**: 12 minutes (Start with meal)
- **Sauce**: 8 minutes (Start with meal)

### Complex Meal with Sequencing
For advanced coordination:
- **Pre-heat oven**: 10 minutes (Start with meal)
- **Chicken**: 45 minutes (Start when oven pre-heat completes)
- **Vegetables**: 20 minutes (Start 25 minutes after chicken starts)
- **Bread**: 5 minutes (Start 40 minutes after chicken starts)

Everything finishes at the same time!

### Using Siri
Voice commands for hands-free cooking:
- **"Hey Siri, start cooking Pasta Dinner in Cooking Timer"**
- **"Hey Siri, list my meals in Cooking Timer"**
- **"Hey Siri, show my meals in Cooking Timer"**

App Shortcuts also appear in:
- Spotlight search
- Shortcuts app
- Siri suggestions

## 🎨 Design Philosophy

This app embraces Apple's design principles:
- **Clarity**: Clean, focused interface with clear visual hierarchy
- **Deference**: Content-first design with beautiful but unobtrusive UI
- **Depth**: Layers, shadows, and depth create realistic connections

The stove burner metaphor provides an intuitive, skeuomorphic interface that makes timer status immediately apparent.

## 🔮 Future Enhancements

- [ ] Apple Watch companion app
- [ ] Widget support for home screen
- [ ] Timer templates for common dishes
- [ ] Share meals with family/friends
- [ ] Add timers via Siri with natural language ("Add 10 minute pasta timer")
- [ ] Manual recipe creation and editing
- [ ] Recipe categories and tags

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with assistance from Claude (Anthropic)
- Inspired by real-world cooking coordination challenges
- Uses Apple's Liquid Glass design system
- SwiftUI sample code patterns from Apple's Landmarks app

---

**Built with ❤️ by Tom Verbroekken**
