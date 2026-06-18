import 'package:clue/services/router.dart';
import 'package:flutter/material.dart';

class NavbarComponent extends StatefulWidget {
  const NavbarComponent({super.key});

  @override
  State<NavbarComponent> createState() => _NavbarComponentState();
}

class _NavbarComponentState extends State<NavbarComponent> {
  String _selectedRoute = '/';

  void _setRoute(String route) {
    setState(() {
      _selectedRoute = route;
    });

    router.go(route);
  }

  Color _selectedIconColor(String route) {
    return _selectedRoute == route ? const Color.fromRGBO(33, 7, 51, 1) : Colors.grey.shade500;
  }
  
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 95,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
            Column(
            children: [
              IconButton(
              icon: Icon(Icons.home, color: _selectedIconColor('/')),
              onPressed: () => _setRoute('/'),
              ),
              Text('Home', style: TextStyle(color: _selectedIconColor('/'))),
            ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 30),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromRGBO(33, 7, 51, 1)),
                  shape: WidgetStateProperty.all(const CircleBorder()),
                  padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
                ),
                onPressed: () => _setRoute('/scan'),
                )
              ],
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.map, color: _selectedIconColor('/map')),
                  onPressed: () => _setRoute('/map'),
                ),
                Text('Map', style: TextStyle(color: _selectedIconColor('/map'))),
              ],
            ),
        ],
      ),
    );
  }
}