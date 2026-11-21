import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/player_repository.dart';
import 'monster_select_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PlayerRepository _player = PlayerRepository.instance;
  bool _loading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await _player.loadOrCreate(user);
    if (mounted) setState(() => _loading = false);
  }

  void _openModule(String title, IconData icon, Color color,
      {String id = ''}) {
    if (id == 'bosses') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MonsterSelectScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title — модуль переносится на следующем этапе'),
        backgroundColor: kPanelColor,
      ),
    );
  }

  List<Widget> get _modules => const [
        ModuleCard('Профиль', Icons.person, Colors.teal, 'profile'),
        ModuleCard('Таверна', Icons.local_bar, Colors.deepOrange, 'tavern'),
        ModuleCard('Гильдия', Icons.shield, kGoldColor, 'guild'),
        ModuleCard('Задания', Icons.assignment, Colors.green, 'quests'),
        ModuleCard('Карта', Icons.map, Colors.blue, 'map'),
        ModuleCard('Боссы', Icons.bolt, Colors.red, 'bosses'),
        ModuleCard('Рынок', Icons.storefront, Colors.purple, 'market'),
        ModuleCard('Аукцион', Icons.gavel, Colors.indigo, 'auction'),
        ModuleCard('Инвентарь', Icons.backpack, Colors.brown, 'inventory'),
        ModuleCard('Почта', Icons.mail, Colors.cyan, 'mail'),
        ModuleCard('Арена', Icons.sports_mma, Colors.pink, 'arena'),
        ModuleCard('Настройки', Icons.settings, Colors.grey, 'settings'),
      ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 68,
        automaticallyImplyLeading: false,
        title: _loading
            ? const Text('Загрузка...')
            : _player.isLoaded
                ? const Center(child: _PlayerStatsRow())
                : const Center(child: Text('Aventoria')),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                _player.applyData(null);
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
              },
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: kPanelColor,
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('AVENTORIA',
                        style: TextStyle(
                            color: kGoldColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              for (final item in [
                ('Профиль', Icons.person, Colors.teal, 'profile'),
                ('Ремесло', Icons.handyman, Colors.amber, 'craft'),
                ('Инвентарь', Icons.backpack, Colors.brown, 'inventory'),
                ('Аукцион', Icons.gavel, Colors.indigo, 'auction'),
                ('Задания', Icons.assignment, Colors.green, 'quests'),
                ('Почта', Icons.mail, Colors.cyan, 'mail'),
                ('Настройки', Icons.settings, Colors.grey, 'settings'),
              ])
                ListTile(
                  leading: Icon(item.$2, color: item.$3),
                  title: Text(item.$1),
                  onTap: () {
                    Navigator.pop(context);
                    _openModule(item.$1, item.$2, item.$3);
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: kPanelColor,
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomBarButton(
              icon: Icons.menu,
              label: 'Меню',
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            BottomBarButton(
              icon: Icons.shield,
              label: 'Гильдия',
              onTap: () => _openModule('Гильдия', Icons.shield, kGoldColor),
            ),
            BottomBarButton(
              icon: Icons.local_bar,
              label: 'Таверна',
              onTap: () =>
                  _openModule('Таверна', Icons.local_bar, Colors.deepOrange),
            ),
            BottomBarButton(
              icon: Icons.storefront,
              label: 'Рынок',
              onTap: () =>
                  _openModule('Рынок', Icons.storefront, Colors.purple),
            ),
            BottomBarButton(
              icon: Icons.map,
              label: 'Карта',
              onTap: () => _openModule('Карта', Icons.map, Colors.blue),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_player.isLoaded || _player.data == null)
                  const SizedBox(height: 0)
                else
                  ..._modules,
              ],
            ),
    );
  }
}

class BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BottomBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatsRow extends StatelessWidget {
  const _PlayerStatsRow();

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset('assets/images/ui/gold_icon.png', width: 28, height: 28),
          Text(
            _format(player.gold),
            style: const TextStyle(color: kGoldColor, fontSize: 18),
          ),
          const SizedBox(width: 16),
          Image.asset('assets/images/ui/rune_icon.png', width: 28, height: 28),
          Text(
            _format(player.rune),
            style: const TextStyle(color: kGoldColor, fontSize: 18),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ур. ${player.level}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String id;

  const ModuleCard(this.title, this.icon, this.color, this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kPanelColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (id == 'bosses') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MonsterSelectScreen()),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title — модуль переносится на следующем этапе'),
              backgroundColor: kPanelColor,
            ),
          );
        },
      ),
    );
  }
}
