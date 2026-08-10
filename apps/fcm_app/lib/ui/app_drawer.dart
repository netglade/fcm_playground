import 'package:flutter/material.dart';

import 'app_destination.dart';

/// The navigation drawer shared by every destination.
///
/// Stateless: the selection lives in `AppShell`, so the drawer cannot disagree
/// with the body about which page is showing.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The destination currently on screen.
  final AppDestination selected;

  /// Called with the destination the user picked.
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    selectedIndex: selected.index,
    onDestinationSelected: (index) => onSelected(AppDestination.values[index]),
    children: const [
      Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text('FCM Sample'),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.inbox_outlined),
        label: Text('Inbox'),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.science_outlined),
        label: Text('Sandbox'),
      ),
    ],
  );
}
