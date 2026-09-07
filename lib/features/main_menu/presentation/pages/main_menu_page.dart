// ignore_for_file: unused_element

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/jungle_background.dart';
import '../../../../shared/widgets/wild_dice_logo.dart';
import '../../domain/main_menu_identity.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({required this.identityController, super.key});

  final MainMenuIdentityController identityController;

  @override
  Widget build(BuildContext context) {
    return MainMenu(identityController: identityController);
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({required this.identityController, super.key});

  final MainMenuIdentityController identityController;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _nicknameController = TextEditingController(
      text: widget.identityController.nickname,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;

        return Scaffold(
          backgroundColor: const Color(0xFF11162D),
          body: Stack(
            children: [
              const Positioned.fill(child: JungleBackground()),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        compact ? 8 : 12,
                        22,
                        compact ? 14 : 20,
                      ),
                      child: Column(
                        children: [
                          const Spacer(),
                          AnimatedLogo(
                            animation: _entranceController,
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 8 : 16),
                          _IdentityPicker(
                            identityController: widget.identityController,
                            nicknameController: _nicknameController,
                            compact: compact,
                          ),
                          const SizedBox(height: 14),
                          _ButtonsEntrance(
                            animation: _entranceController,
                            child: Column(
                              children: [
                                GameButton(
                                  label: 'CREATE GAME',
                                  icon: Icons.add,
                                  color: const Color(0xFFFF5BA8),
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRouter.createGame),
                                ),
                                const SizedBox(height: 14),
                                GameButton(
                                  label: 'JOIN GAME',
                                  icon: Icons.login_rounded,
                                  color: const Color(0xFF3DA7FF),
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRouter.joinGame),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IdentityPicker extends StatelessWidget {
  const _IdentityPicker({
    required this.identityController,
    required this.nicknameController,
    required this.compact,
  });

  final MainMenuIdentityController identityController;
  final TextEditingController nicknameController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: identityController,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.sizeOf(context);
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : screenSize.width;
          final width = math.min(availableWidth, screenSize.width) * 0.9;
          final height = screenSize.height < 650
              ? 62.0
              : screenSize.height < 700
              ? 80.0
              : 86.0;

          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFBDBAB2),
                          width: 2,
                        ),
                        color: const Color(0xFFD5D2CA),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                      ),
                      child: Row(
                        children: [
                          Semantics(
                            key: const Key('avatar-picker'),
                            button: true,
                            label: 'Choose avatar',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _showAvatarCarousel(
                                  context,
                                  identityController,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: compact ? 22 : 28,
                                      backgroundColor: const Color(0xFFE3DED2),
                                      backgroundImage: AssetImage(
                                        AppAssets.avatars[identityController
                                            .avatarId]!,
                                      ),
                                    ),
                                    const Positioned(
                                      right: -3,
                                      bottom: -3,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Color(0xFF8BCB2A),
                                        child: Icon(
                                          Icons.edit,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 12 : 16),
                          Expanded(
                            child: TextField(
                              key: const Key('nickname-field'),
                              controller: nicknameController,
                              maxLength: 20,
                              onChanged: identityController.updateNickname,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF2B2A24),
                                fontSize: compact ? 17 : 20,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'your name',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9B9B96),
                                  fontWeight: FontWeight.w500,
                                ),
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 56 : 72),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _showAvatarCarousel(
  BuildContext context,
  MainMenuIdentityController identityController,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.62,
      child: _AvatarCarouselSheet(identityController: identityController),
    ),
  );
}

class _AvatarCarouselSheet extends StatefulWidget {
  const _AvatarCarouselSheet({required this.identityController});

  final MainMenuIdentityController identityController;

  @override
  State<_AvatarCarouselSheet> createState() => _AvatarCarouselSheetState();
}

class _AvatarCarouselSheetState extends State<_AvatarCarouselSheet> {
  static const _avatarNames = <String, String>{
    'avatar_01': 'JAGUAR',
    'avatar_02': 'BLACK PANTHER',
    'avatar_03': 'KOALA',
    'avatar_04': 'WOLF',
    'avatar_05': 'FROG',
    'avatar_06': 'CROCODILE',
    'avatar_07': 'TOUCAN',
    'avatar_08': 'MONKEY',
    'avatar_09': 'PANDA',
    'avatar_10': 'SNAKE',
  };

  late final List<MapEntry<String, String>> _avatars;
  late final PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _avatars = AppAssets.avatars.entries.toList(growable: false);
    _selectedIndex = _avatars.indexWhere(
      (entry) => entry.key == widget.identityController.avatarId,
    );
    if (_selectedIndex < 0) _selectedIndex = 0;
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.22,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index >= _avatars.length) return;
    setState(() => _selectedIndex = index);
    widget.identityController.updateAvatar(_avatars[index].key);
  }

  void _move(int direction) {
    final next = (_selectedIndex + direction).clamp(0, _avatars.length - 1);
    if (next == _selectedIndex) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _avatars[_selectedIndex];
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF102E1D)),
          child: Stack(
            children: [
              SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 470;
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB9C6A9,
                            ).withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 16),
                        Text(
                          'CHOOSE YOUR AVATAR',
                          style: GoogleFonts.lilitaOne(
                            color: const Color(0xFFF3E5B8),
                            fontSize: compact ? 22 : 28,
                            letterSpacing: 1.1,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 6 : 12),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PageView.builder(
                                key: const Key('avatar-carousel'),
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: _select,
                                itemCount: _avatars.length,
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedIndex;
                                  final entry = _avatars[index];
                                  return Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isSelected) return;
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(
                                            milliseconds: 320,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        );
                                      },
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.28 : 0.88,
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: AnimatedOpacity(
                                          opacity: isSelected ? 1 : 0.62,
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          child: _AvatarMedallion(
                                            imagePath: entry.value,
                                            name: _avatarNames[entry.key]!,
                                            selected: isSelected,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                left: 10,
                                child: _CarouselArrow(
                                  icon: Icons.chevron_left_rounded,
                                  label: 'Previous avatar',
                                  enabled: _selectedIndex > 0,
                                  onPressed: () => _move(-1),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                child: _CarouselArrow(
                                  icon: Icons.chevron_right_rounded,
                                  label: 'Next avatar',
                                  enabled: _selectedIndex < _avatars.length - 1,
                                  onPressed: () => _move(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            _avatarNames[selected.key]!,
                            key: ValueKey(selected.key),
                            style: GoogleFonts.lilitaOne(
                              color: const Color(0xFFF3E5B8),
                              fontSize: compact ? 20 : 25,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 5 : 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _avatars.length,
                            (index) => AnimatedContainer(
                              key: Key('avatar-indicator-$index'),
                              duration: const Duration(milliseconds: 220),
                              width: index == _selectedIndex ? 10 : 6,
                              height: index == _selectedIndex ? 10 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _selectedIndex
                                    ? const Color(0xFF9DDB2F)
                                    : const Color(0xFF76866B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 14),
                        SizedBox(
                          width: 150,
                          height: 44,
                          child: FilledButton.icon(
                            key: const Key('confirm-avatar'),
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4D7D1A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: const BorderSide(
                                  color: Color(0xFF91B83B),
                                  width: 2,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              'CHOOSE',
                              style: GoogleFonts.lilitaOne(letterSpacing: .8),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 14),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarMedallion extends StatelessWidget {
  const _AvatarMedallion({
    required this.imagePath,
    required this.name,
    required this.selected,
  });

  final String imagePath;
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      selected: selected,
      label: name,
      child: Container(
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFF9DDB2F) : const Color(0xFF76512D),
          border: Border.all(
            color: selected ? const Color(0xFFC4F75A) : const Color(0xFFA9824B),
            width: selected ? 4 : 3,
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
            if (selected)
              const BoxShadow(color: Color(0x889DDB2F), blurRadius: 18),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: const Color(0xFF17271B),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: IconButton.filled(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(46),
          backgroundColor: const Color(0xFF3D6C1D),
          disabledBackgroundColor: const Color(0xFF294322),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          side: const BorderSide(color: Color(0xFF739832), width: 2),
          shadowColor: Colors.black,
          elevation: 6,
        ),
      ),
    );
  }
}

class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    required this.animation,
    this.compact = false,
    super.key,
  });

  final Animation<double> animation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.18),
          end: Offset.zero,
        ).animate(curved),
        child: WildDiceLogo(size: compact ? 330 : 450),
      ),
    );
  }
}

class _JungleBackgroundImage extends StatelessWidget {
  const _JungleBackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/main_menu_jungle.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => const _NightCityBackdrop(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NightCityBackdrop extends StatelessWidget {
  const _NightCityBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NightCityBackdropPainter());
  }
}

class _NightCityBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.58;

    final skyWash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF23295A), Color(0xFF1B1E46), Color(0xFF11162D)],
        stops: [0, 0.48, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyWash);

    final centerGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFF4FB8).withValues(alpha: 0.46),
              const Color(0xFF8A4DFF).withValues(alpha: 0.28),
              const Color(0xFF23295A).withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0, 0.23, 0.52, 1],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, horizonY),
              radius: size.width * 0.62,
            ),
          );
    canvas.drawRect(Offset.zero & size, centerGlow);

    final upperVignette = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF030516).withValues(alpha: 0.58),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.36),
              radius: size.width * 0.86,
            ),
          );
    canvas.drawRect(Offset.zero & size, upperVignette);

    final horizonGlow = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFF4FB8).withValues(alpha: 0.38),
              const Color(0xFF8A4DFF).withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.16,
              horizonY - 34,
              size.width * 0.68,
              78,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, horizonY + 4),
        width: size.width * 0.78,
        height: 92,
      ),
      horizonGlow,
    );

    final buildingPaint = Paint()..color = const Color(0xFF0B0E31);
    final farBuildingPaint = Paint()
      ..color = const Color(0xFF171A4D).withValues(alpha: 0.9);

    void building(
      double x,
      double width,
      double height,
      Paint paint, {
      bool rightWindows = true,
    }) {
      final rect = Rect.fromLTWH(x, horizonY - height, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(width * 0.18)),
        paint,
      );
      final windowColors = [
        const Color(0xFFFF4FB8),
        const Color(0xFF4DCBFF),
        const Color(0xFF8A4DFF),
      ];
      for (var y = rect.top + 14; y < rect.bottom - 8; y += 18) {
        final color = windowColors[(y ~/ 18) % windowColors.length];
        final windowX = rightWindows
            ? rect.left + width * 0.58
            : rect.left + width * 0.26;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(windowX, y, 4, 8),
            const Radius.circular(2),
          ),
          Paint()..color = color.withValues(alpha: 0.48),
        );
      }
    }

    void roundedTower({
      required double x,
      required double baseY,
      required double width,
      required double height,
      required bool rightSide,
      double depth = 18,
    }) {
      final frontRect = Rect.fromLTWH(x, baseY - height, width, height);
      final radius = Radius.circular(width * 0.24);
      final frontPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151C55).withValues(alpha: 0.98),
            const Color(0xFF090C2B),
          ],
        ).createShader(frontRect);
      final sidePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF33105A).withValues(alpha: 0.95),
            const Color(0xFF120421).withValues(alpha: 0.98),
          ],
        ).createShader(frontRect);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFFF4FB8).withValues(alpha: 0.34);

      final sidePath = Path()
        ..moveTo(
          rightSide ? frontRect.left : frontRect.right,
          frontRect.top + width * 0.14,
        )
        ..lineTo(
          rightSide ? frontRect.left - depth : frontRect.right + depth,
          frontRect.top + width * 0.26,
        )
        ..lineTo(
          rightSide ? frontRect.left - depth : frontRect.right + depth,
          frontRect.bottom,
        )
        ..lineTo(rightSide ? frontRect.left : frontRect.right, frontRect.bottom)
        ..close();
      canvas.drawPath(sidePath, sidePaint);

      canvas.drawRRect(RRect.fromRectAndRadius(frontRect, radius), frontPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(frontRect, radius), glowPaint);

      final windowColors = [
        const Color(0xFFFF4FB8),
        const Color(0xFF8A4DFF),
        const Color(0xFF4DCBFF),
      ];
      final cols = width > size.width * 0.12 ? 2 : 1;
      for (var row = 0; row < 5; row++) {
        for (var col = 0; col < cols; col++) {
          final wx = frontRect.left + width * (0.32 + col * 0.3);
          final wy = frontRect.top + width * 0.52 + row * height * 0.13;
          if (wy > frontRect.bottom - 24) {
            continue;
          }
          final color = windowColors[(row + col) % windowColors.length];
          final rect = Rect.fromLTWH(wx, wy, width * 0.13, height * 0.055);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(width * 0.035)),
            Paint()..color = color.withValues(alpha: 0.86),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.inflate(2),
              Radius.circular(width * 0.05),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = color.withValues(alpha: 0.35),
          );
        }
      }

      final basePaint = Paint()..color = const Color(0xFF0A0D2D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            frontRect.left - width * 0.08,
            frontRect.bottom - 8,
            width * 1.22,
            14,
          ),
          const Radius.circular(7),
        ),
        basePaint,
      );
    }

    building(
      size.width * 0.03,
      size.width * 0.12,
      size.height * 0.25,
      farBuildingPaint,
      rightWindows: false,
    );
    building(
      size.width * 0.15,
      size.width * 0.10,
      size.height * 0.18,
      buildingPaint,
    );
    building(
      size.width * 0.76,
      size.width * 0.10,
      size.height * 0.20,
      buildingPaint,
      rightWindows: false,
    );
    building(
      size.width * 0.88,
      size.width * 0.11,
      size.height * 0.27,
      farBuildingPaint,
    );

    roundedTower(
      x: size.width * 0.015,
      baseY: horizonY + size.height * 0.08,
      width: size.width * 0.15,
      height: size.height * 0.31,
      rightSide: false,
      depth: size.width * 0.035,
    );
    roundedTower(
      x: size.width * 0.13,
      baseY: horizonY + size.height * 0.12,
      width: size.width * 0.10,
      height: size.height * 0.22,
      rightSide: false,
      depth: size.width * 0.028,
    );
    roundedTower(
      x: size.width * 0.82,
      baseY: horizonY + size.height * 0.07,
      width: size.width * 0.15,
      height: size.height * 0.32,
      rightSide: true,
      depth: size.width * 0.035,
    );
    roundedTower(
      x: size.width * 0.73,
      baseY: horizonY + size.height * 0.13,
      width: size.width * 0.10,
      height: size.height * 0.21,
      rightSide: true,
      depth: size.width * 0.028,
    );

    final roadPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF39246A).withValues(alpha: 0.56),
              const Color(0xFF141633).withValues(alpha: 0.96),
            ],
          ).createShader(
            Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
          );
    final roadPath = Path()
      ..moveTo(size.width * 0.32, horizonY)
      ..lineTo(size.width * 0.68, horizonY)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.78,
        size.width * 0.96,
        size.height,
      )
      ..lineTo(size.width * 0.04, size.height)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.78,
        size.width * 0.32,
        horizonY,
      )
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    final roadGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF6676FF).withValues(alpha: 0.24);
    canvas.drawPath(roadPath, roadGlow);

    final roadCenterGlow = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF4FB8).withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
          );
    canvas.drawPath(roadPath, roadCenterGlow);

    final centerLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF5BA8).withValues(alpha: 0.16);
    canvas.drawLine(
      Offset(size.width * 0.5, horizonY + 12),
      Offset(size.width * 0.5, size.height * 0.95),
      centerLinePaint,
    );

    void rockCluster(double baseX, bool rightSide) {
      final rockPaint = Paint()..color = const Color(0xFF171D52);
      final highlight = Paint()
        ..color = const Color(0xFF4F58C9).withValues(alpha: 0.42);
      final direction = rightSide ? -1.0 : 1.0;
      final baseY = size.height * 0.74;

      for (var i = 0; i < 4; i++) {
        final w = size.width * (0.12 + i * 0.028);
        final h = size.height * (0.055 + i * 0.012);
        final x = baseX + direction * i * size.width * 0.055;
        final y = baseY + i * size.height * 0.035;
        final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(h * 0.45)),
          rockPaint,
        );
        canvas.drawOval(
          Rect.fromLTWH(
            rect.left + w * 0.14,
            rect.top + h * 0.18,
            w * 0.3,
            h * 0.18,
          ),
          highlight,
        );
      }
    }

    rockCluster(size.width * 0.08, false);
    rockCluster(size.width * 0.92, true);

    final foregroundShade = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF050817).withValues(alpha: 0.72),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      foregroundShade,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfettiBackground extends StatelessWidget {
  const ConfettiBackground({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(animation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);

  final double progress;

  static const _colors = [
    Color(0xFFFFD447),
    Color(0xFFFF5BA8),
    Color(0xFF28E0D4),
    Color(0xFFFF8A2A),
    Color(0xFF44E071),
  ];

  static const _particles = [
    _Particle(0.12, 0.12, 0, 0.25, 18),
    _Particle(0.29, 0.08, 1, -0.18, 10),
    _Particle(0.77, 0.11, 2, 0.14, 14),
    _Particle(0.90, 0.22, 3, -0.3, 22),
    _Particle(0.08, 0.36, 4, 0.42, 8),
    _Particle(0.93, 0.43, 0, 0.12, 11),
    _Particle(0.18, 0.58, 1, -0.24, 20),
    _Particle(0.82, 0.63, 2, 0.34, 9),
    _Particle(0.12, 0.82, 3, -0.16, 12),
    _Particle(0.33, 0.88, 4, 0.27, 18),
    _Particle(0.68, 0.86, 0, -0.21, 7),
    _Particle(0.91, 0.78, 1, 0.19, 16),
    _Particle(0.48, 0.17, 2, -0.11, 9),
    _Particle(0.58, 0.72, 3, 0.31, 13),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final drift = math.sin((progress * math.pi * 2) + i) * 5;
      final x = particle.x * size.width;
      final y = (particle.y * size.height) + drift;
      final color = _colors[particle.colorIndex];

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(particle.rotation + progress * 0.25);

      switch (i % 3) {
        case 0:
          canvas.drawLine(
            Offset(-particle.length / 2, 0),
            Offset(particle.length / 2, 0),
            stroke..color = color,
          );
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: particle.length,
                height: 7,
              ),
              const Radius.circular(3),
            ),
            fill..color = color,
          );
        default:
          canvas.drawCircle(Offset.zero, 4, fill..color = color);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  const _Particle(this.x, this.y, this.colorIndex, this.rotation, this.length);

  final double x;
  final double y;
  final int colorIndex;
  final double rotation;
  final double length;
}

class AnimatedTukTuk extends StatelessWidget {
  const AnimatedTukTuk({
    required this.animation,
    required this.size,
    super.key,
  });

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final offsetY = math.sin(animation.value * math.pi * 2) * 2;
        return Transform.translate(offset: Offset(0, offsetY), child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/tuktuk.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const _TukTukPlaceholder(),
        ),
      ),
    );
  }
}

class _TukTukPlaceholder extends StatelessWidget {
  const _TukTukPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TukTukPainter());
  }
}

class _TukTukPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 140;
    Offset p(double x, double y) => Offset(x * scale, y * scale);
    double s(double value) => value * scale;
    final fill = Paint()..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: p(70, 124), width: s(110), height: s(14)),
      Paint()..color = const Color(0x55000000),
    );

    final roof = Path()
      ..moveTo(p(28, 30).dx, p(28, 30).dy)
      ..quadraticBezierTo(
        p(47, 12).dx,
        p(47, 12).dy,
        p(70, 24).dx,
        p(70, 24).dy,
      )
      ..lineTo(p(113, 25).dx, p(113, 25).dy)
      ..quadraticBezierTo(
        p(128, 30).dx,
        p(128, 30).dy,
        p(132, 58).dx,
        p(132, 58).dy,
      )
      ..lineTo(p(132, 78).dx, p(132, 78).dy)
      ..lineTo(p(106, 78).dx, p(106, 78).dy)
      ..lineTo(p(104, 50).dx, p(104, 50).dy)
      ..lineTo(p(46, 48).dx, p(46, 48).dy)
      ..lineTo(p(44, 78).dx, p(44, 78).dy)
      ..lineTo(p(20, 78).dx, p(20, 78).dy)
      ..quadraticBezierTo(
        p(19, 60).dx,
        p(19, 60).dy,
        p(28, 30).dx,
        p(28, 30).dy,
      )
      ..close();
    canvas.drawPath(roof, fill..color = const Color(0xFFFFBE0B));

    final windshield = Path()
      ..moveTo(p(29, 49).dx, p(29, 49).dy)
      ..lineTo(p(45, 49).dx, p(45, 49).dy)
      ..lineTo(p(44, 72).dx, p(44, 72).dy)
      ..quadraticBezierTo(
        p(39, 79).dx,
        p(39, 79).dy,
        p(22, 79).dx,
        p(22, 79).dy,
      )
      ..quadraticBezierTo(
        p(21, 67).dx,
        p(21, 67).dy,
        p(29, 49).dx,
        p(29, 49).dy,
      )
      ..close();
    canvas.drawPath(windshield, fill..color = const Color(0xFFA8DFF2));

    canvas.drawRect(
      Rect.fromLTWH(s(70), s(48), s(8), s(62)),
      fill..color = const Color(0xFFB7B7B7),
    );

    final body = Path()
      ..moveTo(p(20, 78).dx, p(20, 78).dy)
      ..lineTo(p(44, 78).dx, p(44, 78).dy)
      ..lineTo(p(44, 110).dx, p(44, 110).dy)
      ..lineTo(p(105, 110).dx, p(105, 110).dy)
      ..quadraticBezierTo(
        p(103, 91).dx,
        p(103, 91).dy,
        p(118, 86).dx,
        p(118, 86).dy,
      )
      ..lineTo(p(132, 86).dx, p(132, 86).dy)
      ..lineTo(p(132, 112).dx, p(132, 112).dy)
      ..lineTo(p(29, 112).dx, p(29, 112).dy)
      ..quadraticBezierTo(
        p(22, 98).dx,
        p(22, 98).dy,
        p(20, 78).dx,
        p(20, 78).dy,
      )
      ..close();
    canvas.drawPath(body, fill..color = const Color(0xFF08AF4F));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s(88), s(88), s(34), s(30)),
        Radius.circular(s(20)),
      ),
      fill..color = const Color(0xFF2F7F2F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s(103), s(84), s(20), s(6)),
        Radius.circular(s(2)),
      ),
      fill..color = const Color(0xFFFF8A00),
    );

    void wheel(Offset center, double radius) {
      canvas.drawCircle(
        center,
        s(radius),
        fill..color = const Color(0xFF54463E),
      );
      canvas.drawCircle(
        center,
        s(radius * 0.44),
        fill..color = const Color(0xFF1B2023),
      );
      canvas.drawCircle(
        center,
        s(radius * 0.18),
        fill..color = const Color(0xFF54463E),
      );
    }

    wheel(p(28, 116), 18);
    wheel(p(105, 116), 18);

    canvas.drawCircle(p(10, 101), s(8), fill..color = const Color(0xFFD8D8D8));
    canvas.drawOval(
      Rect.fromCenter(center: p(8, 99), width: s(4), height: s(10)),
      fill..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameButton extends StatefulWidget {
  const GameButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GameButtonPalette.forLabel(widget.label);
    final screenSize = MediaQuery.sizeOf(context);
    final buttonHeight = screenSize.height < 650
        ? 62.0
        : screenSize.height < 700
        ? 80.0
        : 86.0;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : screenSize.width;
              final width = math.min(availableWidth, screenSize.width) * 0.9;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onPressed,
                child: SizedBox(
                  width: width,
                  height: buttonHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: palette.shadowGlow.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: palette.border, width: 3),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: palette.gradient,
                              stops: const [0, 0.48, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.16),
                              ],
                              stops: const [0, 0.42, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 7,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.highlight.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.18),
                                blurRadius: 7,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 4,
                        height: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.bottomEdge.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: const Offset(0, -1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, 2),
                                    child: Icon(
                                      widget.icon,
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      size: 23,
                                    ),
                                  ),
                                  Icon(
                                    widget.icon,
                                    color: const Color(0xFFF5EFD8),
                                    size: 23,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              _ButtonLabelText(label: widget.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameButtonPalette {
  const _GameButtonPalette({
    required this.gradient,
    required this.border,
    required this.highlight,
    required this.bottomEdge,
    required this.shadowGlow,
    required this.leafColor,
  });

  final List<Color> gradient;
  final Color border;
  final Color highlight;
  final Color bottomEdge;
  final Color shadowGlow;
  final Color leafColor;

  factory _GameButtonPalette.forLabel(String label) {
    final isCreate = label.toUpperCase().contains('CREATE');
    if (isCreate) {
      return const _GameButtonPalette(
        gradient: [Color(0xFF8BCB2A), Color(0xFF6FAE19), Color(0xFF5A930F)],
        border: Color(0xFF4D7A10),
        highlight: Color(0xFFA9E24A),
        bottomEdge: Color(0xFF356408),
        shadowGlow: Color(0xFF8BCB2A),
        leafColor: Color(0xFF6BBF2A),
      );
    }
    return const _GameButtonPalette(
      gradient: [Color(0xFFF2B129), Color(0xFFE08B13), Color(0xFFC36D08)],
      border: Color(0xFF8C5208),
      highlight: Color(0xFFFFD25A),
      bottomEdge: Color(0xFF7A3D04),
      shadowGlow: Color(0xFFF2B129),
      leafColor: Color(0xFF6BBF2A),
    );
  }
}

class _ButtonLabelText extends StatelessWidget {
  const _ButtonLabelText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.baloo2(
        fontSize: 21,
        height: 1,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFF7F4E8),
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.16),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _ButtonLeafCluster extends StatelessWidget {
  const _ButtonLeafCluster({required this.mirror, required this.color});

  final bool mirror;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: CustomPaint(
        size: const Size(54, 42),
        painter: _ButtonLeafClusterPainter(color),
      ),
    );
  }
}

class _ButtonLeafClusterPainter extends CustomPainter {
  const _ButtonLeafClusterPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    void leaf(Offset center, double length, double angle, Color leafColor) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle);
      final width = length * 0.44;
      final path = Path()
        ..moveTo(0, -length / 2)
        ..cubicTo(width, -length * 0.24, width, length * 0.24, 0, length / 2)
        ..cubicTo(-width, length * 0.24, -width, -length * 0.24, 0, -length / 2)
        ..close();
      canvas.drawPath(path.shift(const Offset(2, 3)), shadow);
      canvas.drawPath(
        path,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [leafColor, const Color(0xFF3E8D1E)],
              ).createShader(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: width,
                  height: length,
                ),
              ),
      );
      canvas.drawLine(
        Offset(0, -length * 0.32),
        Offset(0, length * 0.34),
        vein,
      );
      canvas.restore();
    }

    leaf(const Offset(17, 25), 34, -0.72, color);
    leaf(const Offset(31, 19), 30, -0.18, const Color(0xFF7BD337));
    leaf(const Offset(42, 29), 26, 0.48, const Color(0xFF4E9F24));
  }

  @override
  bool shouldRepaint(covariant _ButtonLeafClusterPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ButtonsEntrance extends StatelessWidget {
  const _ButtonsEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.24, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.28),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class BottomMenu extends StatelessWidget {
  const BottomMenu({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundMenuButton(icon: Icons.emoji_events, compact: compact),
        _RoundMenuButton(icon: Icons.groups, compact: compact),
        _RoundMenuButton(icon: Icons.card_giftcard, compact: compact),
      ],
    );
  }
}

class _RoundMenuButton extends StatelessWidget {
  const _RoundMenuButton({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF27315E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon),
        color: Colors.white,
        iconSize: compact ? 22 : 26,
        padding: EdgeInsets.all(compact ? 12 : 16),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF27315E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.settings),
        color: Colors.white,
        iconSize: compact ? 21 : 24,
        padding: EdgeInsets.all(compact ? 9 : 12),
      ),
    );
  }
}
