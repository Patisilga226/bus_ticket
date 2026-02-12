# Bus Admin Dashboard Flutter

Tableau de bord d'administration pour la gestion de transport & ticketing bus, inspiré d'un design moderne (cartes de stats, graphiques, sidebar, etc.).

## Lancer le projet

Depuis un terminal :

```bash
cd "$HOME/Downloads/bus_admin_dashboard_flutter"
flutter pub get
flutter run -d chrome   # ou un autre device Flutter
```

## Structure

- `pubspec.yaml` : dépendances (Flutter, Google Fonts, fl_chart…)
- `lib/main.dart` : point d'entrée + thème global (Material 3, Poppins, couleurs pastel)
- `lib/ui/dashboard_shell.dart` : layout global (sidebar, topbar, zone de contenu)
- `lib/ui/pages/dashboard_page.dart` : contenu du dashboard (statistiques, graphiques, listes)
- `lib/ui/widgets/*` : composants réutilisables (`StatCard`, `RecentBookingTile`, etc.)

