import 'package:flutter/material.dart';

class BankMiniLogo extends StatelessWidget {
  const BankMiniLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF003FB3),
        borderRadius: BorderRadius.circular(size * 22 / 76),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003FB3).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        label: 'Logo Bank Mini Sekolah',
        image: true,
        child: CustomPaint(
          size: Size.square(size * 0.5),
          painter: _LandmarkPainter(),
        ),
      ),
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);

    final roof = Path()
      ..moveTo(11.119, 2.205)
      ..arcToPoint(
        const Offset(12.881, 2.205),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..lineTo(20.721, 6.051)
      ..arcToPoint(
        const Offset(20.5, 7),
        radius: const Radius.circular(0.5),
        clockwise: true,
      )
      ..lineTo(3.5, 7)
      ..arcToPoint(
        const Offset(3.279, 6.051),
        radius: const Radius.circular(0.5),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(roof, paint);

    final columns = Path()
      ..moveTo(10, 18)
      ..lineTo(10, 11)
      ..moveTo(14, 18)
      ..lineTo(14, 11)
      ..moveTo(18, 18)
      ..lineTo(18, 11)
      ..moveTo(6, 18)
      ..lineTo(6, 11)
      ..moveTo(3, 22)
      ..lineTo(21, 22);
    canvas.drawPath(columns, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter oldDelegate) => false;
}
