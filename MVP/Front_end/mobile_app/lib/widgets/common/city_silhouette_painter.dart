import 'package:flutter/material.dart';

class CitySilhouettePainter extends CustomPainter {
  final String cityKey;
  final Color color;

  CitySilhouettePainter({required this.cityKey, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintLight = Paint()
      ..color = color.withOpacity(color.opacity * 0.5)
      ..style = PaintingStyle.fill;

    switch (cityKey.toUpperCase()) {
      case 'GZ':
        _drawGuangzhou(canvas, size, paint, paintLight);
        break;
      case 'BJ':
        _drawBeijing(canvas, size, paint, paintLight);
        break;
      case 'SH':
        _drawShanghai(canvas, size, paint, paintLight);
        break;
      case 'SZ':
        _drawShenzhen(canvas, size, paint, paintLight);
        break;
      case 'CD':
        _drawChengdu(canvas, size, paint, paintLight);
        break;
      case 'XA':
        _drawXian(canvas, size, paint, paintLight);
        break;
      default:
        _drawGuangzhou(canvas, size, paint, paintLight);
    }
  }

  void _drawGuangzhou(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Canton Tower (tall narrow spire in left third)
    final tower = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..lineTo(w * 0.08, h * 0.55)
      ..lineTo(w * 0.08, h * 0.45)
      ..lineTo(w * 0.133, h * 0.45)
      ..lineTo(w * 0.133, h * 0.35)
      ..lineTo(w * 0.16, h * 0.35)
      ..lineTo(w * 0.16, h * 0.25)
      ..lineTo(w * 0.173, h * 0.25)
      ..lineTo(w * 0.173, h * 0.15)
      ..lineTo(w * 0.187, h * 0.15)
      ..lineTo(w * 0.187, h * 0.08)
      ..lineTo(w * 0.193, h * 0.08)
      ..lineTo(w * 0.197, h * 0.02)
      ..lineTo(w * 0.2, h * 0.02)
      ..lineTo(w * 0.203, h * 0.08)
      ..lineTo(w * 0.208, h * 0.08)
      ..lineTo(w * 0.208, h * 0.15)
      ..lineTo(w * 0.222, h * 0.15)
      ..lineTo(w * 0.222, h * 0.25)
      ..lineTo(w * 0.248, h * 0.25)
      ..lineTo(w * 0.248, h * 0.35)
      ..lineTo(w * 0.275, h * 0.35)
      ..lineTo(w * 0.275, h * 0.45)
      ..lineTo(w * 0.315, h * 0.45)
      ..lineTo(w * 0.315, h * 0.55)
      // City buildings right side
      ..lineTo(w * 0.44, h * 0.55)
      ..lineTo(w * 0.44, h * 0.6)
      ..lineTo(w * 0.48, h * 0.6)
      ..lineTo(w * 0.48, h * 0.55)
      ..lineTo(w * 0.52, h * 0.55)
      ..lineTo(w * 0.52, h * 0.6)
      ..lineTo(w * 0.56, h * 0.6)
      ..lineTo(w * 0.56, h * 0.55)
      ..lineTo(w * 0.6, h * 0.55)
      ..lineTo(w * 0.6, h * 0.6)
      ..lineTo(w * 0.65, h * 0.6)
      ..lineTo(w * 0.65, h * 0.65)
      ..lineTo(w * 0.72, h * 0.65)
      ..lineTo(w * 0.72, h * 0.6)
      ..lineTo(w * 0.78, h * 0.6)
      ..lineTo(w * 0.78, h * 0.65)
      ..lineTo(w * 0.85, h * 0.65)
      ..lineTo(w * 0.85, h * 0.7)
      ..lineTo(w * 0.93, h * 0.7)
      ..lineTo(w * 0.93, h * 0.75)
      ..lineTo(w, h * 0.75)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(tower, p);
    // Foreground hills
    final hills = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.25, h * 0.8, w * 0.5, h * 0.83)
      ..quadraticBezierTo(w * 0.75, h * 0.86, w, h * 0.85)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hills, pl);
  }

  void _drawBeijing(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Temple of Heaven profile
    final temple = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.6)
      ..lineTo(w * 0.13, h * 0.6)
      ..lineTo(w * 0.13, h * 0.55)
      ..lineTo(w * 0.16, h * 0.55)
      ..lineTo(w * 0.16, h * 0.5)
      ..lineTo(w * 0.2, h * 0.45)
      ..lineTo(w * 0.22, h * 0.4)
      ..lineTo(w * 0.237, h * 0.35)
      ..lineTo(w * 0.245, h * 0.3)
      ..lineTo(w * 0.25, h * 0.25)
      ..lineTo(w * 0.255, h * 0.3)
      ..lineTo(w * 0.263, h * 0.35)
      ..lineTo(w * 0.28, h * 0.4)
      ..lineTo(w * 0.3, h * 0.45)
      ..lineTo(w * 0.34, h * 0.5)
      ..lineTo(w * 0.34, h * 0.55)
      ..lineTo(w * 0.37, h * 0.55)
      ..lineTo(w * 0.37, h * 0.6)
      // Right side buildings
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.55, h * 0.55)
      ..lineTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.59, h * 0.5)
      ..lineTo(w * 0.59, h * 0.55)
      ..lineTo(w * 0.64, h * 0.55)
      ..lineTo(w * 0.64, h * 0.45)
      ..lineTo(w * 0.66, h * 0.35)
      ..lineTo(w * 0.67, h * 0.25)
      ..lineTo(w * 0.68, h * 0.35)
      ..lineTo(w * 0.7, h * 0.45)
      ..lineTo(w * 0.7, h * 0.55)
      ..lineTo(w * 0.75, h * 0.55)
      ..lineTo(w * 0.75, h * 0.6)
      ..lineTo(w * 0.82, h * 0.6)
      ..lineTo(w * 0.82, h * 0.65)
      ..lineTo(w * 0.9, h * 0.65)
      ..lineTo(w * 0.9, h * 0.7)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(temple, p);
    final hills = Path()
      ..moveTo(0, h)..lineTo(0, h*0.87)
      ..quadraticBezierTo(w*0.3, h*0.83, w*0.5, h*0.85)
      ..quadraticBezierTo(w*0.7, h*0.87, w, h*0.87)
      ..lineTo(w, h)..close();
    canvas.drawPath(hills, pl);
  }

  void _drawShanghai(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Oriental Pearl Tower (tall spire left)
    final skyline = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..lineTo(w * 0.07, h * 0.55)
      ..lineTo(w * 0.07, h * 0.45)
      ..lineTo(w * 0.1, h * 0.45)
      ..lineTo(w * 0.1, h * 0.35)
      ..lineTo(w * 0.12, h * 0.35)
      ..lineTo(w * 0.12, h * 0.2)
      ..lineTo(w * 0.14, h * 0.12)
      ..lineTo(w * 0.155, h * 0.05)
      ..lineTo(w * 0.16, h * 0.0)
      ..lineTo(w * 0.165, h * 0.05)
      ..lineTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.2, h * 0.2)
      ..lineTo(w * 0.2, h * 0.35)
      ..lineTo(w * 0.22, h * 0.35)
      ..lineTo(w * 0.22, h * 0.45)
      // Shanghai Tower area
      ..lineTo(w * 0.3, h * 0.45)
      ..lineTo(w * 0.3, h * 0.35)
      ..lineTo(w * 0.33, h * 0.28)
      ..lineTo(w * 0.35, h * 0.28)
      ..lineTo(w * 0.38, h * 0.35)
      ..lineTo(w * 0.38, h * 0.45)
      ..lineTo(w * 0.42, h * 0.45)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.44, h * 0.32)
      ..lineTo(w * 0.46, h * 0.38)
      ..lineTo(w * 0.46, h * 0.45)
      // Right side
      ..lineTo(w * 0.55, h * 0.45)
      ..lineTo(w * 0.55, h * 0.55)
      ..lineTo(w * 0.63, h * 0.55)
      ..lineTo(w * 0.63, h * 0.5)
      ..lineTo(w * 0.68, h * 0.5)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.75, h * 0.55)
      ..lineTo(w * 0.75, h * 0.6)
      ..lineTo(w * 0.85, h * 0.6)
      ..lineTo(w * 0.85, h * 0.65)
      ..lineTo(w, h * 0.65)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(skyline, p);
    final hills = Path()
      ..moveTo(0, h)..lineTo(0, h*0.87)
      ..quadraticBezierTo(w*0.25, h*0.83, w*0.5, h*0.85)
      ..quadraticBezierTo(w*0.75, h*0.88, w, h*0.87)
      ..lineTo(w, h)..close();
    canvas.drawPath(hills, pl);
  }

  void _drawShenzhen(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Ping An tower (tall center spire)
    final skyline = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.6)
      ..lineTo(w * 0.08, h * 0.6)
      ..lineTo(w * 0.08, h * 0.5)
      ..lineTo(w * 0.11, h * 0.45)
      ..lineTo(w * 0.13, h * 0.35)
      ..lineTo(w * 0.15, h * 0.2)
      ..lineTo(w * 0.16, h * 0.1)
      ..lineTo(w * 0.165, h * 0.05)
      ..lineTo(w * 0.17, h * 0.1)
      ..lineTo(w * 0.18, h * 0.2)
      ..lineTo(w * 0.2, h * 0.35)
      ..lineTo(w * 0.22, h * 0.45)
      ..lineTo(w * 0.25, h * 0.5)
      ..lineTo(w * 0.25, h * 0.6)
      ..lineTo(w * 0.33, h * 0.6)
      ..lineTo(w * 0.33, h * 0.5)
      ..lineTo(w * 0.36, h * 0.45)
      ..lineTo(w * 0.39, h * 0.5)
      ..lineTo(w * 0.39, h * 0.6)
      ..lineTo(w * 0.47, h * 0.6)
      ..lineTo(w * 0.47, h * 0.55)
      ..lineTo(w * 0.52, h * 0.5)
      ..lineTo(w * 0.57, h * 0.55)
      ..lineTo(w * 0.57, h * 0.6)
      ..lineTo(w * 0.65, h * 0.6)
      ..lineTo(w * 0.65, h * 0.55)
      ..lineTo(w * 0.72, h * 0.55)
      ..lineTo(w * 0.72, h * 0.6)
      ..lineTo(w * 0.8, h * 0.6)
      ..lineTo(w * 0.8, h * 0.65)
      ..lineTo(w * 0.9, h * 0.65)
      ..lineTo(w * 0.9, h * 0.7)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(skyline, p);
    final hills = Path()
      ..moveTo(0, h)..lineTo(0, h*0.87)
      ..quadraticBezierTo(w*0.3, h*0.83, w*0.5, h*0.85)
      ..quadraticBezierTo(w*0.7, h*0.87, w, h*0.87)
      ..lineTo(w, h)..close();
    canvas.drawPath(hills, pl);
  }

  void _drawChengdu(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Rolling hills + pagoda + panda silhouette
    final skyline = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.1, h * 0.58, w * 0.18, h * 0.55)
      ..quadraticBezierTo(w * 0.25, h * 0.52, w * 0.35, h * 0.55)
      ..lineTo(w * 0.38, h * 0.55)
      ..lineTo(w * 0.38, h * 0.5)
      ..lineTo(w * 0.4, h * 0.45)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.43, h * 0.35)
      ..lineTo(w * 0.44, h * 0.38)
      ..lineTo(w * 0.46, h * 0.45)
      ..lineTo(w * 0.48, h * 0.5)
      ..lineTo(w * 0.48, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.52, w * 0.62, h * 0.55)
      ..quadraticBezierTo(w * 0.7, h * 0.58, w * 0.78, h * 0.55)
      ..quadraticBezierTo(w * 0.85, h * 0.52, w * 0.92, h * 0.58)
      ..lineTo(w, h * 0.6)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(skyline, p);
    // Panda face
    final pandaPaint = Paint()..color = p.color.withOpacity(p.color.opacity * 0.7)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.7, h * 0.42), w * 0.04, pandaPaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.44), w * 0.015, p);
    canvas.drawCircle(Offset(w * 0.74, h * 0.44), w * 0.015, p);
    // Hills foreground
    final hills = Path()
      ..moveTo(0, h)..lineTo(0, h*0.87)
      ..quadraticBezierTo(w*0.25, h*0.83, w*0.5, h*0.85)
      ..quadraticBezierTo(w*0.75, h*0.88, w, h*0.87)
      ..lineTo(w, h)..close();
    canvas.drawPath(hills, pl);
  }

  void _drawXian(Canvas canvas, Size s, Paint p, Paint pl) {
    final w = s.width;
    final h = s.height;
    // Big Wild Goose Pagoda + city wall
    final skyline = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.06, h * 0.65)
      ..lineTo(w * 0.06, h * 0.6)
      // City wall section
      ..lineTo(w * 0.2, h * 0.6)
      ..lineTo(w * 0.2, h * 0.55)
      // Pagoda
      ..lineTo(w * 0.22, h * 0.55)
      ..lineTo(w * 0.22, h * 0.5)
      ..lineTo(w * 0.24, h * 0.45)
      ..lineTo(w * 0.25, h * 0.38)
      ..lineTo(w * 0.255, h * 0.3)
      ..lineTo(w * 0.258, h * 0.22)
      ..lineTo(w * 0.26, h * 0.18)
      ..lineTo(w * 0.262, h * 0.22)
      ..lineTo(w * 0.265, h * 0.3)
      ..lineTo(w * 0.27, h * 0.38)
      ..lineTo(w * 0.28, h * 0.45)
      ..lineTo(w * 0.3, h * 0.5)
      ..lineTo(w * 0.3, h * 0.55)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.32, h * 0.6)
      // Right city wall
      ..lineTo(w * 0.46, h * 0.6)
      ..lineTo(w * 0.46, h * 0.65)
      ..lineTo(w * 0.55, h * 0.65)
      ..lineTo(w * 0.55, h * 0.6)
      ..lineTo(w * 0.62, h * 0.58)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.77, h * 0.6)
      ..lineTo(w * 0.77, h * 0.65)
      ..lineTo(w * 0.85, h * 0.65)
      ..lineTo(w * 0.85, h * 0.68)
      ..lineTo(w * 0.93, h * 0.68)
      ..lineTo(w * 0.93, h * 0.7)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(skyline, p);
    // Wall detail rectangles
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.6, w * 0.1, h * 0.04),
      Paint()..color = p.color.withOpacity(p.color.opacity * 0.4),
    );
    final hills = Path()
      ..moveTo(0, h)..lineTo(0, h*0.87)
      ..quadraticBezierTo(w*0.3, h*0.83, w*0.5, h*0.85)
      ..quadraticBezierTo(w*0.7, h*0.87, w, h*0.87)
      ..lineTo(w, h)..close();
    canvas.drawPath(hills, pl);
  }

  @override
  bool shouldRepaint(covariant CitySilhouettePainter oldDelegate) {
    return oldDelegate.cityKey != cityKey || oldDelegate.color != color;
  }
}
